#!/bin/bash

# Script de instalación y configuración para Fedora
# Modularizado por aplicación: Zen Browser (Flatpak), Zed editor, Golang, Node.js LTS, pnpm y Zsh con Oh My Zsh

# Definir colores para mejor legibilidad
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Modo force (sobrescribir)
FORCE=false

# Procesar argumentos
for arg in "$@"; do
  case $arg in
    -f|--force)
      FORCE=true
      shift
      ;;
    *)
      # Desconocido
      ;;
  esac
done

# === Funciones comunes ===

# Función para verificar si se debe instalar
should_install() {
  local program=$1
  local check_command=$2

  # Obtener el usuario real que ejecutó sudo
  REAL_USER=${SUDO_USER:-$USER}

  # Si se ejecuta como sudo, verificar la instalación como el usuario real
  if [ -n "$SUDO_USER" ]; then
    if su - $REAL_USER -c "$check_command" &>/dev/null; then
      if [ "$FORCE" = true ]; then
        echo -e "${YELLOW}$program ya está instalado para $REAL_USER, pero será reinstalado (modo forzado)${NC}"
        return 0
      else
        echo -e "${GREEN}$program ya está instalado para $REAL_USER. Omitiendo instalación${NC}"
        return 1
      fi
    else
      echo -e "${BLUE}$program no está instalado para $REAL_USER. Instalando...${NC}"
      return 0
    fi
  else
    # Comportamiento normal cuando no se usa sudo
    if eval "$check_command" &>/dev/null; then
      if [ "$FORCE" = true ]; then
        echo -e "${YELLOW}$program ya está instalado, pero será reinstalado (modo forzado)${NC}"
        return 0
      else
        echo -e "${GREEN}$program ya está instalado. Omitiendo instalación${NC}"
        return 1
      fi
    else
      echo -e "${BLUE}$program no está instalado. Instalando...${NC}"
      return 0
    fi
  fi
}

# Función para mostrar cabecera
show_header() {
  echo -e "${BLUE}=== $1 ===${NC}"
}

# Función para mostrar estado de instalación
show_status() {
  local program=$1
  local command=$2
  local run_info=$3

  # Obtener el usuario real que ejecutó sudo
  REAL_USER=${SUDO_USER:-$USER}

  # Si se ejecuta como sudo, verificar la instalación como el usuario real
  if [ -n "$SUDO_USER" ]; then
    if su - $REAL_USER -c "$command" &>/dev/null; then
      VERSION_INFO=""
      if [ -n "$run_info" ]; then
        VERSION_INFO=$(su - $REAL_USER -c "$run_info" 2>/dev/null)
      fi
      echo -e "${GREEN}✓ $program está instalado para $REAL_USER $VERSION_INFO${NC}"
      if [ -n "$run_info" ]; then
        echo "   Ejecutar con: $run_info"
      fi
    else
      echo -e "${RED}✗ $program no está instalado para $REAL_USER${NC}"
    fi
  else
    # Comportamiento normal cuando no se usa sudo
    if eval "$command" &>/dev/null; then
      echo -e "${GREEN}✓ $program está instalado$(eval "$run_info" 2>/dev/null)${NC}"
      if [ -n "$run_info" ]; then
        echo "   Ejecutar con: $run_info"
      fi
    else
      echo -e "${RED}✗ $program no está instalado${NC}"
    fi
  fi
}

# === Módulos de instalación ===

# Actualizar sistema
update_system() {
  show_header "Actualizando el sistema"
  dnf update -y
}

# Instalar Flatpak
install_flatpak() {
  if should_install "Flatpak" "command -v flatpak"; then
    show_header "Instalando Flatpak"
    dnf install -y flatpak
  fi

  # Configurar Flathub
  if ! flatpak remotes | grep -q "flathub" || [ "$FORCE" = true ]; then
    show_header "Agregando repositorio Flathub"
    flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
  fi

  # Si ejecutamos como sudo, asegurarnos que el usuario real tenga acceso a Flatpak
  if [ -n "$SUDO_USER" ]; then
    # Añadir usuario al grupo flatpak
    usermod -aG flatpak $SUDO_USER

    # Configurar también para el usuario normal
    su - $SUDO_USER -c "flatpak remote-add --user --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo"
  fi
}

# Instalar Zen Browser
install_zen_browser() {
  # Obtener el usuario real que ejecutó sudo
  REAL_USER=${SUDO_USER:-$USER}

  if should_install "Zen Browser" "flatpak list | grep -q 'app.zen_browser.zen'"; then
    show_header "Instalando Zen Browser"

    # Si se ejecuta con sudo, instalar para el usuario real
    if [ -n "$SUDO_USER" ]; then
      echo -e "${BLUE}Instalando Zen Browser para el usuario $REAL_USER${NC}"
      # Asegurarse de que el usuario tenga permisos para Flatpak
      usermod -aG flatpak $REAL_USER 2>/dev/null || true
      # Instalar como usuario normal para evitar problemas de permisos
      su - $REAL_USER -c "flatpak install -y flathub app.zen_browser.zen"
    else
      flatpak install -y flathub app.zen_browser.zen
    fi
  fi
}

# Función para verificar si tenemos derechos de escritura
check_write_permissions() {
  local dir="$1"
  if [ ! -w "$dir" ]; then
    echo -e "${YELLOW}No tienes permisos de escritura en $dir${NC}"
    return 1
  fi
  return 0
}

# Función para verificar si Zed está instalado
# Verificar instalación de Zed
is_zed_installed() {
  # Obtener el usuario real que ejecutó sudo
  REAL_USER=${SUDO_USER:-$USER}
  REAL_HOME=$(getent passwd "$REAL_USER" | cut -d: -f6)

  # Si se ejecuta con sudo, verificar como el usuario real
  if [ -n "$SUDO_USER" ]; then
    # Verificar en los directorios del usuario real
    if [ -f "$REAL_HOME/.local/bin/zed" ] ||
       su - $REAL_USER -c "command -v zed" &>/dev/null; then
      return 0  # Está instalado para el usuario real
    fi
  else
    # Verificar normalmente
    if command -v zed &>/dev/null; then
      return 0  # Está instalado y en el PATH
    fi

    # Verificar múltiples ubicaciones comunes
    if [ -f "$HOME/.local/bin/zed" ] || [ -f "/usr/local/bin/zed" ] || [ -f "/usr/bin/zed" ]; then
      return 0  # Está instalado pero quizás no en el PATH
    fi
  fi

  return 1  # No está instalado
}

# Función para agregar Zed al PATH si existe pero no está en el PATH
add_zed_to_path() {
  local zed_path=""

  # Obtener el usuario real que ejecutó sudo
  REAL_USER=${SUDO_USER:-$USER}
  REAL_HOME=$(getent passwd "$REAL_USER" | cut -d: -f6)

  # Encontrar dónde está instalado Zed
  if [ -f "$REAL_HOME/.local/bin/zed" ]; then
    zed_path="$REAL_HOME/.local/bin"
  elif [ -f "$HOME/.local/bin/zed" ]; then
    zed_path="$HOME/.local/bin"
  elif [ -f "/usr/local/bin/zed" ]; then
    zed_path="/usr/local/bin"
  elif [ -f "/usr/bin/zed" ]; then
    zed_path="/usr/bin"
  fi

  # Si se encontró una ubicación pero zed no está en el PATH, agregarlo
  if [ -n "$zed_path" ] && ! command -v zed &>/dev/null; then
    export PATH="$zed_path:$PATH"
    echo -e "${BLUE}Agregando Zed al PATH desde $zed_path${NC}"

    # Si tenemos un usuario real (sudo), modificar su .bashrc
    if [ -n "$SUDO_USER" ]; then
      BASHRC="$REAL_HOME/.bashrc"
      if [ -f "$BASHRC" ] && ! grep -q "PATH=\"$zed_path:\\\$PATH\"" "$BASHRC"; then
        echo "export PATH=\"$zed_path:\$PATH\"" >> "$BASHRC"
        echo -e "${GREEN}Zed agregado permanentemente al PATH en .bashrc de $REAL_USER${NC}"
        # Asegurarse de que el usuario sea el dueño de su propio archivo
        chown $REAL_USER:$(id -gn $REAL_USER) "$BASHRC"
      fi
    else
      # Usuario normal
      if ! grep -q "PATH=\"$zed_path:\\\$PATH\"" "$HOME/.bashrc"; then
        echo "export PATH=\"$zed_path:\$PATH\"" >> "$HOME/.bashrc"
        echo -e "${GREEN}Zed agregado permanentemente al PATH en .bashrc${NC}"
      fi
    fi
  fi
}

# Instalar Zed editor
install_zed() {
  # Obtener el usuario real que ejecutó sudo
  REAL_USER=${SUDO_USER:-$USER}
  REAL_HOME=$(getent passwd "$REAL_USER" | cut -d: -f6)

  if is_zed_installed; then
    # Primero intentar agregar al PATH si existe pero no es accesible
    add_zed_to_path

    if [ "$FORCE" = true ]; then
      echo -e "${YELLOW}Zed editor ya está instalado, pero será reinstalado (modo forzado)${NC}"
      show_header "Reinstalando Zed editor"
      install_zed_for_user
    else
      echo -e "${GREEN}Zed editor ya está instalado. Omitiendo instalación${NC}"
    fi
  else
    echo -e "${BLUE}Zed editor no está instalado. Instalando...${NC}"
    show_header "Instalando Zed editor"
    install_zed_for_user
  fi
}

# Instalar Zed para el usuario correcto
install_zed_for_user() {
  # Obtener el usuario real que ejecutó sudo
  REAL_USER=${SUDO_USER:-$USER}
  REAL_HOME=$(getent passwd "$REAL_USER" | cut -d: -f6)

  if [ -n "$SUDO_USER" ]; then
    # Ejecutamos el script de instalación como el usuario real, no como root
    echo -e "${BLUE}Instalando Zed para el usuario $REAL_USER...${NC}"
    su - $REAL_USER -c "curl -f https://zed.dev/install.sh | sh"

    # Verificar instalación
    if [ -f "$REAL_HOME/.local/bin/zed" ]; then
      echo -e "${GREEN}Zed instalado correctamente en $REAL_HOME/.local/bin/zed${NC}"

      # Actualizar PATH para el usuario
      BASHRC="$REAL_HOME/.bashrc"
      if [ -f "$BASHRC" ] && ! grep -q "PATH=\"\\\$HOME/.local/bin:\\\$PATH\"" "$BASHRC"; then
        echo 'export PATH="$HOME/.local/bin:$PATH"' >> "$BASHRC"
        echo -e "${GREEN}Directorio .local/bin agregado permanentemente al PATH en .bashrc de $REAL_USER${NC}"
        # Asegurarse de que el usuario sea el dueño de su propio archivo
        chown $REAL_USER:$(id -gn $REAL_USER) "$BASHRC"
      fi

      # Si también existe .zshrc, actualizarlo
      ZSHRC="$REAL_HOME/.zshrc"
      if [ -f "$ZSHRC" ] && ! grep -q "PATH=\"\\\$HOME/.local/bin:\\\$PATH\"" "$ZSHRC"; then
        echo 'export PATH="$HOME/.local/bin:$PATH"' >> "$ZSHRC"
        echo -e "${GREEN}Directorio .local/bin agregado permanentemente al PATH en .zshrc de $REAL_USER${NC}"
        chown $REAL_USER:$(id -gn $REAL_USER) "$ZSHRC"
      fi
    else
      echo -e "${RED}La instalación de Zed parece haber fallado. Verifique manualmente.${NC}"
    fi
  else
    # Instalación normal
    curl -f https://zed.dev/install.sh | sh

    # Asegurarse de que los binarios estén en el PATH
    if [ -d "$HOME/.local/bin" ]; then
      export PATH="$HOME/.local/bin:$PATH"
      if ! grep -q "PATH=\"\\\$HOME/.local/bin:\\\$PATH\"" "$HOME/.bashrc"; then
        echo 'export PATH="$HOME/.local/bin:$PATH"' >> "$HOME/.bashrc"
      fi

      # Si también existe .zshrc, actualizarlo
      if [ -f "$HOME/.zshrc" ] && ! grep -q "PATH=\"\\\$HOME/.local/bin:\\\$PATH\"" "$HOME/.zshrc"; then
        echo 'export PATH="$HOME/.local/bin:$PATH"' >> "$HOME/.zshrc"
      fi
    fi
  fi
}

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

# Mostrar resumen
# Función para mostrar resumen
show_summary() {
  # Obtener el usuario real que ejecutó sudo
  REAL_USER=${SUDO_USER:-$USER}
  REAL_HOME=$(getent passwd "$REAL_USER" | cut -d: -f6)

  show_header "Instalación completada"
  echo -e "${GREEN}Resumen de instalaciones para el usuario: ${YELLOW}$REAL_USER${NC}"

  if [ -n "$SUDO_USER" ]; then
    echo -e "${BLUE}Instalación ejecutada como root para el usuario: ${GREEN}$REAL_USER${NC}"
    echo -e "${YELLOW}Nota: Para verificar correctamente las instalaciones, inicia sesión como: ${GREEN}$REAL_USER${NC}"
  fi

  # Mostrar información sobre las aplicaciones instaladas y configuraciones
  show_status "Zen Browser" "flatpak list | grep -q 'app.zen_browser.zen'" "flatpak run app.zen_browser.zen"
  # Para Zed, mostramos una información más detallada sobre su ubicación
  if is_zed_installed; then
    REAL_USER=${SUDO_USER:-$USER}
    REAL_HOME=$(getent passwd "$REAL_USER" | cut -d: -f6)

    ZED_PATH=""
    if [ -n "$SUDO_USER" ]; then
      # Buscar como usuario real
      if [ -f "$REAL_HOME/.local/bin/zed" ]; then
        ZED_PATH="$REAL_HOME/.local/bin/zed"
      else
        ZED_PATH=$(su - $REAL_USER -c "which zed" 2>/dev/null || echo "ubicación desconocida")
      fi
    else
      # Buscar normalmente
      if [ -f "$HOME/.local/bin/zed" ]; then
        ZED_PATH="$HOME/.local/bin/zed"
      elif [ -f "/usr/local/bin/zed" ]; then
        ZED_PATH="/usr/local/bin/zed"
      elif [ -f "/usr/bin/zed" ]; then
        ZED_PATH="/usr/bin/zed"
      else
        ZED_PATH=$(which zed 2>/dev/null || echo "ubicación desconocida")
      fi
    fi

    echo -e "${GREEN}✓ Zed editor está instalado${NC}"
    echo "   Ubicación: $ZED_PATH"
    echo "   Ejecutar con: zed"
  else
    echo -e "${RED}✗ Zed editor no está instalado${NC}"
  fi
  show_status "Golang" "command -v go" "go version"
  show_status "Node.js" "command -v node" "node -v"
  show_status "npm" "command -v npm" "npm -v"
  show_status "pnpm" "command -v pnpm" "pnpm -v"
  show_status "Zsh" "command -v zsh" "zsh"

  # Verificar si se ha configurado SSH
  if [ -f "$REAL_HOME/.ssh/id_ed25519" ]; then
    echo -e "${GREEN}✓ Llave SSH (Ed25519) configurada para $REAL_USER${NC}"
    echo "   Ubicación: $REAL_HOME/.ssh/id_ed25519"
    echo "   Llave pública: $REAL_HOME/.ssh/id_ed25519.pub"

    # Verificar si el agente SSH está en uso
    if [ -n "$SUDO_USER" ]; then
      if su - $REAL_USER -c "ssh-add -l" 2>/dev/null | grep -q "ED25519"; then
        echo -e "${GREEN}   ✓ Llave agregada al agente SSH${NC}"
      else
        echo -e "${YELLOW}   ! Llave no agregada al agente SSH. Ejecute: ssh-add${NC}"
      fi
    elif ssh-add -l 2>/dev/null | grep -q "ED25519"; then
      echo -e "${GREEN}   ✓ Llave agregada al agente SSH${NC}"
    else
      echo -e "${YELLOW}   ! Llave no agregada al agente SSH. Ejecute: ssh-add${NC}"
    fi
  else
    echo -e "${YELLOW}✗ No se encontró llave SSH configurada${NC}"
  fi

  # Verificar si Oh My Zsh está instalado
  if [ -d "$REAL_HOME/.oh-my-zsh" ]; then
    echo -e "${GREEN}✓ Oh My Zsh está instalado${NC}"
    if grep -q 'ZSH_THEME="agnoster"' "$REAL_HOME/.zshrc" 2>/dev/null; then
      echo "   Tema: agnoster"
    fi
    if grep -q 'plugins=' "$REAL_HOME/.zshrc" 2>/dev/null; then
      PLUGINS=$(grep 'plugins=' "$REAL_HOME/.zshrc" | sed 's/plugins=(//' | sed 's/)//' | tr -d '\n')
      echo "   Plugins: $PLUGINS"
    fi
  else
    echo -e "${RED}✗ Oh My Zsh no está instalado${NC}"
  fi

  # Verificar si Zsh es el shell predeterminado
  ZSH_PATH=$(which zsh)
  if grep -q "$REAL_USER.*$ZSH_PATH" /etc/passwd; then
    echo -e "${GREEN}✓ Zsh está configurado como shell predeterminado para $REAL_USER${NC}"
  else
    echo -e "${YELLOW}! Zsh está instalado pero no es el shell predeterminado.${NC}"
    if [ "$REAL_USER" = "$USER" ]; then
      echo -e "${YELLOW}Para cambiarlo, ejecute: chsh -s $ZSH_PATH${NC}"
    else
      echo -e "${YELLOW}Para cambiarlo, ejecute: sudo usermod -s $ZSH_PATH $REAL_USER${NC}"
    fi
    echo -e "${YELLOW}También puede abrir .bashrc y añadir: if [ -x \"$(command -v zsh)\" ]; then exec zsh; fi${NC}"
  fi

  # Verificar si las terminales nuevas inician con zsh automáticamente
  if [ -n "$SUDO_USER" ]; then
    if grep -q "exec zsh" "$REAL_HOME/.bashrc" 2>/dev/null; then
      echo -e "${GREEN}✓ Las nuevas terminales iniciarán Zsh automáticamente (configurado en .bashrc)${NC}"
    fi
  else
    if grep -q "exec zsh" "$HOME/.bashrc" 2>/dev/null; then
      echo -e "${GREEN}✓ Las nuevas terminales iniciarán Zsh automáticamente (configurado en .bashrc)${NC}"
    fi
  fi

  echo -e "${BLUE}Para asegurarte de que todas las variables de entorno estén cargadas en tu sesión actual:${NC}"
  echo -e "${YELLOW}Nota: Si hay errores en /etc/profile.d/, puedes configurar manualmente en tu archivo .bashrc o .zshrc${NC}"
  if [ -n "$SUDO_USER" ]; then
    if getent passwd $REAL_USER | grep -q "$(which zsh)"; then
      echo -e "${YELLOW}Para el usuario $REAL_USER:${NC}"
      echo "Todas las variables de entorno están configuradas en .zshrc y se cargarán automáticamente al iniciar sesión."
      echo "Para cargarlas en esta sesión sin reiniciar: $ su - $REAL_USER -c 'source $REAL_HOME/.zshrc'"
    else
      echo -e "${YELLOW}Para el usuario $REAL_USER:${NC}"
      echo "$ su - $REAL_USER"
      echo "$ source /etc/profile.d/go.sh"
      echo "$ source /etc/profile.d/nodejs.sh"
    fi
  else
    # Sin sudo
    if getent passwd $USER | grep -q "$(which zsh)"; then
      echo "Todas las variables de entorno están configuradas en .zshrc y se cargarán automáticamente al iniciar sesión."
      echo "Para cargarlas en esta sesión sin reiniciar: $ source $HOME/.zshrc"
    else
      echo "$ source /etc/profile.d/go.sh"
      echo "$ source /etc/profile.d/nodejs.sh"
    fi
  fi
}

# === Verificación de privilegios ===
check_privileges() {
  # Verificar si se está ejecutando como root/sudo
  if [ "$EUID" -ne 0 ]; then
    echo -e "${RED}Este script necesita privilegios de administrador.${NC}"
    echo -e "${RED}Por favor, ejecútalo con sudo.${NC}"
    echo -e "${YELLOW}Nota: La instalación se realizará para el usuario que ejecuta sudo, no para root.${NC}"
    exit 1
  fi

  # Verificar si tenemos acceso a directorios importantes
  if ! check_write_permissions "/etc/profile.d" 2>/dev/null; then
    echo -e "${YELLOW}Advertencia: No tienes permisos de escritura en /etc/profile.d${NC}"
    echo -e "${YELLOW}Se intentará una solución alternativa para la configuración del sistema${NC}"
  fi

  # Si estamos ejecutando como sudo, guardamos el usuario real para instalaciones específicas
  if [ -n "$SUDO_USER" ]; then
    echo -e "${BLUE}Ejecutando como root para el usuario: ${GREEN}$SUDO_USER${NC}"
  fi
}

# Instalar Zsh y Oh My Zsh
install_zsh() {
  # Obtener el usuario real que ejecutó sudo
  REAL_USER=${SUDO_USER:-$USER}
  REAL_HOME=$(getent passwd "$REAL_USER" | cut -d: -f6)

  # Instalar Zsh
  if should_install "Zsh" "command -v zsh"; then
    show_header "Instalando Zsh"
    dnf install -y zsh util-linux-user

    # Intentar instalar las fuentes Powerline para el tema agnoster
    if ! rpm -q powerline-fonts >/dev/null 2>&1; then
      echo -e "${BLUE}Instalando fuentes Powerline para Oh My Zsh${NC}"
      dnf install -y powerline-fonts || dnf install -y google-noto-sans-mono-fonts || dnf install -y fira-code-fonts
    fi
  fi

  # Instalar Oh My Zsh
  if [ ! -d "$REAL_HOME/.oh-my-zsh" ] || [ "$FORCE" = true ]; then
    show_header "Instalando Oh My Zsh"

    if [ -n "$SUDO_USER" ]; then
      # Instalar como usuario normal
      echo -e "${BLUE}Instalando Oh My Zsh para el usuario $REAL_USER${NC}"
      # Primero desinstalar si está en modo force
      if [ "$FORCE" = true ] && [ -d "$REAL_HOME/.oh-my-zsh" ]; then
        su - $REAL_USER -c "rm -rf $REAL_HOME/.oh-my-zsh"
      fi

      # Instalar Oh My Zsh
      su - $REAL_USER -c 'sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended'

      # Configurar tema preferido y plugins útiles
      if [ -f "$REAL_HOME/.zshrc" ]; then
        sed -i 's/ZSH_THEME="robbyrussell"/ZSH_THEME="agnoster"/' "$REAL_HOME/.zshrc"
        # Agregar plugins útiles
        sed -i 's/plugins=(git)/plugins=(git npm docker golang node sudo)/' "$REAL_HOME/.zshrc"
        # Asegurarnos de que los permisos son correctos
        chown $REAL_USER:$(id -gn $REAL_USER) "$REAL_HOME/.zshrc"
      fi
    else
    # Si ya existe y estamos en modo force, eliminar
    if [ "$FORCE" = true ] && [ -d "$HOME/.oh-my-zsh" ]; then
      rm -rf "$HOME/.oh-my-zsh"
    fi

    # Instalar normalmente
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended

      # Configurar tema preferido y plugins útiles
      if [ -f "$HOME/.zshrc" ]; then
        sed -i 's/ZSH_THEME="robbyrussell"/ZSH_THEME="agnoster"/' "$HOME/.zshrc"
        # Agregar plugins útiles
        sed -i 's/plugins=(git)/plugins=(git npm docker golang node sudo)/' "$HOME/.zshrc"
      fi
    fi

    echo -e "${GREEN}Oh My Zsh instalado correctamente con tema agnoster y plugins útiles${NC}"
    echo -e "${YELLOW}Nota: Para ver correctamente el tema agnoster, asegúrate de usar una fuente compatible con Powerline${NC}"
  else
    echo -e "${GREEN}Oh My Zsh ya está instalado. Omitiendo instalación${NC}"
  fi

  # Establecer Zsh como shell predeterminado
  show_header "Configurando Zsh como shell predeterminado"

  # Asegurarse de obtener la ruta completa de zsh
  ZSH_PATH=$(which zsh)

  if [ -n "$SUDO_USER" ]; then
    # Verificar si ya es el shell predeterminado
    if ! grep -q "$REAL_USER.*$ZSH_PATH" /etc/passwd; then
      echo -e "${BLUE}Estableciendo Zsh como shell predeterminado para $REAL_USER${NC}"
      # Usar chsh directamente para el usuario real
      chsh -s "$ZSH_PATH" $REAL_USER 2>/dev/null
      # Si falla chsh, usar usermod como alternativa
      if [ $? -ne 0 ]; then
        usermod -s "$ZSH_PATH" $REAL_USER
      fi

      # Verificar el cambio
      if grep -q "$REAL_USER.*$ZSH_PATH" /etc/passwd; then
        echo -e "${GREEN}Zsh establecido como shell predeterminado para $REAL_USER${NC}"
      else
        echo -e "${RED}No se pudo establecer Zsh como shell predeterminado automáticamente${NC}"
        echo -e "${YELLOW}Por favor, ejecuta manualmente: chsh -s $ZSH_PATH${NC}"
      fi
    else
      echo -e "${GREEN}Zsh ya es el shell predeterminado para $REAL_USER${NC}"
    fi

    # Mostrar mensaje para activar Zsh
    echo -e "${YELLOW}Para usar Zsh inmediatamente sin cerrar sesión, ejecute: ${NC}"
    echo "su - $REAL_USER"

    # Asegurarse de que el shell por defecto en las nuevas terminales sea zsh
    if [ -f "$REAL_HOME/.bashrc" ]; then
      if ! grep -q "exec zsh" "$REAL_HOME/.bashrc"; then
        echo 'if [ -x "$(command -v zsh)" ]; then exec zsh; fi' >> "$REAL_HOME/.bashrc"
        chown $REAL_USER:$(id -gn $REAL_USER) "$REAL_HOME/.bashrc"
        echo -e "${BLUE}Configurado .bashrc para iniciar Zsh automáticamente${NC}"
      fi
    fi
  else
    # Para el usuario actual
    if ! grep -q "$USER.*$ZSH_PATH" /etc/passwd; then
      echo -e "${BLUE}Estableciendo Zsh como shell predeterminado${NC}"
      chsh -s "$ZSH_PATH"
      echo -e "${GREEN}Zsh establecido como shell predeterminado${NC}"
      echo -e "${YELLOW}Cierra sesión y vuelve a entrar para usar Zsh${NC}"
    else
      echo -e "${GREEN}Zsh ya es el shell predeterminado${NC}"
    fi

    # Asegurarse de que las nuevas terminales usen zsh
    if [ -f "$HOME/.bashrc" ]; then
      if ! grep -q "exec zsh" "$HOME/.bashrc"; then
        echo 'if [ -x "$(command -v zsh)" ]; then exec zsh; fi' >> "$HOME/.bashrc"
        echo -e "${BLUE}Configurado .bashrc para iniciar Zsh automáticamente${NC}"
      fi
    fi
  fi
}

# Configurar SSH para GitHub y GitLab
configure_ssh() {
  # Obtener el usuario real que ejecutó sudo
  REAL_USER=${SUDO_USER:-$USER}
  REAL_HOME=$(getent passwd "$REAL_USER" | cut -d: -f6)

  show_header "Configurando SSH para GitHub y GitLab"

  # Verificar si ya existe una clave SSH
  SSH_DIR="$REAL_HOME/.ssh"
  SSH_KEY="$SSH_DIR/id_ed25519"

  if [ -f "$SSH_KEY" ] && [ "$FORCE" != true ]; then
    echo -e "${GREEN}Ya existe una llave SSH Ed25519. Omitiendo creación.${NC}"
    echo -e "${BLUE}Ubicación: $SSH_KEY${NC}"
    echo -e "${BLUE}Llave pública: $SSH_KEY.pub${NC}"
  else
    # Crear directorio .ssh si no existe
    if [ ! -d "$SSH_DIR" ]; then
      if [ -n "$SUDO_USER" ]; then
        # Crear como usuario normal
        su - $REAL_USER -c "mkdir -p $SSH_DIR"
        su - $REAL_USER -c "chmod 700 $SSH_DIR"
      else
        mkdir -p "$SSH_DIR"
        chmod 700 "$SSH_DIR"
      fi
    fi

    echo -e "${BLUE}Generando nueva llave SSH Ed25519...${NC}"

    # Generar clave SSH
    if [ -n "$SUDO_USER" ]; then
      # Generar como usuario normal sin passphrase
      echo -e "${YELLOW}Generando llave sin passphrase para $REAL_USER${NC}"
      su - $REAL_USER -c "ssh-keygen -t ed25519 -f $SSH_KEY -N '' -C \"$REAL_USER@$(hostname)\""
    else
      # Generar como usuario actual sin passphrase
      echo -e "${YELLOW}Generando llave sin passphrase${NC}"
      ssh-keygen -t ed25519 -f "$SSH_KEY" -N "" -C "$USER@$(hostname)"
    fi

    echo -e "${GREEN}Llave SSH generada correctamente${NC}"
    echo -e "${BLUE}Ubicación: $SSH_KEY${NC}"
    echo -e "${BLUE}Llave pública: $SSH_KEY.pub${NC}"
  fi

  # Configurar ssh-agent
  if [ -n "$SUDO_USER" ]; then
    # Verificar si ssh-agent está configurado en .zshrc
    ZSHRC="$REAL_HOME/.zshrc"
    if [ -f "$ZSHRC" ] && ! grep -q "ssh-agent" "$ZSHRC"; then
      echo -e "${BLUE}Configurando ssh-agent en .zshrc para $REAL_USER${NC}"
      cat >> "$ZSHRC" << 'EOF'

# Configuración del agente SSH
if [ -z "$SSH_AUTH_SOCK" ]; then
   # Check for a currently running instance of the agent
   RUNNING_AGENT="`ps -ax | grep 'ssh-agent -s' | grep -v grep | wc -l | tr -d '[:space:]'`"
   if [ "$RUNNING_AGENT" = "0" ]; then
        # Launch a new instance of the agent
        ssh-agent -s &> $HOME/.ssh/ssh-agent
   fi
   eval `cat $HOME/.ssh/ssh-agent`
fi
EOF
      chown $REAL_USER:$(id -gn $REAL_USER) "$ZSHRC"
    fi

    # Verificar si ssh-agent está configurado en .bashrc
    BASHRC="$REAL_HOME/.bashrc"
    if [ -f "$BASHRC" ] && ! grep -q "ssh-agent" "$BASHRC"; then
      echo -e "${BLUE}Configurando ssh-agent en .bashrc para $REAL_USER${NC}"
      cat >> "$BASHRC" << 'EOF'

# Configuración del agente SSH
if [ -z "$SSH_AUTH_SOCK" ]; then
   # Check for a currently running instance of the agent
   RUNNING_AGENT="`ps -ax | grep 'ssh-agent -s' | grep -v grep | wc -l | tr -d '[:space:]'`"
   if [ "$RUNNING_AGENT" = "0" ]; then
        # Launch a new instance of the agent
        ssh-agent -s &> $HOME/.ssh/ssh-agent
   fi
   eval `cat $HOME/.ssh/ssh-agent`
fi
EOF
      chown $REAL_USER:$(id -gn $REAL_USER) "$BASHRC"
    fi

    # Iniciar ssh-agent si no está corriendo y añadir la llave
    echo -e "${BLUE}Intentando añadir la llave al agente SSH...${NC}"
    su - $REAL_USER -c "
      if [ -z \"\$SSH_AUTH_SOCK\" ]; then
        eval \$(ssh-agent -s)
      fi
      ssh-add $SSH_KEY 2>/dev/null || true
    "
  else
    # Configurar ssh-agent para el usuario actual
    # Verificar si ssh-agent está configurado en .zshrc
    if [ -f "$HOME/.zshrc" ] && ! grep -q "ssh-agent" "$HOME/.zshrc"; then
      echo -e "${BLUE}Configurando ssh-agent en .zshrc${NC}"
      cat >> "$HOME/.zshrc" << 'EOF'

# Configuración del agente SSH
if [ -z "$SSH_AUTH_SOCK" ]; then
   # Check for a currently running instance of the agent
   RUNNING_AGENT="`ps -ax | grep 'ssh-agent -s' | grep -v grep | wc -l | tr -d '[:space:]'`"
   if [ "$RUNNING_AGENT" = "0" ]; then
        # Launch a new instance of the agent
        ssh-agent -s &> $HOME/.ssh/ssh-agent
   fi
   eval `cat $HOME/.ssh/ssh-agent`
fi
EOF
    fi

    # Verificar si ssh-agent está configurado en .bashrc
    if [ -f "$HOME/.bashrc" ] && ! grep -q "ssh-agent" "$HOME/.bashrc"; then
      echo -e "${BLUE}Configurando ssh-agent en .bashrc${NC}"
      cat >> "$HOME/.bashrc" << 'EOF'

# Configuración del agente SSH
if [ -z "$SSH_AUTH_SOCK" ]; then
   # Check for a currently running instance of the agent
   RUNNING_AGENT="`ps -ax | grep 'ssh-agent -s' | grep -v grep | wc -l | tr -d '[:space:]'`"
   if [ "$RUNNING_AGENT" = "0" ]; then
        # Launch a new instance of the agent
        ssh-agent -s &> $HOME/.ssh/ssh-agent
   fi
   eval `cat $HOME/.ssh/ssh-agent`
fi
EOF
    fi

    # Iniciar ssh-agent si no está corriendo y añadir la llave
    echo -e "${BLUE}Intentando añadir la llave al agente SSH...${NC}"
    if [ -z "$SSH_AUTH_SOCK" ]; then
      eval $(ssh-agent -s)
    fi
    ssh-add "$SSH_KEY" 2>/dev/null || true
  fi

  # Mostrar instrucciones para añadir la llave a GitHub/GitLab
  echo -e "${GREEN}Para añadir esta llave a GitHub/GitLab:${NC}"
  echo -e "${YELLOW}1. Copia el contenido de tu llave pública:${NC}"

  if [ -n "$SUDO_USER" ]; then
    echo -e "${BLUE}   cat $SSH_KEY.pub${NC}"
    # Mostrar el contenido de la llave pública
    if [ -f "$SSH_KEY.pub" ]; then
      echo -e "${GREEN}   Contenido de la llave pública:${NC}"
      su - $REAL_USER -c "cat $SSH_KEY.pub" || cat "$SSH_KEY.pub"
    fi
  else
    echo -e "${BLUE}   cat $SSH_KEY.pub${NC}"
    # Mostrar el contenido de la llave pública
    if [ -f "$SSH_KEY.pub" ]; then
      echo -e "${GREEN}   Contenido de la llave pública:${NC}"
      cat "$SSH_KEY.pub"
    fi
  fi

  echo -e "${YELLOW}2. Ve a GitHub -> Settings -> SSH and GPG keys -> New SSH key${NC}"
  echo -e "${YELLOW}   O para GitLab: User Settings -> SSH Keys${NC}"
  echo -e "${YELLOW}3. Pega la clave pública y guarda${NC}"
  echo -e "${YELLOW}4. Prueba la conexión con: ssh -T git@github.com${NC}"
}

# === Ejecución principal ===
main() {
  # Obtener el usuario real que ejecutó sudo
  REAL_USER=${SUDO_USER:-$USER}
  REAL_HOME=$(getent passwd "$REAL_USER" | cut -d: -f6)

  # Mostrar información del script
  show_header "Script de instalación para Fedora"
  echo -e "${BLUE}Instalará: Zen Browser, Zed editor, Golang, Node.js LTS, pnpm, Zsh con Oh My Zsh (tema agnoster) y configurará SSH para GitHub/GitLab${NC}"

  if [ "$FORCE" = true ]; then
    echo -e "${YELLOW}Modo forzado activado: Se sobrescribirán instalaciones existentes${NC}"
  fi

  if [ -n "$SUDO_USER" ]; then
    echo -e "${YELLOW}Ejecutando como root para el usuario: $REAL_USER${NC}"
    echo -e "${YELLOW}Las aplicaciones se instalarán considerando el perfil de usuario de: $REAL_USER${NC}"
  fi

  echo -e "${YELLOW}Nota: Al instalar Zsh, se configurará como shell predeterminado automáticamente${NC}"

  # Verificar privilegios
  check_privileges

  # Ejecutar módulos de instalación
  update_system
  install_flatpak
  install_zen_browser
  install_zed
  install_golang
  install_nodejs
  install_pnpm
  install_zsh
  configure_ssh

  # Mostrar resumen
  show_summary
}

# Iniciar ejecución
main
