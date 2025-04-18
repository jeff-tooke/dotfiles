local env = require("config.core.environment")
local constants = require("config.core.constants")
local alerts = require("config.core.alerts")

local wifiWatcher, screenWatcher
local lastLayout = nil

local function updateInputSource()
  local ctx = env.getContext()
  local newLayout

  if ctx.isHome and ctx.isDocked and not ctx.hasInternalDisplay then
    newLayout = constants.layout.au
  else
    newLayout = constants.layout.uk
  end

  -- Only change if new layout is different
  if lastLayout ~= newLayout then
       hs.keycodes.setLayout(newLayout)
       alerts.show("🔡 Switched to " .. newLayout .. " layout")
       lastLayout = newLayout
  end
end

local function init()
  updateInputSource()
  wifiWatcher = hs.wifi.watcher.new(updateInputSource)
  wifiWatcher:start()

  screenWatcher = hs.screen.watcher.new(updateInputSource)
  screenWatcher:start()
end

return {
  init = init
}
