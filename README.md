# inx-container

Run nixos container on nixos host with shared nix store using [incus](https://linuxcontainers.org/incus/).

Inspired by [nixos-container](https://wiki.nixos.org/wiki/NixOS_Containers) and [nixcloud-container](https://github.com/nixcloud/nixcloud-container).

nixos-container lets container share host's nix store. But it uses systemd-nspawn, which I am not familiar with. And it *might* be less functional than other prevalent lxc managers.

nixcloud-container project brings the concept of sharing nix store to LXD, but hasn't been maintained for a long time. During the years, incus took the place of LXD ([project history](https://github.com/lxc/incus?tab=readme-ov-file#project-history)). And that is the target of inx-container.

## Usage

**Tip:** When encontering problems, add a environment variable `VERBOSE=1` might help. That tells inx-container to show what it does step by step.

Firstly, manually create a directory `/nix/var/nix/profiles/inx-container` ([more details](#persistent-storage)). I personally suggest make it writable by incus-admin group, letting a user in the group uses inx-container without dedicated permission.

Then, there is an example folder in this repo, cd into example folder,

```
inx-container create inx-ex --flake .
```

The system should be built and placed under `/nix/var/nix/profiles/inx-container/inx-ex`. And a incus container named "inx-ex" should be created but not started.

From now on, "inx-ex" is just a normal incus container, not much different from others. You can start it now, or customize before first run.

Next time after editing the configration,

```
inx-container update inx-ex --flake .
```

## Notice

### Container Declaration

[Incus - Official NixOS Wiki](https://wiki.nixos.org/wiki/Incus#Custom_Images) talks about how to create custom container image. It includes a module from [`"${inputs.nixpkgs}/nixos/modules/virtualisation/lxc-container.nix"`](https://github.com/NixOS/nixpkgs/blob/38b523e9e8e607bcd8f638d8a53608bb1658a0e4/nixos/modules/virtualisation/lxc-container.nix), which requires a /sbin folder under root directory. But we are not gonna build rootfs from the lxc-container configuration. So please **DO NOT** follow that. Instead, add `boot.isContainer = true;` manually to your module.

Example in this repo provides a fully functional instance.

### Nix Command in Container

nix commands **are** supported in container, although not recommended. There is a known issue with nix garbage collection, which nixos-container also confronts ([details here](#problem-with-gc)).

That said, `nix-shell` and even `nixos-rebuild switch` work fine in container. Though it might be preferred to use `inx-container update` form host rather than `nixos-rebuild switch` in container.

There is also a flaw with `sudo` ([same as nixos-container](#flawed-sudo-environment)), that you cannot directly sudo a nix command. It can be easily solved.

### Persistent Storage

inx-container stores container system profiles in `/nix/var/nix/profiles/inx-container/$INSTANCE`, which should be kept persistent if the host system uses a volatile rootfs.

## Design Consideration

### Behavior of nixos-container

nixos-container has some key components, a cli written in perl (`/run/current-system/sw/bin/nixos-container`) and a systemd service template (`/etc/systemd/system/container@.service`). There is also a [nixos-containers.nix](https://github.com/NixOS/nixpkgs/blob/c6f52ebd45e5925c188d1a20119978aa4ffd5ef6/nixos/modules/virtualisation/nixos-containers.nix) module for containers defined with [`containers`](https://search.nixos.org/options?channel=25.11&show=containers&query=containers) option, which is pretty much the same. They provide key clues to find out how nixos-container works.

#### Problem with GC

nixos-container mounts `/nix/var/nix/gcroots/per-container/$INSTANCE` on host to `/nix/var/nix/gcroots` in container. Which seems reasonable, but actually does nothing.

- `booted-system` and `current-system` in that gcroots directory are symlinks to `/run/booted-system` and `/run/current-system`. From the perspective of nix daemon, they refer to the host system instead of container. Even so it is not a big deal because `/nix/var/nix/profiles` is also treated as gc root. There are symlinks point directly to absolute path in nix store, which will keep the container system from being deleted.

- When nix performs a build, it automatically leaves a symlink in `/nix/var/nix/gcroots/auto` pointing to build result ([more details here](https://nixos.org/guides/nix-pills/11-garbage-collector.html#indirect-roots)). But if the build is requested from container, the symlink will point to a path inside container, unreachable from host, causing build result get garbage collected when gc. The problem has existed for a long time ([a discussion in 2021](https://discourse.nixos.org/t/garbage-collection-vs-nix-evaluation/14197/7)), and it is still there.

#### Flawed sudo Environment

Inside nixos-container, `NIX_REMOTE=daemon` is absent in sudo environment. But both root and non-root user's environments are correct. Only sudo a nix command will fail.

### Declarative and Purity

inx-container is just a command line helper, calling nix and incus to set up container properly. It does not offer the declarative that [`containers`](https://search.nixos.org/options?channel=25.11&show=containers&query=containers) option provides. Which could be improved to some extent.
