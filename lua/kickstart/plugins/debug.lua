-- C/C++ debugging with LLVM's lldb-dap. See README.md for the workflow.
vim.pack.add {
  'https://github.com/mfussenegger/nvim-dap',
  'https://github.com/rcarriga/nvim-dap-ui',
  'https://github.com/nvim-neotest/nvim-nio',
}

local dap = require 'dap'
local dapui = require 'dapui'

-- Ubuntu installs versioned names such as lldb-dap-18. Prefer an unversioned
-- binary, then try versioned binaries on PATH. Set vim.g.lldb_dap before this
-- module is loaded to use a particular LLVM installation.
local function find_lldb_dap()
  if vim.g.lldb_dap then return vim.fn.exepath(vim.g.lldb_dap) end
  local command = vim.fn.exepath 'lldb-dap'
  if command ~= '' then return command end
  local candidates = {}
  local separator = vim.fn.has 'win32' == 1 and ';' or ':'
  for _, directory in ipairs(vim.split(vim.env.PATH or '', separator, { plain = true, trimempty = true })) do
    vim.list_extend(candidates, vim.fn.glob(directory .. '/lldb-dap-[0-9]*', false, true))
  end
  table.sort(candidates, function(a, b) return (tonumber(a:match '(%d+)$') or 0) > (tonumber(b:match '(%d+)$') or 0) end)
  for _, candidate in ipairs(candidates) do
    if vim.fn.executable(candidate) == 1 then return candidate end
  end
  return ''
end

local lldb_dap = find_lldb_dap()
dap.adapters['lldb-dap'] = {
  type = 'executable',
  command = lldb_dap ~= '' and lldb_dap or 'lldb-dap',
  name = 'lldb',
}

local function pick_program()
  if lldb_dap == '' then
    vim.notify('lldb-dap not found. Install LLDB or set vim.g.lldb_dap to its executable path.', vim.log.levels.ERROR)
    return dap.ABORT
  end
  local path = vim.fn.input { prompt = 'Path to executable: ', default = vim.fn.getcwd() .. '/', completion = 'file' }
  if path == '' then return dap.ABORT end
  path = vim.fn.fnamemodify(vim.fn.expand(path), ':p')
  if vim.fn.executable(path) ~= 1 or vim.fn.isdirectory(path) == 1 then
    vim.notify('Not an executable file: ' .. path .. '. Build with -g -O0 first.', vim.log.levels.ERROR)
    return dap.ABORT
  end
  return path
end

for _, filetype in ipairs { 'c', 'cpp' } do
  dap.configurations[filetype] = {
    {
      name = 'C/C++: Launch executable (LLDB)',
      type = 'lldb-dap',
      request = 'launch',
      program = pick_program,
      cwd = '${workspaceFolder}',
      args = {},
      stopOnEntry = false,
      -- Disable stalled debuginfod downloads while preserving local symbol lookup.
      initCommands = { 'settings clear plugin.symbol-locator.debuginfod.server-urls' },
      -- A terminal resize should not interrupt the program.
      preRunCommands = { 'process handle -p true -s false -n false SIGWINCH' },
      -- Supported by LLDB 18 as well as newer versions; allows stdin input.
      runInTerminal = true,
    },
    {
      name = 'C/C++: Attach to process (LLDB)',
      type = 'lldb-dap',
      request = 'attach',
      pid = require('dap.utils').pick_process,
      cwd = '${workspaceFolder}',
      initCommands = { 'settings clear plugin.symbol-locator.debuginfod.server-urls' },
      preRunCommands = { 'process handle -p true -s false -n false SIGWINCH' },
    },
  }
end

vim.keymap.set('n', '<F5>', dap.continue, { desc = 'Debug: Start / Continue' })
vim.keymap.set('n', '<F10>', dap.step_over, { desc = 'Debug: Step Over' })
vim.keymap.set('n', '<F11>', dap.step_into, { desc = 'Debug: Step Into' })
vim.keymap.set('n', '<S-F11>', dap.step_out, { desc = 'Debug: Step Out' })
vim.keymap.set('n', '<F7>', dapui.toggle, { desc = 'Debug: Toggle UI' })
vim.keymap.set('n', '<leader>dc', dap.continue, { desc = '[D]ebug: Start / [C]ontinue' })
vim.keymap.set('n', '<leader>db', dap.toggle_breakpoint, { desc = '[D]ebug: Toggle [B]reakpoint' })
vim.keymap.set('n', '<leader>dB', function() dap.set_breakpoint(vim.fn.input 'Breakpoint condition: ') end, { desc = '[D]ebug: Conditional [B]reakpoint' })
vim.keymap.set('n', '<leader>dn', dap.step_over, { desc = '[D]ebug: [N]ext line (step over)' })
vim.keymap.set('n', '<leader>di', dap.step_into, { desc = '[D]ebug: Step [I]nto' })
vim.keymap.set('n', '<leader>do', dap.step_out, { desc = '[D]ebug: Step [O]ut' })
vim.keymap.set('n', '<leader>dt', dap.terminate, { desc = '[D]ebug: [T]erminate' })
vim.keymap.set('n', '<leader>dr', dap.run_last, { desc = '[D]ebug: [R]un last' })
vim.keymap.set('n', '<leader>du', dapui.toggle, { desc = '[D]ebug: Toggle [U]I' })
vim.keymap.set({ 'n', 'x' }, '<leader>de', function() dapui.eval() end, { desc = '[D]ebug: [E]valuate expression' })

---@diagnostic disable-next-line: missing-fields
dapui.setup {
  icons = { expanded = '▾', collapsed = '▸', current_frame = '*' },
  ---@diagnostic disable-next-line: missing-fields
  controls = {
    icons = {
      pause = '⏸',
      play = '▶',
      step_into = '⏎',
      step_over = '⏭',
      step_out = '⏮',
      step_back = 'b',
      run_last = '▶▶',
      terminate = '⏹',
      disconnect = '⏏',
    },
  },
}

dap.listeners.after.event_initialized['dapui_config'] = function() dapui.open() end
dap.listeners.before.event_terminated['dapui_config'] = function() dapui.close() end
dap.listeners.before.event_exited['dapui_config'] = function() dapui.close() end
