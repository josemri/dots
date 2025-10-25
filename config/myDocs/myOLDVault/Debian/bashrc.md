De la misma forma que he dicho en [[Debian/main|main]] estoy a un punto en el que he cambiado tanto el bashrc que me vale la pena hacer un archivo nuevo.

![[Pasted image 20250203085412.png]]

Para empezar como se puede ver he ido cambiando cosas en [[neofetch]], principalmente ya no estoy usando [screenfetch](Xubuntu/screenfetch) ya que este ultimo ya no me da problemas y creo que queda mucho mas bonito que el que usaba en xubuntu. Ademas como ahora ya no estoy usando [xfce](Xubuntu/xfce), ahora estoy usando [i3](Debian/i3) por lo que hay muchisima config que esta metida en [i3](Debian/i3) y ya no es necesario meterla aqui.
Todo lo que voy a explicar lo tengo metido en ~/.bashrc por lo que a partir de ahora doy por hecho esto.

## Screen mapping

```bash
if [ ! -n "$(xrandr | grep "DP-1 disconnected")" ]; then
        xinput map-to-output 12 DP-1;
        if xinput | grep 'Stylus Pen'>/dev/null 2>&1 ; then xinput map-to-output $(xinput | grep 'Stylus Pen' | awk '{print $8}' | cut -d= -f 2) DP-1; fi
        if xinput | grep 'Stylus Eraser'>/dev/null 2>&1 ; then xinput map-to-output $(xinput | grep 'Stylus Eraser' | awk '{print $8}' | cut -d= -f 2) DP-1; fi
fi;
```

Como dice el titulo lo unico que hago aqui es mapear la sengunda pantalla a si misma y el  pen de asus dependiendo de si esta conectado o no, este no lo suelo usar casi nunca ya que me obliga a hacer un resource cada vez que conecto el pen al portatil, por lo que acabo antes mapeando un script casi identico a este codigo a la tecla fn+F12, cosa que explico mejor en [asus-stylus](Debian/asus-stylus).

## tmux

```bash
if command -v tmux>/dev/null; then
[[ ! $TERM =~ screen ]] && [ -z $TMUX ] && exec tmux
fi
```
Config estandar de tmux, es lo que pone en su [github](https://github.com/tmux/tmux) de como se configura y yo no he tocado nada de como esta definido de [tmux](Xubuntu/bashrc#tmux).

## alias

A partir de aqui casi todo lo que tengo son alias para diferentes acciones, hay algunos que ya no uso o que ya no funciona pero eso ya es tema de que me tengo que poner a limpar. Por otro lado he visto que en el propio .bashrc ya viene integrado en el codigo para cargar los alias desde otro archivo lo que probablemente deberia hacer en un futuro, pero de momento asi no esta mal.

``` bash
alias whatsapp='xdg-open https://web.whatsapp.com > /dev/null 2>&1'
alias notes='xournalpp > /dev/null 2>&1'
alias battery='upower -i $(upower -e | grep "BAT") | grep -E "state|to\ full|percentage"'
alias ai2u='ollama run llama2-uncensored'
alias ai3='ollama run llama3.1'
alias sql='sudo -i -u postgres psql' # -d dbintro'
alias n='nvim'
alias info='clear && neofetch --disable gpu icons theme uptime --ascii_distro Debian --ascii_bold on'
alias net='nmtui'
alias neton='nmcli r wifi on'
alias netoff='nmcli r wifi off'
```

La mayoria son bastante directos, tengo uno para whatsapp(que no se si funciona porque ya no lo uso practicamente nunca), otro para notes, el de battery ya no lo uso casi nunca tampoco, los de ollama ya no funcionan ya que no tengo insalado ollama ni los llms, tampoco tengo instalado postgres. A partir de aqui estos alias si los utilizo mucho mas. n para abrir antes [nvim](Debain/nvim), info para [[neofetch]], y los otros tres para controlar la conexión a internet con nmtui o nmcli.

``` bash
alias maxb="echo 255 > '/sys/class/leds/asus::screenpad/brightness'"
alias minb="echo 0 > '/sys/class/leds/asus::screenpad/brightness'"
duo_() {
    echo "$1" > '/sys/class/leds/asus::screenpad/brightness'
}

eval "$(starship init bash)"
alias w11='VBoxManage startvm "w11vm" && exit'
alias kali='VBoxManage startvm "kali" && exit'
alias off='systemctl poweroff'
alias rbt='systemctl reboot'
alias la='clear && ls *'
alias o='xdg-open'
alias studio='studio > /dev/null 2>&1 &'
alias sudo='sudo '
alias cal='ncal -M -b '
alias src='source ~/.bashrc'
alias aptcli='.~/.config/aptcli.sh'
alias purge='.~/.config/purge.sh'
```

Alias para el control del brillo del segundo monitor, la inicialización de [[starship]], alias para las dos maquinas virtuales, off y rbt para apagar y reiniciar, la para limpiar y mostrar el contenido de la carpeta actual y el siguiente nivel de subcarpetas con su contenido. He sustituido xdg-open por o par simplificarlo igual que he hecho con nvim, studio ya no lo utilizo ya que voy completamente por nvim y cal es un pequeño calendario. Por ultimo src aptcli y purge recarga el source, mustra un tui muy simple usando fzf para instalar paquetes y purge ejecuta un script que limpia archivos basura.

## neofetch
```bash
if [ ! -f /tmp/.neofetch_done ]; then
    maxb && clear && neofetch --disable gpu icons theme uptime --ascii_distro Debian --ascii_bold on
    touch /tmp/.neofetch_done
fi
```

Con el objetivo de que solo se abra una vez el neofetch al inicar por primera vez la terminal por tal de no molestar simplemente he implementado que si no existe el arhcivo /tmp/.neofetch_done ejecuta neofetch y luego crea el archivo simplemente par aque luego no se vuelva a ejecutar. Al estar en tmp no hace falta eliminarlo ya que al reiniciar se elimina todo lo de esta carpeta automaticamente.

## fzf

```bash
f() {
  local selection
  selection=$(find . -mindepth 1 | fzf --query="$1" --preview 'cat {}' --border --height 40% --layout=reverse)
  if [ -d "$selection" ]; then
    cd "$selection"; ls || return
  elif [ -f "$selection" ]; then
    xdg-open "$selection"
  fi
}
```

Lo que tengo hecho aqui implementa fzf para poder buscar archivos y carpetas y luego poder abrirlos, ya que fzf solo retorna la direccion por lo que me he hecho esta función para que en caso de ser una carpeta, se va a mover a dicha carpeta y en caso de ser un archivo lo ejecutara con la config que tenga en [[xdg-open]]