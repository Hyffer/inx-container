# inx-container

Run nixos container on nixos host with shared nix store using incus.

Inspired by [nixos-container](https://nixos.wiki/wiki/NixOS_Containers) and [nixcloud-container](https://github.com/nixcloud/nixcloud-container).

## Container Declaration

[Incus - Official NixOS Wiki](https://wiki.nixos.org/wiki/Incus#Custom_Images) talks about how to create custom container image. It includes a module from [`"${inputs.nixpkgs}/nixos/modules/virtualisation/lxc-container.nix"`](https://github.com/NixOS/nixpkgs/blob/38b523e9e8e607bcd8f638d8a53608bb1658a0e4/nixos/modules/virtualisation/lxc-container.nix), which requires a /sbin folder under root directory. But we are not gonna build rootfs from the lxc-container configuration. So please **DO NOT** follow that. Instead, add `boot.isContainer = true;` manually to your module.
