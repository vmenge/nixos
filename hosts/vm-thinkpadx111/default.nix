{ ... }:

{
  imports = [
    ../../modules/system.nix
    ./hardware-configuration.nix
  ];

  networking.hostName = "vm-thinkpadx111";
  hardware.bluetooth.enable = true;
  hardware.bluetooth.powerOnBoot = true;

  services.pipewire.wireplumber.extraConfig."99-disable-libcamera" = {
    "wireplumber.profiles" = {
      "main" = {
        "monitor.libcamera" = "disabled";
      };
    };
  };
}
