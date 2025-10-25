La configuración de starship (~/.config/starship.toml) es simple y copiada prácticamente toda de internet, com la configuración de [[tmux]]. En general no hay ningún comando demasiado complejo, la verdad que los que han hecho el lenguaje de configuración de starship lo han dejado lo mas claro que pueden con muchísimas posibles configuraciones.

```starship
format = '$battery$directory$character'
```
Lo primero de todo es darle formato, este es simplemente un indicador del porcentaje de batería, la carpeta en la que me encuentro y el carácter > con diferentes colores.

``` starship
add_newline = true
```
Entre prompt y respuesta inserta un espacio en blanco.

```
[character]
success_symbol = '[>](bold purple)'
error_symbol = '[>](bold red)'
```
Aquí se modifica como se va a ver el $character que sale en el format, simplemente se le cambia el color a morado de normal, y si starship detecta algún error en el prompt anterior cambia el color a rojo

```
[directory]
style = "bold white"
read_only = " 🔒"
```
Cambiar el color de los directorios a blanco y ponerlo en negrita y en caso de ser una carpeta con permisos solo de lectura se pone el emoticon del candado después del nombre del directorio.

```starship 
[battery]
format = '[$percentage]($style) '
[[battery.display]]
threshold = 15
style = 'white'
```
Aquí lo tengo puesto para que solo aparezca el porcentaje de la batería cuando es inferior al 15%, también le he quitado el emoticon que viene predefinido. Prefiero ver solo el porcentaje.