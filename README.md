# 🎤 Presenter Timer for OBS Studio

A polished, fully customisable stage timer for live presentations. Control the countdown from OBS while displaying a beautiful full-screen timer to your presenters via a monitor, projector, or NDI feed.

![Timer Preview](https://img.shields.io/badge/OBS-28%2B-blue?style=flat-square) ![Lua](https://img.shields.io/badge/Script-Lua-blue?style=flat-square) ![License](https://img.shields.io/badge/License-MIT-green?style=flat-square)

---

## ✨ Features

- **Quick Presets** — One-click buttons for 5, 10, 15, 20, 30, 45, 60, 90 minutes
- **Manual Time** — Set any custom duration (minutes + seconds)
- **Transport Controls** — Start, Pause/Resume, Reset, ±1 min, ±5 min adjustments
- **7 Polished Themes** — Modern Dark, Neon Glow, Minimal Light, Broadcast Red, Elegant Gold, Cyberpunk, Clean Blue
- **Custom Theme** — Full colour picker for every element (normal, warning, danger, overtime, background)
- **Warning Phase** — Colour changes when time is running low (configurable threshold)
- **Danger Phase** — Distinct colour + optional flashing when critically low
- **Overtime / Negative Time** — Timer continues past zero with a dedicated colour
- **Flash Effects** — Screen flashing during danger and overtime phases
- **Pulse Animation** — Subtle scale pulse in the last 10 seconds
- **Pause Blink** — Timer blinks when paused so presenters know it's intentional
- **End Message** — Customisable "TIME'S UP" message displayed at zero
- **Progress Bar** — Colour-coded bar along the bottom
- **Count Up Mode** — Stopwatch mode for open-ended sessions
- **Hotkey Support** — Bind Start, Pause, Reset, +1 min, -1 min to keyboard shortcuts
- **Configurable Font Size** — Scale the timer from small to massive

---

## 📦 What's in the Box

| File | Purpose |
|---|---|
| `presenter-timer.lua` | OBS Lua script — all controls, settings, and timer logic |
| `timer-display.html` | Browser Source — the visual timer display |
| `timer-state.json` | Auto-generated state file (created on first run) |
| `README.md` | This file |

---

## 🚀 Installation

### Prerequisites

- **OBS Studio 28+** (with Lua scripting support — included by default)
- No additional plugins or dependencies required

### Step-by-Step

1. **Download/Copy all files** into a single folder, for example:
   ```
   C:\OBS-Scripts\presenter-timer\
   ├── presenter-timer.lua
   ├── timer-display.html
   └── README.md
   ```

2. **Add the Script to OBS:**
   - Open OBS Studio
   - Go to **Tools → Scripts**
   - Click the **+** button (bottom-left)
   - Navigate to your folder and select **`presenter-timer.lua`**
   - The script will load and you'll see all the controls in the Scripts panel

3. **Add the Timer Display to your Scene:**
   - In your scene, click **+** under Sources
   - Select **Browser** (Browser Source)
   - Check **"Local file"**
   - Click **Browse** and select **`timer-display.html`**
   - Set the resolution (recommended: **1920×1080**)
   - **Important:** Leave the **"Custom CSS"** field **empty** (clear the default)
   - Click **OK**

4. **Done!** The timer display will now respond to your controls in the Scripts panel.

---

## 🎮 How to Use

### Setting the Time

1. Go to **Tools → Scripts** and select **Presenter Timer**
2. Use a **Quick Preset** button (5, 10, 15, 20, 30, 45, 60, 90 min), or
3. Enter custom **Minutes** and **Seconds** in the Manual Time section and click **Set Manual Time**

### Controlling the Timer

| Button | Action |
|---|---|
| **▶ Start** | Begins the countdown |
| **⏸ Pause / Resume** | Toggles pause (timer blinks when paused) |
| **⏹ Reset** | Stops and resets to the set time |
| **+1 / -1 Minute** | Adjust time on the fly while running |
| **+5 / -5 Minutes** | Larger adjustments while running |

### Hotkeys

Set up keyboard shortcuts in **Settings → Hotkeys** — search for "Presenter Timer":

| Hotkey | Action |
|---|---|
| Presenter Timer: Start | Start the countdown |
| Presenter Timer: Pause/Resume | Toggle pause |
| Presenter Timer: Reset | Reset timer |
| Presenter Timer: +1 Minute | Add 1 minute |
| Presenter Timer: -1 Minute | Subtract 1 minute |

---

## 🎨 Themes

Select your theme in **Tools → Scripts → Appearance → Theme**:

| Theme | Description |
|---|---|
| **Modern Dark** | Clean white-on-black with subtle glow |
| **Neon Glow** | Cyan neon on deep dark — sci-fi look |
| **Minimal Light** | Light background, thin font — corporate feel |
| **Broadcast Red** | Red on black with Impact font — broadcast TV |
| **Elegant Gold** | Gold serif text — awards ceremony style |
| **Cyberpunk** | Hot pink with scanlines — retro-future |
| **Clean Blue** | Calm blue tones — professional events |
| **Custom** | Use the Colour pickers to define every colour yourself |

---

## ⚙ Settings Reference

### Appearance

| Setting | Description | Default |
|---|---|---|
| Theme | Visual style preset | Modern Dark |
| Font Size (vw) | Timer text size in viewport-width units | 20 |
| Show Label | Display the label above the timer | Yes |
| Label Text | Custom label text | "TIME REMAINING" |
| Show Progress Bar | Animated bar at the bottom | Yes |
| Always Show Hours | Show hours even when < 1 hour | No |

### Custom Colours (used with "Custom" theme)

| Setting | Default |
|---|---|
| Normal Colour | White |
| Warning Colour | Amber |
| Danger Colour | Red |
| Overtime Colour | Hot Pink |
| Background Colour | Near Black |

### Behaviour

| Setting | Description | Default |
|---|---|---|
| Warning at (seconds) | When to enter warning phase | 120 (2 min) |
| Danger at (seconds) | When to enter danger phase | 30 |
| Flash on Danger | Screen flash during danger phase | Yes |
| Flash on Overtime | Screen flash when past zero | Yes |
| Allow Negative Time | Continue counting past zero | Yes |
| Pulse Last 10 Seconds | Scale animation in final 10s | Yes |
| Count Up | Stopwatch mode (count up instead of down) | No |

### End Message

| Setting | Description | Default |
|---|---|---|
| Show End Message | Display message when time expires | Yes |
| End Message | Text to display | "TIME'S UP" |

---

## 📺 Recommended OBS Setup for Stage Presentations

### Basic Setup (1 monitor to stage)

```
Scene: "Stage Timer"
  └── Browser Source: timer-display.html (1920x1080)

Output to a second monitor / projector via:
  - Fullscreen Projector (right-click scene → Fullscreen Projector)
  - or Windowed Projector dragged to the presentation monitor
```

### Advanced Setup (timer + slides)

```
Scene: "Presentation"
  ├── Display Capture / Window Capture (slides)
  └── Browser Source: timer-display.html
       - Resize and position in a corner
       - Or use as an overlay strip at the bottom
```

### NDI Output

If using the **obs-ndi** plugin, you can send the timer scene to any NDI-capable monitor on your network — perfect for confidence monitors.

---

## 🔧 Troubleshooting

### Timer display shows "--:--"

- Make sure `presenter-timer.lua` is loaded in **Tools → Scripts**
- Verify both files are in the **same folder**
- Check the Browser Source is pointing to the correct `timer-display.html`

### Timer doesn't update

- In the Browser Source properties, ensure **"Local file"** is checked
- Clear the **Custom CSS** field (remove the default OBS CSS)
- Try clicking **Refresh cache of current page** in the Browser Source properties

### Colours don't change

- Make sure you're using the **Custom** theme if you want colour picker values to apply
- The 7 built-in themes use their own fixed palette

### Script won't load

- OBS 28+ is required
- Go to **Tools → Scripts → Script Log** tab to check for errors
- Ensure the file extension is `.lua` (not `.lua.txt`)

---

## 💡 Tips & Tricks

1. **Quick Theme Switching** — Change themes live during the event; the display updates instantly
2. **Pause for Q&A** — Pause the timer during audience questions, resume when the speaker continues
3. **Overtime Awareness** — Enable negative time + flash so the speaker sees exactly how far over they are
4. **Multiple Timers** — You can add multiple Browser Sources pointing to the same HTML for different output views
5. **Custom Messages** — Change the end message to "WRAP UP", "QUESTIONS", or the next speaker's name
6. **Full Screen** — Right-click the scene preview → **Fullscreen Projector (Scene)** to fill a confidence monitor
7. **Scale for Visibility** — Increase Font Size to 30+ vw for timers viewed from far away on stage

---

## 📄 License

MIT License — free for personal and commercial use.
