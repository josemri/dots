En cuanto al archivo de config de bash (~/.bashrc) he ido añadiendo bastantes cosas con el tiempo, principalmente alias, pero también alguna otra mejora que me va bien. No hay mucha cosa para hacer la terminal, en mi caso estoy usando la predeterminada de xfce4-terminal bonita fuera de cambiarle la opacidad y permitir la escritura en negrita.
![[Pasted image 20240607191915.png]]

## Stylus 

> 2024-06-09 04:57
   He implementado una mejora en esta aproximación que he detallado en [[asus-stylus]]. Por lo que ahora esto se ha quedado desactualizado, pero aun asi lo dejo por mantantener un log de los cambios que voy haciendo. #desactualizado

Lo primero que tengo puesto es un script para detectar y mapear a la segunda pantalla el Stylus 

```bash
#if screen is not off
if [ ! -n "$(xrandr | grep "DP-1 disconnected")" ]; then
        #map screen
        xinput map-to-output 12 DP-1;
        #map pen
        if xinput | grep 'Stylus Pen'>/dev/null 2>&1 ; then xinput map-to-output $(xinput | grep 'Stylus Pen' | awk '{print $8}' | cut -d= -f 2) DP-1; fi
        if xinput | grep 'Stylus Eraser'>/dev/null 2>&1 ; then xinput map-to-output $(xinput | grep 'Stylus Eraser' | awk '{print $8}' | cut -d= -f 2) DP-1; fi
fi;
```

1. Comprueba que el segundo monitor no este desconectado 
2. En caso que no sea para corregir el mapeado que viene predefinido en Xubuntu asigna al segundo monitor el area de dibujo de este, ya que cuando lo instalas por primera vez cuando intentas usar la pantalla táctil mapea todas las pantallas
3. en caso de que el sistema detecte el lápiz, coge su id y la asigna al segundo monitor, ya que como con la pantalla táctil, Xubuntu mapea el lápiz a todas las pantallas
4. repite lo mismo que para el lápiz en si pero para el "borrador", que no es mas que otro botón del lápiz.
## tmux

```bash
if command -v tmux>/dev/null; then
[[ ! $TERM =~ screen ]] && [ -z $TMUX ] && exec tmux
fi
```
Simplemente inicio [[tmux]] con el comando que te pone en la pagina web oficial de este, lo tengo así para que cada vez que abra una terminal directamente me abra tmux dentro ya que me parece mucho mas util así.

## screenfetch

```bash
screenfetch -A 'Windows'
```
Inicio [[screenfetch]] cambiando el ASCII art que sale de Ubuntu por el de windows.

## LD_PRELOAD

```bash
unset LD_PRELOAD
```
La verdad es que no se exactamente que hace este comando pero me he dado cuenta que des habilitado eso no me salta un error cuando abro, por ejemplo nmap. Este lo tengo de la anterior instalación que hice de Xubuntu, no se si ahora esta haciendo algo o no, pero lo dejo porque si funciona para que cambiarlo.

## alias

```bash
alias whatsapp='xdg-open https://web.whatsapp.com > /dev/null 2>&1'
alias notes='xournalpp %f > /dev/null 2>&1'
alias battery='upower -i $(upower -e | grep "BAT") | grep -E "state|to\ full|percentage"'
alias ai2u='ollama run llama2-uncensored'
alias ai3='ollama run llama3'
alias sql='sudo -i -u postgres psql' # -d dbintro'
alias n='nvim'
```
Alias bastante simples, quizás el mas complejo es el de battery, aun que lo saque de algún foro de internet.

## mas alias

```bash
# /etc/udev/rules.d/99-asus.rules > modificar brillo sin privilegio
alias maxb="echo 255 > '/sys/class/leds/asus::screenpad/brightness'"
alias minb="echo 0 > '/sys/class/leds/asus::screenpad/brightness'"
duo_() {
    echo "$1" > '/sys/class/leds/asus::screenpad/brightness'
}
```
De momento los 2 últimos alias que tengo configurados, comandos para interactuar con el driver de [[asus-wmi-screenpad]], ahí supongo que explico mejor como lo tengo configurado.

## starship

```bash
#start starship
eval "$(starship init bash)"
```
Pues lo que dice, comando que he sacado también de la pagina web de [[starship]], en cuanto a la configuración que tiene supongo que explico un poco mejor en su nota.


# 2024-06-24 21:56

He añadido dos alias al archivo, uno sirve para ejecutar la maquina virtual con windows instalada y la otra para apagar el ordenador con el comando off.

``` bash
alias w11='/usr/lib/virtualbox/VirtualBoxVM --comment "w11" --startvm "{aca82126-48f9-492c-90bd-e3e6fd32cebb}" &'
alias off='poweroff'  
```

el shortcut del w11 tambien he implementado al menu [Whisker](xfce#Whisker).

