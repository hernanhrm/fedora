#!/bin/bash

# Módulo para la instalación y configuración de fzf-zsh

# Instalar y configurar fzf-zsh
install_fzf_zsh() {
  # Obtener el usuario real que ejecutó sudo
  REAL_USER=${SUDO_USER:-$USER}
  REAL_HOME=$(getent passwd "$REAL_USER" | cut -d: -f6)

  show_header "Configurando fzf para Zsh"

  # Verificar que fzf esté instalado
  if ! command -v fzf >/dev/null 2>&1; then
    echo -e "${YELLOW}fzf no está instalado. Instalando...${NC}"
    dnf install -y fzf
    if [ $? -ne 0 ]; then
      echo -e "${RED}Error al instalar fzf. No se puede continuar con la configuración de fzf-zsh${NC}"
      return 1
    fi
  fi

  # Verificar que zsh esté instalado
  if ! command -v zsh >/dev/null 2>&1; then
    echo -e "${YELLOW}Zsh no está instalado. Instalando...${NC}"
    dnf install -y zsh
    if [ $? -ne 0 ]; then
      echo -e "${RED}Error al instalar Zsh. No se puede continuar con la configuración de fzf-zsh${NC}"
      return 1
    fi
  fi

  # Verificar si Oh My Zsh está instalado
  if [ -n "$SUDO_USER" ]; then
    OMZ_DIR="$REAL_HOME/.oh-my-zsh"
  else
    OMZ_DIR="$HOME/.oh-my-zsh"
  fi

  if [ -d "$OMZ_DIR" ]; then
    echo -e "${GREEN}Oh My Zsh detectado. Configurando fzf como plugin...${NC}"
    
    # Descargar el plugin fzf para Oh My Zsh si no existe
    FZF_PLUGIN_DIR="$OMZ_DIR/custom/plugins/fzf"
    if [ ! -d "$FZF_PLUGIN_DIR" ]; then
      if [ -n "$SUDO_USER" ]; then
        su - $REAL_USER -c "mkdir -p $OMZ_DIR/custom/plugins"
        su - $REAL_USER -c "git clone --depth 1 https://github.com/junegunn/fzf.git $FZF_PLUGIN_DIR"
      else
        mkdir -p "$OMZ_DIR/custom/plugins"
        git clone --depth 1 https://github.com/junegunn/fzf.git "$FZF_PLUGIN_DIR"
      fi
    fi

    # Activar el plugin en .zshrc
    ZSHRC_FILE="$REAL_HOME/.zshrc"
    if [ ! -n "$SUDO_USER" ]; then
      ZSHRC_FILE="$HOME/.zshrc"
    fi

    if [ -f "$ZSHRC_FILE" ]; then
      # Verificar si fzf ya está en la lista de plugins
      if ! grep -q "plugins=.*fzf" "$ZSHRC_FILE"; then
        # Agregar fzf a la lista de plugins
        if [ -n "$SUDO_USER" ]; then
          sed -i 's/plugins=(/plugins=(fzf /' "$ZSHRC_FILE"
          chown $REAL_USER:$(id -gn $REAL_USER) "$ZSHRC_FILE"
        else
          sed -i 's/plugins=(/plugins=(fzf /' "$ZSHRC_FILE"
        fi
        echo -e "${GREEN}Plugin fzf añadido a Oh My Zsh${NC}"
      else
        echo -e "${GREEN}El plugin fzf ya está configurado en Oh My Zsh${NC}"
      fi
    fi
  else
    echo -e "${YELLOW}Oh My Zsh no está instalado. Configurando fzf para Zsh estándar...${NC}"
    
    # Instalar fzf-zsh-plugin mediante git
    if [ -n "$SUDO_USER" ]; then
      FZF_PLUGIN_DIR="$REAL_HOME/.fzf"
      if [ ! -d "$FZF_PLUGIN_DIR" ]; then
        su - $REAL_USER -c "git clone --depth 1 https://github.com/junegunn/fzf.git $FZF_PLUGIN_DIR"
        su - $REAL_USER -c "$FZF_PLUGIN_DIR/install --key-bindings --completion --no-update-rc"
      fi
    else
      FZF_PLUGIN_DIR="$HOME/.fzf"
      if [ ! -d "$FZF_PLUGIN_DIR" ]; then
        git clone --depth 1 https://github.com/junegunn/fzf.git "$FZF_PLUGIN_DIR"
        "$FZF_PLUGIN_DIR/install" --key-bindings --completion --no-update-rc
      fi
    fi

    # Añadir configuración a .zshrc si no está ya
    ZSHRC_FILE="$REAL_HOME/.zshrc"
    if [ ! -n "$SUDO_USER" ]; then
      ZSHRC_FILE="$HOME/.zshrc"
    fi

    if [ -f "$ZSHRC_FILE" ] && ! grep -q "source ~/.fzf.zsh" "$ZSHRC_FILE"; then
      echo -e "\n# fzf configuration\n[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh" >> "$ZSHRC_FILE"
      if [ -n "$SUDO_USER" ]; then
        chown $REAL_USER:$(id -gn $REAL_USER) "$ZSHRC_FILE"
      fi
      echo -e "${GREEN}Configuración fzf añadida a .zshrc${NC}"
    else
      echo -e "${GREEN}La configuración fzf ya está presente en .zshrc${NC}"
    fi
  fi

  echo -e "${GREEN}fzf-zsh configurado correctamente${NC}"
}