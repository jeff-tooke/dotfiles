local M = {}

local alertId = nil

function M.show(text)
  -- Kill previous alert if still showing
  if alertId then
    hs.alert.closeSpecific(alertId)
    alertId = nil
  end

  local screen = hs.screen.mainScreen()
  local screenFrame = screen:frame()

  local alertWidth, alertHeight = 300, 50
  local margin = 20

  -- Calculate position: bottom right
  local x = screenFrame.x + screenFrame.w - alertWidth - margin
  local y = screenFrame.y + screenFrame.h - alertHeight - margin

  local customStyle = {
    strokeColor = { white = 1, alpha = 0 },
    fillColor = { white = 0, alpha = 0.7 },
    textColor = { white = 1, alpha = 1 },
    textSize = 16,
    radius = 10,
    atScreenEdge = 2,
    fadeInDuration = 0.2,
    fadeOutDuration = 0.2,
    padding = 10,
  }

  alertId = hs.alert.show(text, customStyle, screen, 1.0)
end

return M
