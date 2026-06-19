local settings = require("config.settings")

local function isHome()
    local currentSSID = hs.wifi.currentNetwork()
    return currentSSID == settings.homeSSID
end

local function hasInternalDisplay()
    for _, screen in ipairs(hs.screen.allScreens()) do
        if screen:name():lower():find("built%-in") then
            return true
        end
    end
    return false
end

return {
    getContext = function()
        return {
            isHome = isHome(),
            hasInternalDisplay = hasInternalDisplay()
        }
    end
}
