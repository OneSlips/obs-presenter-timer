-- Presenter Timer for OBS Studio
-- A fully customisable stage timer with presets, manual time, and visual alerts
-- By Roman Alurkoff
-- https://github.com/OneSlips/obs-presenter-timer
-- https://obsproject.com/

obs = obslua

-- ============================================================================
-- STATE
-- ============================================================================
local timer_running = false
local timer_paused  = false
local total_seconds = 0      -- total countdown in seconds
local elapsed       = 0      -- seconds elapsed since start
local last_tick     = 0
local state_file    = ""
local display_html  = ""

-- ============================================================================
-- SETTINGS (defaults)
-- ============================================================================
local settings_data = {
    -- Timer
    preset          = 0,
    manual_minutes  = 10,
    manual_seconds  = 0,
    -- Appearance
    theme           = "modern-dark",
    font_size       = 20,       -- vw units
    show_label      = true,
    label_text      = "TIME REMAINING",
    show_progress   = true,
    -- Colours
    color_normal    = "#FFFFFF",
    color_warning   = "#FFB800",
    color_danger    = "#FF3333",
    color_overtime  = "#FF0044",
    color_bg        = "#0A0A0F",
    -- Warning / danger thresholds
    warning_seconds = 120,
    danger_seconds  = 30,
    -- Behaviour
    flash_on_danger    = true,
    flash_on_overtime  = true,
    allow_negative     = true,
    show_hours         = false,
    count_up           = false,
    pulse_last_10      = true,
    -- Message
    end_message        = "TIME'S UP",
    show_end_message   = true,
}

-- ============================================================================
-- HELPERS
-- ============================================================================
local function script_dir()
    local info = debug.getinfo(1, "S")
    local path = info.source:match("@?(.*[\\/])")
    return path or ""
end

local function get_remaining()
    if settings_data.count_up then
        return elapsed
    end
    return total_seconds - elapsed
end

local function format_time(secs)
    local negative = secs < 0
    local abs_secs = math.abs(secs)
    local h = math.floor(abs_secs / 3600)
    local m = math.floor((abs_secs % 3600) / 60)
    local s = abs_secs % 60
    local sign = negative and "-" or ""
    if settings_data.show_hours or h > 0 then
        return string.format("%s%d:%02d:%02d", sign, h, m, s)
    else
        return string.format("%s%02d:%02d", sign, m, s)
    end
end

local function get_timer_phase()
    local remaining = get_remaining()
    if not settings_data.count_up then
        if remaining < 0 then return "overtime" end
        if remaining <= settings_data.danger_seconds then return "danger" end
        if remaining <= settings_data.warning_seconds then return "warning" end
    end
    return "normal"
end

local function get_progress()
    if total_seconds <= 0 then return 1.0 end
    if settings_data.count_up then
        return math.min(elapsed / total_seconds, 1.0)
    end
    return math.max(0, (total_seconds - elapsed) / total_seconds)
end

local function write_state()
    if state_file == "" then return end
    local remaining = get_remaining()
    local phase = get_timer_phase()
    local progress = get_progress()

    local json = string.format(
        '{"time":"%s","remaining":%d,"total":%d,"elapsed":%d,"phase":"%s","progress":%.4f,'..
        '"running":%s,"paused":%s,"theme":"%s","fontSize":%d,'..
        '"showLabel":%s,"labelText":"%s","showProgress":%s,'..
        '"colorNormal":"%s","colorWarning":"%s","colorDanger":"%s","colorOvertime":"%s","colorBg":"%s",'..
        '"flashOnDanger":%s,"flashOnOvertime":%s,"allowNegative":%s,'..
        '"pulseLastTen":%s,"endMessage":"%s","showEndMessage":%s,'..
        '"showHours":%s,"countUp":%s,"timestamp":%d}',
        format_time(remaining),
        remaining,
        total_seconds,
        elapsed,
        phase,
        progress,
        tostring(timer_running),
        tostring(timer_paused),
        settings_data.theme,
        settings_data.font_size,
        tostring(settings_data.show_label),
        settings_data.label_text,
        tostring(settings_data.show_progress),
        settings_data.color_normal,
        settings_data.color_warning,
        settings_data.color_danger,
        settings_data.color_overtime,
        settings_data.color_bg,
        tostring(settings_data.flash_on_danger),
        tostring(settings_data.flash_on_overtime),
        tostring(settings_data.allow_negative),
        tostring(settings_data.pulse_last_10),
        settings_data.end_message,
        tostring(settings_data.show_end_message),
        tostring(settings_data.show_hours),
        tostring(settings_data.count_up),
        os.time()
    )

    local f = io.open(state_file, "w")
    if f then
        f:write(json)
        f:close()
    end
end

-- ============================================================================
-- TIMER LOGIC
-- ============================================================================
local function timer_tick()
    if not timer_running or timer_paused then return end

    local now = os.time()
    local dt = now - last_tick
    if dt >= 1 then
        elapsed = elapsed + dt
        last_tick = now

        -- Stop if we don't allow negative and time is up
        local remaining = get_remaining()
        if not settings_data.count_up and not settings_data.allow_negative and remaining <= 0 then
            elapsed = total_seconds
            timer_running = false
            obs.timer_remove(timer_tick)
        end

        write_state()
    end
end

local function start_timer()
    if timer_running and not timer_paused then return end
    if timer_paused then
        timer_paused = false
        last_tick = os.time()
        write_state()
        return
    end
    timer_running = true
    timer_paused = false
    elapsed = 0
    last_tick = os.time()
    obs.timer_add(timer_tick, 200)
    write_state()
end

local function pause_timer()
    if not timer_running then return end
    timer_paused = not timer_paused
    if not timer_paused then
        last_tick = os.time()
    end
    write_state()
end

local function reset_timer()
    timer_running = false
    timer_paused = false
    elapsed = 0
    obs.timer_remove(timer_tick)
    write_state()
end

local function set_time(minutes, seconds)
    total_seconds = minutes * 60 + (seconds or 0)
    reset_timer()
end

local function add_time(seconds)
    total_seconds = total_seconds + seconds
    if total_seconds < 0 then total_seconds = 0 end
    write_state()
end

-- ============================================================================
-- HOTKEY CALLBACKS
-- ============================================================================
local hotkey_start_id  = obs.OBS_INVALID_HOTKEY_ID
local hotkey_pause_id  = obs.OBS_INVALID_HOTKEY_ID
local hotkey_reset_id  = obs.OBS_INVALID_HOTKEY_ID
local hotkey_add1_id   = obs.OBS_INVALID_HOTKEY_ID
local hotkey_sub1_id   = obs.OBS_INVALID_HOTKEY_ID

local function on_hotkey_start(pressed)
    if pressed then start_timer() end
end
local function on_hotkey_pause(pressed)
    if pressed then pause_timer() end
end
local function on_hotkey_reset(pressed)
    if pressed then reset_timer() end
end
local function on_hotkey_add1(pressed)
    if pressed then add_time(60) end
end
local function on_hotkey_sub1(pressed)
    if pressed then add_time(-60) end
end

-- ============================================================================
-- OBS SCRIPT API
-- ============================================================================

function script_description()
    return [[
<h2>🎤 Presenter Timer</h2>
<p>By <b>Roman Alurkoff</b></p>
<p>A polished, fully customisable stage timer for live presentations.</p>
<p>Add <b>timer-display.html</b> as a <b>Browser Source</b> in your scene.</p>
<hr>
<p><b>Hotkeys available:</b> Start, Pause/Resume, Reset, +1 min, -1 min</p>
<p>Configure them in <i>Settings → Hotkeys</i>.</p>
]]
end

function script_properties()
    local props = obs.obs_properties_create()

    -- == PRESET BUTTONS ==
    local g1 = obs.obs_properties_create()
    obs.obs_properties_add_button(g1, "btn_5",   "5 min",  function() set_time(5);  return true end)
    obs.obs_properties_add_button(g1, "btn_10",  "10 min", function() set_time(10); return true end)
    obs.obs_properties_add_button(g1, "btn_15",  "15 min", function() set_time(15); return true end)
    obs.obs_properties_add_button(g1, "btn_20",  "20 min", function() set_time(20); return true end)
    obs.obs_properties_add_button(g1, "btn_30",  "30 min", function() set_time(30); return true end)
    obs.obs_properties_add_button(g1, "btn_45",  "45 min", function() set_time(45); return true end)
    obs.obs_properties_add_button(g1, "btn_60",  "60 min", function() set_time(60); return true end)
    obs.obs_properties_add_button(g1, "btn_90",  "90 min", function() set_time(90); return true end)
    obs.obs_properties_add_group(props, "grp_presets", "⏱ Quick Presets", obs.OBS_GROUP_NORMAL, g1)

    -- == MANUAL TIME ==
    local g2 = obs.obs_properties_create()
    obs.obs_properties_add_int(g2, "manual_minutes", "Minutes", 0, 600, 1)
    obs.obs_properties_add_int(g2, "manual_seconds", "Seconds", 0, 59, 1)
    obs.obs_properties_add_button(g2, "btn_set_manual", "Set Manual Time", function()
        set_time(settings_data.manual_minutes, settings_data.manual_seconds)
        return true
    end)
    obs.obs_properties_add_group(props, "grp_manual", "🔢 Manual Time", obs.OBS_GROUP_NORMAL, g2)

    -- == TRANSPORT CONTROLS ==
    local g3 = obs.obs_properties_create()
    obs.obs_properties_add_button(g3, "btn_start", "▶ Start",         function() start_timer(); return true end)
    obs.obs_properties_add_button(g3, "btn_pause", "⏸ Pause / Resume", function() pause_timer(); return true end)
    obs.obs_properties_add_button(g3, "btn_reset", "⏹ Reset",         function() reset_timer(); return true end)
    obs.obs_properties_add_button(g3, "btn_add1",  "+1 Minute",       function() add_time(60);  return true end)
    obs.obs_properties_add_button(g3, "btn_sub1",  "-1 Minute",       function() add_time(-60); return true end)
    obs.obs_properties_add_button(g3, "btn_add5",  "+5 Minutes",      function() add_time(300); return true end)
    obs.obs_properties_add_button(g3, "btn_sub5",  "-5 Minutes",      function() add_time(-300);return true end)
    obs.obs_properties_add_group(props, "grp_controls", "🎮 Controls", obs.OBS_GROUP_NORMAL, g3)

    -- == THEME ==
    local g4 = obs.obs_properties_create()
    local theme_list = obs.obs_properties_add_list(g4, "theme", "Theme",
        obs.OBS_COMBO_TYPE_LIST, obs.OBS_COMBO_FORMAT_STRING)
    obs.obs_property_list_add_string(theme_list, "Modern Dark",    "modern-dark")
    obs.obs_property_list_add_string(theme_list, "Neon Glow",      "neon-glow")
    obs.obs_property_list_add_string(theme_list, "Minimal Light",  "minimal-light")
    obs.obs_property_list_add_string(theme_list, "Broadcast Red",  "broadcast-red")
    obs.obs_property_list_add_string(theme_list, "Elegant Gold",   "elegant-gold")
    obs.obs_property_list_add_string(theme_list, "Cyberpunk",      "cyberpunk")
    obs.obs_property_list_add_string(theme_list, "Clean Blue",     "clean-blue")
    obs.obs_property_list_add_string(theme_list, "Custom",         "custom")

    obs.obs_properties_add_int_slider(g4, "font_size", "Font Size (vw)", 5, 40, 1)
    obs.obs_properties_add_bool(g4, "show_label",   "Show Label")
    obs.obs_properties_add_text(g4, "label_text",    "Label Text", obs.OBS_TEXT_DEFAULT)
    obs.obs_properties_add_bool(g4, "show_progress", "Show Progress Bar")
    obs.obs_properties_add_bool(g4, "show_hours",    "Always Show Hours")
    obs.obs_properties_add_group(props, "grp_theme", "🎨 Appearance", obs.OBS_GROUP_NORMAL, g4)

    -- == COLOURS ==
    local g5 = obs.obs_properties_create()
    obs.obs_properties_add_color(g5, "color_normal_int",   "Normal Colour")
    obs.obs_properties_add_color(g5, "color_warning_int",  "Warning Colour")
    obs.obs_properties_add_color(g5, "color_danger_int",   "Danger Colour")
    obs.obs_properties_add_color(g5, "color_overtime_int", "Overtime Colour")
    obs.obs_properties_add_color(g5, "color_bg_int",       "Background Colour")
    obs.obs_properties_add_group(props, "grp_colors", "🎨 Custom Colours (for Custom theme)", obs.OBS_GROUP_NORMAL, g5)

    -- == BEHAVIOUR ==
    local g6 = obs.obs_properties_create()
    obs.obs_properties_add_int(g6, "warning_seconds", "Warning at (seconds left)", 0, 3600, 10)
    obs.obs_properties_add_int(g6, "danger_seconds",  "Danger at (seconds left)",  0, 600, 5)
    obs.obs_properties_add_bool(g6, "flash_on_danger",    "Flash on Danger")
    obs.obs_properties_add_bool(g6, "flash_on_overtime",  "Flash on Overtime")
    obs.obs_properties_add_bool(g6, "allow_negative",     "Allow Negative Time (overtime)")
    obs.obs_properties_add_bool(g6, "pulse_last_10",      "Pulse Animation Last 10 Seconds")
    obs.obs_properties_add_bool(g6, "count_up",           "Count Up (stopwatch mode)")
    obs.obs_properties_add_group(props, "grp_behaviour", "⚙ Behaviour", obs.OBS_GROUP_NORMAL, g6)

    -- == END MESSAGE ==
    local g7 = obs.obs_properties_create()
    obs.obs_properties_add_bool(g7, "show_end_message", "Show End Message")
    obs.obs_properties_add_text(g7, "end_message", "End Message", obs.OBS_TEXT_DEFAULT)
    obs.obs_properties_add_group(props, "grp_endmsg", "💬 End Message", obs.OBS_GROUP_NORMAL, g7)

    return props
end

local function obs_color_to_hex(c)
    -- OBS stores colours as ABGR integers
    local r = bit.band(c, 0xFF)
    local g = bit.band(bit.rshift(c, 8), 0xFF)
    local b = bit.band(bit.rshift(c, 16), 0xFF)
    return string.format("#%02X%02X%02X", r, g, b)
end

function script_update(settings)
    settings_data.theme           = obs.obs_data_get_string(settings, "theme")
    settings_data.font_size       = obs.obs_data_get_int(settings, "font_size")
    settings_data.show_label      = obs.obs_data_get_bool(settings, "show_label")
    settings_data.label_text      = obs.obs_data_get_string(settings, "label_text")
    settings_data.show_progress   = obs.obs_data_get_bool(settings, "show_progress")
    settings_data.show_hours      = obs.obs_data_get_bool(settings, "show_hours")

    settings_data.color_normal    = obs_color_to_hex(obs.obs_data_get_int(settings, "color_normal_int"))
    settings_data.color_warning   = obs_color_to_hex(obs.obs_data_get_int(settings, "color_warning_int"))
    settings_data.color_danger    = obs_color_to_hex(obs.obs_data_get_int(settings, "color_danger_int"))
    settings_data.color_overtime  = obs_color_to_hex(obs.obs_data_get_int(settings, "color_overtime_int"))
    settings_data.color_bg        = obs_color_to_hex(obs.obs_data_get_int(settings, "color_bg_int"))

    settings_data.warning_seconds  = obs.obs_data_get_int(settings, "warning_seconds")
    settings_data.danger_seconds   = obs.obs_data_get_int(settings, "danger_seconds")
    settings_data.flash_on_danger  = obs.obs_data_get_bool(settings, "flash_on_danger")
    settings_data.flash_on_overtime= obs.obs_data_get_bool(settings, "flash_on_overtime")
    settings_data.allow_negative   = obs.obs_data_get_bool(settings, "allow_negative")
    settings_data.pulse_last_10    = obs.obs_data_get_bool(settings, "pulse_last_10")
    settings_data.count_up         = obs.obs_data_get_bool(settings, "count_up")

    settings_data.end_message      = obs.obs_data_get_string(settings, "end_message")
    settings_data.show_end_message = obs.obs_data_get_bool(settings, "show_end_message")

    settings_data.manual_minutes   = obs.obs_data_get_int(settings, "manual_minutes")
    settings_data.manual_seconds   = obs.obs_data_get_int(settings, "manual_seconds")

    write_state()
end

function script_defaults(settings)
    obs.obs_data_set_default_string(settings, "theme",        "modern-dark")
    obs.obs_data_set_default_int(settings,    "font_size",     20)
    obs.obs_data_set_default_bool(settings,   "show_label",    true)
    obs.obs_data_set_default_string(settings, "label_text",   "TIME REMAINING")
    obs.obs_data_set_default_bool(settings,   "show_progress", true)
    obs.obs_data_set_default_bool(settings,   "show_hours",    false)

    obs.obs_data_set_default_int(settings,    "color_normal_int",   0xFFFFFFFF)
    obs.obs_data_set_default_int(settings,    "color_warning_int",  0xFF00B8FF)
    obs.obs_data_set_default_int(settings,    "color_danger_int",   0xFF3333FF)
    obs.obs_data_set_default_int(settings,    "color_overtime_int", 0xFF4400FF)
    obs.obs_data_set_default_int(settings,    "color_bg_int",       0xFF0F0A0A)

    obs.obs_data_set_default_int(settings, "warning_seconds",  120)
    obs.obs_data_set_default_int(settings, "danger_seconds",   30)
    obs.obs_data_set_default_bool(settings, "flash_on_danger",   true)
    obs.obs_data_set_default_bool(settings, "flash_on_overtime", true)
    obs.obs_data_set_default_bool(settings, "allow_negative",    true)
    obs.obs_data_set_default_bool(settings, "pulse_last_10",     true)
    obs.obs_data_set_default_bool(settings, "count_up",          false)

    obs.obs_data_set_default_string(settings, "end_message",     "TIME'S UP")
    obs.obs_data_set_default_bool(settings,   "show_end_message", true)

    obs.obs_data_set_default_int(settings, "manual_minutes", 10)
    obs.obs_data_set_default_int(settings, "manual_seconds", 0)
end

function script_load(settings)
    local dir = script_dir()
    state_file   = dir .. "timer-state.json"
    display_html = dir .. "timer-display.html"

    -- Register hotkeys
    hotkey_start_id = obs.obs_hotkey_register_frontend("presenter_timer_start", "Presenter Timer: Start", on_hotkey_start)
    hotkey_pause_id = obs.obs_hotkey_register_frontend("presenter_timer_pause", "Presenter Timer: Pause/Resume", on_hotkey_pause)
    hotkey_reset_id = obs.obs_hotkey_register_frontend("presenter_timer_reset", "Presenter Timer: Reset", on_hotkey_reset)
    hotkey_add1_id  = obs.obs_hotkey_register_frontend("presenter_timer_add1",  "Presenter Timer: +1 Minute", on_hotkey_add1)
    hotkey_sub1_id  = obs.obs_hotkey_register_frontend("presenter_timer_sub1",  "Presenter Timer: -1 Minute", on_hotkey_sub1)

    -- Load saved hotkeys
    local key_start = obs.obs_data_get_array(settings, "presenter_timer_start")
    local key_pause = obs.obs_data_get_array(settings, "presenter_timer_pause")
    local key_reset = obs.obs_data_get_array(settings, "presenter_timer_reset")
    local key_add1  = obs.obs_data_get_array(settings, "presenter_timer_add1")
    local key_sub1  = obs.obs_data_get_array(settings, "presenter_timer_sub1")

    obs.obs_hotkey_load(hotkey_start_id, key_start)
    obs.obs_hotkey_load(hotkey_pause_id, key_pause)
    obs.obs_hotkey_load(hotkey_reset_id, key_reset)
    obs.obs_hotkey_load(hotkey_add1_id,  key_add1)
    obs.obs_hotkey_load(hotkey_sub1_id,  key_sub1)

    obs.obs_data_array_release(key_start)
    obs.obs_data_array_release(key_pause)
    obs.obs_data_array_release(key_reset)
    obs.obs_data_array_release(key_add1)
    obs.obs_data_array_release(key_sub1)

    -- Initial state
    total_seconds = settings_data.manual_minutes * 60 + settings_data.manual_seconds
    write_state()
end

function script_save(settings)
    local key_start = obs.obs_hotkey_save(hotkey_start_id)
    local key_pause = obs.obs_hotkey_save(hotkey_pause_id)
    local key_reset = obs.obs_hotkey_save(hotkey_reset_id)
    local key_add1  = obs.obs_hotkey_save(hotkey_add1_id)
    local key_sub1  = obs.obs_hotkey_save(hotkey_sub1_id)

    obs.obs_data_set_array(settings, "presenter_timer_start", key_start)
    obs.obs_data_set_array(settings, "presenter_timer_pause", key_pause)
    obs.obs_data_set_array(settings, "presenter_timer_reset", key_reset)
    obs.obs_data_set_array(settings, "presenter_timer_add1",  key_add1)
    obs.obs_data_set_array(settings, "presenter_timer_sub1",  key_sub1)

    obs.obs_data_array_release(key_start)
    obs.obs_data_array_release(key_pause)
    obs.obs_data_array_release(key_reset)
    obs.obs_data_array_release(key_add1)
    obs.obs_data_array_release(key_sub1)
end

function script_unload()
    obs.timer_remove(timer_tick)
end
