--
--------------------------------------------------------------------------------
-- main.lua
--------------------------------------------------------------------------------
--
-- Copyright (c) 2024 Tyler Wayne
--
-- Licensed under the Apache License, Version 2.0 (the "License");
-- you may not use this file except in compliance with the License.
-- You may obtain a copy of the License at
-- 
--     http://www.apache.org/licenses/LICENSE-2.0
-- 
-- Unless required by applicable law or agreed to in writing, software
-- distributed under the License is distributed on an "AS IS" BASIS,
-- WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
-- See the License for the specific language governing permissions and
-- limitations under the License.
--

-- For help on % expanding to the current file name
-- :help _%

-- Other important tmux commands
-- last-pane : select the last (previously selected pane)
-- select-pane -t <target>
--
-- tmux FORMAT variables
-- pane_active : 1 if active pane
-- pane_id : unique pane id (#D)
-- pane_last : 1 if last pane
-- pane_title : Title of pane (can be set by application)
-- window_panes : number of panes in window

function IsWide ()
  -- Check the terminal dimensions. when vim is in full screen, the 
  -- interpreter window will be opened to the left or right, whichever is
  -- default. on the otherhand, when vim is in half screen, the interpreter
  -- window will be either above or below
  return (2.5 * vim.opt.lines:get()) < vim.opt.columns:get()
end


function ReplExists ()
  -- Determine whether the pane exists by whether the tmux list-panes commands
  -- runs successfully when called with the pane-id
  if not vim.t.repl_pane_id then
    return false
  end

  local cmd = {"tmux", "list-panes", "-t", vim.t.repl_pane_id}
  return vim.system(cmd):wait()["code"] == 0
end


function GetHighestPaneId ()
  -- Return the pane id of the last pane create, which is the highest
  local cmd = {"tmux", "list-panes", "-F#D"}
  local stdout = vim.system(cmd, {text=true}):wait()["stdout"]
  local pane_ids = vim.split(vim.trim(stdout), "\n")

  -- Remove the leading % and cast to number
  local function id2number (id) return tonumber(string.sub(id, 2, -1)) end
  table.sort(pane_ids, function(a, b) return id2number(a) < id2number(b) end)

  return pane_ids[#pane_ids]
end


function RunCode (mode)
  -- if normal mode, visually select the current line
  -- TODO: should we select the current paragraph instead?
  if mode == "n" then
    vim.cmd.normal("V:<cr>")
  end

  -- ensure anything being paged is closed before running code
  os.execute("tmux send-keys -t " .. vim.t.repl_pane_id .. " 'q' c-h")

  vim.t.paste_buffer = "~/.tmux_paste_buffer"
  vim.api.nvim_exec2("silent '<,'> write! " .. vim.t.paste_buffer, {})

  -- TODO: figure out to translate this to Lua
  if vim.fn.exists("t:SendKeysPreHook") == 1 then
    vim.api.nvim_exec2("call t:SendKeysPreHook()", {})
  end

  os.execute("tmux load-buffer -b vim " .. vim.t.paste_buffer)
  os.execute("tmux paste-buffer -b vim -d -t " .. vim.t.repl_pane_id)

  if vim.fn.exists("t:SendKeysPostHook") == 1 then
    vim.api.nvim_exec2("call t:SendKeysPostHook()", {})
  end

end


function StartRepl (opts)

  local cmd = opts.fargs[1]

  if ReplExists() then
    vim.notify("REPL already open")
    return
  end

  local tmux_split = "tmux split-window -d "
  local direction = IsWide() and "-h " or "-v "

  local max_pane_id = GetHighestPaneId()

  -- TODO: get full path of command
  -- call system("which " . split(a:cmd, ' ')[0])
  -- if v:shell_error
  --   echom "Path to REPL not found"
  --   return
  -- endif

  os.execute(tmux_split .. direction .. cmd)

  -- check that we opened a new pane
  vim.t.repl_pane_id = GetHighestPaneId()
  if max_pane_id == vim.t.repl_pane_id then
    vim.t.repl_pane_id = nil
    -- vim.cmd.redraw()
    -- TODO: ensure that the message actually shows
    vim.notify("Failed to start REPL")
    return
  end

  -- set filetype for tab in case editor is accidentally closed
  vim.t.replcmd = cmd
  vim.t.filetype = vim.opt.ft:get()

  -- load any filetype specific hook. these hooks are registered
  -- as tab-scored variables, allowing multiple tabs with interpreters
  -- to be opened without the hooks interferring with each other
  if _G["RegisterHooks"] then
    RegisterHooks()
  end

end


function CleanupTab()
  -- Delete tab-scoped variables
  vim.t.filetype = nil
  vim.t.replcmd = nil
  vim.t.repl_pane_id = nil
  vim.t.SendKeysPreHook = nil
  vim.t.SendKeysPostHook = nil
end


function QuitRepl()
  if ReplExists() then
    os.execute("tmux kill-pane -t " .. vim.t.repl_pane_id)
    CleanupTab()
  end
end


-- :help lua-guide-commands-create
vim.api.nvim_create_user_command(
  'StartRepl', 
  function(opts) StartRepl(opts) end,
  { nargs = 1 }
)

vim.keymap.set('n', '<localleader>r', ':call v:lua.RunCode("n")<cr>', {silent=true})
vim.keymap.set('v', '<localleader>r', ':<c-u>call v:lua.RunCode(visualmode())<cr>',
  {silent=true})

-- Press \q in the editor window to close the interpreter
-- vim.keymap.set('n', '<localleader>q', ':call QuitRepl()<cr>', {silent=true})
vim.keymap.set('n', '<localleader>q', QuitRepl, {silent=true})

-- Close interpreter window when quitting from the editor window
vim.api.nvim_create_augroup("close_interp_on_exit", {})
vim.api.nvim_create_autocmd({"QuitPre"}, {
  group = "close_interp_on_exit", 
  callback = function (ev) QuitRepl() end
})
