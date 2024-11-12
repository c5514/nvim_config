local ls = require("luasnip")
local util = require("luasnip.util.util")
local node_util = require("luasnip.nodes.util")
local fmt = require("luasnip.extras.fmt").fmt
local s = ls.snippet
local sn = ls.snippet_node
local t = ls.text_node
local i = ls.insert_node
local d = ls.dynamic_node
local r = ls.restore_node

local function find_dynamic_node(node)
	-- the dynamicNode-key is set on snippets generated by a dynamicNode only (its'
	-- actual use is to refer to the dynamicNode that generated the snippet).
	while not node.dynamicNode do
		node = node.parent
	end
	return node.dynamicNode
end

local external_update_id = 0
-- func_indx to update the dynamicNode with different functions.
function dynamic_node_external_update(func_indx)
	local current_node = ls.session.current_nodes[vim.api.nvim_get_current_buf()]
	local dynamic_node = find_dynamic_node(current_node)

	external_update_id = external_update_id + 1
	current_node.external_update_id = external_update_id
	local current_node_key = current_node.key

	local insert_pre_call = vim.fn.mode() == "i"
	local cursor_pos_end_relative = util.pos_sub(
		util.get_cursor_0ind(),
		current_node.mark:get_endpoint(1)
	)

	node_util.leave_nodes_between(dynamic_node.snip, current_node)

	local func = dynamic_node.user_args[func_indx]
	if func then
		func(dynamic_node.parent.snippet)
	end
	dynamic_node.last_args = nil
	dynamic_node:update()

	local target_node = dynamic_node:find_node(function(test_node)
		return (test_node.external_update_id == external_update_id) or
			(current_node_key ~= nil and test_node.key == current_node_key)
	end)

	if target_node then
		node_util.enter_nodes_between(dynamic_node, target_node)

		if insert_pre_call then
			util.set_cursor_0ind(
				util.pos_add(
					target_node.mark:get_endpoint(1),
					cursor_pos_end_relative
				)
			)
		else
			node_util.select_node(target_node)
		end
		ls.session.current_nodes[vim.api.nvim_get_current_buf()] = target_node
	else
		ls.session.current_nodes[vim.api.nvim_get_current_buf()] = dynamic_node.snip:jump_into(1)
	end
end

--
local function column_count_from_string(descr)
	return #(descr:gsub("[^clm]", ""))
end

-- function for the dynamicNode.
local tab = function(args, snip)
	local cols = column_count_from_string(args[1][1])
	if not snip.rows then
		snip.rows = 1
	end
	local nodes = {}
	local ins_indx = 1
	for j = 1, snip.rows do
		table.insert(nodes, r(ins_indx, tostring(j) .. "x1", i(1)))
		ins_indx = ins_indx + 1
		for k = 2, cols do
			table.insert(nodes, t " & ")
			table.insert(nodes, r(ins_indx, tostring(j) .. "x" .. tostring(k), i(1)))
			ins_indx = ins_indx + 1
		end
		table.insert(nodes, t { "\\\\", "" })
	end
	nodes[#nodes] = t ""
	return sn(nil, nodes)
end

--
ls.add_snippets('tex', {
	s("test", fmt([[
\begin{{tabular}}{{{}}}
{}
\end{{tabular}}
]], { i(1, "c"), d(2, tab, { 1 }, {
		user_args = {
			function(snip) snip.rows = snip.rows + 1 end,
			function(snip) snip.rows = math.max(snip.rows - 1, 1) end
		}
	}) })),
})
