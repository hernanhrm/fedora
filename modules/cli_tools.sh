#!/bin/bash

# Módulo para la instalación de herramientas CLI básicas

# Instalar herramientas CLI básicas (fzf, ripgrep, neofetch, xclip, tree, htop, vim)
install_cli_tools() {
  # Obtener el usuario real que ejecutó sudo
  REAL_USER=${SUDO_USER:-$USER}
  REAL_HOME=$(getent passwd "$REAL_USER" | cut -d: -f6)

  show_header "Instalando herramientas CLI básicas"

  # Lista de herramientas CLI para instalar
  CLI_TOOLS=("fzf" "ripgrep" "neofetch" "xclip" "tree" "htop" "vim")
  
  # Instalar cada herramienta si no está ya instalada
  for tool in "${CLI_TOOLS[@]}"; do
    if should_install "$tool" "command -v $tool"; then
      echo -e "${BLUE}Instalando $tool...${NC}"
      dnf install -y $tool
      
      if [ $? -eq 0 ]; then
        echo -e "${GREEN}$tool instalado correctamente${NC}"
      else
        echo -e "${RED}Error instalando $tool${NC}"
      fi
    fi
  done

  # Configurar fzf si está instalado
  if command -v fzf >/dev/null 2>&1; then
    # Si el usuario tiene zsh, configurar fzf para zsh
    if [ -n "$SUDO_USER" ] && [ -f "$REAL_HOME/.zshrc" ]; then
      # Evitar duplicar configuración
      if ! grep -q "FZF_BASE" "$REAL_HOME/.zshrc"; then
        cat >> "$REAL_HOME/.zshrc" << 'EOF'

# fzf configuration
export FZF_DEFAULT_COMMAND='rg --files --no-ignore --hidden --follow --glob "!.git/*" --glob "!node_modules/*" 2> /dev/null'
export FZF_DEFAULT_OPTS='--height 40% --layout=reverse --border'
export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh
EOF
        echo -e "${GREEN}fzf configurado en .zshrc${NC}"
        chown $REAL_USER:$(id -gn $REAL_USER) "$REAL_HOME/.zshrc"
      fi
    elif [ -f "$HOME/.zshrc" ]; then
      # Para el usuario actual usando zsh
      if ! grep -q "FZF_BASE" "$HOME/.zshrc"; then
        cat >> "$HOME/.zshrc" << 'EOF'

# fzf configuration
export FZF_DEFAULT_COMMAND='rg --files --no-ignore --hidden --follow --glob "!.git/*" --glob "!node_modules/*" 2> /dev/null'
export FZF_DEFAULT_OPTS='--height 40% --layout=reverse --border'
export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh
EOF
        echo -e "${GREEN}fzf configurado en .zshrc${NC}"
      fi
    fi
  fi

  # Mostrar instrucciones para neofetch si está instalado
  if command -v neofetch >/dev/null 2>&1; then
    echo -e "${BLUE}Puedes ejecutar 'neofetch' para ver información del sistema de manera elegante${NC}"
    
    # Opcionalmente añadir neofetch al inicio de la sesión de shell
    if [ -n "$SUDO_USER" ] && [ -f "$REAL_HOME/.zshrc" ]; then
      if ! grep -q "neofetch" "$REAL_HOME/.zshrc"; then
        echo -e "${YELLOW}¿Deseas mostrar neofetch al iniciar una nueva terminal? (s/n)${NC}"
        read -r ADD_NEOFETCH
        if [[ "$ADD_NEOFETCH" =~ ^[Ss]$ ]]; then
          echo -e "\n# Mostrar neofetch al inicio\nneofetch" >> "$REAL_HOME/.zshrc"
          chown $REAL_USER:$(id -gn $REAL_USER) "$REAL_HOME/.zshrc"
          echo -e "${GREEN}neofetch añadido al inicio de la terminal${NC}"
        fi
      fi
    fi
  fi

  echo -e "${GREEN}Instalación de herramientas CLI básicas completada${NC}"
}