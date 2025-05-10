
#!/bin/bash

# Módulo para la instalación de Hyprland en Fedora

# Instalar Hyprland
install_hyprland() {
  # Obtener el usuario real que ejecutó sudo
  REAL_USER=${SUDO_USER:-$USER}
  REAL_HOME=$(getent passwd "$REAL_USER" | cut -d: -f6)

  if should_install "Hyprland" "test -d $REAL_HOME/.config/hypr || command -v Hyprland"; then
    show_header "Instalando Hyprland"

    # Instalar dependencias necesarias
    dnf install -y meson cmake gcc-c++ libxcb-devel libX11-devel pixman-devel \
      wayland-devel wayland-protocols-devel mesa-libEGL-devel mesa-libGLES-devel \
      libdrm-devel libxkbcommon-devel systemd-devel hwdata-devel libdisplay-info-devel \
      libudev-devel libinput-devel libevdev-devel cairo-devel pango-devel \
      libseat-devel json-c-devel wlroots-devel xorg-x11-server-Xwayland-devel \
      xdg-desktop-portal-devel mesa-dri-drivers

    # Instalar Hyprland desde los repositorios de Fedora
    dnf install -y hyprland

    # Instalar complementos útiles para Hyprland
    dnf install -y \
      waybar \
      dunst \
      kitty \
      polkit-gnome \
      xdg-desktop-portal-wlr \
      grim \
      slurp \
      wl-clipboard \
      brightnessctl \
      NetworkManager-tui \
      blueman \
      pipewire \
      wireplumber

    # Verificar si la instalación fue exitosa
    if command -v Hyprland >/dev/null 2>&1; then
      echo -e "${GREEN}Hyprland instalado correctamente${NC}"

      # Crear directorios de configuración
      HYPR_CONFIG_DIR="$REAL_HOME/.config/hypr"
      if [ ! -d "$HYPR_CONFIG_DIR" ]; then
        mkdir -p "$HYPR_CONFIG_DIR"
        chown $REAL_USER:$(id -gn $REAL_USER) "$HYPR_CONFIG_DIR"
      fi

      # Crear archivo de configuración básico para Hyprland
      cat > "$HYPR_CONFIG_DIR/hyprland.conf" << 'EOF'
# Configuración básica de Hyprland

# Monitores
monitor=,preferred,auto,1

# Autostart
exec-once = waybar
exec-once = dunst
exec-once = /usr/libexec/polkit-gnome-authentication-agent-1
exec-once = hyprpaper
exec-once = wl-paste --type text --watch cliphist store
exec-once = wl-paste --type image --watch cliphist store

# Configuración de entrada
input {
    kb_layout = us
    kb_variant =
    kb_model =
    kb_options =
    kb_rules =

    follow_mouse = 1

    touchpad {
        natural_scroll = true
    }

    sensitivity = 0
}

# Apariencia general
general {
    gaps_in = 5
    gaps_out = 10
    border_size = 2
    col.active_border = rgba(61afefee)
    col.inactive_border = rgba(595959aa)

    layout = dwindle
}

# Decoración de ventanas
decoration {
    rounding = 10
    blur = yes
    blur_size = 3
    blur_passes = 1
    blur_new_optimizations = on

    drop_shadow = yes
    shadow_range = 4
    shadow_render_power = 3
    col.shadow = rgba(1a1a1aee)
}

# Animaciones
animations {
    enabled = yes

    bezier = myBezier, 0.05, 0.9, 0.1, 1.05

    animation = windows, 1, 7, myBezier
    animation = windowsOut, 1, 7, default, popin 80%
    animation = border, 1, 10, default
    animation = fade, 1, 7, default
    animation = workspaces, 1, 6, default
}

# Comportamiento de ventanas
dwindle {
    pseudotile = yes
    preserve_split = yes
}

master {
    new_is_master = true
}

# Gestos
gestures {
    workspace_swipe = on
}

# Reglas de ventanas
windowrule = float, ^(pavucontrol)$
windowrule = float, ^(nm-connection-editor)$
windowrule = float, ^(blueman-manager)$

# Accesos directos
$mainMod = SUPER

# Aplicaciones
bind = $mainMod, RETURN, exec, kitty
bind = $mainMod, Q, killactive,
bind = $mainMod, M, exit,
bind = $mainMod, E, exec, dolphin
bind = $mainMod, V, togglefloating,
bind = $mainMod, R, exec, rofi -show combi -modi combi,drun,window,run
bind = $mainMod, P, pseudo, # dwindle
bind = $mainMod, J, togglesplit, # dwindle

# Capturas de pantalla
bind = $mainMod, S, exec, grim -g "$(slurp)" - | wl-copy
bind = $mainMod SHIFT, S, exec, grim -g "$(slurp)" ~/Pictures/Screenshots/screenshot-$(date +%F_%T).png

# Navegación
bind = $mainMod, left, movefocus, l
bind = $mainMod, right, movefocus, r
bind = $mainMod, up, movefocus, u
bind = $mainMod, down, movefocus, d

# Workspaces
bind = $mainMod, 1, workspace, 1
bind = $mainMod, 2, workspace, 2
bind = $mainMod, 3, workspace, 3
bind = $mainMod, 4, workspace, 4
bind = $mainMod, 5, workspace, 5
bind = $mainMod, 6, workspace, 6
bind = $mainMod, 7, workspace, 7
bind = $mainMod, 8, workspace, 8
bind = $mainMod, 9, workspace, 9
bind = $mainMod, 0, workspace, 10

# Mover ventanas entre workspaces
bind = $mainMod SHIFT, 1, movetoworkspace, 1
bind = $mainMod SHIFT, 2, movetoworkspace, 2
bind = $mainMod SHIFT, 3, movetoworkspace, 3
bind = $mainMod SHIFT, 4, movetoworkspace, 4
bind = $mainMod SHIFT, 5, movetoworkspace, 5
bind = $mainMod SHIFT, 6, movetoworkspace, 6
bind = $mainMod SHIFT, 7, movetoworkspace, 7
bind = $mainMod SHIFT, 8, movetoworkspace, 8
bind = $mainMod SHIFT, 9, movetoworkspace, 9
bind = $mainMod SHIFT, 0, movetoworkspace, 10

# Control de volumen
bind = , XF86AudioRaiseVolume, exec, pactl set-sink-volume @DEFAULT_SINK@ +5%
bind = , XF86AudioLowerVolume, exec, pactl set-sink-volume @DEFAULT_SINK@ -5%
bind = , XF86AudioMute, exec, pactl set-sink-mute @DEFAULT_SINK@ toggle

# Control de brillo
bind = , XF86MonBrightnessUp, exec, brightnessctl set +10%
bind = , XF86MonBrightnessDown, exec, brightnessctl set 10%-

# Scroll entre workspaces
bind = $mainMod, mouse_down, workspace, e+1
bind = $mainMod, mouse_up, workspace, e-1

# Mover/redimensionar ventanas con el ratón
bindm = $mainMod, mouse:272, movewindow
bindm = $mainMod, mouse:273, resizewindow
EOF

      # Configurar archivo de autoinicio
      mkdir -p "$REAL_HOME/.config/autostart"
      cat > "$REAL_HOME/.config/autostart/hyprland-session.desktop" << 'EOF'
[Desktop Entry]
Type=Application
Name=Hyprland Session
Comment=Start Hyprland compositor
Exec=Hyprland
Terminal=false
Categories=Utility;
EOF

      # Crear directorio para capturas de pantalla
      mkdir -p "$REAL_HOME/Pictures/Screenshots"

      # Establecer permisos correctos
      chown -R $REAL_USER:$(id -gn $REAL_USER) "$HYPR_CONFIG_DIR"
      chown -R $REAL_USER:$(id -gn $REAL_USER) "$REAL_HOME/.config/autostart"
      chown -R $REAL_USER:$(id -gn $REAL_USER) "$REAL_HOME/Pictures/Screenshots"

      # Información de uso
      echo -e "${BLUE}Hyprland ha sido configurado con Rofi. Para utilizarlo:${NC}"
      echo -e "- Cierra sesión y selecciona 'Hyprland' en la pantalla de inicio de sesión"
      echo -e "- Utiliza Super+R para abrir Rofi (rofi -show combi -modi combi,drun,window,run)"
      echo -e "- Usa Super+Enter para abrir la terminal Kitty"
      echo -e "- Usa Super+Q para cerrar la ventana activa"
    else
      echo -e "${RED}La instalación de Hyprland falló${NC}"
    fi
  else
    echo -e "${GREEN}Hyprland ya está instalado. Omitiendo instalación${NC}"
  fi
}
