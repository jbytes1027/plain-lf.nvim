local SELECTED_FILEPATH = vim.fn.stdpath("cache") .. "/lf_selected_files"

local M = {}

---Configurable user options.
---@class Options
---@field enable_cmds boolean set commands
---@field replace_netrw boolean
---@field ui UI

---@class UI
---@field border string (see ':h nvim_open_win')
---@field height number from 0 to 1 (0 = 0% of screen and 1 = 100% of screen)
---@field width number from 0 to 1 (0 = 0% of screen and 1 = 100% of screen)
---@field x number from 0 to 1 (0 = left most of screen and 1 = right most of
---screen)
---@field y number from 0 to 1 (0 = top most of screen and 1 = bottom most of
---screen)
local opts = {
	enable_cmds = false,
	replace_netrw = false,
	ui = {
		border = "rounded",
		height = 0.9,
		width = 0.9,
		x = 0.5,
		y = 0.5,
	},
}

---Opens all files in `filepath` using `open`.
---@param filepath string
---@param open function
local function open_files(filepath, open)
	local selected_files = vim.fn.readfile(filepath)
	for _, file in ipairs(selected_files) do
		open(file)
	end
end

---Builds the ranger command to be executed with open().
---@param select_current_file boolean open ranger with the current buffer file selected.
---@return string
local function build_lf_cmd(select_current_file)
	lf_cmd = "lf"
	lf_cmd = lf_cmd .. ' -selection-path="' .. SELECTED_FILEPATH .. '"'

	if select_current_file and vim.fn.expand("%") then
		lf_cmd = lf_cmd .. ' "' .. vim.fn.expand("%") .. '"'
	end

	return lf_cmd
end

local function get_win_options()
	local from_height = vim.o.lines
	local from_width = vim.o.columns

	from_height = from_height - vim.o.cmdheight
	if vim.o.laststatus ~= 0 then
		from_height = from_height - 1
	end

	local popup_height = math.floor(from_height * opts.ui.height)
	local popup_width = math.floor(from_width * opts.ui.width)

	padding_y = from_height - popup_height
	padding_x = from_width - popup_width

	local row = math.floor(padding_y * opts.ui.y)
	local col = math.floor(padding_x * opts.ui.x)

    local win_width
    local win_height
	if opts.ui.border == "none" then
        win_height = popup_height
        win_width = popup_width
    elseif opts.ui.border ~= "none" then
		win_height = popup_height - 2
		win_width = popup_width - 2
	end

	return {
		relative = "editor",
		width = win_width,
		height = win_height,
		border = opts.ui.border,
		row = row,
		col = col,
		style = "minimal",
		zindex = 1000,
	}
end

---Open a window for ranger to run in.
local function open_win()
	local buf = vim.api.nvim_create_buf(false, true)
	local win = vim.api.nvim_open_win(buf, true, get_win_options())
	vim.api.nvim_win_set_option(win, "winhl", "NormalFloat:Normal")
	vim.api.nvim_create_autocmd("VimResized", {
		buffer = buf,
		callback = function()
			vim.api.nvim_win_set_config(win, get_win_options())
		end,
	})
end

---Clean up temporary files used to communicate between ranger and the plugin.
local function clean_up()
	vim.fn.delete(SELECTED_FILEPATH)
end

---Opens lf and open selected files on exit.
---@param select_current_file boolean|nil open lf and select the current file. Defaults to true.
function M.open(select_current_file)
	if vim.fn.executable("lf") ~= 1 then
		vim.api.nvim_err_write("lf executable not found, please check that lf is installed and is in your path\n")
		return
	end

	if select_current_file == nil then
		select_current_file = true
	end

	clean_up()

	local cmd = build_lf_cmd(select_current_file)
	local last_win = vim.api.nvim_get_current_win()
	open_win()
	vim.fn.termopen(cmd, {
		on_exit = function()
			vim.api.nvim_win_close(0, true)
			vim.api.nvim_set_current_win(last_win)
			if vim.fn.filereadable(SELECTED_FILEPATH) == 1 then
				open_files(SELECTED_FILEPATH, vim.cmd.edit)
			end
			clean_up()
		end,
	})
	vim.cmd.startinsert()
end

---Disable and replace netrw with ranger.
local function replace_netrw()
	vim.g.loaded_netrw = 1
	vim.g.loaded_netrwPlugin = 1
	vim.api.nvim_create_autocmd("VimEnter", {
		pattern = "*",
		callback = function()
			if vim.fn.isdirectory(vim.fn.argv(0)) == 1 then
				M.open(false)
			end
			return true
		end,
	})
end

---Optional setup to configure ranger.nvim.
---@param user_opts Options Configurable options.
function M.setup(user_opts)
	if user_opts then
		opts = vim.tbl_deep_extend("force", opts, user_opts)
	end
	if opts.replace_netrw then
		replace_netrw()
	end
	if opts.enable_cmds then
		vim.cmd('command! Lf lua require("plain-lf-nvim").open(true)')
	end
end

return M
