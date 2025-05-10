#!/bin/bash

# Función para mostrar resumen de instalación

# Función para verificar si se encuentra instalada una aplicación flatpak
is_flatpak_installed() {
  local app_id=$1
  if [ -n "$SUDO_USER" ]; then
    su - $REAL_USER -c "flatpak list | grep -q '$app_id' || flatpak list --user | grep -q '$app_id'" &>/dev/null
  else
    flatpak list | grep -q "$app_id" || flatpak list --user | grep -q "$app_id" &>/dev/null
  fi
  return $?
}

# Mostrar resumen
show_summary() {
  # Obtener el usuario real que ejecutó sudo
  REAL_USER=${SUDO_USER:-$USER}
  REAL_HOME=$(getent passwd "$REAL_USER" | cut -d: -f6)
  
  # Asegurar que ~/.local/bin esté en PATH para la sesión actual
  export PATH="$REAL_HOME/.local/bin:$PATH"

  show_header "Instalación completada"
  echo -e "${GREEN}Resumen de instalaciones para el usuario: ${YELLOW}$REAL_USER${NC}"

  if [ -n "$SUDO_USER" ]; then
    echo -e "${BLUE}Instalación ejecutada como root para el usuario: ${GREEN}$REAL_USER${NC}"
    echo -e "${YELLOW}Nota: Para verificar correctamente las instalaciones, inicia sesión como: ${GREEN}$REAL_USER${NC}"
  fi

  # Mostrar información sobre las aplicaciones instaladas y configuraciones
  if [ "${MODULES_AVAILABLE["zen"]}" = true ]; then
    show_status "Zen Browser" "flatpak list | grep -q 'app.zen_browser.zen' || flatpak list --user | grep -q 'app.zen_browser.zen'" "flatpak run app.zen_browser.zen"
  fi
  
  # Para Zed, mostramos una información más detallada sobre su ubicación
  if [ "${MODULES_AVAILABLE["zed"]}" = true ]; then
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
  fi
  
  if [ "${MODULES_AVAILABLE["golang"]}" = true ]; then
    show_status "Golang" "command -v go" "go version"
  fi
  
  if [ "${MODULES_AVAILABLE["nodejs"]}" = true ]; then
    show_status "Node.js" "command -v node" "node -v"
    show_status "npm" "command -v npm" "npm -v"
  fi
  
  if [ "${MODULES_AVAILABLE["pnpm"]}" = true ]; then
    show_status "pnpm" "command -v pnpm" "pnpm -v"
  fi
  
  if [ "${MODULES_AVAILABLE["docker"]}" = true ]; then
    show_status "Docker" "command -v docker" "docker --version"
    show_status "Docker Compose" "command -v docker-compose" "docker-compose --version"
  fi
  
  if [ "${MODULES_AVAILABLE["flameshot"]}" = true ]; then
    show_status "Flameshot" "command -v flameshot" "flameshot --version"
  fi
  
  if [ "${MODULES_AVAILABLE["cli"]}" = true ] || [ "${MODULES_AVAILABLE["fzf"]}" = true ]; then
    show_status "fzf" "command -v fzf" "fzf --version"
    show_status "ripgrep" "command -v rg" "rg --version"
    show_status "neofetch" "command -v neofetch" "neofetch --version"
    show_status "xclip" "command -v xclip" "xclip -version"
    show_status "tree" "command -v tree" "tree --version"
    show_status "htop" "command -v htop" "htop --version"
    show_status "vim" "command -v vim" "vim --version | head -n 1"
  fi
  
  if [ "${MODULES_AVAILABLE["ngrok"]}" = true ]; then
    show_status "ngrok" "command -v ngrok &>/dev/null || test -x \"$REAL_HOME/.local/bin/ngrok\"" "$REAL_HOME/.local/bin/ngrok --version 2>/dev/null || ngrok --version 2>/dev/null || echo 'Installed'"
  fi
  
  if [ "${MODULES_AVAILABLE["starship"]}" = true ]; then
    show_status "Starship" "command -v starship" "starship --version"
  fi
  
  if [ "${MODULES_AVAILABLE["flatpak_apps"]}" = true ]; then
    show_status "Bruno (Flatpak)" "flatpak list | grep -q 'com.usebruno.Bruno' || flatpak list --user | grep -q 'com.usebruno.Bruno'" "flatpak info com.usebruno.Bruno 2>/dev/null | grep Version || echo 'Installed'"
    show_status "Postman (Flatpak)" "flatpak list | grep -q 'com.getpostman.Postman' || flatpak list --user | grep -q 'com.getpostman.Postman'" "flatpak info com.getpostman.Postman 2>/dev/null | grep Version || echo 'Installed'"
  fi
  
  if [ "${MODULES_AVAILABLE["zsh"]}" = true ]; then
    show_status "Zsh" "command -v zsh" "zsh"
  fi
  
  if [ "${MODULES_AVAILABLE["rofi"]}" = true ]; then
    show_status "Rofi" "command -v rofi &>/dev/null || test -f /usr/bin/rofi" "rofi -version 2>/dev/null || echo 'Installed'"
  fi
  
  if [ "${MODULES_AVAILABLE["hyprland"]}" = true ]; then
    show_status "Hyprland" "command -v Hyprland &>/dev/null || test -f /usr/bin/Hyprland" "Hyprland -version 2>/dev/null || echo 'Installed'"
  fi

  # Verificar si se ha configurado SSH
  if [ "${MODULES_AVAILABLE["ssh"]}" = true ]; then
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
  fi

  # Verificar si Oh My Zsh está instalado
  if [ "${MODULES_AVAILABLE["zsh"]}" = true ]; then
    if [ -d "$REAL_HOME/.oh-my-zsh" ]; then
      echo -e "${GREEN}✓ Oh My Zsh está instalado${NC}"
      if grep -q 'ZSH_THEME="robbyrussell"' "$REAL_HOME/.zshrc" 2>/dev/null; then
        echo "   Tema: robbyrussell"
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
  fi

  # Mostrar información sobre carga de variables de entorno
  if [ "${MODULES_AVAILABLE["golang"]}" = true ] || [ "${MODULES_AVAILABLE["nodejs"]}" = true ] || [ "${MODULES_AVAILABLE["zsh"]}" = true ]; then
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
        if [ "${MODULES_AVAILABLE["golang"]}" = true ]; then
          echo "$ source /etc/profile.d/go.sh"
        fi
        if [ "${MODULES_AVAILABLE["nodejs"]}" = true ]; then
          echo "$ source /etc/profile.d/nodejs.sh"
        fi
      fi
    else
      # Sin sudo
      if getent passwd $USER | grep -q "$(which zsh)"; then
        echo "Todas las variables de entorno están configuradas en .zshrc y se cargarán automáticamente al iniciar sesión."
        echo "Para cargarlas en esta sesión sin reiniciar: $ source $HOME/.zshrc"
      else
        if [ "${MODULES_AVAILABLE["golang"]}" = true ]; then
          echo "$ source /etc/profile.d/go.sh"
        fi
        if [ "${MODULES_AVAILABLE["nodejs"]}" = true ]; then
          echo "$ source /etc/profile.d/nodejs.sh"
        fi
      fi
    fi
  fi
}