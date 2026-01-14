# Steam-CompatSync

A small installer script to automatically synchronize Proton `compatdata` directories between the Steam home directory and external Steam libraries.

Requirements

- Run as root (sudo).
- Make sure all external drives and Steam library folders you plan to use are added in Steam before running the setup.

Installation / Update

1. Run:
   ```sh
   sudo ./steam-compatsync-setup.sh
   ```
2. The installer will:
   - scan external Steam libraries,
   - offer to configure a shared group (variable `GROUP_NAME` in steam-compatsync-setup.sh),
   - create the executable sync script (`FINAL_SCRIPT`),
   - add an autostart entry (`GLOBAL_AUTOSTART`),
   - install a copy of the installer to `SELF_INSTALL_PATH`.

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

- The script optionally changes ownership and group on external library paths. Default group is set by `GROUP_NAME`.
- Uninstall does not remove the created group or revert permissions automatically.
- Verify external library paths listed in your `libraryfolders.vdf` before running the installer.
- NTFS note: NTFS does not support POSIX permissions — mount with the correct uid= and gid= (or set correct ownership after mount) to ensure access.
- This project has not been tested with SELinux or AppArmor; additional policy changes or disabling enforcement may be required on systems using those LSMs.

Code references

- Installer and core logic: `steam-compatsync-setup.sh` — defines `FINAL_SCRIPT`, `GLOBAL_AUTOSTART`, `SELF_INSTALL_PATH`, `GROUP_NAME` and handles `--uninstall`.
