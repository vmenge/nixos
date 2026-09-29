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

}
