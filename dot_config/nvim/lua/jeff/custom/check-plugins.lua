vim.api.nvim_create_user_command("CheckPluginDrift", function()
  local json = vim.fn.stdpath("config") .. "/lazy-lock.json"
  local data = vim.fn.readfile(json)
  if not data then
    print("lazy-lock.json not found")
    return
  end

  local ok, lock = pcall(vim.json.decode, table.concat(data, "\n"))
  if not ok then
    print("Failed to parse lazy-lock.json")
    return
  end

  local base = vim.fn.stdpath("data") .. "/lazy"
  local mismatches = {}

  for plugin, info in pairs(lock) do
    local commit = info.commit
    local head_file = base .. "/" .. plugin .. "/.git/HEAD"
    local ref_file = vim.fn.readfile(head_file)[1]

    -- Resolve the actual commit hash
    local current
    if ref_file:match("^ref:") then
      local ref_path = vim.fn.trim(ref_file:sub(6))
      local full_ref = base .. "/" .. plugin .. "/.git/" .. ref_path
      local ref_data = vim.fn.readfile(full_ref)[1]
      current = ref_data and vim.fn.trim(ref_data)
    else
      current = vim.fn.trim(ref_file)
    end

    if current and current ~= commit then
      table.insert(mismatches, {
        plugin = plugin,
        lock = commit,
        current = current,
      })
    end
  end

  if #mismatches == 0 then
    print("✅ All plugins match lazy-lock.json")
  else
    print("❌ Drift detected in the following plugins:")
    for _, m in ipairs(mismatches) do
      print(string.format(
        "- %s: lockfile=%s, installed=%s",
        m.plugin, m.lock:sub(1, 7), m.current:sub(1, 7)
      ))
    end
  end
end, {
  desc = "Check for plugin drift vs lazy-lock.json",
})
