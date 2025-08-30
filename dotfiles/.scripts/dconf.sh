gns() {
  dconf dump / | dconf2nix > ~/nixos/home/dconf.nix
}
