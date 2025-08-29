gns() {
  dconf dump / | dconf2nix > ~/nixos/modules/dconf.nix
}
