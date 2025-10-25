Bueno pues ya que me gustaban bastante los gestos del mac con el raton, he pensado que podría hacer algo parecido aqui. Al final ha resultado en la creación de dos scripts mas que basicamente me mueven entre workspaces y muestran una notificación indicando en que workspace me encuentro.
Lo primero de todo ha sido instalar [[Touché]], me he decidido por esta oción porque es la que a mi parecer menos morralla instala con la funcionalidad principal. He seguido los pasos de isntalación que se muestran en [Unlock Multi-Touch Gestures in Xubuntu](https://blog.bluesabre.org/2022/02/17/unlock-multi-touch-gestures-in-xubuntu/)
Es antigua y no tiene muchas funcionalidades, pero la gracia está en la opción: Execute a command. Por lo que puedes mapear los gestos para hacer absolitamente lo que te de la gana.
Viene tambien con una opción para cambiar de workspace, pero no me gusta mucho ya que no hay confirmación ninguna de que te has cambiado de escritorio, fuera de que las aplicaciónes desaparecen. Como se puede ver en [xfce](xfce#Panel) tengo los workspaces renombrados con unos iconos. Por lo que en lugar de mostrar un numero en la notificación muestro el icono de ese workspace. Para poder cambiarme de workspace usando bash he tenido que instalar también wmctrl, mismo porgrama que he usado tambien para [asus-wmi-screenpad](asus-wmi-screenpad#ToggleApp)
Al final se han quedado los dos scripts asi:

```bash
current=$(xprop -root _NET_CURRENT_DESKTOP | awk '{print $3}')
if [ $current -eq 0 ]; then
        current=3
else
        current=$(($current-1))
fi;
echo $current
wmctrl -s $current
array=(🟣️ 🔵️ 🔴️ 🟢️)
notify-send "${array[$current]}" -t 1000
```
este lo he llamado toggleWsRight.sh y se encuentra donde guardo todos los scripts, ~/.config/toggleWsRight.sh

```bash
current_ws=$(xprop -root _NET_CURRENT_DESKTOP | awk '{print $3}')
total_ws=$(xprop -root _NET_NUMBER_OF_DESKTOPS | awk '{print $3}')

final_ws=$(((current_ws+1)%total_ws))

wmctrl -s $final_ws

array=(🟣️ 🔵️ 🔴️ 🟢️)
notify-send "${array[$final_ws]}" -t 1000

```
y este ~/.config/toggleWsLeft.sh

Basicamente lo que hacen los dos escripts es iterar entre los workspaces, y luego con notify-send muestre el icono del workspace actual.

Esta función se activa cuando deslizas tres dedos a la izquierda o derecha.


## Adicional

Tambien he querido añadir funcionalidades que me parecen muy comunes y que por defecto no vienen habilitadas, simplemente he metido el gesto de zoom y zoom out con pinch. Con dos dedos hacia dentro ejecuta el shortcut ctrl- y para fuera ctrl+.

Luego en el tap he puesto que con dos dedos haga el click dereco y con tres haga el click central del raton.

Como algo un poco mas raro he puesto en el pinch con 4 dedos que abra una terminal en la segunda pantalla en pantalla completa.