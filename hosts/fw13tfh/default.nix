{ ... }:

{
  imports = [
    ../../modules/system.nix
    ./hardware-configuration.nix
  ];

  networking.hostName = "fw13tfh";
  hardware.bluetooth.enable = true;
  hardware.bluetooth.powerOnBoot = true;
}
