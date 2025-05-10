#!/bin/bash

# Script de instalación y configuración para Fedora
# Modularizado por aplicación: Zen Browser (Flatpak), Zed editor, Golang, Node.js LTS, pnpm y Zsh con Oh My Zsh

# Modo force (sobrescribir)
FORCE=false

# Arrays para los módulos disponibles y seleccionados
declare -A MODULES_AVAILABLE
declare -A MODULES_SELECTED

# Inicializar todos los módulos disponibles (desactivados por defecto)
MODULES_AVAILABLE["update"]=false        # Actualización del sistema
MODULES_AVAILABLE["flatpak"]=false       # Flatpak base
MODULES_AVAILABLE["zen"]=false           # Zen Browser (Flatpak)
MODULES_AVAILABLE["zed"]=false           # Zed editor
MODULES_AVAILABLE["golang"]=false        # Go language
MODULES_AVAILABLE["nodejs"]=false        # Node.js y npm
MODULES_AVAILABLE["pnpm"]=false          # pnpm
MODULES_AVAILABLE["docker"]=false        # Docker
MODULES_AVAILABLE["flameshot"]=false     # Flameshot
MODULES_AVAILABLE["cli"]=false           # Herramientas CLI
MODULES_AVAILABLE["fzf"]=false           # fzf para zsh
MODULES_AVAILABLE["nerdfonts"]=false     # Nerd Fonts
MODULES_AVAILABLE["ngrok"]=false         # ngrok
MODULES_AVAILABLE["starship"]=false      # Starship
MODULES_AVAILABLE["flatpak_apps"]=false  # Apps de Flatpak
MODULES_AVAILABLE["zsh"]=false           # Zsh con Oh My Zsh
MODULES_AVAILABLE["ssh"]=false           # Configuración SSH
MODULES_AVAILABLE["rofi"]=false          # Rofi
MODULES_AVAILABLE["hyprland"]=false      # Hyprland

# Función para mostrar la ayuda
show_help() {
  echo "Uso: $0 [opciones] [--modulo1] [--modulo2] ..."
  echo ""
  echo "Opciones:"
  echo "  -f, --force         Forzar reinstalación incluso si ya está instalado"
  echo "  -h, --help          Mostrar esta ayuda"
  echo "  -a, --all           Instalar todos los módulos"
  echo ""
  echo "Módulos disponibles:"
  echo "  --update            Actualización del sistema"
  echo "  --flatpak           Instalar Flatpak"
  echo "  --zen               Instalar Zen Browser (Flatpak)"
  echo "  --zed               Instalar Zed editor"
  echo "  --golang            Instalar Go language"
  echo "  --nodejs            Instalar Node.js y npm"
  echo "  --pnpm              Instalar pnpm"
  echo "  --docker            Instalar Docker"
  echo "  --flameshot         Instalar Flameshot"
  echo "  --cli               Instalar herramientas CLI (fzf, ripgrep, etc.)"
  echo "  --fzf               Instalar fzf para zsh"
  echo "  --nerdfonts         Instalar Nerd Fonts"
  echo "  --ngrok             Instalar ngrok"
  echo "  --starship          Instalar Starship prompt"
  echo "  --flatpak-apps      Instalar aplicaciones Flatpak"
  echo "  --zsh               Instalar Zsh con Oh My Zsh"
  echo "  --ssh               Configurar SSH"
  echo "  --rofi              Instalar Rofi"
  echo "  --hyprland          Instalar Hyprland"
  echo ""
  echo "Ejemplos:"
  echo "  $0 --all            Instalar todos los módulos"
  echo "  $0 --zsh --nodejs   Instalar sólo Zsh y Node.js"
  echo "  $0 -f --golang      Forzar reinstalación de Golang"
  exit 0
}

# Función para activar todos los módulos
enable_all_modules() {
  for module in "${!MODULES_AVAILABLE[@]}"; do
    MODULES_AVAILABLE["$module"]=true
  done
}

# Procesar argumentos
while [[ "$#" -gt 0 ]]; do
  case $1 in
    -f|--force) FORCE=true ;;
    -h|--help) show_help ;;
    -a|--all) enable_all_modules ;;
    --update) MODULES_AVAILABLE["update"]=true ;;
    --flatpak) MODULES_AVAILABLE["flatpak"]=true ;;
    --zen) MODULES_AVAILABLE["zen"]=true ;;
    --zed) MODULES_AVAILABLE["zed"]=true ;;
    --golang) MODULES_AVAILABLE["golang"]=true ;;
    --nodejs) MODULES_AVAILABLE["nodejs"]=true ;;
    --pnpm) MODULES_AVAILABLE["pnpm"]=true ;;
    --docker) MODULES_AVAILABLE["docker"]=true ;;
    --flameshot) MODULES_AVAILABLE["flameshot"]=true ;;
    --cli) MODULES_AVAILABLE["cli"]=true ;;
    --fzf) MODULES_AVAILABLE["fzf"]=true ;;
    --nerdfonts) MODULES_AVAILABLE["nerdfonts"]=true ;;
    --ngrok) MODULES_AVAILABLE["ngrok"]=true ;;
    --starship) MODULES_AVAILABLE["starship"]=true ;;
    --flatpak-apps) MODULES_AVAILABLE["flatpak_apps"]=true ;;
    --zsh) MODULES_AVAILABLE["zsh"]=true ;;
    --ssh) MODULES_AVAILABLE["ssh"]=true ;;
    --rofi) MODULES_AVAILABLE["rofi"]=true ;;
    --hyprland) MODULES_AVAILABLE["hyprland"]=true ;;
    *) echo "Opción desconocida: $1"; show_help ;;
  esac
  shift
done

# Si no se especificó ningún módulo, activar todos
if ! grep -q "true" <<< "$(declare -p MODULES_AVAILABLE)"; then
  enable_all_modules
fi

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
source "$MODULES_DIR/rofi.sh"
source "$MODULES_DIR/hyprland.sh"
source "$MODULES_DIR/summary.sh"

# === Ejecución principal ===
main() {
  # Obtener el usuario real que ejecutó sudo
  REAL_USER=${SUDO_USER:-$USER}
  REAL_HOME=$(getent passwd "$REAL_USER" | cut -d: -f6)

  # Construir lista de módulos a instalar para mostrar información
  MODULE_LIST=""
  if [ "${MODULES_AVAILABLE["update"]}" = true ]; then MODULE_LIST="${MODULE_LIST}Actualización del sistema, "; fi
  if [ "${MODULES_AVAILABLE["flatpak"]}" = true ]; then MODULE_LIST="${MODULE_LIST}Flatpak, "; fi
  if [ "${MODULES_AVAILABLE["zen"]}" = true ]; then MODULE_LIST="${MODULE_LIST}Zen Browser, "; fi
  if [ "${MODULES_AVAILABLE["zed"]}" = true ]; then MODULE_LIST="${MODULE_LIST}Zed editor, "; fi
  if [ "${MODULES_AVAILABLE["golang"]}" = true ]; then MODULE_LIST="${MODULE_LIST}Golang, "; fi
  if [ "${MODULES_AVAILABLE["nodejs"]}" = true ]; then MODULE_LIST="${MODULE_LIST}Node.js, "; fi
  if [ "${MODULES_AVAILABLE["pnpm"]}" = true ]; then MODULE_LIST="${MODULE_LIST}pnpm, "; fi
  if [ "${MODULES_AVAILABLE["docker"]}" = true ]; then MODULE_LIST="${MODULE_LIST}Docker, "; fi
  if [ "${MODULES_AVAILABLE["flameshot"]}" = true ]; then MODULE_LIST="${MODULE_LIST}Flameshot, "; fi
  if [ "${MODULES_AVAILABLE["cli"]}" = true ]; then MODULE_LIST="${MODULE_LIST}Herramientas CLI, "; fi
  if [ "${MODULES_AVAILABLE["fzf"]}" = true ]; then MODULE_LIST="${MODULE_LIST}fzf, "; fi
  if [ "${MODULES_AVAILABLE["nerdfonts"]}" = true ]; then MODULE_LIST="${MODULE_LIST}Nerd Fonts, "; fi
  if [ "${MODULES_AVAILABLE["ngrok"]}" = true ]; then MODULE_LIST="${MODULE_LIST}ngrok, "; fi
  if [ "${MODULES_AVAILABLE["starship"]}" = true ]; then MODULE_LIST="${MODULE_LIST}Starship, "; fi
  if [ "${MODULES_AVAILABLE["flatpak_apps"]}" = true ]; then MODULE_LIST="${MODULE_LIST}Apps Flatpak, "; fi
  if [ "${MODULES_AVAILABLE["zsh"]}" = true ]; then MODULE_LIST="${MODULE_LIST}Zsh, "; fi
  if [ "${MODULES_AVAILABLE["ssh"]}" = true ]; then MODULE_LIST="${MODULE_LIST}SSH, "; fi
  if [ "${MODULES_AVAILABLE["rofi"]}" = true ]; then MODULE_LIST="${MODULE_LIST}Rofi, "; fi
  if [ "${MODULES_AVAILABLE["hyprland"]}" = true ]; then MODULE_LIST="${MODULE_LIST}Hyprland, "; fi
  
  # Eliminar la última coma y espacio
  MODULE_LIST=$(echo "$MODULE_LIST" | sed 's/, $//')

  # Mostrar información del script
  show_header "Script de instalación para Fedora"
  echo -e "${BLUE}Se instalarán los siguientes módulos: ${MODULE_LIST}${NC}"

  if [ "$FORCE" = true ]; then
    echo -e "${YELLOW}Modo forzado activado: Se sobrescribirán instalaciones existentes${NC}"
  fi

  if [ -n "$SUDO_USER" ]; then
    echo -e "${YELLOW}Ejecutando como root para el usuario: $REAL_USER${NC}"
    echo -e "${YELLOW}Las aplicaciones se instalarán considerando el perfil de usuario de: $REAL_USER${NC}"
  fi

  if [ "${MODULES_AVAILABLE["zsh"]}" = true ]; then
    echo -e "${YELLOW}Nota: Al instalar Zsh, se configurará como shell predeterminado automáticamente${NC}"
  fi

  # Verificar privilegios
  check_privileges

  # Ejecutar módulos seleccionados
  if [ "${MODULES_AVAILABLE["update"]}" = true ]; then update_system; fi
  if [ "${MODULES_AVAILABLE["flatpak"]}" = true ]; then install_flatpak; fi
  if [ "${MODULES_AVAILABLE["zen"]}" = true ]; then install_zen_browser; fi
  if [ "${MODULES_AVAILABLE["zed"]}" = true ]; then install_zed; fi
  if [ "${MODULES_AVAILABLE["golang"]}" = true ]; then install_golang; fi
  if [ "${MODULES_AVAILABLE["nodejs"]}" = true ]; then install_nodejs; fi
  if [ "${MODULES_AVAILABLE["pnpm"]}" = true ]; then install_pnpm; fi
  if [ "${MODULES_AVAILABLE["docker"]}" = true ]; then install_docker; fi
  if [ "${MODULES_AVAILABLE["flameshot"]}" = true ]; then install_flameshot; fi
  if [ "${MODULES_AVAILABLE["cli"]}" = true ]; then install_cli_tools; fi
  if [ "${MODULES_AVAILABLE["fzf"]}" = true ]; then install_fzf_zsh; fi
  if [ "${MODULES_AVAILABLE["nerdfonts"]}" = true ]; then install_nerdfonts; fi
  if [ "${MODULES_AVAILABLE["ngrok"]}" = true ]; then install_ngrok; fi
  if [ "${MODULES_AVAILABLE["starship"]}" = true ]; then install_starship; fi
  if [ "${MODULES_AVAILABLE["flatpak_apps"]}" = true ]; then install_flatpak_apps; fi
  if [ "${MODULES_AVAILABLE["zsh"]}" = true ]; then install_zsh; fi
  if [ "${MODULES_AVAILABLE["ssh"]}" = true ]; then configure_ssh; fi
  if [ "${MODULES_AVAILABLE["rofi"]}" = true ]; then install_rofi; fi
  if [ "${MODULES_AVAILABLE["hyprland"]}" = true ]; then install_hyprland; fi

  # Mostrar resumen
  show_summary
}

# Iniciar ejecución
main
