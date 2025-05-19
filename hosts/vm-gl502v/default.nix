{ ... }:

{
  imports = [
    ../../modules/system.nix
    ./hardware-configuration.nix
  ];

  networking.hostName = "vm-gl502v";
}
