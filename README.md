# bluebuild-bazzite-dx &nbsp; [![bluebuild build badge](https://github.com/abirkel/bluebuild-bazzite-dx/actions/workflows/build.yml/badge.svg)](https://github.com/abirkel/bluebuild-bazzite-dx/actions/workflows/build.yml)

A custom [BlueBuild](https://blue-build.org/) image based on [Bazzite](https://bazzite.gg/) (gaming-focused Fedora Atomic with developer tools) that includes [yeetmouse](https://github.com/AndyFilter/YeetMouse) for advanced mouse control.

## About yeetmouse

yeetmouse is a Linux kernel module that provides sophisticated mouse acceleration curves. This image includes:

- **yeetmouse**: User-space tools and configuration for mouse control
- **kmod-yeetmouse**: Kernel module for mouse functionality

## Installation

> [!WARNING]  
> [This is an experimental feature](https://www.fedoraproject.org/wiki/Changes/OstreeNativeContainerStable), try at your own discretion.

### Rebasing to bluebuild-bazzite-dx

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

## ISO

If build on Fedora Atomic, you can generate an offline ISO with the instructions available [here](https://blue-build.org/learn/universal-blue/#fresh-install-from-an-iso). These ISOs cannot unfortunately be distributed on GitHub for free due to large sizes, so for public projects something else has to be used for hosting.

## Verification

These images are signed with [Sigstore](https://www.sigstore.dev/)'s [cosign](https://github.com/sigstore/cosign). You can verify the signature by downloading the `cosign.pub` file from this repo and running the following command:

```bash
cosign verify --key cosign.pub ghcr.io/abirkel/bluebuild-bazzite-dx
```
