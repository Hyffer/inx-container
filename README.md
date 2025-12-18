# inx-container

Run nixos container on nixos host with shared nix store using incus.

Inspired by [nixos-container](https://wiki.nixos.org/wiki/NixOS_Containers) and [nixcloud-container](https://github.com/nixcloud/nixcloud-container).

## Container Declaration

[Incus - Official NixOS Wiki](https://wiki.nixos.org/wiki/Incus#Custom_Images) talks about how to create custom container image. It includes a module from [`"${inputs.nixpkgs}/nixos/modules/virtualisation/lxc-container.nix"`](https://github.com/NixOS/nixpkgs/blob/38b523e9e8e607bcd8f638d8a53608bb1658a0e4/nixos/modules/virtualisation/lxc-container.nix), which requires a /sbin folder under root directory. But we are not gonna build rootfs from the lxc-container configuration. So please **DO NOT** follow that. Instead, add `boot.isContainer = true;` manually to your module.

## Design Consideration

### Behavior of nixos-container

nixos-container has some key components, a cli written in perl (`/run/current-system/sw/bin/nixos-container`) and a systemd service template (`/etc/systemd/system/container@.service`). There is also a [nixos-containers.nix](https://github.com/NixOS/nixpkgs/blob/c6f52ebd45e5925c188d1a20119978aa4ffd5ef6/nixos/modules/virtualisation/nixos-containers.nix) module for containers defined with [`containers`](https://search.nixos.org/options?channel=25.11&show=containers&query=containers) option, which is pretty much the same. They provide key clues to find out how nixos-container works.

#### Problem with GC

nixos-container mounts `/nix/var/nix/gcroots/per-container/$INSTANCE` on host to `/nix/var/nix/gcroots` in container. Which seems reasonable, but actually does nothing.

- `booted-system` and `current-system` in that gcroots directory are symlinks to `/run/booted-system` and `/run/current-system`. From the perspective of nix daemon, they refer to the host system instead of container. Even so it is not a big deal because `/nix/var/nix/profiles` is also treated as gc root. There are symlinks point directly to absolute path in nix store, which will keep the container system from being deleted.

- When nix performs a build, it automatically leaves a symlink in `/nix/var/nix/gcroots/auto` pointing to build result ([more details here](https://nixos.org/guides/nix-pills/11-garbage-collector.html#indirect-roots)). But if the build is requested from container, the symlink will point to a path inside container, unreachable from host, causing build result get garbage collected when gc. The problem has existed for a long time ([a discussion in 2021](https://discourse.nixos.org/t/garbage-collection-vs-nix-evaluation/14197/7)), and it is still there.
