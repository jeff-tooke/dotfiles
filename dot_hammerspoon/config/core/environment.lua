local constants = require("config.core.constants")

local function isHome()
  return hs.wifi.currentNetwork() == constants.homeSSID
end

local function hasInternalDisplay()
  for _, screen in ipairs(hs.screen.allScreens()) do
    if screen:name():lower():find("built%-in") then
      return true
    end
  end
  return false
end

local function isDocked()
  for _, screen in ipairs(hs.screen.allScreens()) do
    if screen:name() == constants.homeMonitorName then
      return true
    end
  end
  return false
end

return {
  getContext = function()
    return {
      isHome = isHome(),
      isDocked = isDocked(),
      hasInternalDisplay = hasInternalDisplay()
    }
  end
}
