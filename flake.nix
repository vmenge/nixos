{
  description = "nixos";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    plasma-manager = {
      url = "github:nix-community/plasma-manager";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.home-manager.follows = "home-manager";
    };
  };

  outputs =
    { nixpkgs, home-manager, plasma-manager, ... }:
    let
      cfg =
        system: hostName:
        nixpkgs.lib.nixosSystem {
          system = system;
          modules = [
            ./hosts/${hostName}
            home-manager.nixosModules.home-manager
            {
              home-manager.useGlobalPkgs = true;
              home-manager.useUserPackages = true;
              home-manager.users.vmenge = import ./home;
              home-manager.sharedModules = [ plasma-manager.homeModules.plasma-manager ];
              home-manager.extraSpecialArgs = { inherit nixpkgs; };
              home-manager.backupFileExtension = "bak";
            }
          ];
        };
    in
    {
      nixosConfigurations = {
        vm-gl502v = cfg "x86_64-linux" "vm-gl502v";
        vm-raiderge67hx = cfg "x86_64-linux" "vm-raiderge67hx";
        vm-thinkpadx111 = cfg "x86_64-linux" "vm-thinkpadx111";
        fw13tfh = cfg "x86_64-linux" "fw13tfh";
      };
    };
}
