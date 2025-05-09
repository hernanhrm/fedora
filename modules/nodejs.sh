#!/bin/bash

# Módulo para la instalación de Node.js y pnpm

# Instalar Node.js
install_nodejs() {
  # Obtener el usuario real que ejecutó sudo
  REAL_USER=${SUDO_USER:-$USER}
  REAL_HOME=$(getent passwd "$REAL_USER" | cut -d: -f6)

  if should_install "Node.js" "command -v node"; then
    show_header "Instalando Node.js LTS (v22.15.0)"

    # Instalar dependencias necesarias
    dnf install -y xz

    # Descargar Node.js
    wget https://nodejs.org/dist/v22.15.0/node-v22.15.0-linux-x64.tar.xz

    # Eliminar instalaciones previas de Node.js si existen y estamos en modo forzado
    if [ -d "/usr/local/node" ] && [ "$FORCE" = true ]; then
      echo -e "${YELLOW}Eliminando instalación anterior de Node.js...${NC}"
      rm -rf /usr/local/node
    fi

    # Crear directorio para Node.js
    mkdir -p /usr/local/node

    # Extraer Node.js en /usr/local/node
    tar -xf node-v22.15.0-linux-x64.tar.xz -C /usr/local/node --strip-components=1

    # Eliminar el archivo descargado
    rm node-v22.15.0-linux-x64.tar.xz

    # Configurar variables de entorno para Node.js
    show_header "Configurando variables de entorno para Node.js"

    # Variables a configurar
    NODE_ENV_CONTENT=$(cat << 'EOF'
#!/bin/bash
export PATH=$PATH:/usr/local/node/bin
EOF
)

    # Intentar crear el archivo de perfil
    echo "$NODE_ENV_CONTENT" > "/tmp/node_env.sh"

    # Intentar mover el archivo al directorio correcto
    if sudo mv "/tmp/node_env.sh" "/etc/profile.d/nodejs.sh" && sudo chmod +x "/etc/profile.d/nodejs.sh"; then
      echo -e "${GREEN}Variables de entorno de Node.js configuradas en /etc/profile.d/nodejs.sh${NC}"
    else
      echo -e "${YELLOW}No se pudo crear el archivo global. Configurando solo para el usuario actual.${NC}"
      # No importa, lo configuraremos en los archivos del usuario
    fi

    # Agregar variables de entorno a .zshrc si Zsh está instalado
    if [ -n "$SUDO_USER" ]; then
      ZSHRC="$REAL_HOME/.zshrc"
      if [ -f "$ZSHRC" ] && ! grep -q "/usr/local/node/bin" "$ZSHRC"; then
        # Agregar variables de Node.js al zshrc
        echo '# Node.js' >> "$ZSHRC"
        echo 'export PATH=$PATH:/usr/local/node/bin' >> "$ZSHRC"
        chown $REAL_USER:$(id -gn $REAL_USER) "$ZSHRC"
      fi
    elif [ -f "$HOME/.zshrc" ] && ! grep -q "/usr/local/node/bin" "$HOME/.zshrc"; then
      # Agregar variables de Node.js al zshrc
      echo '# Node.js' >> "$HOME/.zshrc"
      echo 'export PATH=$PATH:/usr/local/node/bin' >> "$HOME/.zshrc"
    fi

    # Cargar las variables de entorno inmediatamente
    show_header "Cargando variables de entorno de Node.js"
    export PATH=$PATH:/usr/local/node/bin
    # Intentar cargar el archivo si existe
    [ -f /etc/profile.d/nodejs.sh ] && source /etc/profile.d/nodejs.sh

    # Crear enlaces simbólicos para node y npm
    ln -sf /usr/local/node/bin/node /usr/local/bin/node
    ln -sf /usr/local/node/bin/npm /usr/local/bin/npm
    ln -sf /usr/local/node/bin/npx /usr/local/bin/npx
  fi
}

# Instalar pnpm
install_pnpm() {
  # Obtener el usuario real que ejecutó sudo
  REAL_USER=${SUDO_USER:-$USER}
  REAL_HOME=$(getent passwd "$REAL_USER" | cut -d: -f6)

  if should_install "pnpm" "command -v pnpm"; then
    show_header "Instalando pnpm"

    # Asegurarse de que npm esté disponible
    if [ -n "$SUDO_USER" ]; then
      if su - $REAL_USER -c "command -v npm" &>/dev/null; then
        # Instalar como usuario real
        su - $REAL_USER -c "npm install -g pnpm"
        # Crear enlace simbólico global
        if [ ! -f "/usr/local/bin/pnpm" ] || [ "$FORCE" = true ]; then
          ln -sf /usr/local/node/bin/pnpm /usr/local/bin/pnpm
        fi
      else
        echo -e "${RED}npm no está disponible para $REAL_USER. No se pudo instalar pnpm${NC}"
      fi
    else
      # Instalación normal
      if command -v npm &>/dev/null; then
        npm install -g pnpm
        # Crear enlace simbólico para pnpm si no existe
        if [ ! -f "/usr/local/bin/pnpm" ] || [ "$FORCE" = true ]; then
          ln -sf /usr/local/node/bin/pnpm /usr/local/bin/pnpm
        fi
      else
        echo -e "${RED}npm no está disponible. No se pudo instalar pnpm${NC}"
      fi
    fi
  fi
}