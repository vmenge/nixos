local mainMod = "SUPER"

hl.config({
    ecosystem = {
        no_update_news = true,
    },
    general = {
        gaps_in = 3,
        gaps_out = 8,
    },
    misc = {
        focus_on_activate = true,
        disable_splash_rendering = true,
        disable_hyprland_logo = true,
    },
    render = {
        cm_enabled = true,
        cm_auto_hdr = 1,
    },
    input = {
        touchpad = {
            natural_scroll = true,
        },
    },
})

hl.layer_rule({
    name = "vicinae-blur",
    blur = true,
    ignore_alpha = 0,
    match = { namespace = "vicinae" },
})

hl.layer_rule({
    name = "vicinae-no-animation",
    no_anim = true,
    match = { namespace = "vicinae" },
})

hl.on("hyprland.start", function()
    hl.exec_cmd("uwsm app -- hypridle")
    hl.exec_cmd([[bash -c '[ ! -f /run/user/$(id -u)/kanshi-lock ] && uwsm app -- kanshi']])
    hl.exec_cmd("uwsm app -- hyprpaper")
    hl.exec_cmd("uwsm app -- dunst")
    hl.exec_cmd("uwsm app -- waybar")
    hl.exec_cmd("uwsm app -- vicinae server")
    hl.exec_cmd("uwsm app -- swayosd-server")
    hl.exec_cmd("uwsm app -- handy --start-hidden")
end)

hl.window_rule({
    name = "steam-float",
    match = { initial_class = "^(steam)$" },
    float = true,
})

hl.window_rule({
    name = "steam-games-float",
    match = { initial_class = "^(steam_app_[0-9]+)$" },
    float = true,
})

hl.window_rule({
    name = "detected-games-float",
    match = { content = "game" },
    float = true,
})

hl.bind(mainMod .. " + Return", hl.dsp.exec_cmd("ghostty"))
hl.bind(mainMod .. " + Q", hl.dsp.window.close())
hl.bind(mainMod .. " + D", hl.dsp.exec_cmd("vicinae toggle"))
hl.bind(mainMod .. " + period", hl.dsp.exec_cmd("emote"))
hl.bind(mainMod .. " + Y", hl.dsp.exec_cmd("pkill -USR2 -x handy"))
hl.bind(mainMod .. " + SHIFT + E", hl.dsp.exec_cmd("~/.config/i3/scripts/powermenu"))
hl.bind(mainMod .. " + SHIFT + R", hl.dsp.exec_cmd("hyprctl reload"))

hl.bind(mainMod .. " + H", hl.dsp.focus({ direction = "left" }))
hl.bind(mainMod .. " + J", hl.dsp.focus({ direction = "down" }))
hl.bind(mainMod .. " + K", hl.dsp.focus({ direction = "up" }))
hl.bind(mainMod .. " + L", hl.dsp.focus({ direction = "right" }))

hl.bind(mainMod .. " + SHIFT + H", hl.dsp.window.move({ direction = "left" }))
hl.bind(mainMod .. " + SHIFT + J", hl.dsp.window.move({ direction = "down" }))
hl.bind(mainMod .. " + SHIFT + K", hl.dsp.window.move({ direction = "up" }))
hl.bind(mainMod .. " + SHIFT + L", hl.dsp.window.move({ direction = "right" }))

hl.bind(mainMod .. " + Tab", hl.dsp.focus({ workspace = "e+1" }))
hl.bind(mainMod .. " + SHIFT + Tab", hl.dsp.focus({ workspace = "e-1" }))

hl.bind(mainMod .. " + 1", hl.dsp.focus({ workspace = 1 }))
hl.bind(mainMod .. " + 2", hl.dsp.focus({ workspace = 2 }))
hl.bind(mainMod .. " + 3", hl.dsp.focus({ workspace = 3 }))
hl.bind(mainMod .. " + 4", hl.dsp.focus({ workspace = 4 }))
hl.bind(mainMod .. " + 5", hl.dsp.focus({ workspace = 5 }))
hl.bind(mainMod .. " + 6", hl.dsp.focus({ workspace = 6 }))
hl.bind(mainMod .. " + 7", hl.dsp.focus({ workspace = 7 }))
hl.bind(mainMod .. " + 8", hl.dsp.focus({ workspace = 8 }))
hl.bind(mainMod .. " + 9", hl.dsp.focus({ workspace = 9 }))
hl.bind(mainMod .. " + 0", hl.dsp.focus({ workspace = 10 }))

hl.bind(mainMod .. " + SHIFT + 1", hl.dsp.window.move({ workspace = 1, follow = true }))
hl.bind(mainMod .. " + SHIFT + 2", hl.dsp.window.move({ workspace = 2, follow = true }))
hl.bind(mainMod .. " + SHIFT + 3", hl.dsp.window.move({ workspace = 3, follow = true }))
hl.bind(mainMod .. " + SHIFT + 4", hl.dsp.window.move({ workspace = 4, follow = true }))
hl.bind(mainMod .. " + SHIFT + 5", hl.dsp.window.move({ workspace = 5, follow = true }))
hl.bind(mainMod .. " + SHIFT + 6", hl.dsp.window.move({ workspace = 6, follow = true }))
hl.bind(mainMod .. " + SHIFT + 7", hl.dsp.window.move({ workspace = 7, follow = true }))
hl.bind(mainMod .. " + SHIFT + 8", hl.dsp.window.move({ workspace = 8, follow = true }))
hl.bind(mainMod .. " + SHIFT + 9", hl.dsp.window.move({ workspace = 9, follow = true }))
hl.bind(mainMod .. " + SHIFT + 0", hl.dsp.window.move({ workspace = 10, follow = true }))

hl.bind(mainMod .. " + F", hl.dsp.window.fullscreen({ mode = "fullscreen", action = "toggle" }))

hl.bind(mainMod .. " + SHIFT + Space", hl.dsp.window.float({ action = "toggle" }))
hl.bind(mainMod .. " + Space", hl.dsp.focus({ urgent_or_last = true }))
hl.bind(mainMod .. " + mouse:272", hl.dsp.window.drag(), { mouse = true })
hl.bind(mainMod .. " + mouse:273", hl.dsp.window.resize(), { mouse = true })

hl.bind(mainMod .. " + G", hl.dsp.group.toggle())

hl.bind(mainMod .. " + CTRL + H", hl.dsp.window.move({ into_group = "left" }))
hl.bind(mainMod .. " + CTRL + J", hl.dsp.window.move({ into_group = "down" }))
hl.bind(mainMod .. " + CTRL + K", hl.dsp.window.move({ into_group = "up" }))
hl.bind(mainMod .. " + CTRL + L", hl.dsp.window.move({ into_group = "right" }))
hl.bind(mainMod .. " + SHIFT + G", hl.dsp.window.move({ out_of_group = true }))

hl.bind("ALT + CTRL + J", hl.dsp.group.next())
hl.bind("ALT + CTRL + K", hl.dsp.group.prev())
hl.bind("ALT + Tab", hl.dsp.group.next())

hl.bind(mainMod .. " + CTRL + SHIFT + H", hl.dsp.workspace.move({ monitor = "l" }))
hl.bind(mainMod .. " + CTRL + SHIFT + J", hl.dsp.workspace.move({ monitor = "d" }))
hl.bind(mainMod .. " + CTRL + SHIFT + K", hl.dsp.workspace.move({ monitor = "u" }))
hl.bind(mainMod .. " + CTRL + SHIFT + L", hl.dsp.workspace.move({ monitor = "r" }))
hl.bind(mainMod .. " + CTRL + SHIFT + left", hl.dsp.workspace.move({ monitor = "l" }))
hl.bind(mainMod .. " + CTRL + SHIFT + down", hl.dsp.workspace.move({ monitor = "d" }))
hl.bind(mainMod .. " + CTRL + SHIFT + up", hl.dsp.workspace.move({ monitor = "u" }))
hl.bind(mainMod .. " + CTRL + SHIFT + right", hl.dsp.workspace.move({ monitor = "r" }))

hl.bind(mainMod .. " + B", hl.dsp.exec_cmd([[bash -c 'if pgrep waybar; then pkill waybar; else uwsm app -- waybar; fi']]))
hl.bind(mainMod .. " + SHIFT + B", hl.dsp.exec_cmd("pkill waybar"))

hl.bind(mainMod .. " + C", hl.dsp.exec_cmd("dunstctl close-all"))

hl.bind(mainMod .. " + P", hl.dsp.exec_cmd("/usr/local/bin/switch-audio-port"))

hl.bind(mainMod .. " + SHIFT + P", hl.dsp.exec_cmd([[bash -c '$HOME/.scripts/screencap.sh && notify-send "Screenshot saved to ~/.screenshots/"']]))
hl.bind(mainMod .. " + ALT + P", hl.dsp.exec_cmd([[bash -c '$HOME/.scripts/screencap.sh clip && notify-send "Screenshot saved to clipboard"']]))

hl.bind("XF86MonBrightnessDown", hl.dsp.exec_cmd("swayosd-client --brightness lower"))
hl.bind("XF86MonBrightnessUp", hl.dsp.exec_cmd("swayosd-client --brightness raise"))

hl.bind("XF86AudioRaiseVolume", hl.dsp.exec_cmd("swayosd-client --output-volume raise"))
hl.bind("XF86AudioLowerVolume", hl.dsp.exec_cmd("swayosd-client --output-volume lower"))
hl.bind("XF86AudioMute", hl.dsp.exec_cmd("swayosd-client --output-volume mute-toggle"))

hl.bind("XF86AudioPlay", hl.dsp.exec_cmd("playerctl play"))
hl.bind("XF86AudioPause", hl.dsp.exec_cmd("playerctl pause"))
hl.bind("XF86AudioNext", hl.dsp.exec_cmd("playerctl next"))
hl.bind("XF86AudioPrev", hl.dsp.exec_cmd("playerctl previous"))

hl.bind(mainMod .. " + R", hl.dsp.submap("resize"))
hl.define_submap("resize", function()
    hl.bind("H", hl.dsp.window.resize({ x = -20, y = 0, relative = true }), { repeating = true })
    hl.bind("L", hl.dsp.window.resize({ x = 20, y = 0, relative = true }), { repeating = true })
    hl.bind("K", hl.dsp.window.resize({ x = 0, y = -20, relative = true }), { repeating = true })
    hl.bind("J", hl.dsp.window.resize({ x = 0, y = 20, relative = true }), { repeating = true })
    hl.bind("Return", hl.dsp.submap("reset"))
    hl.bind("Escape", hl.dsp.submap("reset"))
end)
