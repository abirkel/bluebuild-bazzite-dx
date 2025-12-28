# bluebuild-bazzite-dx &nbsp; [![bluebuild build badge](https://github.com/abirkel/bluebuild-bazzite-dx/actions/workflows/build.yml/badge.svg)](https://github.com/abirkel/bluebuild-bazzite-dx/actions/workflows/build.yml)

A custom [BlueBuild](https://blue-build.org/) image based on [Bazzite](https://bazzite.gg/) (gaming-focused Fedora Atomic with developer tools) that includes [yeetmouse](https://github.com/AndyFilter/YeetMouse) for advanced mouse control.

## About yeetmouse

yeetmouse is a Linux kernel module that provides sophisticated mouse acceleration curves. This image includes:

- **yeetmouse**: User-space tools and configuration for mouse control
- **kmod-yeetmouse**: Kernel module for mouse functionality

## Installation

> [!WARNING]  
> [This is an experimental feature](https://www.fedoraproject.org/wiki/Changes/OstreeNativeContainerStable), try at your own discretion.

### Option 1: Rebase from Existing Installation

To rebase an existing atomic Fedora installation to the latest bluebuild-bazzite-dx build:

- First rebase to the unsigned image, to get the proper signing keys and policies installed:
  ```
  rpm-ostree rebase ostree-unverified-registry:ghcr.io/abirkel/bluebuild-bazzite-dx:latest
  ```
- Reboot to complete the rebase:
  ```
  systemctl reboot
  ```
- Then rebase to the signed image, like so:
  ```
  rpm-ostree rebase ostree-image-signed:docker://ghcr.io/abirkel/bluebuild-bazzite-dx:latest
  ```
- Reboot again to complete the installation
  ```
  systemctl reboot
  ```

The `latest` tag will automatically point to the latest build. That build will still always use the Fedora version specified in `recipe.yml`, so you won't get accidentally updated to the next major version.

### Option 2: Fresh Install from ISO

ISOs are built on-demand and available as GitHub Actions artifacts:

1. Go to the [Actions tab](https://github.com/abirkel/bluebuild-bazzite-dx/actions/workflows/build-iso.yml)
2. Click "Run workflow" to trigger a new ISO build
3. Wait for the build to complete (~20-30 minutes)
4. Download the ISO from the workflow artifacts
5. Flash to USB using [Fedora Media Writer](https://www.fedoraproject.org/en/workstation/download) or similar tool
6. Boot and install

**Note:** ISOs are retained for 7 days after build. If you need an ISO and none are available, simply trigger a new build.

### yeetmouse Configuration

After rebasing to bluebuild-bazzite-dx, the yeetmouse kernel module and tools are automatically installed.

To verify yeetmouse is installed and loaded:

```bash
# Check if yeetmouse packages are installed
rpm -qa | grep yeetmouse

# Check if the yeetmouse kernel module is available
modinfo yeetmouse

# Load the yeetmouse module (if not already loaded)
sudo modprobe yeetmouse
```

For yeetmouse configuration and usage, refer to the [yeetmouse documentation](https://github.com/AndyFilter/YeetMouse).

## Managing Flatpaks

This image installs a curated set of Flatpak applications on first boot. After installation, these applications will automatically reinstall if removed (standard BlueBuild behavior).

**To prevent automatic reinstallation:**
```bash
bluebuild-flatpak-manager disable all
```

**To re-enable automatic management:**
```bash
bluebuild-flatpak-manager enable all
```

## Included Customizations

- **Removed packages:** Docker (use Podman), Waydroid, various Cockpit modules, and other unwanted packages
- **Added packages:** Konsole terminal, yeetmouse tools
- **Fonts:** Custom MS core fonts and Nerd Fonts (CodeNewRoman, CascadiaCode, CascadiaMono, AurulentSansMono)
- **Flatpaks:** KDE apps, gaming tools, development containers, and more (see `recipes/recipe.yml` for full list)

## Verification

These images are signed with [Sigstore](https://www.sigstore.dev/)'s [cosign](https://github.com/sigstore/cosign). You can verify the signature by downloading the `cosign.pub` file from this repo and running the following command:

```bash
cosign verify --key cosign.pub ghcr.io/abirkel/bluebuild-bazzite-dx
```
