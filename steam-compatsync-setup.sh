#!/bin/bash

# Checking if the script is running with sudo
if [ -z "$SUDO_USER" ]; then
    echo "!Error: Superuser privileges are required to run this script: sudo $0"
    exit 1
fi

# Determining the real user and their home directory
REAL_USER=$SUDO_USER
REAL_HOME=$(getent passwd "$REAL_USER" | cut -d: -f6)

# Paths
STEAM_CONFIG="$REAL_HOME/.local/share/Steam/steamapps/libraryfolders.vdf"
FINAL_SCRIPT="/usr/local/bin/steam-compatsync.sh"
SELF_INSTALL_PATH="/usr/local/bin/steam-compatsync-setup"
GLOBAL_AUTOSTART="/etc/xdg/autostart/steam-compatsync.desktop"
GROUP_NAME="steam"

# Removal function
if [[ "$1" == "--uninstall" ]]; then
    echo "======================================================================="
    echo "                            Uninstalling..."
    echo "======================================================================="
    read -p "Are you sure you want to remove all components? (y/n):" confirm_un
    if [[ $confirm_un =~ ^[Yy]$ ]]; then
        echo "*Removing the main script..."
        rm -f "$FINAL_SCRIPT"
        echo "*Removing autostart settings..."
        rm -f "$GLOBAL_AUTOSTART"
        echo "*Removing the setup utility..."
        rm -f "$SELF_INSTALL_PATH"

        echo ""
        echo "======================================================================="
        echo "                          Removal complete."
        echo "======================================================================="
        echo "Note: Group '$GROUP_NAME' and directory permissions remained unchanged"
        echo "                  to avoid issues with game access."
        echo "======================================================================="
        exit 0
    else
        echo "Operation canceled"
        exit 1
    fi
fi


echo "======================================================================="
echo "      Welcome to the Steam-CompatSync installation/update script"
echo "======================================================================="
echo "    This script is designed to fix Steam Proton multi-user issues."
echo "    It dynamically creates 'compatdata' symlinks from the current"
echo "   user's Steam home directory to your external libraries on login."
echo "======================================================================="
echo "            To remove the script and its components, run:"
echo "              sudo steam-compatsync-setup --uninstall"
echo "======================================================================="
echo "                      Current user: $REAL_USER"
echo "======================================================================="

# Parsing dirs
if [ ! -f "$STEAM_CONFIG" ]; then
    echo -e "${YELLOW}!Error: Configuration file libraryfolders.vdf not found at:${NC}"
    echo "$STEAM_CONFIG"
    exit 1
fi

# Searching for paths on external drives
RAW_PATHS=$(grep "path" "$STEAM_CONFIG" | awk -F'"' '{print $4}' | grep -v "$REAL_HOME")

if [ -z "$RAW_PATHS" ]; then
    echo "!No external Steam libraries detected."
    exit 1
fi

echo ""
echo "Found the following external Steam libraries:"
FORMATTED_PATHS=""
for p in $RAW_PATHS; do
    FULL_PATH="$p/steamapps/compatdata"
    echo "  -> $FULL_PATH"
    FORMATTED_PATHS+="    \"$FULL_PATH\"\n"
done
echo ""

read -p "Continue configuration generation? (y/n):" confirm_paths
if [[ ! $confirm_paths =~ ^[Yy]$ ]]; then
    echo "Operation canceled"
    exit 1
fi

# setting up groups
echo ""
read -p "Set/update permissions for group $GROUP_NAME? (y/n):" confirm_group
if [[ $confirm_group =~ ^[Yy]$ ]]; then
    if ! getent group "$GROUP_NAME" > /dev/null; then
        echo "*Creating group $GROUP_NAME..."
        groupadd "$GROUP_NAME"
    fi
    usermod -aG "$GROUP_NAME" "$REAL_USER"

    echo "*Applying permissions to libraries..."
    for p in $RAW_PATHS; do
        chgrp -R "$GROUP_NAME" "$p"
        chmod -R 775 "$p"
        chmod g+s "$p"
    done
fi

# Generating final script
echo ""
echo "*Generating script at $FINAL_SCRIPT..."
MAIN_SCRIPT_CONTENT="#!/bin/bash
# Automatically generated

EXTERNAL_PATHS=(
{{PATHS}}
)

for EXTERNAL_LINK in \"\${EXTERNAL_PATHS[@]}\"; do
    LOCAL_COMPATDATA=\"\$HOME/.local/share/Steam/steamapps/compatdata\"
    LIB_PATH=\$(dirname \"\$EXTERNAL_LINK\")

    if [ ! -d \"\$LIB_PATH\" ]; then continue; fi

    if [ -L \"\$EXTERNAL_LINK\" ]; then
        rm -f \"\$EXTERNAL_LINK\"
    elif [ -d \"\$EXTERNAL_LINK\" ]; then
        TIMESTAMP=\$(date +%Y%m%d_%H%M%S)
        mv \"\$EXTERNAL_LINK\" \"\${EXTERNAL_LINK}_bak_\$TIMESTAMP\"
    fi

    mkdir -p \"\$LOCAL_COMPATDATA\"
    ln -s \"\$LOCAL_COMPATDATA\" \"\$EXTERNAL_LINK\"
    chgrp -h $GROUP_NAME \"\$EXTERNAL_LINK\" 2>/dev/null
done"

echo -e "${MAIN_SCRIPT_CONTENT/\{\{PATHS\}\}/$FORMATTED_PATHS}" > "$FINAL_SCRIPT"
chmod +x "$FINAL_SCRIPT"

# Configuring global autostart
if [ ! -f "$GLOBAL_AUTOSTART" ]; then
    echo "*Configuring global autostart..."
    cat <<EOF > "$GLOBAL_AUTOSTART"
[Desktop Entry]
Type=Application
Name=Steam-CompatSync
Exec=$FINAL_SCRIPT
Terminal=false
X-GNOME-Autostart-enabled=true
EOF
fi

# Copying the installer to PATH
echo "*Copying the installer to $SELF_INSTALL_PATH..."
cp "$0" "$SELF_INSTALL_PATH"
chmod +x "$SELF_INSTALL_PATH"

echo ""
echo "================================================================"
echo "              INSTALLATION AND UPDATE COMPLETE!"
echo "================================================================"
echo "     You can now update the config at any time by running:"
echo "                 sudo steam-compatsync-setup"
echo "================================================================"
echo "         Dont forget to add other users to the group:"
echo "            sudo usermod -aG $GROUP_NAME username"
echo "================================================================"
