# HyprlandSetup
All dotfiles and tools for my Hyprland setup on Arch linux

curl -fLo ~/.vim/autoload/plug.vim --create-dirs https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim

Then open `vim` and run `:PluginInstall` to actually install wal.vim (declared in vimrc but not installed until this is run)
Make sure to use `gvim` to have system wide clipboard access in vim

yay -S pixie-sddm-git
The files under the `usr` dir must be placed under the `/usr` dir of the computer and not in `home` dir
