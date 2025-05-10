#!/bin/bash

# Script de instalación y configuración para Fedora
# Modularizado por aplicación: Zen Browser (Flatpak), Zed editor, Golang, Node.js LTS, pnpm y Zsh con Oh My Zsh

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

# Ruta base para los módulos
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
COMMON_DIR="$SCRIPT_DIR/common"
MODULES_DIR="$SCRIPT_DIR/modules"

# Cargar funciones comunes
source "$COMMON_DIR/utils.sh"

# Cargar todos los módulos
source "$MODULES_DIR/system_update.sh"
source "$MODULES_DIR/flatpak.sh"
source "$MODULES_DIR/zed.sh"
source "$MODULES_DIR/golang.sh"
source "$MODULES_DIR/nodejs.sh"
source "$MODULES_DIR/docker.sh"
source "$MODULES_DIR/flameshot.sh"
source "$MODULES_DIR/cli_tools.sh"
source "$MODULES_DIR/fzf_zsh.sh"
source "$MODULES_DIR/nerdfonts.sh"
source "$MODULES_DIR/ngrok.sh"
source "$MODULES_DIR/starship.sh"
source "$MODULES_DIR/flatpak_apps.sh"
source "$MODULES_DIR/zsh.sh"
source "$MODULES_DIR/ssh.sh"
source "$MODULES_DIR/summary.sh"

# === Ejecución principal ===
main() {
  # Obtener el usuario real que ejecutó sudo
  REAL_USER=${SUDO_USER:-$USER}
  REAL_HOME=$(getent passwd "$REAL_USER" | cut -d: -f6)

  # Mostrar información del script
  show_header "Script de instalación para Fedora"
  echo -e "${BLUE}Instalará: Zen Browser, Zed editor, Golang, Node.js LTS, pnpm, Docker, Flameshot, herramientas CLI (fzf, ripgrep, neofetch, xclip, tree, htop, vim), fzf-zsh, Nerd Fonts, ngrok, Starship, Bruno, Postman, Zsh con Oh My Zsh (tema robbyrussell) y configurará SSH para GitHub/GitLab${NC}"

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
  install_docker
  install_flameshot
  install_cli_tools
  install_fzf_zsh
  install_nerdfonts
  install_ngrok
  install_starship
  install_flatpak_apps
  install_zsh
  configure_ssh

  # Mostrar resumen
  show_summary
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