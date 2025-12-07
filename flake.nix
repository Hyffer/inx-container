{
  description = "Run nixos container on nixos host with shared nix store using incus";

  outputs = { self }: {
    overlays.inx-container = final: prev: {
      inx-container = prev.callPackage ./package.nix {};
    };
  };
}
