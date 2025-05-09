#!/bin/bash

# Módulo para configurar SSH para GitHub y GitLab

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