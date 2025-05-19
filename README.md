# set up 
```bash
cd ~
git clone git@github.com:vmenge/nixos.git
sudo mv /etc/nixos /etc/nixos.bak  
sudo ln -s ~/nixos /etc/nixos
sudo nixos-rebuild switch
```
