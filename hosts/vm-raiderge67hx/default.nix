{ pkgs, ... }:

{
  imports = [
    ../../modules/system.nix
    ./hardware-configuration.nix
  ];

  networking.hostName = "vm-raiderge67hx";

  hardware.graphics = {
    enable = true;
  };

  services.xserver.videoDrivers = [ "nvidia" ];

  hardware.nvidia = {
    modesetting.enable = true;
    powerManagement.enable = false;
    powerManagement.finegrained = false;
    open = false;

    nvidiaSettings = true;
  };

  hardware.graphics.extraPackages = with pkgs; [
    vulkan-loader
    vulkan-validation-layers
    vulkan-extension-layer
    vulkan-tools
  ];

  environment.systemPackages = with pkgs; [
    mcontrolcenter # tool to change the settings of msi laptops
    egl-wayland
  ];

  fileSystems."/mnt/ntfs" = {
    device = "/dev/disk/by-uuid/2834BB6434BB33A2";
    fsType = "ntfs";
  };
}
