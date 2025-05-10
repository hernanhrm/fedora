#!/bin/bash

# Módulo para la instalación de Alacritty en Fedora

# Instalar Alacritty
install_alacritty() {
  # Obtener el usuario real que ejecutó sudo
  REAL_USER=${SUDO_USER:-$USER}
  REAL_HOME=$(getent passwd "$REAL_USER" | cut -d: -f6)

  if should_install "Alacritty" "command -v alacritty"; then
    show_header "Instalando Alacritty"

    # Instalar Alacritty desde los repositorios oficiales de Fedora
    dnf install -y alacritty

    # Verificar si la instalación fue exitosa
    if command -v alacritty >/dev/null 2>&1; then
      echo -e "${GREEN}Alacritty instalado correctamente${NC}"
      
      # Mostrar información de uso
      echo -e "${BLUE}Para usar Alacritty:${NC}"
      echo -e "- Ejecuta 'alacritty' desde la terminal o menú de aplicaciones"
      
      # Crear directorio de configuración si no existe
      CONFIG_DIR="$REAL_HOME/.config/alacritty"
      if [ ! -d "$CONFIG_DIR" ]; then
        mkdir -p "$CONFIG_DIR"
        chown $REAL_USER:$(id -gn $REAL_USER) "$CONFIG_DIR"
        echo -e "${BLUE}Directorio de configuración creado: $CONFIG_DIR${NC}"
      fi
      
      # Preguntar si desea crear un archivo de configuración básico
      echo -e "${YELLOW}¿Deseas crear un archivo de configuración básico para Alacritty? (s/n)${NC}"
      read -r CREATE_CONFIG
      if [[ "$CREATE_CONFIG" =~ ^[Ss]$ ]]; then
        # Crear archivo de configuración básico
        CONFIG_FILE="$CONFIG_DIR/alacritty.yml"
        cat > "$CONFIG_FILE" << EOF
# Configuración básica para Alacritty
window:
  dimensions:
    columns: 110
    lines: 30
  padding:
    x: 10
    y: 10
  dynamic_padding: true
  decorations: full
  opacity: 0.95

scrolling:
  history: 10000
  multiplier: 3

font:
  normal:
    family: monospace
    style: Regular
  bold:
    style: Bold
  italic:
    style: Italic
  size: 11.0
  offset:
    x: 0
    y: 0
  glyph_offset:
    x: 0
    y: 0

colors:
  primary:
    background: '#282c34'
    foreground: '#abb2bf'
  cursor:
    text: '#000000'
    cursor: '#ffffff'
  normal:
    black:   '#282c34'
    red:     '#e06c75'
    green:   '#98c379'
    yellow:  '#e5c07b'
    blue:    '#61afef'
    magenta: '#c678dd'
    cyan:    '#56b6c2'
    white:   '#abb2bf'
  bright:
    black:   '#5c6370'
    red:     '#e06c75'
    green:   '#98c379'
    yellow:  '#e5c07b'
    blue:    '#61afef'
    magenta: '#c678dd'
    cyan:    '#56b6c2'
    white:   '#ffffff'

key_bindings:
  - { key: V,        mods: Control,       action: Paste                }
  - { key: C,        mods: Control,       action: Copy                 }
  - { key: Insert,   mods: Shift,         action: PasteSelection       }
  - { key: Equals,   mods: Control,       action: IncreaseFontSize     }
  - { key: Minus,    mods: Control,       action: DecreaseFontSize     }
  - { key: Key0,     mods: Control,       action: ResetFontSize        }
EOF
        chown $REAL_USER:$(id -gn $REAL_USER) "$CONFIG_FILE"
        echo -e "${GREEN}Archivo de configuración creado en $CONFIG_FILE${NC}"
        echo -e "${BLUE}Puedes personalizar este archivo según tus preferencias${NC}"
      else
        echo -e "${BLUE}No se creó un archivo de configuración${NC}"
        echo -e "${BLUE}Puedes crear uno más tarde en $CONFIG_DIR/alacritty.yml${NC}"
      fi
      
      # Configurar como terminal predeterminada (opcional)
      echo -e "${YELLOW}¿Deseas configurar Alacritty como tu terminal predeterminada? (s/n)${NC}"
      read -r DEFAULT_TERMINAL
      if [[ "$DEFAULT_TERMINAL" =~ ^[Ss]$ ]]; then
        # Usar update-alternatives para configurar la terminal predeterminada
        update-alternatives --set x-terminal-emulator /usr/bin/alacritty 2>/dev/null || true
        
        # Para entornos de escritorio basados en XDG, configurar el archivo mimeapps.list
        MIME_DIR="$REAL_HOME/.config"
        MIME_FILE="$MIME_DIR/mimeapps.list"
        
        # Asegurarse de que el directorio existe
        if [ ! -d "$MIME_DIR" ]; then
          mkdir -p "$MIME_DIR"
          chown $REAL_USER:$(id -gn $REAL_USER) "$MIME_DIR"
        fi
        
        # Crear o actualizar el archivo mimeapps.list
        if [ ! -f "$MIME_FILE" ]; then
          touch "$MIME_FILE"
          chown $REAL_USER:$(id -gn $REAL_USER) "$MIME_FILE"
        fi
        
        # Añadir la entrada para la terminal predeterminada
        if ! grep -q "x-scheme-handler/terminal=alacritty.desktop" "$MIME_FILE"; then
          echo "[Default Applications]" >> "$MIME_FILE"
          echo "x-scheme-handler/terminal=alacritty.desktop" >> "$MIME_FILE"
          chown $REAL_USER:$(id -gn $REAL_USER) "$MIME_FILE"
        fi
        
        echo -e "${GREEN}Alacritty configurado como terminal predeterminada${NC}"
      else
        echo -e "${BLUE}Alacritty no se configuró como terminal predeterminada${NC}"
      fi
      
    else
      echo -e "${RED}La instalación de Alacritty falló${NC}"
    fi
  else
    echo -e "${GREEN}Alacritty ya está instalado. Omitiendo instalación${NC}"
  fi
}