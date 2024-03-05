--
--------------------------------------------------------------------------------
-- python.lua
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

-- TODO: refine logic for sending cpaste
-- TODO: reduce scope of add_cpaste variable to script (if possible)

vim.cmd [[
function! RegisterHooks()

  " If the interpreter is ipython then we need to wrap
  " multi-line code blocks with a special magic function so that
  " ipython interprets it correctly. We only need to do this if
  " it's a multi-line statement with at least indented one line.
  if stridx(t:replcmd, "ipython") >= 0

    function! SendKeysPreHook_Python()

      call system("grep -qP '(\t|    )' " . t:paste_buffer)
      if v:shell_error
        let t:add_cpaste = v:false
        return
      endif
        
      let t:add_cpaste = v:true
      execute "silent !tmux send-keys -t\\" . t:repl_pane_id . " '\\%cpaste -q' c-m"

      " There seems to be a race condition happening, which prevents
      " %cpaste from working correctly. A short wait fixes this.
      sleep 50m
    endfunction!

    function! SendKeysPostHook_Python()
      if t:add_cpaste
        execute "silent !tmux send-keys -t\\" . t:repl_pane_id . " c-d"
      endif
    endfunction!

    " Register hooks as tab-scoped variables
    let t:SendKeysPreHook = function("SendKeysPreHook_Python")
    let t:SendKeysPostHook = function("SendKeysPostHook_Python")

  endif
endfunction!
]]
