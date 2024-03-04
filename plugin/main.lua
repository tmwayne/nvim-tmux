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

-- TODO: add REPL specific hooks
-- TODO: convert to lua
-- TODO: ensure error message shows when REPL fails to start

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

vim.cmd [[
command! -nargs=1 StartRepl call StartRepl(<args>)

nnoremap <silent> <localleader>r :call RunCode("char")<cr>
vnoremap <silent> <localleader>r :<c-u>call RunCode(visualmode())<cr>

" Press \q in the editor window to close the interpreter
nnoremap <silent> <localleader>q :call QuitRepl()<cr>

" Press <Ctrl-q> in the interpreter window to close the interpreter
" tnoremap <silent> <c-q> <c-w>: :call QuitRepl()<cr>

" Close interpreter window when quitting from the editor window.
augroup close_interp_on_exit
  autocmd!
  autocmd QuitPre * :call QuitRepl()
augroup END
]]

vim.cmd [[
function! IsWide()
  " Check the terminal dimensions.
  " When Vim is in full screen, the interpreter window will be opened
  " to the left or right, whichever is default.
  " On the otherhand, when Vim is in half screen, 
  " the interpreter window will be either above or below.
  return (2.5 * &lines) < &columns
endfunction!
]]

vim.cmd [[
function! ReplExists()
  " Determine whether tmux list-panes found the repl pane by
  " the return code from the function
  if !exists("t:repl_pane_id")
    return v:false
  endif

  " This command fails if there is a space between `-t` and t:repl_pane_id
  call system(['tmux', 'list-panes', '-t' . t:repl_pane_id])
  return !v:shell_error
endfunction!
]]

vim.cmd [[
function! RunCode(type)
  " Send the contents of buffer 0. Note this will fail if there's a newline
  " in the buffer

  " If RunCode is executed from normal mode, then make the current line
  " the visual selection
  if a:type !=? 'V'
    normal V:<cr>
  endif

  let t:paste_buffer = "~/.vim_tmux_buffer"
  execute ":silent '<,'> write! " . t:paste_buffer

  if exists("t:SendKeysPreHook")
    call t:SendKeysPreHook()
  endif

  execute "silent !tmux load-buffer -b vim " . t:paste_buffer
  execute "silent !tmux paste-buffer -b vim -d -t \\" . t:repl_pane_id

  if exists("t:SendKeysPostHook")
    call t:SendKeysPostHook()
  endif


endfunction!
]]

vim.cmd [[
function! CleanupTab()
  " Delete tab-scoped variables

  unlet! t:filetype t:replcmd t:repl_pane_id
  if exists("t:SendKeysPreHook")
    unlet! t:SendKeysPreHook
  endif
  
  if exists("t:SendKeysPostHook")
    unlet! t:SendKeysPostHook
  endif
endfunction!
]]

vim.cmd [[
function! GetHighestPaneId()
  " Take the id of the pane created, which will have largest ID
  " `list-panes` return the ids sorted not by pane id but by orientation,
  " sort we sort by pane ids to extract the max
  let pane_ids = split(system(['tmux', 'list-panes', '-F#D']), '\n')
  return sort(pane_ids, {a, b -> a[1:] - b[1:]})[-1]
endfunction!
]]

vim.cmd [[
function! StartRepl(cmd)

  if ReplExists()
    echo "REPL already open"
    return
  endif

  " Start a terminal by running the provided command.
  let tmux_split = "silent !tmux split-window -d "

  let direction = IsWide() ? "-h " : "-v "

  let max_pane_id = GetHighestPaneId()

  " Note that the command fails, this still sets v:shell_error to 0
  execute tmux_split . direction . a:cmd

  let t:repl_pane_id = GetHighestPaneId()
  if max_pane_id == t:repl_pane_id
    unlet! t:repl_pane_id
    " Explicitly redraw to ensure message is shown (see :help echo-redraw)
    redraw | echom "Failed to start REPL"
    return
  endif

  " Set filetype for tab in case we accidently close the editor
  let t:replcmd = a:cmd
  let t:filetype = &ft

  " Load any filetype specific hooks. These hooks are registered
  " as tab-scoped variables, allowing multiple tabs with interpreters
  " to be opened without the hooks interferring with each other
  if exists("*RegisterHooks")
    call RegisterHooks()
  endif

endfunction!
]]

vim.cmd [[
function! QuitRepl()
  if !ReplExists()
    echom "No REPL is open"
    return
  endif
  execute "silent !tmux kill-pane -t \\" . t:repl_pane_id
  call CleanupTab()
endfunction!
]]
