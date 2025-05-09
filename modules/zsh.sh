#!/bin/bash

# Módulo para la instalación de Zsh y Oh My Zsh

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
        # Ya está configurado con robbyrussell por defecto, no es necesario cambiarlo
        # sed -i 's/ZSH_THEME="robbyrussell"/ZSH_THEME="agnoster"/' "$REAL_HOME/.zshrc"
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
        # Ya está configurado con robbyrussell por defecto, no es necesario cambiarlo
        # sed -i 's/ZSH_THEME="robbyrussell"/ZSH_THEME="agnoster"/' "$HOME/.zshrc"
        # Agregar plugins útiles
        sed -i 's/plugins=(git)/plugins=(git npm docker golang node sudo)/' "$HOME/.zshrc"
      fi
    fi

    echo -e "${GREEN}Oh My Zsh instalado correctamente con tema robbyrussell y plugins útiles${NC}"
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