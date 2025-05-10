#!/bin/bash

# Módulo para la instalación de Starship Prompt

# Instalar Starship
install_starship() {
  # Obtener el usuario real que ejecutó sudo
  REAL_USER=${SUDO_USER:-$USER}
  REAL_HOME=$(getent passwd "$REAL_USER" | cut -d: -f6)

  if should_install "Starship" "command -v starship"; then
    show_header "Instalando Starship prompt"

    # Instalar dependencias necesarias
    dnf install -y curl

    # Comprobar si tenemos una conexión a Internet
    if curl -s --head https://starship.rs > /dev/null; then
      echo -e "${BLUE}Descargando e instalando Starship...${NC}"
      
      # Usar el script de instalación oficial
      if [ -n "$SUDO_USER" ]; then
        # Instalar para el usuario real
        su - $REAL_USER -c "curl -sS https://starship.rs/install.sh | sh -s -- -y"
      else
        # Instalar para el usuario actual
        curl -sS https://starship.rs/install.sh | sh -s -- -y
      fi
      
      # Verificar la instalación
      if command -v starship >/dev/null 2>&1; then
        echo -e "${GREEN}Starship instalado correctamente${NC}"
        
        # Configurar para Zsh si está disponible
        if [ -n "$SUDO_USER" ] && [ -f "$REAL_HOME/.zshrc" ]; then
          if ! grep -q "starship init zsh" "$REAL_HOME/.zshrc"; then
            echo -e "${BLUE}Configurando Starship para Zsh...${NC}"
            echo -e '\n# Inicializar Starship prompt\neval "$(starship init zsh)"' >> "$REAL_HOME/.zshrc"
            chown $REAL_USER:$(id -gn $REAL_USER) "$REAL_HOME/.zshrc"
          fi
        elif [ -f "$HOME/.zshrc" ]; then
          if ! grep -q "starship init zsh" "$HOME/.zshrc"; then
            echo -e "${BLUE}Configurando Starship para Zsh...${NC}"
            echo -e '\n# Inicializar Starship prompt\neval "$(starship init zsh)"' >> "$HOME/.zshrc"
          fi
        fi
        
        # Configurar para Bash si está disponible
        if [ -n "$SUDO_USER" ] && [ -f "$REAL_HOME/.bashrc" ]; then
          if ! grep -q "starship init bash" "$REAL_HOME/.bashrc"; then
            echo -e "${BLUE}Configurando Starship para Bash...${NC}"
            echo -e '\n# Inicializar Starship prompt\neval "$(starship init bash)"' >> "$REAL_HOME/.bashrc"
            chown $REAL_USER:$(id -gn $REAL_USER) "$REAL_HOME/.bashrc"
          fi
        elif [ -f "$HOME/.bashrc" ]; then
          if ! grep -q "starship init bash" "$HOME/.bashrc"; then
            echo -e "${BLUE}Configurando Starship para Bash...${NC}"
            echo -e '\n# Inicializar Starship prompt\neval "$(starship init bash)"' >> "$HOME/.bashrc"
          fi
        fi
        
        # Crear archivo de configuración básico de Starship si no existe
        STARSHIP_CONFIG_DIR="$REAL_HOME/.config"
        if [ -n "$SUDO_USER" ]; then
          if [ ! -d "$STARSHIP_CONFIG_DIR" ]; then
            su - $REAL_USER -c "mkdir -p $STARSHIP_CONFIG_DIR"
          fi
          
          # Solo crear el archivo de configuración si no existe
          if [ ! -f "$STARSHIP_CONFIG_DIR/starship.toml" ]; then
            su - $REAL_USER -c "cat > $STARSHIP_CONFIG_DIR/starship.toml << 'EOF'
# Configuración básica de Starship

# Muestra una línea en blanco entre comandos
add_newline = true

# Reemplaza el símbolo \"❯\" en el prompt con \"➜\"
[character]
success_symbol = \"[➜](bold green)\"
error_symbol = \"[✗](bold red)\"

# Deshabilitar el módulo de paquetes para mejorar rendimiento
[package]
disabled = true

# Personalización del prompt de Git
[git_branch]
format = \"on [$symbol$branch]($style) \"
EOF"
          fi
        else
          if [ ! -d "$HOME/.config" ]; then
            mkdir -p "$HOME/.config"
          fi
          
          # Solo crear el archivo de configuración si no existe
          if [ ! -f "$HOME/.config/starship.toml" ]; then
            cat > "$HOME/.config/starship.toml" << 'EOF'
# Configuración básica de Starship

# Muestra una línea en blanco entre comandos
add_newline = true

# Reemplaza el símbolo \"❯\" en el prompt con \"➜\"
[character]
success_symbol = \"[➜](bold green)\"
error_symbol = \"[✗](bold red)\"

# Deshabilitar el módulo de paquetes para mejorar rendimiento
[package]
disabled = true

# Personalización del prompt de Git
[git_branch]
format = \"on [$symbol$branch]($style) \"
EOF
          fi
        fi
        
        echo -e "${GREEN}Configuración de Starship completada${NC}"
        echo -e "${YELLOW}Puedes personalizar tu prompt editando ~/.config/starship.toml${NC}"
        echo -e "${YELLOW}Visita https://starship.rs/config/ para ver todas las opciones${NC}"
      else
        echo -e "${RED}Error al instalar Starship${NC}"
      fi
    else
      echo -e "${RED}No se pudo conectar al servidor de descarga de Starship${NC}"
    fi
  else
    echo -e "${GREEN}Starship ya está instalado. Omitiendo instalación${NC}"
  fi
}