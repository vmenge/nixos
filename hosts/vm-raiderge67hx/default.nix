{ pkgs, config, ... }:

{
  imports = [
    ../../modules/system.nix
    ./hardware-configuration.nix
  ];

  boot.extraModulePackages = [ config.boot.kernelPackages.msi-ec ];
  boot.kernelModules = [ "msi-ec" ];

  networking.hostName = "vm-raiderge67hx";
  hardware.bluetooth.enable = true;
  hardware.bluetooth.powerOnBoot = true;

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
    prime = {
      # disable bc igpu disabled rn
      # sync.enable = true;
      # offload.enable = false;

      # intelBusId = "PCI:0:2:0";
      # nvidiaBusId = "PCI:1:0:0";
    };
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

  environment.sessionVariables = {
    WLR_NO_HARDWARE_CURSORS = "1";
    WLR_RENDERER = "vulkan";
    WLR_RENDERER_DEVICE = "/dev/dri/card0";
  };

  fileSystems."/mnt/ntfs" = {
    device = "/dev/disk/by-uuid/2834BB6434BB33A2";
    fsType = "ntfs";
  };
}
