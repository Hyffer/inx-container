{
  description = "NixOS flake";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.05";
  };

  outputs = { self, nixpkgs, ... } @ inputs: {
    nixosConfigurations.inx-ex = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      modules = [
        ./inx_example.nix
      ];
    };
  };
}
