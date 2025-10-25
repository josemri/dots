Esto es un proyecto de [GitHub](https://github.com/Plippo/asus-wmi-screenpad) que me sirve de drivers para controlar el brillo de la pantalla secundaria, este, una vez instalado, usando el comando
```bash
echo XXX | sudo tee '/sys/class/leds/asus::screenpad/brightness'
```
donde XXX es un valor entre 0 y 255. 0 apagara el monitor completamente y 255 pondrá el brillo al máximo.

El problema que tiene esto es que cada vez que quiero cambiar el brillo con el alias que tenía puesto me pedía la contraseña. Para solucionar esto, en el propio GitHub te enseña a solucionarlo creando el archivo /etc/udev/rules.d/99-asus.rules.

```bash
ACTION=="add", SUBSYSTEM=="leds", KERNEL=="asus::screenpad", RUN+="/bin/chmod a+w /sys/class/leds/%k/brightness"
```

y ahora se puede cambiar el brillo con el siguiente comando:
```bash
echo XXX > '/sys/class/leds/asus::screenpad/brightness'
```
 Con esto y los alias de [[Xubuntu/bashrc]] ahora cambio el brillo con:
- maxb: brillo al máximo
- duo_ X: regular el brillo donde x es un valor de 0 a 255
- minb: apagar monitor

Adicionalmente este driver te permite mapear las teclas especiales de asus, cosa que de momento he usado para implementar el [Screenshooter](xfce#Screenshooter).

## ToggleScreen

También se menciona en los drivers que se puede desarrollar un script para mapear la tecla de apagar el monitor.

Para esto lo único que he hecho ha sido un if-else muy simple en el que si esta encendido mando el comando de poner el brillo a 0 y si esta apagado lo pongo a 255
```bash
#!/bin/bash
if [ ! -n "$(xrandr | grep "DP-1 disconnected")" ]; then
        echo 0 > '/sys/class/leds/asus::screenpad/brightness';
        else echo 255 > '/sys/class/leds/asus::screenpad/brightness';
fi
```

luego estoy lo he asignado a un shortcut de la misma forma que he hecho con [Screenshooter](xfce#Screenshooter) pero en este caso ejecuto el comando
```bash
./.config/toggleScreen.sh
```
y lo he asignado a esa tecla.

## ToggleMouse

Ya que me he puesto he hecho el script para activar y desactivar el ratón, este ha supuesto un nivel un poco mas alto de dificultad ya que haciendolo con xinput hay que tener en cuenta que el id del ratón puede modificarse por lo que primero se debe obtener este para luego poder modificarlo. Este script, de la misma forma que el script de [Screenshooter](xfce#Screenshooter) y el de [Toggle Screen](asus-wmi-screenpad#ToggleScreen) lo he asignado a la tecla Fn+F6, donde esta ejecutara el comando:

```bash
./.config/toggleMouse.sh
```

Lugar donde se encuentra el script:
```bash
#!/bin/bash
ID=$(xinput list | grep -i "Touchpad" | grep -o 'id=[0-9]*' | grep -o '[0-9]*');
if [ "$(xinput list-props $ID | grep "Device Enabled" | awk '{print $4}')" -eq 1 ]; then
        xinput disable $ID;
else
        xinput enable $ID;
fi;

```
- Obtengo la id de el dispositivo "Touchpad" desde xinput y la asigno a ID
- Dentro del if compruebo si esta encendido, de ser así, lo apago, de lo contrario lo enciendo.

## ToggleApp

2024-06-10  00:01

Lo que hace hace este boton en windows es basicamente mover las aplicaciones de una ventana a otra y viceversa.
Cuando he empezado escribir no pensaba que sería tan dificil ya que tiene cirtas funcionalidades que no consigo terminar de hacer como lo hace la aplicacion normal.
De momento he conseguido desarrollar un pequeño script que usa la aplicación [wmctrl](https://linux.die.net/man/1/wmctrl). Hay cosas que aun no me acaban de convencer por lo que seguramente acabe haciendo algunos cambios, pero de momento me vale como esta. El scipt lo tengo guardado en el mismo sitio que [Toggle Screen](asus-wmi-screenpad#ToggleScreen) y que [Toggle Mouse](asus-wmi-screenpad#ToggleMouse). Igual que siempre se ejecuta con:
```bash
./.config/toggleApp.sh
```
y lo tengo mapeado a la tecla especifica que tiene este modelo para hacer esto.

```bash
#!/bin/bash

guardarEstado() {
local WINDOW_STATE=$(xprop -id $ID _NET_WM_STATE)
#0 si esta en ventana, 1 si esta maximizada y 2 si esta en pantalla completa

if echo "$WINDOW_STATE" | grep -q "_NET_WM_STATE_FULLSCREEN"; then
        estado=2
elif echo "$WINDOW_STATE" | grep -q "_NET_WM_STATE_MAXIMIZED_VERT" && echo "$WINDOW_STATE" | grep -q "_NET_WM_STATE_MAXIMIZED_HORZ"; then
        estado=1
else
        estado=0
fi
}
```
Lo primero que tengo hecho es una función donde modifico una variable global que tengo  basicamente para guardar el estado en el que se encuentra la ventana
- 0: modo ventana
- 1: modo maximizado
- 2: pantalla completa
Esta variable la usare luego para volver a dejarlo en el mismo estado que esta antes de hacer nada. basicamente esto lo hago ya que mas tarde voy a poner la aplicacion en modo ventana ya que de otra forma [wmctrl](https://linux.die.net/man/1/wmctrl) no puede modificar la posicion y dimensión de este.

```bash
nventanas=$(wmctrl -l | awk -v ws=$(wmctrl -d | awk '/\*/ {print $1}') '$2 == ws' | wc -l)
```
primero saco un listado de todas las aplicaciónes, luego a estas les quito las aplicaciones que no esten en mi workspace y luego cuento las lineas

```bash
for n in $(seq $nventanas); do
        ventana=$(wmctrl -lG | awk -v ws=$(wmctrl -d | awk '/\*/ {print $1}') '$2 == ws' | head -n $n | tail -n 1)
```
Una vez empezado el for que itera nventanas voy asignando a ventana el output de una aplicación, de este output luego voy a sacar mas variables de este

```bash
        
        ID=$(echo "$ventana" | awk '{print $1}')
        guardarEstado
        posY=$(echo "$ventana" | awk '{print $4}')
        resY=$(echo "$ventana" | awk '{print $6}')
```
Sacamos el ID de la aplicación, llamamos a la función para guardar el estado de la aplicación, sacamos la posición y la dimensión de esta

```bash
        wmctrl -i -r $ID -b remove,fullscreen && wmctrl -i -r $ID -b remove,maximized_vert,maximized_horz
```
Con este comando fuerzo que se ponga en modo ventana para poder cambiar la posición

```bash
        if [ $posY -gt 1079 ]; then #esta en monitor 2
                posY=0
                if [ $resY -eq 488 ]; then resY=1019; fi;

        else #esta en monitor 1
                posY=1080
                if [ $resY -gt 487 ]; then resY=488; fi;
        fi
```
Asignar a las variables posY y resY valores dependiendo de la posición y dimensión que tengan.
Lo que me toca hacer  es arreglar esta parte principalmente, ya que no he conseguido que funcione como yo quiero, e hacer es arreglar esta parts algo muy especifico, y no creo que en ningun momento me supongo mucho problema pero es mas por dejarlo todo bien.

```bash
        wmctrl -i -r $ID -e 0,-1,$posY,-1,$resY

        if [ $estado -eq 1 ]; then
                wmctrl -i -r $ID -b add,maximized_vert,maximized_horz
        elif [ $estado -eq 2 ]; then
                wmctrl -i -r $ID -b add,fullscreen
        fi
done
```
Una vez configurado todo lo ultimo que queda por hacer es poner la aplicación en la nueva posición, y luego usando la variable de estado volver a poner la aplicación en el estado que tenía antes.

## MapPen

Ya que no le encontraba ninguna utilidad a la tecla MyAsus y no he conseguido implementar lo que muestro en [[asus-stylus]] simplemente voy a mapear esta tecla a un script (el mismo que esta en [bashrc](Xubuntu/bashrc.md#Stylus))

```bash
if [ ! -n "$(xrandr | grep "DP-1 disconnected")" ]; then
        if xinput | grep 'Stylus Pen'>/dev/null 2>&1 ; then xinput map-to-output $(xinput | grep 'Stylus Pen' | awk '{print $8}' | cut -d= -f 2) DP-1; fi
        if xinput | grep 'Stylus Eraser'>/dev/null 2>&1 ; then xinput map-to-output $(xinput | grep 'Stylus Eraser' | awk '{print $8}' | cut -d= -f 2) DP-1; fi
fi;
```

este se encuentra en ~/.config/mapPen.sh.

### 17:12 2024-09-05
He tenido que cambiar el nombre de los monitores ya que ahora me reconoce al DP-1 como DP1 y el eDP-1 como eDP1. Todo lo demas sigue igual.