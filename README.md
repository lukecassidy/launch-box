# launch‑box

Open your daily tabs and apps on macOS with one command, powered by a simple config file.

Every morning, you probably open the same browser tabs, launch the same apps, configure them, and arrange windows the same way. This tool reads your config and does it all for you. What started as a small time saver for my morning routine ended up being something I use every day. So I kept refining it.

![launch-1280](https://github.com/user-attachments/assets/6d82b6ab-714e-4def-9516-4aca1c6e5460)

---

## Installation

### 1. Clone Repo & Install Dependencies

```bash
# Clone repo
git clone https://github.com/lukecassidy/launch-box.git
cd launch-box

# Install dependencies
brew install jq
brew install --cask hammerspoon
```

### 2. Run as macOS App (Recommended)

This gives LaunchBox its own identity for system permissions:
```bash
./install-app.sh         # Normal installation (copies files)
./install-app.sh --dev   # Dev mode (symlinks files)
```

This will:
- Install LaunchBox.app to `/Applications` with its own permissions
- Dev mode: symlinks files for live updates (no copying needed)
- Launch via Spotlight (⌘+Space), Dock, or menu bar (using Shortcuts)

> **Note:** You can also run `launch-box.sh` directly from Terminal without installing (see Running from Terminal for examples).

---

## Running from Terminal

**Flags:**
- `-c, --config <file>`  Use a custom config
- `-d, --dry-run`        Print actions only
- `-h, --help`           Show usage

**Examples:**
```bash
./launch-box.sh                   # Use the default config (launch-config.json)
./launch-box.sh -c work.json      # Use a custom config file
./launch-box.sh -d                # Dry run
```

---

## Config
Edit `~/.launch-box/launch-config.json` (created on first run):

```json
{
  "urls": ["https://github.com/notifications"],
  "apps": ["Visual Studio Code", "Slack", "iTerm"],
  "plugins": {
    "code": {},
    "iTerm": { "panes": ["echo hello", "echo world"] }
  },
  "layouts": {
    "single": {
      "Built-in Retina Display": [
        { "slot": "lft_half_all", "app": "code" },
        { "slot": "rgt_half_all", "app": "Slack" }
      ]
    }
  }
}
```

**Sections:**
- `urls` – Any valid http/https links. Opened in your default browser.
- `apps` – Must match names in /Applications (e.g. iTerm, Slack).
- `plugins` – Extensible section for post application configuration.
- `layouts` – Window layout configurations for different display setups.

---

## Troubleshooting

**Permission Issues:**

If you encounter permission errors when running launch-box:

1. Grant **Accessibility** permissions to the app running the script
2. Depending on your setup, this could be:
   - LaunchBox.app
   - iTerm2 or Terminal
   - Shortcuts or Automator
3. Navigate to: `System Settings → Privacy & Security → Accessibility`
4. Add the relevant app and enable permissions
5. Try running the script again

---

## Architecture

```mermaid
graph LR
    Start([launch-box.sh]) --> Init[Initialize & Validate]
    Init --> Phase1[1. Open URLs]
    Phase1 --> Phase2[2. Launch Apps]
    Phase2 --> Phase3[3. Run Plugins]
    Phase3 --> Phase4[4. Apply Layouts]
    Phase4 --> Complete([Done])

    Config[(Config<br/>JSON)] -.-> Init
    Config -.-> Phase1
    Config -.-> Phase2
    Config -.-> Phase3
    Config -.-> Phase4

    Phase3 -.-> Plugins[plugins/<br/>code.sh<br/>iTerm.sh]
    Phase4 -.-> Layout[layout/<br/>Hammerspoon]

    Common[lib/common.sh<br/>shared utilities] -.-> Init
    Common -.-> Phase1
    Common -.-> Phase2
    Common -.-> Plugins
    Common -.-> Layout

    style Start fill:#e1f5ff
    style Complete fill:#e1f5ff
    style Config fill:#fff4e1
    style Common fill:#f0f0f0
    style Phase1 fill:#e8f5e9
    style Phase2 fill:#e8f5e9
    style Phase3 fill:#e8f5e9
    style Phase4 fill:#e8f5e9
```


**Key Components:**
| Component       | Purpose                                                        |
| --------------- | -------------------------------------------------------------- |
| `launch-box.sh` | Main orchestrator                                              |
| Config JSON     | Single file drives all behavior (urls, apps, plugins, layouts) |
| `lib/common.sh` | Shared utilities (logging, validation, process management)     |
| `plugins/`      | Extensible system                                              |
| `layout/`       | Hammerspoon integration for window management                  |

---

## Uninstallation

To remove LaunchBox.app:

```bash
./uninstall-app.sh
```

This removes the app from `/Applications` and optionally removes your config at `~/.launch-box/`.

---

## TODO
- [ ] Add more elegant screen name handling
- [ ] Support multiple Chrome profiles (e.g., work vs personal)
- [ ] More plugins
  - [ ] Finder - Open recent files
  - [ ] Spotify - play playlists
  - [ ] Slack - Navigate to channel, set status
- [ ] Add multi config support for app install option
- [ ] Dry-run mode for plugins
