# l(a)unch‑box

Open your daily tabs and apps on macOS with one command, powered by a simple config file.

Every morning, you probably open the same browser tabs, launch the same apps, configure them, and arrange windows the same way. This tool reads your config and does it all for you.

What started as a small time saver for my morning routine ended up being something I use every day. So I kept refining it.

![launch-1280](https://github.com/user-attachments/assets/6d82b6ab-714e-4def-9516-4aca1c6e5460)

---

## Setup
```bash
git clone https://github.com/lukecassidy/launch-box.git
cd launch-box
chmod +x eat.sh

# Install dependencies
brew install jq
```

---

## Config
The default config file is `box.json` in the project root with four sections: `urls`, `apps`, `plugins`, and `layouts`.

`box.json`:
```json
{
  "urls": [
    "https://calendar.google.com/calendar/u/0/r/week",
    "https://mail.google.com/mail/u/0/#inbox",
    "https://github.com/notifications"
  ],
  "apps": [
    "Visual Studio Code",
    "Slack",
    "iTerm"
  ],
  "plugins": [
    "code",
    "iTerm"
  ],
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

Sections:
- **urls**: Any valid `http`/`https` links. Opened in your default browser.
- **apps**: Must match names in `/Applications` (e.g. `Visual Studio Code`, `Google Chrome`, `Slack`).
- **plugins**: Each entry corresponds to a script in `plugins/` for post launch app configuration (e.g. VS Code window merging, iTerm pane setup).
- **layouts**: Hammerspoon window layout configurations for different screen setups.

---

## Usage
Flags
- `-c, --config <file>`  Use a custom config
- `-d, --dry-run`        Print actions only
- `-h, --help`           Show usage

Examples:
```bash
./eat.sh                # Use the default config (box.json)
./eat.sh -c work.json   # Use a custom config file
./eat.sh -d             # Dry run
```

---

## Run It Your Way
You can run eat.sh manually, on startup, or add a menu bar shortcut. I like this last approach so I'll outline it here. 

### Make it Clickable
1. Open Applications ▸ Automator → New Document → Application
2. “Run Shell Script”.
3. Add `"/Path/to/repo/launch-box/eat.sh" "$@"`
4. Save as `LaunchBox`

### Add To Menu Bar
5. Open Shortcuts → New Shortcut → Open App.
6. Select `LaunchBox`
7. Click "i" icon & Turn on 'Pin in Menu Bar'.

That's it. Now you've got a one click workspace launcher 🌯.

---

## Troubleshooting
If you encounter permission issues, grant **Accessibility** permissions to the app that runs `eat.sh`. Depending on your setup, this could be iTerm2, Shortcuts, Automator etc. You can do this via:
- System Settings → Privacy & Security → Accessibility

After granting access, try running the script again.

---

## TODO
- [ ] Elegant screen name handling
- [ ] Support multiple Chrome profiles
- [ ] Tidy up to be a lot more user friendly
