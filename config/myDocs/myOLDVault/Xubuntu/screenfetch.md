En cuanto a esta aplicación tampoco se le puede meter mucha configuración adicional, aun que me gustaría trabajar en una version hecha por mi que arregle todo lo que no me gusta de esta, por ejemplo: Quiero poner el ASCII art de windows, pero los colores del texto quiero que sean morados. El caso es que aun no he conseguido encontrar el comando o no existe para configuraciones mas concretas que me gustaría tener. De momento lo único que tengo configurado es que cada vez que se abre la terminal se ejecuta screenfetch de la forma que tengo puesta aquí [[Xubuntu/bashrc]].
```bash
screenfetch -A 'Windows'
```

## Proyecto

En cuanto a la idea que tengo yo, va a ser mucho mas simple. De momento solo tengo estos 4 comando que te dan el usuario, el sistema operativo, el kernel y el tiempo que lleva encendido.
```bash
echo $(whoami)@$(uname -n)
echo 'OS: ' $(grep -E '^(VERSION|NAME)=' /etc/os-release | cut -d '=' -f 2 | tr -d "\"\n")
echo 'kernel: ' $(uname -m) $(uname -s) $(uname -r)
echo 'Uptime: ' $(uptime -p | cut -d ' ' -f2,3)
```

Me gustaría intentar añadir los cuadrados de colores que muestra neofetch pero aun no me he puesto a ver como hacer eso.