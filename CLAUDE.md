# NixOS Configuration

## Repository Structure
- `flake.nix`: Main entry point for NixOS configuration
- `modules/`: System-wide NixOS modules
  - `system.nix`: Base system configuration
  - `sway.nix`: Sway window manager configuration
  - `pkgs.nix`: System-wide packages
- `home/`: Home-manager configuration
  - `default.nix`: Main home-manager config
  - `apps.nix`: User applications
  - `services.nix`: User services
- `hosts/`: Host-specific configurations
  - Host directories contain `default.nix` and `hardware-configuration.nix`
- `dotfiles/`: Configuration files linked by home-manager

## Key Features
- Sway window manager with waybar
- ZSH shell configuration
- Auto-start Sway on TTY1 login

## Common Commands
- `sudo nixos-rebuild switch`: Rebuild NixOS system
- `sudo nixos-rebuild switch --upgrade`: Rebuild and upgrade
- `sudo nix-collect-garbage -d && nix-collect-garbage -d`: Clean up old generations

## Verification Commands
After making changes to the configuration, you can use:
```bash
# Rebuild NixOS configuration
sudo nixos-rebuild switch
```

## Important Notes
- Sway auto-starts on TTY1 login via .zshrc
- Added services are managed via home-manager's systemd user services
- Window manager environment is configured for Wayland compatibility