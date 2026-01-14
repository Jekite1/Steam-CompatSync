# Steam-CompatSync

A small installer script to automatically synchronize Proton `compatdata` directories between the Steam home directory and external Steam libraries.

Requirements

- Run as root (sudo).
- Make sure all external drives and Steam library folders you plan to use are added in Steam before running the setup.

Installation / Update

Run:

```sh
sudo ./steam-compatsync-setup.sh
```

The installer will:

- scan external Steam libraries (default: `STEAM_CONFIG="$REAL_HOME/.local/share/Steam/steamapps/libraryfolders.vdf"`),
- offer to configure a shared group (default: `GROUP_NAME="steam"`)
- create the executable sync script (default: `FINAL_SCRIPT="/usr/local/bin/steam-compatsync.sh"`),
- add an autostart entry (default:`GLOBAL_AUTOSTART="/etc/xdg/autostart/steam-compatsync.desktop"`),
- install a copy of the installer (default:`SELF_INSTALL_PATH="/usr/local/bin/steam-compatsync-setup"`)

Usage

- To reconfigure or update, run:
  ```sh
  sudo steam-compatsync-setup
  ```
- The sync script creates symlinks to the local folder `~/.local/share/Steam/steamapps/compatdata` inside external libraries.

Uninstall

- To remove installed components:
  ```sh
  sudo steam-compatsync-setup --uninstall
  ```

Notes & Security

- The script optionally changes ownership and group on external library paths. Default group is set by `GROUP_NAME` (default: `steam`).
- Uninstall does not remove the created group or revert permissions automatically.
- Verify external library paths listed in your `libraryfolders.vdf` before running the installer.
- NTFS note: NTFS does not support POSIX permissions — mount with the correct uid= and gid= (or set correct ownership after mount) to ensure access.
- This project has not been tested with SELinux or AppArmor; additional policy changes or disabling enforcement may be required on systems using those LSMs.
