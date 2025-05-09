#!/bin/bash

# Módulo para la instalación de Zed Editor

# Función para verificar si Zed está instalado
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