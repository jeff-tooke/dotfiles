hs.window.animationDuration = 0

hs.hotkey.bind({ "cmd", "alt", "ctrl" }, "R", function()
  hs.reload()
  hs.alert.show("🔁 Reloaded Hammerspoon")
end)
