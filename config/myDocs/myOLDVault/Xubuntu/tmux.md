La configuración que tengo hecha de tmux (, como con la configuración de [[starship]] la verdad que es principalmente copiado todo o casi todo de internet.
La idea de mi config es que se note lo mínimo posible que estoy usando tmux, ya que la apariencia básica de bash me gusta bastante y la barra inferior de tmux no.

```tmux
set-option -g prefix C-j
set-option -g prefix2 C-f
```

Primero he cambiado el comando para interactuar con tmux a Control + f o Control + j, aun que este ultimo no lo utilizo nunca. A este comando a partir de ahora le llamare teclas de control, ya que prácticamente le tienes que dar siempre que quieras interactuar con la aplicación.

```tmux
bind-key r source-file ~/.tmux.conf \; display-message "tmux.conf reload."
```
Aquí he configurado que una vez le das a las teclas de control + r reinicie tmux para implementar algún cambio que le haya hecho a la configuración de este. 

```tmux
set -g mouse on
```

Habilitar el ratón, muy util para cambiar de pestaña o cambiar el tamaño de una ya que supongo que hay un montón de shortcuts para esto, pero no me lo se.

```tmux
bind-key v split-window -h
bind-key h split-window -v
```
Cambiar el comando para dividir la pantalla, ya que el de por defecto es comicamente enrevesado, igual que el de copiar y pegar, pero bueno. Esos no los he cambiado aun por pereza y porque no se como unificar todos los clipboard del sistema, ya que dentro de [bash](Xubuntu/bashrc.md) hay uno, dentro de tmux hay otro con [[xfce]] te viene otro.
- con teclas de Control + h se divide la pantalla horizontalmente
- con teclas de Control + v se divide verticalmente

```tmux
set-option -g status
```
Como ya he dicho antes, no me gusta nada com queda la barra de tmux (status bar), por eso la tengo siempre deshabilitada.

```tmux
set -s set-clipboard on
set -s set-clipboard external
set -s set-clipboard off
```
Intento fallido de unificar todos los clipboard, pero buen, se va a seguir intentando.
```tmux
bind -T copy-mode-vi Enter send-keys -X copy-pipe-and-cancel "xclip -i -f -selection primary | xclip -i -selection clipboard"
bind -T copy-mode-vi MouseDragEnd1Pane send-keys -X copy-pipe-and-cancel "xclip -i -f -selection primary | xclip -i -selection clipboard"
bind -T copy-mode-vi C-j send-keys -X copy-pipe-and-cancel "xclip -i -f -selection primary | xclip -i -selection clipboard"

```
Otro intento fallido de unificar los clipboard, aun así lo que uso ahora mismo es seleccionar el texto que quiero copiar con el ratón + shift, y luego Control + Alt + c.