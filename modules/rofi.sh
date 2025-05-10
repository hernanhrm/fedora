#!/bin/bash

# Módulo para la instalación de Rofi en Fedora

# Instalar Rofi
install_rofi() {
  # Obtener el usuario real que ejecutó sudo
  REAL_USER=${SUDO_USER:-$USER}
  REAL_HOME=$(getent passwd "$REAL_USER" | cut -d: -f6)

  if should_install "Rofi" "command -v rofi"; then
    show_header "Instalando Rofi"

    # Instalar Rofi desde los repositorios oficiales de Fedora
    dnf install -y rofi

    # Verificar si la instalación fue exitosa
    if command -v rofi >/dev/null 2>&1; then
      echo -e "${GREEN}Rofi instalado correctamente${NC}"
      
      # Crear directorio de configuración si no existe
      ROFI_CONFIG_DIR="$REAL_HOME/.config/rofi"
      if [ ! -d "$ROFI_CONFIG_DIR" ]; then
        mkdir -p "$ROFI_CONFIG_DIR"
        chown $REAL_USER:$(id -gn $REAL_USER) "$ROFI_CONFIG_DIR"
      fi
      
      # Crear archivo de configuración personalizado
      cat > "$ROFI_CONFIG_DIR/config.rasi" << 'EOF'
configuration {
    modi: "drun,run,window,ssh";
    font: "Ubuntu 12";
    show-icons: true;
    icon-theme: "Papirus";
    display-drun: "Applications";
    display-run: "Commands";
    display-window: "Windows";
    display-ssh: "SSH";
    drun-display-format: "{name}";
    window-format: "{w} · {c} · {t}";
    terminal: "alacritty";
    case-sensitive: false;
    cycle: true;
    sidebar-mode: true;
    matching: "fuzzy";
    sort: true;
    sorting-method: "fzf";
    threads: 0;
    scroll-method: 1;
}

* {
    background-color: #282c34;
    border-color: #3f4552;
    text-color: #efefef;
    spacing: 0;
    width: 700px;
    height: 400px;
    border-radius: 10px;
}

inputbar {
    border: 0 0 1px 0;
    children: [prompt, entry];
    background-color: #1e222a;
    border-radius: 10px 10px 0 0;
}

prompt {
    padding: 16px;
    border: 0 1px 0 0;
    text-color: #61afef;
    background-color: #1e222a;
}

entry {
    padding: 16px;
    background-color: #1e222a;
}

listview {
    cycle: false;
    margin: 0 0 -1px 0;
    scrollbar: true;
    lines: 8;
}

element {
    border: 0 0 1px 0;
    padding: 8px;
}

element selected {
    background-color: #3f4552;
    border-radius: 5px;
}

element-icon {
    size: 24px;
    margin: 0 8px 0 0;
}

element-text {
    background-color: inherit;
    text-color: inherit;
    vertical-align: 0.5;
}

scrollbar {
    width: 4px;
    border: 0;
    handle-width: 8px;
    handle-color: #61afef;
    background-color: #282c34;
}

window {
    background-color: #282c34;
    border: 2px;
    border-color: #61afef;
    border-radius: 10px;
}

mode-switcher {
    border: 1px 0 0 0;
    border-color: #3f4552;
    background-color: #1e222a;
    border-radius: 0 0 10px 10px;
}

button {
    padding: 10px;
    background-color: #1e222a;
    text-color: #efefef;
}

button selected {
    background-color: #3f4552;
    text-color: #61afef;
}
EOF
      
      # Establecer permisos correctos
      chown -R $REAL_USER:$(id -gn $REAL_USER) "$ROFI_CONFIG_DIR"
      
      # Mostrar información de uso
      echo -e "${BLUE}Para usar Rofi:${NC}"
      echo -e "- Comando básico: rofi -show drun"
      echo -e "- Con múltiples modos: rofi -show combi -modi combi,drun,window,run"
      echo -e "- Cambiador de ventanas: rofi -show window"
      
      # Sugerir configuración de accesos directos
      echo -e "${YELLOW}Sugerencia: Configura un atajo de teclado para Rofi en la configuración de tu entorno de escritorio${NC}"
      echo -e "- Comando recomendado: rofi -show combi -modi combi,drun,window,run"
      echo -e "- Atajo recomendado: Super+Space o Alt+F2"
    else
      echo -e "${RED}La instalación de Rofi falló${NC}"
    fi
  else
    echo -e "${GREEN}Rofi ya está instalado. Omitiendo instalación${NC}"
  fi
}