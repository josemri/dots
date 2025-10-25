De momento he intenado algunas cosas como apagar el segundo monitor cuando estoy iniciando el sistema. Lo que si tengo puesto ahora es que sale la pantalla de login, ya que como tengo el SSD cifrado me da un poco igual tener que introducir otra contraseña antes de poder entrar, con la que de momento lo he quitado.

En el archivo /etc/lightdm/lightdm.conf solo tengo la siguiente configuración
```lightdm
[Seat:*]
#display-setup-script=/bin/bash -c "echo 0 > /sys/class/leds/asus::screenpad/brightness"
autologin-user=josep
```
La primera linea la tengo comentada ya que simplemente apaga el segundo monitor usando [[asus-wmi-screenpad]] y la segunda linea es bastante intuitiva. A parte de esto he tenido que entrar a la configuración de Usuario y he puesto que no se pida cuando inicio el ordenador.