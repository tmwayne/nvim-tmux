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

function RegisterHooks ()

  -- if the interpreter is ipython, then we need to wrap multi-line code
  -- blocks with a special function so that ipython interprets it correctly.
  -- we only need to do this if it's a multi-line statement with at least
  -- one indented line
  if string.find(vim.t.replcmd, "ipython") then

    function SendKeysPreHook_Python ()

      local has_multiline = "grep -qP '(\t|    )' " .. vim.t.paste_buffer
      if os.execute(has_multiline) ~= 0 then
        vim.t.add_cpaste = false
        return
      end

      vim.t.add_cpaste = true
      os.execute("tmux send-keys -t " .. vim.t.repl_pane_id .. " '%cpaste -q' c-m")

      -- there seems to be a race condition happening, which prevents %cpaste
      -- from working correctly. a short sleep fixes this
      vim.cmd.sleep("50m")
      
    end

    -- send a final <cr>
    function SendKeysPostHook_Python ()
      if vim.t.add_cpaste then
        os.execute("tmux send-keys -t " .. vim.t.repl_pane_id .. " c-d")
      end
    end

    -- register hooks as tab-scoped variables
    vim.t.SendKeysPreHook = SendKeysPreHook_Python
    vim.t.SendKeysPostHook = SendKeysPostHook_Python

  end

end
