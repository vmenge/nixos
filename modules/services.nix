{ ... }:
{
  services.gitwatch.brain = {
    enable = true;
    path = "/home/vmenge/brain";
    remote = "git@github.com:vmenge/brain.git";
    user = "vmenge";
  };
}
