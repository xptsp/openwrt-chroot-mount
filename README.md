# OpenWrt chroot mount

`chroot-mount` is an OpenWrt package that prepares a chroot mount tree during
system startup. Its procd-managed worker reads `/etc/config/chroot_mount`, waits
for configured block devices to appear, mounts them, and binds selected runtime
filesystems into the configured chroot directory.

## Features

- Mounts configured `mount_root` and `mount_point` devices once their block
  device nodes are available.
- Supports mount options and per-mount `before_mount` and `after_mount` shell
  hooks.
- Bind-mounts `/proc`, `/sys`, `/dev`, and `/dev/pts` into the chroot and
  creates a temporary filesystem at its `tmp` directory.
- Supports global `after_mount` and `before_umount` hooks.
- Runs as an OpenWrt procd service, with startup priority 95 and stop priority
  10.

## Requirements

- An OpenWrt build tree and the OpenWrt package build system.
- A configured chroot root directory and the block devices/filesystems you
  want mounted.

The worker uses OpenWrt's UCI shell functions, `procd`, `mountpoint`, and
standard mount utilities. Ensure the required commands and filesystem support
are available in your image.

## Build and install

Place this package directory in an OpenWrt package feed or build tree, then
select **Utilities → chroot-mount** in `make menuconfig` and build the package
using the standard OpenWrt package build process. Install the resulting package
on the router with `opkg`, or include it in a custom firmware image.

After installation, edit `/etc/config/chroot_mount` and enable the service:

```sh
/etc/init.d/chroot_mount enable
/etc/init.d/chroot_mount start
```

## Configuration

The installed example configuration sets the chroot root to `/chroot`. A
minimal configuration looks like this:

```uci
config global
	option target_dir '/chroot'
	option after_mount '/chroot/bin/my-chroot.sh start-after'
	option before_umount '/chroot/bin/my-chroot.sh stop-before'

config mount_root
	option device '/dev/mapper/rootfs'
	option target '/chroot'
	option options 'subvol=@'

config mount_point
	option device '/dev/mapper/data'
	option target '/chroot/var/data'
	option options 'noatime'
	option before_mount 'logger mounting chroot data'
	option after_mount 'logger mounted chroot data'
```

Available sections and options:

| Section | Option | Purpose |
| --- | --- | --- |
| `global` | `target_dir` | Chroot root used for runtime filesystem mounts. Required. |
| `global` | `after_mount` | Shell command run after the worker mounts filesystems. |
| `global` | `before_umount` | Shell command run before the service unmounts filesystems. |
| `mount_root` | `device` | Block device to wait for and mount. |
| `mount_root` | `target` | Mount directory for the device. |
| `mount_root` | `options` | Optional arguments passed to `mount -o`. |
| `mount_root` | `before_mount`, `after_mount` | Optional shell commands run before mounting and after a successful mount. |
| `mount_point` | `device`, `target`, `options`, `before_mount`, `after_mount` | Same options as `mount_root`, for additional mounts. |

You can define multiple `mount_root` and `mount_point` sections. Mount targets
must be appropriate for the host filesystem layout; for example, mount the
chroot root at `target_dir` and place other chroot filesystems beneath it.

Hooks are evaluated by the init script as shell code and run with the router's
privileges. Only configure commands you trust.

## Lifecycle behavior

At startup the service checks `target_dir`, then waits in a one-second loop for
each configured block device to exist before mounting it. It mounts
`mount_root` entries first, followed by `mount_point` entries. It then binds
`/proc`, `/sys`, `/dev`, and `/dev/pts` into the target, mounts tmpfs at
`<target_dir>/tmp`, and invokes the global `after_mount` hook.

When stopped, it invokes `before_umount`, then reads the mount table for entries
whose lines contain `/chroot`, reverses that list, and lazily unmounts each
mountpoint. This unmounts matching mounts in reverse mount-table order,
including physical and virtual mounts. The worker copies the router's automatic
resolver configuration to `$CHROOT_DIR/etc/resolv.conf`; ensure that path
exists in your environment.

## Helper script

`files/my-chroot.sh` contains example service actions for the hook commands:

- `start-before`: stops `dockerd`.
- `start-after`: starts `dockerd`, `media-downloader`, and `samba4`, then
  restarts `sshd`.
- `stop-before`: stops `dockerd`, `media-downloader`, `samba4`, and `nfsd`,
  then restarts `sshd`.

The package Makefile does not install this helper. Copy it into the chroot (or
provide an equivalent script) before referencing it from a hook.

## Package contents

- `files/chroot_mount.init` — procd service and mount/unmount worker.
- `files/chroot_mount.config` — example UCI configuration installed as
  `/etc/config/chroot_mount`.
- `files/chroot_mount.hotplug` — Hotplug helper
- `sample-chroot-init.sh` — optional example hook helper.
- `Makefile` — OpenWrt package definition.
