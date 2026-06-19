local settings = require("config.settings")

local function isHome()
    local currentSSID = hs.wifi.currentNetwork()
    return currentSSID == settings.homeSSID
end
