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

-- TODO: add <silent> after nnoremp
-- TODO: add <cr><c-l> at end of the line
vim.cmd [[
command! -nargs=1 StartRepl call StartRepl(<args>)

nnoremap <silent> <localleader>r :call RunCode("char")<cr>
vnoremap <silent> <localleader>r :<c-u>call RunCode(visualmode())<cr>

" Press \q in the editor window to close the interpreter
nnoremap <silent> <localleader>q :call QuitRepl()<cr>

" Press <Ctrl-q> in the interpreter window to close the interpreter
tnoremap <silent> <c-q> <c-w>: :call QuitRepl()<cr>

" Close interpreter window when quitting from the editor window.
augroup close_interp_on_exit
  autocmd!
  autocmd QuitPre * :call QuitRepl()
augroup END

function! IsWide()
  " Check the terminal dimensions.
  " When Vim is in full screen, the interpreter window will be opened
  " to the left or right, whichever is default.
  " On the otherhand, when Vim is in half screen, 
  " the interpreter window will be either above or below.
  return (2.5 * &lines) < &columns
endfunction!

function! ExistsRepl()
  " TODO: Somehow associate a tmux pane with the vim editor pane in StartRepl
  " TODO: and then check that that pane still exists in this function
  echom "ExistsRepl"
endfunction!

function! RunCode(type)
  " Send the contents of buffer 0. Note this will fail if there's a newline
  " in the buffer
  execute "!tmux send-keys -t 1 " . shellescape(getreg('0')) . " Enter" 
endfunction!

function! CleanupTab()
  " Delete tab-scoped variables

  unlet! t:filetype t:interpcmd
  if exists("t:SendKeysPreHook")
    unlet! t:SendKeysPreHook
  endif
  
  if exists("t:SendKeysPostHook")
    unlet! t:SendKeysPostHook
  endif
endfunction!

function! QuitRepl()
  if s:ExistsRepl()
    " Clone the correct tmux pane
  endif
  call s:CleanupTab()
endfunction!

function! StartRepl(cmd)

  " Start a terminal by running the provided command.
  let tmux_split = "!tmux split-window -d "

  if IsWide()
    let direction = "-h "
  else
    let direction = "-v "
  endif

  let command = tmux_split . direction . a:cmd 
  execute command

  " Set filetype for tab in case we accidently close the editor
  let t:interpcmd=a:cmd
  let t:filetype=&ft

  " Load any filetype specific hooks. These hooks are registered
  " as tab-scoped variables, allowing multiple tabs with interpreters
  " to be opened without the hooks interferring with each other
  if exists("*RegisterHooks")
    call RegisterHooks()
  endif

endfunction!

]]

-- Mappings code for ide-vim
-- 
-- function! RunCode(type)
--   " Send a command to the terminal.
--   " If the selection is visual, send that.
--   " Otherwise, yank the paragraph and send that.
--   " Use the "@ register and restore it afterwards
-- 
--   if !s:ExistsRepl()
--     return
--   endif
-- 
--   let saved_reg = @@
-- 
--   if a:type ==? 'V'
--     execute "normal! `<" . a:type . "`>y"
--   else
--     normal yip
--   endif
-- 
--   " Exit any pager that may be open before sending keys (e.g., help screen).
--   " Otherwise the code won't execute properly, if at all.
--   " call term_sendkeys(t:interpbufnr, "q\<c-H>")
-- 
--   if exists("t:SendKeysPreHook")
--     call t:SendKeysPreHook()
--   endif
-- 
--   call term_sendkeys(t:interpbufnr, @@)
-- 
--   if exists("t:SendKeysPostHook")
--     call t:SendKeysPostHook()
--   endif
-- 
--   let @@ = saved_reg
-- endfunction!
