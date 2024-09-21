--
--------------------------------------------------------------------------------
-- sql.lua
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

function RegisterHooks ()

  function SendKeysPostHook_SQL ()
    -- TODO: check whether the semi-colon needs to be escaped
    os.execute("tmux send-keys -t " .. t:repl_pane_id .. " '\\;' c-m"
  end

  -- register hook as tab-scoped variable
  vim.t.SendKeysPostHook = SendKeysPostHook_SQL
end

-- vim.cmd [[
-- function! RegisterHooks()
--
--     function! SendKeysPostHook_SQL()
--       execute "silent !tmux send-keys -t\\" . t:repl_pane_id . " '\\;' c-m"
--     endfunction!
--
--     " Register hooks as tab-scoped variables
--     let t:SendKeysPostHook = function("SendKeysPostHook_SQL")
--
-- endfunction!
-- ]]
