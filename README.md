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
```

---

## Config
The default config file is `box.config` in the project root and three sections: `# URLs`, `# APPS` and `# PLUGINS`.

`box.config`:
```text
# URLs
https://calendar.google.com/calendar/u/0/r/week
https://mail.google.com/mail/u/0/#inbox
https://github.com/notifications

# APPS
Visual Studio Code # editor
Slack              # chat
iTerm              # terminal

# PLUGINS
iTerm              # configure iTerm (split panes, run cmd)
layout             # arrange windows/screens
```

Sections:
- **URLs**: Any valid `http`/`https` links. Opened in your default browser.
- **APPS**: Must match names in `/Applications` (e.g. `Visual Studio Code`, `Google Chrome`, `Slack`).
- **PLUGINS**: Each entry corresponds to a script in `plugins` for post-launch setup (e.g. custom app configs or window layouts).

---

## Usage
Flags
- `-c, --config <file>`  Use a custom config
- `-d, --dry-run`        Print actions only
- `-h, --help`           Show usage

Examples:
```bash
./eat.sh                # Use the default config (box.config)
./eat.sh -c work.config # Use a custom config file
./eat.sh -d             # Dry run
```

---

## Run It Your Way
You can run eat.sh manually, on startup, or add a menu bar shortcut. I like this approach so I'll outline it here. 

### Add a Menu Bar Button (macOS Shortcuts)
1. Open Shortcuts → New Shortcut → Run Shell Script.
2. Add your script path, e.g. /Users/you/launch-box/eat.sh.
3. Turn on 'Pin in Menu Bar'.

That's it. Now you've got a one click workspace launcher 🌯.


---

## TODO
- [ ] Support multiple Chrome profiles
- [ ] Move monitor layout to main config file
- [ ] Update config file format/type
- [ ] Tidy up to be a lot more user friendly
