SSLa verdad es que aún no he probado otros entornos de escritorio, pero no creo que me haga falta salirme de momento de xfce 4 ya que cumple con todo lo que quiero.
No tengo mucha cosa cambiado fuera de lo que tengo en [[lightdm]]. De momento lo único que he tocado de xfce en general es principalmente el [[Xubuntu/bashrc]] del xfce-terminal.

# Chicago95

También tengo instalada una capa de personalización llamada Chicago 95, esta principalmente cambia la apariencia del sistema operativo entero para que parezca windows 95 pero con todas las funcionalidades que tenemos ahora. Yo he usado el proyecto Chicagofier ya que lo simplifica todo bastante, la única diferencia entre el original y este es que la instalación es de botón gordo, no te puedes perder. Lo malo es que creo que deja muchos archivos basura.

## Panel

![[Pasted image 20240607191713.png]]

En cuanto a los items que tengo puestos son los siguientes:
- [Whisker](xfce#Whisker)
- [WindowButtons](xfce#WindowButtons)
- Separator (Style: transparent, con expand)
- [Workspace Switcher](xfce#Workspace)
- Separator (Style: transparent, sin expand)
- [Status Tray Plugin](xfce#StatusTray)
- Power Manager Plugin
- Pulse Audio Plugin
- [Clock](xfce#Clock)

### Whisker

![[Pasted image 20240607193005.png]]

Este creo que va pre instalado con xfce pero aun así lo meto en la categoría de Chicago 95 ya que cambia por completo la apariencia que tiene este.
dentro de ~/.themes/Chicago95/gtk-3.24/apps/whiskermenu.css he cambiado lo siguiente:

```css
/*background-image: url("../assets/branding_C95_aliased.png");*/ 
background-image: url("../assets/branding_W95_orig.png"); 
```
 Con esto he cambiado la barra lateral donde ponía Chicago 95 ahora pone Windows 95

Luego si entro por la configuración del panel he tocado algunas cosas de como se ve el menu en si. 

***General***
- Application icon size : Smaller
- Category icon size: Very Small
- Menu width: 416
- Menu height: 383
***Appearance***
- Menu
	- Profile: Hidden
- Panel Button
	- Display : Icon and title
	- Title: Start
***Commands*** //los que tengo marcados
- Settings Manager
-  Shutdown
-  Edit Application
-  Edit Profile

Como se puede ver en la imagen la mayoría de los iconos están cambiados, hay muchos que [Chicago 95](xfce#Chicago95) te cambia por defecto, y supongo que si instalas las aplicaciones antes de aplicar la capa te cambiara las otras aplicaciones, pero como no lo he probado no lo puedo asegurar. Aun así todos los iconos que no ha cambiado [Chicago 95](xfce#Chicago95) los he cambiado yo a mano y siempre he encontrado algún icono que encaja bien con la temática dentro de los iconos que te proporciona este mismo

#### 2024-06-24 22:02
He implementado un shortcut para entrar directamente a la maquina virtual de windows en el menu. Esto lo he hecho metiendome en Settings> MenuEditor y añadiendo un launcher con el comando: ```/usr/lib/virtualbox/VirtualBoxVM --comment "w11" --startvm "{aca82126-48f9-492c-90bd-e3e6fd32cebb}"``` para ejecutar la maquina directamente. a este tambien le he puesto un icono de lo que vienen con [Chicago95](xfce#Chicago95) y queda asi:

![[Pasted image 20240624220832.png]]

### WindowButtons

De aquí no he tocado nada, lo he dejado todo como lo deja [Chicago 95](xfce#Chicago95), aun que quizás aunque quitando el texto de las pestañas ya que te quita o no te deja con poco espacio en la barra de tareas

### Workspace

La configuración que tengo del Workspace switcher es muy básica, tengo 4 workspace colocados en una misma fila, tengo habilitado que pueda cambiar de workspace con la rueda del ratón en el escritorio. Luego tengo puesto 1 emoticon de un circulo de color para cada workspace.

### StatusTray

Aquí he cambiado la forma que tiene por defecto xfce de organizar los iconos, he marcado la casilla Arrange items in a single row. Por lo demás esta todo igual.

### Clock

La configuración del reloj tampoco se puede tocar mucho, lo único que tengo cambiado es
***Appearance***
- Layout: Digital
***Clock Options***
- Layout: Time Only
- Font: More Perfect DOS VGA Regular | 11
- Format: 18:32

## Screenshooter 

Para esta aplicación principalmente quería tener la misma configuración que en windows. 
Control + Shift + s esto abre un menu para seleccionar la parte que quiero de la pantalla y la guarda el el clipboard. Como el portátil tiene una tecla para esto en la posición de la tecla de F11 también he hecho que reaccione igual al pulsar la tecla. Esto lo he hecho gracias al mapeo que implementa [[asus-wmi-screenpad]] por defecto.
Dentro de xfce4-keyboard-settings/Application Shortcuts he metido el siguiente shortcut:
```bash
xfce4-screenshooter -r -c
```
Y lo he asignado al comando Control + Shift + s. 
- -r: seleccionar la region que quiero capturar
- -c: copia al clipboard directamente

## Appfinder

Igual que con Screenshooter quería tener una funcionalidad parecida a la que tiene el mac, en este caso lo he mapeado a las teclas Control + Espacio y el comando que ejecutan es el siguiente: 
```bash
xfce4-appfinder -c
```


