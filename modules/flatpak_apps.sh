#!/bin/bash

# Módulo para la instalación de aplicaciones Flatpak

# Instalar aplicaciones Flatpak
install_flatpak_apps() {
  # Obtener el usuario real que ejecutó sudo
  REAL_USER=${SUDO_USER:-$USER}
  
  show_header "Instalando aplicaciones Flatpak"

  # Verificar que Flatpak esté instalado
  if ! command -v flatpak >/dev/null 2>&1; then
    echo -e "${YELLOW}Flatpak no está instalado. Instalando...${NC}"
    dnf install -y flatpak
  fi
    
  # Configurar repositorio Flathub si no está configurado (sistema)
  if ! flatpak remotes | grep -q "flathub"; then
    flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
  fi
  
  # Configurar repositorio Flathub para el usuario si estamos usando sudo
  if [ -n "$SUDO_USER" ]; then
    if ! su - $REAL_USER -c "flatpak remotes --user | grep -q flathub"; then
      su - $REAL_USER -c "flatpak remote-add --user --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo"
    fi
  fi

  # Lista de aplicaciones Flatpak a instalar con sus IDs
  declare -A FLATPAK_APPS=(
    ["Bruno"]="com.usebruno.Bruno"
    ["Postman"]="com.getpostman.Postman"
  )

  # Iterar sobre el array asociativo e instalar cada aplicación
  for app_name in "${!FLATPAK_APPS[@]}"; do
    app_id="${FLATPAK_APPS[$app_name]}"
    
    # Verificar si la aplicación ya está instalada (sistema o usuario)
  if flatpak list | grep -q "$app_id" || flatpak list --user | grep -q "$app_id"; then
      if [ "$FORCE" = true ]; then
        echo -e "${YELLOW}$app_name ya está instalado, pero será reinstalado (modo forzado)${NC}"
        # Reinstalar la aplicación
        if [ -n "$SUDO_USER" ]; then
          echo -e "${BLUE}Reinstalando $app_name para el usuario $REAL_USER...${NC}"
          su - $REAL_USER -c "flatpak install --user -y --reinstall flathub $app_id"
        else
          echo -e "${BLUE}Reinstalando $app_name...${NC}"
          flatpak install -y --reinstall flathub $app_id
        fi
      else
        echo -e "${GREEN}$app_name ya está instalado. Omitiendo instalación${NC}"
      fi
    else
      echo -e "${BLUE}Instalando $app_name...${NC}"
      
      # Instalar la aplicación
      if [ -n "$SUDO_USER" ]; then
        # Asegurarse de que el usuario tenga permisos
        usermod -aG flatpak $REAL_USER 2>/dev/null || true
        echo -e "${BLUE}Instalando $app_name para el usuario $REAL_USER...${NC}"
        su - $REAL_USER -c "flatpak install --user -y flathub $app_id"
      else
        echo -e "${BLUE}Instalando $app_name...${NC}"
        flatpak install -y flathub $app_id
      fi
      
      # Verificar si la instalación fue exitosa (sistema o usuario)
      if flatpak list | grep -q "$app_id" || flatpak list --user | grep -q "$app_id"; then
        echo -e "${GREEN}$app_name instalado correctamente${NC}"
      else
        echo -e "${RED}Error al instalar $app_name${NC}"
      fi
    fi
  done

  echo -e "${GREEN}Instalación de aplicaciones Flatpak completada${NC}"
  echo -e "${BLUE}Las aplicaciones instaladas estarán disponibles en el menú de aplicaciones${NC}"
}