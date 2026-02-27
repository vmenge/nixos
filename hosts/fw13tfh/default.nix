{ pkgs, ... }:

{
  imports = [
    ../../modules/system.nix
    ./hardware-configuration.nix
  ];

  networking.hostName = "fw13tfh";
  hardware.bluetooth.enable = true;
  hardware.bluetooth.powerOnBoot = true;

  # Ensure the internal mic is selected on this host (ALC285 exclusive capture group).
  systemd.services.fw13tfh-internal-mic = {
    description = "Select internal microphone on ALC285";
    wantedBy = [ "multi-user.target" ];
    after = [ "sound.target" ];
    path = [ pkgs.alsa-utils ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
    };
    script = ''
      amixer -c 1 set 'Headset Mic' nocap
      amixer -c 1 set 'Internal Mic' cap
      amixer -c 1 set 'Internal Mic Boost' 0
    '';
  };
}
