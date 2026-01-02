install-flatpaks:
    #!/usr/bin/env bash
    set -euo pipefail
    
    # Ensure Flathub user remote is configured
    if ! flatpak remote-list --user | grep -q "^flathub"; then
        echo "Adding Flathub remote..."
        flatpak remote-add --user flathub https://flathub.org/repo/flathub.flatpakrepo
    else
        echo "Flathub remote already configured."
    fi
    
    FLATPAK_LIST="/usr/share/ublue-os/flatpaks.txt"
    
    echo "Installing Flatpaks from list..."
    echo "This may take a while depending on your internet connection."
    echo ""
    
    # Read flatpaks.txt and install each one
    while IFS= read -r line || [ -n "$line" ]; do
        # Skip empty lines and comments
        [[ -z "$line" || "$line" =~ ^[[:space:]]*# ]] && continue
        
        echo "Installing: $line"
        flatpak install -y --user --noninteractive flathub "$line" || echo "Failed to install $line, continuing..."
    done < "$FLATPAK_LIST"
    
    echo ""
    echo "Flatpak installation complete!"
    echo "Run 'flatpak list' to see installed applications."

list-flatpaks:
    #!/usr/bin/env bash
    FLATPAK_LIST="/usr/share/ublue-os/flatpaks.txt"
    echo "Flatpaks configured for installation:"
    grep -v '^#' "$FLATPAK_LIST" | grep -v '^[[:space:]]*$'
