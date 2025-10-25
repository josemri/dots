Como se muestra en [[Debian/bashrc|bashrc]] se puede ver que no hay muchos cambios a la config default de neofetch, lo unico que le he hecho ha sido meter la ip publica y la privada, y quitar la gpu ya que aun no he conseguido que no me de error al ejecutar cualquier comando relacionado con la obtencion de datos de esta.
Aqui recopilo toda la config de neofetch por lo que tengo que hacer mencion a las dos cositas que tengo puestas en [[Debian/bashrc|bashrc]] siendo: 
``` bash
alias info='clear && neofetch --disable gpu icons theme uptime --ascii_distro Debian --ascii_bold on'
```
para ejecutar neofetch limpiando la pantalla y

```bash
if [ ! -f /tmp/.neofetch_done ]; then
    maxb && clear && neofetch --disable gpu icons theme uptime --ascii_distro Debian --ascii_bold on
    touch /tmp/.neofetch_done
fi
```
para ejecutar neofetch la primera vez que se abre la terminal.

Por otro lado tengo creado un archivo de config en ~/.config/neofetch/config.conf, este tiene el siguiente contenido:

``` bash
print_info() {
    info title
    info "Uptime" uptime
    info "Local IP" local_ip
    prin "Public IP" "$(curl -4 -s ifconfig.me)"
    info "Battery" battery
    info "OS" distro
    info "Host" model
    info "Kernel" kernel
    info "Shell" shell
    info "Resolution" resolution
    info "Terminal Font" term_font
    info "CPU" cpu
    info "Memory" memory
    info "Disk" disk
    info cols
}
```

lo unico que tengo definido yo, a parte de el orden diferente al predeterminado es la ip publica ya que no la puedo definir de otra forma mas que haciendo esa llamada.