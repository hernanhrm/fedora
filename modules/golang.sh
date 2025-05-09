#!/bin/bash

# Módulo para la instalación de Golang

# Instalar Golang
install_golang() {
  # Obtener el usuario real que ejecutó sudo
  REAL_USER=${SUDO_USER:-$USER}
  REAL_HOME=$(getent passwd "$REAL_USER" | cut -d: -f6)

  if should_install "Golang" "command -v go"; then
    show_header "Instalando Golang 1.24.3"

    # Instalar dependencias necesarias
    dnf install -y wget tar

    # Descargar Go
    wget https://go.dev/dl/go1.24.3.linux-amd64.tar.gz

    # Eliminar instalaciones previas de Go si existen y estamos en modo forzado
    if [ -d "/usr/local/go" ] && [ "$FORCE" = true ]; then
      echo -e "${YELLOW}Eliminando instalación anterior de Go...${NC}"
      rm -rf /usr/local/go
    fi

    # Extraer Go en /usr/local
    tar -C /usr/local -xzf go1.24.3.linux-amd64.tar.gz

    # Eliminar el archivo descargado
    rm go1.24.3.linux-amd64.tar.gz

    # Configurar variables de entorno para Go
    show_header "Configurando variables de entorno para Go"

    # Variables a configurar
    GO_ENV_CONTENT=$(cat << 'EOF'
#!/bin/bash
export GOROOT=/usr/local/go
export GOPATH=$HOME/go
export PATH=$PATH:$GOROOT/bin:$GOPATH/bin
export GO111MODULE=on
EOF
)

    # Intentar crear el archivo de perfil
    echo "$GO_ENV_CONTENT" > "/tmp/go_env.sh"

    # Intentar mover el archivo al directorio correcto
    if sudo mv "/tmp/go_env.sh" "/etc/profile.d/go.sh" && sudo chmod +x "/etc/profile.d/go.sh"; then
      echo -e "${GREEN}Variables de entorno de Go configuradas en /etc/profile.d/go.sh${NC}"
    else
      echo -e "${YELLOW}No se pudo crear el archivo global. Configurando solo para el usuario actual.${NC}"
      # No importa, lo configuraremos en los archivos del usuario
    fi

  # Crear directorio para proyectos Go del usuario real
  if [ -n "$SUDO_USER" ]; then
    mkdir -p $REAL_HOME/go/{bin,pkg,src}
    chown -R $REAL_USER:$(id -gn $REAL_USER) $REAL_HOME/go
  else
    mkdir -p $HOME/go/{bin,pkg,src}
  fi

  # Agregar variables de entorno a .zshrc si Zsh está instalado
  if [ -n "$SUDO_USER" ]; then
    ZSHRC="$REAL_HOME/.zshrc"
    if [ -f "$ZSHRC" ] && ! grep -q "GOROOT" "$ZSHRC"; then
      # Agregar variables de Go al zshrc
      echo '# Golang' >> "$ZSHRC"
      echo 'export GOROOT=/usr/local/go' >> "$ZSHRC"
      echo 'export GOPATH=$HOME/go' >> "$ZSHRC"
      echo 'export PATH=$PATH:$GOROOT/bin:$GOPATH/bin' >> "$ZSHRC"
      echo 'export GO111MODULE=on' >> "$ZSHRC"
      chown $REAL_USER:$(id -gn $REAL_USER) "$ZSHRC"
    fi
  elif [ -f "$HOME/.zshrc" ] && ! grep -q "GOROOT" "$HOME/.zshrc"; then
    # Agregar variables de Go al zshrc
    echo '# Golang' >> "$HOME/.zshrc"
    echo 'export GOROOT=/usr/local/go' >> "$HOME/.zshrc"
    echo 'export GOPATH=$HOME/go' >> "$HOME/.zshrc"
    echo 'export PATH=$PATH:$GOROOT/bin:$GOPATH/bin' >> "$HOME/.zshrc"
    echo 'export GO111MODULE=on' >> "$HOME/.zshrc"
  fi

  # Cargar las variables de entorno inmediatamente
  show_header "Cargando variables de entorno de Go"
  export GOROOT=/usr/local/go
  export GOPATH=$HOME/go
  export PATH=$PATH:$GOROOT/bin:$GOPATH/bin
  export GO111MODULE=on
  # Intentar cargar el archivo si existe
  [ -f /etc/profile.d/go.sh ] && source /etc/profile.d/go.sh
  fi
}