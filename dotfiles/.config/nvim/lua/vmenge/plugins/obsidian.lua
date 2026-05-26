local daily_notes = {
  personal = "~/brain/👷 areas/personal/daily",
  work = "~/brain/👷 areas/work/daily",
}

local function normalize_dir(path)
  return vim.fn.fnamemodify(vim.fn.expand(path), ":p"):gsub("/$", "")
end

local function previous_daily_note(dir, today)
  local previous = nil

  for _, path in ipairs(vim.fn.globpath(dir, "*.md", false, true)) do
    local date = vim.fn.fnamemodify(path, ":t"):match("^(%d%d%d%d%-%d%d%-%d%d)%.md$")

    if date and date < today and (previous == nil or date > previous.date) then
      previous = { date = date, path = path }
    end
  end

  return previous and previous.path or nil
end

local function daily_note_outline_lines(path, opts)
  local carried = {}
  local heading_stack = {}
  local emitted_headings = {}
  local heading_id = 0

  if not path or vim.fn.filereadable(path) == 0 then
    return carried
  end

  local include_completed = opts and opts.include_completed

  for _, line in ipairs(vim.fn.readfile(path)) do
    local marks = line:match("^(#+)%s+")

    if marks then
      heading_id = heading_id + 1
      local level = #marks

      if level == 1 then
        heading_stack = {}
      else
        while #heading_stack > 0 and heading_stack[#heading_stack].level >= level do
          table.remove(heading_stack)
        end

        table.insert(heading_stack, { id = heading_id, level = level, line = line })
      end
    else
      local state = line:match("^%s*[-*+]%s+%[([^%]])%]")

      if state and (include_completed or state:lower() ~= "x") then
        local common = 0

        while common < #heading_stack and common < #emitted_headings do
          if heading_stack[common + 1].id ~= emitted_headings[common + 1].id then
            break
          end

          common = common + 1
        end

        if common ~= #heading_stack or common ~= #emitted_headings then
          if #carried > 0 then
            table.insert(carried, "")
          end

          for index = common + 1, #heading_stack do
            table.insert(carried, heading_stack[index].line)
          end

          emitted_headings = {}
          for index, heading in ipairs(heading_stack) do
            emitted_headings[index] = heading
          end
        end

        table.insert(carried, line)
      end
    end
  end

  return carried
end

local function open_daily_note(kind)
  local dir = normalize_dir(daily_notes[kind])
  local today = os.date("%Y-%m-%d")
  local path = dir .. "/" .. today .. ".md"

  vim.fn.mkdir(dir, "p")

  if vim.fn.filereadable(path) == 0 then
    local lines = { "# " .. today }
    local template = daily_note_outline_lines(dir .. "/template.md", { include_completed = true })
    local carried = daily_note_outline_lines(previous_daily_note(dir, today))

    for _, block in ipairs({ template, carried }) do
      if #block > 0 then
        if #lines > 1 then
          table.insert(lines, "")
        end

        for _, line in ipairs(block) do
          table.insert(lines, line)
        end

      end
    end

    if #lines > 1 then
      table.insert(lines, "")
    end

    vim.fn.writefile(lines, path)
  end

  vim.cmd.edit(vim.fn.fnameescape(path))
end

return {
  "obsidian-nvim/obsidian.nvim",
  version = "*", -- use latest release, remove to use latest commit
  keys = {
    { "<leader>op", function() open_daily_note("personal") end, desc = "Personal Daily" },
    { "<leader>ow", function() open_daily_note("work") end, desc = "Work Daily" },
  },
  ---@module 'obsidian'
  ---@type obsidian.config
  opts = {
    legacy_commands = false, -- this will be removed in the next major release
    workspaces = {
      {
        name = "personal",
        path = "~/brain",
      },
    },
  },
  config = function(_, opts)
    require("obsidian").setup(opts)

    vim.api.nvim_create_user_command("ObsidianDailyPersonal", function() open_daily_note("personal") end, {})
    vim.api.nvim_create_user_command("ObsidianDailyWork", function() open_daily_note("work") end, {})
  end,
}
