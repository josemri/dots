La configuración de este dispositivo ha empezado por el problema evidente de, que como pasa con la pantalla secundaria, la parte tactil mapea los dos monitores por lo que basicamente lo hace muy poco practico, por eso lo que he ido haciendo ha sido ir cambiando la configuración de este poco a poco hasta llegar al punto en el que estoy, donde funciona exactamente igual que si lo usaras en windows.

## Primera aproximación

La primara idea que tube para solucionar este problema puede ser algo ortopedica, ya que implicaba tener que reiniciar el [[Xubuntu/bashrc]] cada vez que quisiera utilizar el boligrafo, aun que sea una chorrada que se puede soportar, la idea es dejarlo todo con la misma funcionalidad que tiene en windows o incluso, mejorarla.

El codigo sigue estando disponible para consultar en [bashrc](Xubuntu/bashrc.md#Stylus)

## Segunda aproximación

#error

Ahora mismo la idea es no tener que hacer nada, para eso, con ayuda de chat gpt, he creado una regla udev, que basicamente lo que hace es que al detectar un evento ejecuta el codigo que tu quieras, en este caso el script que tengo en ~/.config/mapPen.sh

```bash
#!/bin/bash

# Nombres de los dispositivos
DEVICE_NAMES=("ELAN9009:00 04F3:2C58 Stylus Pen (0)" "ELAN9009:00 04F3:2C58 Stylus Eraser (0)")

for DEVICE_NAME in "${DEVICE_NAMES[@]}"; do
    # Obtén el ID del dispositivo
    DEVICE_ID=$(xinput list --id-only "$DEVICE_NAME")

    # Verifica que se haya encontrado el ID
    if [ -n "$DEVICE_ID" ]; then
        # Configura el dispositivo para que se asigne solo al segundo monitor
        xinput map-to-output "$DEVICE_ID" "DP-1"
    fi
done
```
A este codigo le he dado permisos de ejecución:
```bash
chmod +x ~/.config/mapPen.sh
```

Luego he creado un archivo dentro de /etc/udev/rules.d
```bash
sudo nano /etc/udev/rules.d/99-boligrafo.rules
```

al que le he metido el siguiente contendio:
```bash
ACTION=="add", SUBSYSTEM=="input", ATTRS{name}=="ELAN9009:00 04F3:2C58 Stylus Pen (0)", RUN+="/home/josep/.config/mapPen.sh"
ACTION=="add", SUBSYSTEM=="input", ATTRS{name}=="ELAN9009:00 04F3:2C58 Stylus Eraser (0)", RUN+="/home/josep/.config/mapPen.sh"
```

Esto lo he hecho asi ya que el portatil detecta el stylus como dos dispositivos, donde uno es el boligrafo en si y el otro el 'eraser', basicamente el boton que tiene para activar la goma.

Por ultimo, para aplicar esto se debe o bien reiniciar el portatil o ejecutar los dos siguientes comandos:
```bash
sudo udevadm control --reload-rules
sudo udevadm trigger
```
yo recomiendo reiniciar, ya que asi desvinculas el stylus y puedes probar que todo funcione como debería.

## Tercera Aproximación

Como de momento no consigo hacer funcionar la segunda aproximación lo que podría hacer es intentar vincular el script al boton MyAsus, ya que dudo que lo vaya a usar para nada, aun asi la idea con el tiempo es poder arreglar esto. Mi intención es crear un especie de trigger que busque en el output de xinput list si se ha conectado el stylus, en caso que sea asi que ejecute mi script. He usado el mismo script que tengo en [[Xubuntu/bashrc]] con la diferencia que le he quitado el mapeo de la segunda pantalla, lo he asignado con xfce4-keyboard-settings, tengo mas ejemplos de mapeos en [Toggle Screen](asus-wmi-screenpad#ToggleScreen) o [ToggleMouse](asus-wmi-screenpad#ToggleMouse). 
Como he usado las teclas especiales que habilita [[asus-wmi-screenpad]] el codigo de como lo he hecho se va a quedar ahi.

## [asus-wmi-screenpad](asus-wmi-screenpad#MapPen)
