#!/bin/bash

# Módulo para la instalación de Flameshot en Fedora

# Instalar Flameshot
install_flameshot() {
  # Obtener el usuario real que ejecutó sudo
  REAL_USER=${SUDO_USER:-$USER}
  REAL_HOME=$(getent passwd "$REAL_USER" | cut -d: -f6)

  if should_install "Flameshot" "command -v flameshot"; then
    show_header "Instalando Flameshot"

    # Instalar Flameshot desde los repositorios oficiales de Fedora
    dnf install -y flameshot

    # Verificar si la instalación fue exitosa
    if command -v flameshot >/dev/null 2>&1; then
      echo -e "${GREEN}Flameshot instalado correctamente${NC}"
      
      # Mostrar información de uso
      echo -e "${BLUE}Para usar Flameshot:${NC}"
      echo -e "- Ejecuta 'flameshot gui' para capturar pantalla"
      echo -e "- Presiona PrtSc si está configurado como atajo"
      
      # Configurar para autoarranque (opcional)
      if [ -n "$SUDO_USER" ]; then
        # Crear directorio de autoarranque si no existe
        AUTOSTART_DIR="$REAL_HOME/.config/autostart"
        if [ ! -d "$AUTOSTART_DIR" ]; then
          mkdir -p "$AUTOSTART_DIR"
          chown $REAL_USER:$(id -gn $REAL_USER) "$AUTOSTART_DIR"
        fi
        
        # Preguntar si desea configurar Flameshot para iniciar con el sistema
        echo -e "${YELLOW}¿Deseas que Flameshot se inicie automáticamente con el sistema? (s/n)${NC}"
        read -r AUTO_START
        if [[ "$AUTO_START" =~ ^[Ss]$ ]]; then
          # Usar el archivo .desktop del sistema como plantilla
          if [ -f "/usr/share/applications/org.flameshot.Flameshot.desktop" ]; then
            cp "/usr/share/applications/org.flameshot.Flameshot.desktop" "$AUTOSTART_DIR/"
            echo -e "${GREEN}Flameshot configurado para iniciar automáticamente${NC}"
            chown $REAL_USER:$(id -gn $REAL_USER) "$AUTOSTART_DIR/org.flameshot.Flameshot.desktop"
          else
            # Crear archivo de autoarranque manualmente si no existe la plantilla
            cat > "$AUTOSTART_DIR/flameshot.desktop" << EOF
[Desktop Entry]
Name=Flameshot
Icon=flameshot
Exec=flameshot
Terminal=false
Type=Application
X-GNOME-Autostart-enabled=true
Hidden=false
EOF
            chown $REAL_USER:$(id -gn $REAL_USER) "$AUTOSTART_DIR/flameshot.desktop"
            echo -e "${GREEN}Flameshot configurado para iniciar automáticamente${NC}"
          fi
        else
          echo -e "${BLUE}Flameshot no se iniciará automáticamente con el sistema${NC}"
        fi
      fi
    else
      echo -e "${RED}La instalación de Flameshot falló${NC}"
    fi
  else
    echo -e "${GREEN}Flameshot ya está instalado. Omitiendo instalación${NC}"
  fi
}