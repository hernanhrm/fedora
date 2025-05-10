#!/bin/bash

# Módulo para la instalación de Nerd Fonts

# Instalar Nerd Fonts
install_nerdfonts() {
  # Obtener el usuario real que ejecutó sudo
  REAL_USER=${SUDO_USER:-$USER}
  REAL_HOME=$(getent passwd "$REAL_USER" | cut -d: -f6)

  show_header "Instalando Nerd Fonts"

  # Crear directorio para las fuentes si no existe
  FONT_DIR="$REAL_HOME/.local/share/fonts"
  if [ ! -d "$FONT_DIR" ]; then
    if [ -n "$SUDO_USER" ]; then
      su - $REAL_USER -c "mkdir -p $FONT_DIR"
    else
      mkdir -p "$FONT_DIR"
    fi
  fi

  # Lista de fuentes populares de Nerd Fonts para instalar
  # Aquí puedes modificar esta lista según tus preferencias
  FONTS=(
    "JetBrainsMono"
    "Hack"
    "FiraCode"
    "Meslo"
  )

  # Preguntar al usuario qué fuente quiere instalar
  echo -e "${YELLOW}Selecciona la fuente Nerd Font a instalar:${NC}"
  echo -e "${BLUE}0) Todas${NC}"
  for i in "${!FONTS[@]}"; do
    echo -e "${BLUE}$((i+1))) ${FONTS[$i]}${NC}"
  done
  echo -e "${BLUE}$((${#FONTS[@]}+1))) Ninguna / Salir${NC}"

  read -r FONT_SELECTION

  # Verificar la selección
  if [[ "$FONT_SELECTION" == "0" ]]; then
    SELECTED_FONTS=("${FONTS[@]}")
    echo -e "${GREEN}Instalando todas las fuentes disponibles${NC}"
  elif [[ "$FONT_SELECTION" -gt 0 && "$FONT_SELECTION" -le "${#FONTS[@]}" ]]; then
    SELECTED_FONTS=("${FONTS[$((FONT_SELECTION-1))]}")
    echo -e "${GREEN}Instalando ${SELECTED_FONTS[0]} Nerd Font${NC}"
  else
    echo -e "${YELLOW}No se instalará ninguna fuente${NC}"
    return 0
  fi

  # Instalar las dependencias necesarias
  dnf install -y curl unzip wget

  # Directorio temporal para descargas
  TMP_DIR="/tmp/nerdfonts"
  mkdir -p "$TMP_DIR"

  # Descargar e instalar las fuentes seleccionadas
  for font in "${SELECTED_FONTS[@]}"; do
    echo -e "${BLUE}Descargando $font Nerd Font...${NC}"
    
    # Usar la última versión disponible de las Nerd Fonts
    FONT_URL="https://github.com/ryanoasis/nerd-fonts/releases/latest/download/$font.zip"
    
    # Descargar la fuente
    wget -q --show-progress -O "$TMP_DIR/$font.zip" "$FONT_URL"
    
    if [ $? -eq 0 ]; then
      echo -e "${GREEN}Descarga completada. Instalando...${NC}"
      
      # Extraer la fuente en el directorio de fuentes del usuario
      if [ -n "$SUDO_USER" ]; then
        su - $REAL_USER -c "unzip -o '$TMP_DIR/$font.zip' -d '$FONT_DIR/$font/' -x '*Windows*' '*Powershell*' '*.md' '*LICENSE*' '*.txt'"
      else
        unzip -o "$TMP_DIR/$font.zip" -d "$FONT_DIR/$font/" -x "*Windows*" "*Powershell*" "*.md" "*LICENSE*" "*.txt"
      fi
      
      echo -e "${GREEN}$font Nerd Font instalada correctamente${NC}"
    else
      echo -e "${RED}Error descargando $font Nerd Font${NC}"
    fi
  done

  # Limpiar archivos temporales
  rm -rf "$TMP_DIR"

  # Actualizar la caché de fuentes
  if [ -n "$SUDO_USER" ]; then
    su - $REAL_USER -c "fc-cache -fv"
  else
    fc-cache -fv
  fi

  echo -e "${GREEN}Instalación de Nerd Fonts completada${NC}"
  echo -e "${YELLOW}Recuerda configurar tu terminal para usar las nuevas fuentes${NC}"
  echo -e "${BLUE}Ejemplo: JetBrainsMono Nerd Font, FiraCode Nerd Font, etc.${NC}"
}