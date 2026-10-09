# i3 dots
my i3 dots and scripts for asus zenbook duo (debian)
## demo


https://github.com/user-attachments/assets/90c3a8ee-6ca4-4bc5-aea0-fc6c925cbd4c




https://github.com/user-attachments/assets/91abfeeb-d601-4c25-9ae2-1684514ae6d6


This repo contains my **personalized build and configuration optimized for the Asus Zenbook Duo**.  
Due to the unique features of this laptop (secondary screen, specialized touchpad, extra buttons and an asus pen), the entire setup and scripts have been adapted specifically for this hardware.

## install

```bash
git clone https://github.com/josemri/dots.git ~/dots
cd ~/dots
./install.sh
```

## things

- install.sh installs the packages, symlinks the dotfiles, compiles asus-wmi-screenpad dkms module, writes the xorg conf for the pen, enables network/bluetooth/pipewire/tlp, and applies the hardware fixes (acpi, sd reader, gpu).
- hardware fixes: acpi, sd card reader, gpu on demand. (config/bashrc/fix/)
- touchpad and secondary screen toggles. (config/bashrc/toggleMouse.sh & config/bashrc/toggleScreen.sh)
- brightness and power management adjustments. (config/i3/config)
- asus pen button mapping. (config/i3/config)
- custom workspace and window management tailored for dual screens. (config/bashrc/workspace.sh, config/bashrc/mvapp.sh & config/i3/config)
- nvim
- xournalpp
- luks unlock splashscreen. (config/bashrc/splashscreen.sh)
- bash (custom git prompt, aliases, functions, zoxide)
- rofi (drun config, web shortcuts, audio sink switcher, external screen control menu, powermenu and recording menu with ffmpeg)
- i3 + i3blocks (weird keymapping because of the dual screen and extra buttons)
- picom
- kitty
- nitrogen (wallpapers in config/wp)
- zathura
- librewolf (userChrome.css)
- mimeapps.list

... I will be updating this as I add more scripts or modify old ones ...

## recommendations with this specific hardware

If you have this laptop and want to install linux on it take this into account:
sd slot does not work for me out of the box but there is a fix in config/bashrc/fix/fix-sd-reader.sh, applied by install.sh.
to remap all keyboard extra buttons you will need to install [asus-wmi-screenpad](https://github.com/Plippo/asus-wmi-screenpad) (install.sh compiles it via dkms with the `dkms` step) then remap to whatever you want in i3 config.

**asus pen** works weirdly since it can either work out of the box or not and you will need to find a solution for each specific case, me for example i have to remap the drawing area to only the secondary screen because it automatically maps to both screens and that makes it unusable. Also, at least in this build, i had to add a file into /etc/X11/xorg.conf.d/50-asus-pen.conf (install.sh writes it for you with the `pen` step):
```bash
cat /etc/X11/xorg.conf.d/50-asus-pen.conf                                                              
Section "InputClass"

      Identifier "ASUS SPEN"                                                                           
      MatchProduct "ELAN9009:00 04F3:2C58"                                                             
      Driver "wacom"                                                                                   
      Option "Gesture" "off"                                                                           
EndSection                                                                                             
```
if you have this pen i recommend disabling touchscreen for the secondary screen so it does not interfere with pen input.
xournalpp works fine with the pen after that.
also the pen has to be remapped each time the pc restarts, so the i3 config already ships these startup actions (config/i3/config):

```bash
exec --no-startup-id xrandr --output DP-1 --below eDP-1 #this just places the secondary screen below main screen
exec --no-startup-id xinput disable "$(xinput list | grep "touch" | grep -o 'id=[0-9]\+' | cut -d= -f2)" # disable touch screen
exec --no-startup-id xinput map-to-output "$(xinput list | grep "Stylus stylus" | grep -o 'id=[0-9]\+' | cut -d= -f2)" DP-1 # map pen to secondary screen
exec --no-startup-id xinput map-to-output "$(xinput list | grep "Stylus eraser" | grep -o 'id=[0-9]\+' | cut -d= -f2)" DP-1 # map eraser to secondary screen
```

**action keys** you will have to remap asus specific action keys, this is how i did it (in order from left to right on the keyboard):
```bash

#volume maps
bindsym XF86AudioMute exec --no-startup-id "wpctl set-mute @DEFAULT_SINK@ toggle"
bindsym XF86AudioLowerVolume exec --no-startup-id "wpctl set-volume @DEFAULT_SINK@ 5%-"
bindsym XF86AudioRaiseVolume exec --no-startup-id "wpctl set-volume @DEFAULT_SINK@ 5%+ -l 1.0"
bindsym Shift+XF86AudioMute exec --no-startup-id ./.config/rofi/audio.sh

# brightness maps
bindsym XF86MonBrightnessUp exec --no-startup-id brightnessctl s +10%
bindsym XF86MonBrightnessDown exec --no-startup-id brightnessctl s 10%-
bindsym Shift+XF86MonBrightnessUp exec --no-startup-id brightnessctl -d asus::screenpad s +10%
bindsym Shift+XF86MonBrightnessDown exec --no-startup-id brightnessctl -d asus::screenpad s 10%-

bindsym XF86TouchpadToggle exec --no-startup-id ./.config/bashrc/toggleMouse.sh
bindsym $mod+p exec --no-startup-id ./.config/rofi/externalScreen.sh
bindsym $mod+l exec --no-startup-id "i3lock -c 000000 --no-unlock-indicator --ignore-empty-password -n" # lock screen
bindsym $mod+Shift+s exec --no-startup-id ffmpeg -nostdin -loglevel quiet -f x11grab -draw_mouse 0 -select_region 1 -i :0.0 -frames:v 1 -c:v png -f image2pipe - | xclip -i -selection clipboard -t image/png
bindsym XF86Launch1 exec --no-startup-id ./.config/rofi/rec.sh
bindsym Print exec --no-startup-id ffmpeg -nostdin -loglevel quiet -f x11grab -draw_mouse 0 -i :0.0 -frames:v 1 -c:v png -f image2pipe - | xclip -i -selection clipboard -t image/png
bindsym XF86Launch6 exec --no-startup-id ./.config/bashrc/mvapp.sh
bindsym XF86Launch7 exec --no-startup-id ./.config/bashrc/toggleScreen.sh # toggle eDP-1 on/off
bindsym XF86PowerOff  exec --no-startup-id ./.config/rofi/powermenu.sh 
```

apart from that everything else is pretty standard i3 setup.
