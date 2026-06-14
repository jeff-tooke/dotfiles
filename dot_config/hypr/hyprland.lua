-- ~/.config/hypr/hyprland.lua
-- NixOS VM — Hyprland 0.55 Lua config
-- Catppuccin Mocha

------------------
---- MONITOR ----
------------------
hl.monitor({
	output = "Virtual-1",
	mode = "1920x1080@60",
	position = "0x0",
	scale = 1,
})

-------------------------------
---- ENVIRONMENT VARIABLES ----
-------------------------------
hl.env("XCURSOR_SIZE", "24")
hl.env("HYPRCURSOR_SIZE", "24")
hl.env("GDK_BACKEND", "wayland,x11")
hl.env("QT_QPA_PLATFORM", "wayland")
hl.env("MOZ_ENABLE_WAYLAND", "1")

-------------------
---- AUTOSTART ----
-------------------
hl.on("hyprland.start", function()
	hl.exec_cmd("waybar")
	hl.exec_cmd("dunst")
	hl.exec_cmd("hyprpaper")
end)

-----------------------
---- LOOK AND FEEL ----
-----------------------
hl.config({
	general = {
		gaps_in = 5,
		gaps_out = 10,
		border_size = 2,
		col = {
			active_border = { colors = { "rgba(cba6f7ee)", "rgba(89b4faee)" }, angle = 45 },
			inactive_border = "rgba(313244aa)",
		},
		layout = "dwindle",
	},
	decoration = {
		rounding = 8,
		shadow = {
			enabled = true,
			range = 8,
			render_power = 2,
			color = 0xee1e1e2e,
		},
		blur = {
			enabled = true,
			size = 4,
			passes = 2,
			vibrancy = 0.1696,
		},
	},
	animations = {
		enabled = true,
	},
	dwindle = {
		preserve_split = true,
	},
	misc = {
		force_default_wallpaper = 0,
		disable_hyprland_logo = true,
	},
	input = {
		kb_layout = "us",
		follow_mouse = 1,
		sensitivity = 0,
	},
})

---------------------
---- KEYBINDINGS ----
---------------------
local mod = "SUPER"

-- Core
hl.bind(mod .. " + Return", hl.dsp.exec_cmd("foot"))
hl.bind(mod .. " + Space", hl.dsp.exec_cmd("wofi --show drun"))
hl.bind(mod .. " + X", hl.dsp.exec_cmd("swaylock -f -c 1e1e1e"))
hl.bind(mod .. " + Q", hl.dsp.window.close())
hl.bind(mod .. " + SHIFT + Q", hl.dsp.exit())
hl.bind(mod .. " + F", hl.dsp.window.fullscreen({ mode = "fullscreen" }))
hl.bind(mod .. " + V", hl.dsp.window.float({ action = "toggle" }))
hl.bind(mod .. " + P", hl.dsp.window.pseudo())

-- Focus (vim-style)
hl.bind(mod .. " + H", hl.dsp.focus({ direction = "left" }))
hl.bind(mod .. " + L", hl.dsp.focus({ direction = "right" }))
hl.bind(mod .. " + K", hl.dsp.focus({ direction = "up" }))
hl.bind(mod .. " + J", hl.dsp.focus({ direction = "down" }))

-- Move windows
hl.bind(mod .. " + SHIFT + H", hl.dsp.window.move({ direction = "left" }))
hl.bind(mod .. " + SHIFT + L", hl.dsp.window.move({ direction = "right" }))
hl.bind(mod .. " + SHIFT + K", hl.dsp.window.move({ direction = "up" }))
hl.bind(mod .. " + SHIFT + J", hl.dsp.window.move({ direction = "down" }))

-- Workspaces
for i = 1, 9 do
	hl.bind(mod .. " + " .. i, hl.dsp.focus({ workspace = i }))
	hl.bind(mod .. " + SHIFT + " .. i, hl.dsp.window.move({ workspace = i }))
end

-- Scroll through workspaces
hl.bind(mod .. " + mouse_down", hl.dsp.focus({ workspace = "e+1" }))
hl.bind(mod .. " + mouse_up", hl.dsp.focus({ workspace = "e-1" }))

-- Mouse drag
hl.bind(mod .. " + mouse:272", hl.dsp.window.drag(), { mouse = true })
hl.bind(mod .. " + mouse:273", hl.dsp.window.resize(), { mouse = true })

-- Screenshots (needs grim + slurp installed)
hl.bind("Print", hl.dsp.exec_cmd('grim -g "$(slurp)" - | wl-copy'))

----------------------
---- WINDOW RULES ----
----------------------
hl.window_rule({
	name = "suppress-maximize",
	match = { class = ".*" },
	suppress_event = "maximize",
})

hl.window_rule({
	name = "fix-xwayland-drags",
	match = {
		class = "^$",
		title = "^$",
		xwayland = true,
		float = true,
		fullscreen = false,
		pin = false,
	},
	no_focus = true,
})
