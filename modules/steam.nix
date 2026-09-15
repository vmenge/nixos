{ pkgs, ... }:
{
  environment.sessionVariables.STEAM_FORCE_DESKTOPUI_SCALING = "1.0";

  programs.gamemode.enable = true;
  programs.steam.enable = true;

  jovian.steam = {
    enable = true;
    autoStart = false;
    user = "vmenge";
  };

  # This is a normal NVIDIA laptop, not a Steam Deck.
  jovian.steamos.useSteamOSConfig = false;

  hardware.graphics = {
    enable = true;
    enable32Bit = true;
  };

#  programs.alvr = {
#    enable = true;
#    openFirewall = true;
#  };

  services.wivrn = {
    enable = true;
    openFirewall = true;

    # Run WiVRn as a systemd service on startup
    autoStart = true;

    # If you're running this with an nVidia GPU and want to use GPU Encoding (and don't otherwise have CUDA enabled system wide), you need to override the cudaSupport variable.
    package = (pkgs.wivrn.override { cudaSupport = true; });

    # You should use the default configuration (which is no configuration), as that works the best out of the box.
    # However, if you need to configure something see https://github.com/WiVRn/WiVRn/blob/master/docs/configuration.md for configuration options and https://mynixos.com/nixpkgs/option/services.wivrn.config.json for an example configuration.
  };
}
