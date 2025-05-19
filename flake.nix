{
  description = "nixos";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    { nixpkgs, home-manager, ... }:
    let
      homeManager = [
        home-manager.nixosModules.home-manager
        {
          home-manager.useGlobalPkgs = true;
          home-manager.useUserPackages = true;
          home-manager.users.vmenge = import ./home;
          home-manager.extraSpecialArgs = { inherit nixpkgs; };
          home-manager.backupFileExtension = "bak";
        }
      ];
    in
    {
      nixosConfigurations = {
        vm-gl502v = nixpkgs.lib.nixosSystem {
          system = "x86_64-linux";
          modules = [
            ./hosts/vm-gl502v
          ] ++ homeManager;
        };

        vm-raiderge67hx = nixpkgs.lib.nixosSystem {
          system = "x86_64-linux";
          modules = [
            ./hosts/vm-raiderge67hx
          ] ++ homeManager;
        };

        vm-thinkpadx111 = nixpkgs.lib.nixosSystem {
          system = "x86_64-linux";
          modules = [
            ./hosts/vm-thinkpadx111
          ] ++ homeManager;
        };
      };
    };
}
