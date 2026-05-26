{ ... }:
{
  services.gitwatch.brain = {
    enable = true;
    path = "/home/vmenge/brain";
    remote = "git@github.com:vmenge/nixos.git";
    user = "vmenge";
    message = "Auto-commit by gitwatch on %d";
  };
}
