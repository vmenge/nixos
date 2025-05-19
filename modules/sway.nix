{ pkgs, ... }:
{

  environment.systemPackages = with pkgs; [
    swayfx
    swaylock-effects
    waybar
  ];

  xdg.portal = {
    enable = true;
    wlr.enable = true;
    config.sway = {
      default = [
        "wlr"
        "gtk"
      ];
    };
    extraPortals = [
      pkgs.xdg-desktop-portal-gtk
    ];
  };

  security.pam.services.swaylock = { };

  services.greetd = {
    enable = true;
    settings = {
      default_session = {
        command = ''
          ${pkgs.greetd.tuigreet}/bin/tuigreet --time --cmd \
          "bash -lc \"source /etc/profiles/per-user/\$USER/etc/profile.d/hm-session-vars.sh; exec sway --unsupported-gpu\""
        '';
        user = "greeter";
      };
    };
  };
}
