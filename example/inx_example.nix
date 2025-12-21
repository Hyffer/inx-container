{ config, lib, pkgs, ... }:

{
  boot.isContainer = true;
  system.nixos.tags = lib.mkOverride 99 [ "inx-ex" ];

  environment.systemPackages = with pkgs; [
    neofetch
  ];

  system.stateVersion = "25.05";
}