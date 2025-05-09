#!/bin/bash

# Módulo para la instalación de Flatpak y Zen Browser

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