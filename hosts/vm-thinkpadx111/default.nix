{ ... }:

{
  imports =
    [ 
      ../../modules/system.nix
      ./hardware-configuration.nix
    ];

  networking.hostName = "vm-thinkpadx111"; 
}

