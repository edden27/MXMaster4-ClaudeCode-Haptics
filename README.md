# MXMaster4 Haptics For Claude Code

Haptic feedback from your Logi MX Master 4 for Claude Code events. Feel when a response finishes, when something needs approval, when an error happens — without looking at the screen.

This is a Claude Code plugin. Install it and your mouse buzzes differently for different events. Your brain learns the patterns fast. Even with hand-off-mouse (vim, btw) you can subtly hear the haptics, which I found to be more tolerable than sound effects or tts audio.

## Requirements

- **macOS** (arm64) - See [below](#platform-support) for Linux/Windows options
- **Logitech MX Master 4** — the only mouse with controllable haptics
- **Logi Options+** (free) — no Logi account required
- **HapticWeb plugin** (free) installed in Logi Options+ — no Logi account required
- **Claude Code**

## Install HapticWeb

HapticWeb is a Logi Options+ plugin that exposes a local haptic API on your machine. It's what lets this plugin talk to your mouse.

**From marketplace (easiest if u have an account already):**  
Open Logi Options+ → MX Master 4 → Haptic Feedback settings → find HapticWeb in the marketplace

**Manual (no Logitech account version):**  
Download `HapticWeb.lplug4` from [GitHub Releases](https://github.com/jmw-fr/HapticWeb/releases) → Logi Options+ → MX Master 4 → Haptic Feedback → Settings popover → Install and Uninstall Plugins → double-click the `.lplug4` file → click Continue

The server starts automatically at `https://local.jmw.nz:41443/`. The `local.jmw.nz` domain just resolves to `127.0.0.1` (localhost) — it uses this to serve HTTPS with a valid certificate instead of self-signed certs.

**Try it out:** Open the [Haptic Playground](https://haptics.jmw.nz/playground) — it detects your mouse locally and lets you click any waveform to feel it instantly.

## Install the Plugin

**Option 1 — From GitHub:**

```
claude plugin marketplace add edden27/MXMaster4-ClaudeCode-Haptics
```

Then inside Claude Code:

```
/plugin install mousetic
```

**Option 2 — Local / testing:**

```
claude --plugin-dir /path/to/MXMaster4-ClaudeCode-Haptics
```

## Sensible Defaults On Day One

### During Sessions


| Event                                                                | What happened                                             | Waveform                             |
| -------------------------------------------------------------------- | --------------------------------------------------------- | ------------------------------------ |
| `Stop`                                                               | Claude is done talking (finally)                          | `completed`                          |
| `Notification` (permission_prompt)                                   | A tool needs your permission (less common with auto mode) | `knock`                              |
| `Notification` (idle_prompt)                                         | Claude is idle, waiting on you                            | `ringing`                            |
| `Notification` (elicitation_dialog) / `PreToolUse` (AskUserQuestion) | Dialog or elicitation asking you something                | `sharp_collision` / `damp_collision` |
| `PostToolUseFailure`                                                 | A tool call failed                                        | `mad`                                |


### Session lifecycle


| Event           | What happened         | Waveform           |
| --------------- | --------------------- | ------------------ |
| `SessionStart`  | New session opened    | `happy_alert`      |
| `SessionEnd`    | Session closed        | `wave`             |
| `SubagentStart` | A subagent kicked off | `happy_alert`      |
| `SubagentStop`  | A subagent completed  | `square`           |
| `TaskCreated`   | A new task was queued | `subtle_collision` |
| `TaskCompleted` | A task finished       | `square`           |


### System


| Event              | What happened                  | Waveform             |
| ------------------ | ------------------------------ | -------------------- |
| `StopFailure`      | Turn ended due to an API error | `angry_alert`        |
| `PermissionDenied` | Auto mode blocked a tool call  | `happy_alert`        |
| `PostModelSwitch`  | The model changed mid-session  | `sharp_state_change` |


## Customize

Every mapping lives in `hooks/hooks.json`. To change which haptic plays for which event, just edit the waveform name — no recompiling, no code changes.

Available waveforms:
`sharp_collision` `sharp_state_change` `knock` `damp_collision` `mad` `ringing` `subtle_collision` `completed` `jingle` `damp_state_change` `firework` `happy_alert` `wave` `angry_alert` `square`

Use the [Haptic Playground](https://haptics.jmw.nz/playground) to try each one on your mouse before picking.

## How It Works

A binary compiled from a 19-line Swift file ([mousetic.swift](mousetic.swift)) sends a POST request to the HapticWeb local server with the waveform name. Each hook in `hooks.json` calls this binary with a different waveform as the argument.

The binary runs in ~30ms. The haptic triggers instantly once the hook fires.

```
POST https://local.jmw.nz:41443/haptic/{waveform_name}
```

To recompile from source:

```bash
swiftc -O mousetic.swift -o bin/mousetic
```

## Platform Support

**macOS:** Fully supported. Prebuilt arm64 binary included, 19-line Swift file compiled for you (visible in the repo).

**Windows:** Logi Options+ and HapticWeb work on Windows, but the Swift binary doesn't. You could adapt the approach using `curl` or a Python script that POSTs to the same endpoint — it's just a single POST to `https://local.jmw.nz:41443/haptic/{waveform_name}` with an empty body.

**Linux:** Logi Options+ doesn't run on Linux, so HapticWeb isn't available. However, haptic feedback IS possible via community tools that talk directly to the MX Master 4 hardware through HID++:

- [Solaar](https://github.com/pwr-Solaar/Solaar) — `solaar config 'mx master 4' haptic-play 'WAVE'`
- [mx4-haptic-linux](https://github.com/search?q=mx4-haptic-linux) — Python project for haptic pulses directly
- [mx4notifications](https://github.com/search?q=mx4notifications) — D-Bus listener for KDE/GNOME tactile alerts
- [JuhRadial MX](https://github.com/search?q=JuhRadial+MX) — Rust-based HID++ daemon for full actuator haptics

## Troubleshooting

**No haptics firing:**

- Check HapticWeb is running: `curl https://local.jmw.nz:41443/` should respond
- Check plugin status in Logi Options+ (should show green "Normal")
- Make sure the binary is executable: `chmod +x bin/mousetic`

**Certificate errors:**

- Verify internet for initial cert download
- Restart Logi Plugin Service

**Port in use:**

```bash
lsof -ti:41443 | xargs kill -9
```

Then restart Logi Plugin Service.

**Delayed haptics:**
Any perceived delay is Claude Code's hook scheduling, not the binary. The haptic triggers in ~30ms once the hook fires.

## License

MIT