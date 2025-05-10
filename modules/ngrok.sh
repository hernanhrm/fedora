#!/bin/bash

# Módulo para la instalación de ngrok

# Instalar ngrok
install_ngrok() {
  # Obtener el usuario real que ejecutó sudo
  REAL_USER=${SUDO_USER:-$USER}
  REAL_HOME=$(getent passwd "$REAL_USER" | cut -d: -f6)

  if should_install "ngrok" "command -v ngrok"; then
    show_header "Instalando ngrok"

    # Instalar dependencias necesarias
    dnf install -y curl unzip

    # Crear directorio para binarios si no existe
    NGROK_DIR="$REAL_HOME/.local/bin"
    if [ ! -d "$NGROK_DIR" ]; then
      if [ -n "$SUDO_USER" ]; then
        su - $REAL_USER -c "mkdir -p $NGROK_DIR"
      else
        mkdir -p "$NGROK_DIR"
      fi
    fi

    # Determinar la arquitectura del sistema
    ARCH=$(uname -m)
    if [ "$ARCH" == "x86_64" ]; then
      NGROK_ARCH="amd64"
    elif [ "$ARCH" == "aarch64" ] || [ "$ARCH" == "arm64" ]; then
      NGROK_ARCH="arm64"
    else
      echo -e "${RED}Arquitectura $ARCH no soportada por ngrok${NC}"
      return 1
    fi

    # URL de descarga para la última versión de ngrok
    NGROK_URL="https://bin.equinox.io/c/bNyj1mQVY4c/ngrok-v3-stable-linux-${NGROK_ARCH}.zip"
    
    # Descargar ngrok
    echo -e "${BLUE}Descargando ngrok...${NC}"
    curl -L "$NGROK_URL" -o "/tmp/ngrok.zip"
    
    if [ $? -eq 0 ]; then
      echo -e "${GREEN}Descarga completada. Descomprimiendo...${NC}"
      
      # Extraer ngrok
      unzip -o "/tmp/ngrok.zip" -d "/tmp"
      
      # Instalar ngrok en el directorio correcto
      if [ -n "$SUDO_USER" ]; then
        cp "/tmp/ngrok" "$NGROK_DIR/"
        chmod +x "$NGROK_DIR/ngrok"
        chown $REAL_USER:$(id -gn $REAL_USER) "$NGROK_DIR/ngrok"
      else
        cp "/tmp/ngrok" "$NGROK_DIR/"
        chmod +x "$NGROK_DIR/ngrok"
      fi
      
      # Limpiar archivos temporales
      rm -f "/tmp/ngrok" "/tmp/ngrok.zip"
      
      # Verificar la instalación
      if [ -x "$NGROK_DIR/ngrok" ]; then
        echo -e "${GREEN}ngrok instalado correctamente en $NGROK_DIR/ngrok${NC}"
        
        # Asegurarse de que el directorio esté en el PATH
        if [ -n "$SUDO_USER" ]; then
          if ! grep -q "$NGROK_DIR" "$REAL_HOME/.zshrc" 2>/dev/null && ! grep -q "$NGROK_DIR" "$REAL_HOME/.bashrc" 2>/dev/null; then
            echo -e "${BLUE}Añadiendo $NGROK_DIR al PATH en los archivos de perfil${NC}"
            echo -e "\n# Añadir directorio de binarios locales al PATH\nexport PATH=\"$NGROK_DIR:\$PATH\"" >> "$REAL_HOME/.zshrc"
            chown $REAL_USER:$(id -gn $REAL_USER) "$REAL_HOME/.zshrc"
          fi
        elif ! grep -q "$NGROK_DIR" "$HOME/.zshrc" 2>/dev/null && ! grep -q "$NGROK_DIR" "$HOME/.bashrc" 2>/dev/null; then
          echo -e "\n# Añadir directorio de binarios locales al PATH\nexport PATH=\"$NGROK_DIR:\$PATH\"" >> "$HOME/.zshrc"
        fi
        
        # Agregar el directorio al PATH para la sesión actual
        export PATH="$NGROK_DIR:$PATH"
        
        # Instrucciones para configurar ngrok
        echo -e "${YELLOW}Para configurar ngrok, necesitas una cuenta y un token de autenticación.${NC}"
        echo -e "${YELLOW}Regístrate en https://ngrok.com/ y obtén tu token de autenticación.${NC}"
        echo -e "${YELLOW}Después, ejecuta: ngrok config add-authtoken <TU_TOKEN>${NC}"
      else
        echo -e "${RED}Error al instalar ngrok${NC}"
      fi
    else
      echo -e "${RED}Error descargando ngrok${NC}"
    fi
  else
    echo -e "${GREEN}ngrok ya está instalado. Omitiendo instalación${NC}"
  fi
}