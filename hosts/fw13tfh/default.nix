{ pkgs, ... }:

{
  imports = [
    ../../modules/system.nix
    ./hardware-configuration.nix
  ];

  networking.hostName = "fw13tfh";
  hardware.bluetooth.enable = true;
  hardware.bluetooth.powerOnBoot = true;

  # The ACP PDM DMIC (acp-pdm-mach) on this board produces full-scale garbage.
  # Disable the WirePlumber node so PipeWire falls back to the working ALC285
  # analog internal mic instead.
  services.pipewire.wireplumber.extraConfig."52-disable-dmic" = {
    "monitor.alsa.rules" = [
      {
        matches = [ { "node.name" = "~alsa_input.*HiFi__Mic1__source"; } ];
        actions = {
          "update-props" = {
            "node.disabled" = true;
          };
        };
      }
    ];
  };

  # Select the internal mic on the ALC285 analog capture path and set a
  # reasonable capture volume (20/63 ≈ -2.25 dB avoids clipping).
  # Must be a user service: WirePlumber runs as a user service and overrides
  # ALSA mixer state via UCM profiles after any system-level service has run.
  systemd.user.services.fw13tfh-internal-mic = {
    description = "Select internal microphone on ALC285";
    wantedBy = [ "wireplumber.service" ];
    after = [ "wireplumber.service" ];
    path = with pkgs; [ wireplumber alsa-utils ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
    };
    script = ''
      # Wait for WirePlumber to finish creating the headset source node
      for i in $(seq 1 60); do
        wpctl inspect alsa_input.pci-0000_c1_00.6.HiFi__Headset__source &>/dev/null && break
        sleep 0.5
      done
      amixer -c 1 set 'Headset Mic' nocap
      amixer -c 1 set 'Internal Mic' cap
      amixer -c 1 set 'Internal Mic Boost' 0
      amixer -c 1 set 'Capture' 20 cap
    '';
  };
}
