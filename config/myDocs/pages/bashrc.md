## alias
- Los alias hasta ahora siempre los he tenido metidos dentro del .bashrc, pero desde que probe hyprland me he dado cuenta de lo limpio que queda meterlos en otro archivo, en mi caso los tengo metidos en el archivo ~/.config/bashrc/alias. Este solo contiene alias y muy probablemente acabe haciendo algun tipo de funcion para meterlos automaticamente. Para listarlos sigue siendo igual que siempre(alias) y de momento tengo los siguientes:
- ```bash
  alias c3='nvim ~/.config/i3/config' #config i3
  alias ls='ls --color=auto'
  alias n='nvim'
  alias off='poweroff'
  alias src='source ~/.bashrc'
  alias w11='/usr/lib/virtualbox/VirtualBoxVM --comment "w11" --startvm "{aca82126-48f9-492c-90bd-e3e6fd32cebb}" &'
  alias wpp='firefox --new-window --kiosk https://web.whatsapp.com'
  alias o='xdg-open'
  ```
- el unico que tiene mas cosa es el de w11 que se explica en [[VirtualBox]] y el de [wpp](Firefox)
- Para cargarlos en el .bashrc necesito lo siguiente:
- ```bash
  if [ -f ~/.config/bashrc/alias ]; then
  	. ~/.config/bashrc/alias
  fi
  ```
-
-
-
-
-