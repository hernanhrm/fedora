#!/bin/bash

# Definir colores para mejor legibilidad
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Función para verificar si se debe instalar
should_install() {
  local program=$1
  local check_command=$2

  # Obtener el usuario real que ejecutó sudo
  REAL_USER=${SUDO_USER:-$USER}

  # Si se ejecuta como sudo, verificar la instalación como el usuario real
  if [ -n "$SUDO_USER" ]; then
    if su - $REAL_USER -c "$check_command" &>/dev/null; then
      if [ "$FORCE" = true ]; then
        echo -e "${YELLOW}$program ya está instalado para $REAL_USER, pero será reinstalado (modo forzado)${NC}"
        return 0
      else
        echo -e "${GREEN}$program ya está instalado para $REAL_USER. Omitiendo instalación${NC}"
        return 1
      fi
    else
      echo -e "${BLUE}$program no está instalado para $REAL_USER. Instalando...${NC}"
      return 0
    fi
  else
    # Comportamiento normal cuando no se usa sudo
    if eval "$check_command" &>/dev/null; then
      if [ "$FORCE" = true ]; then
        echo -e "${YELLOW}$program ya está instalado, pero será reinstalado (modo forzado)${NC}"
        return 0
      else
        echo -e "${GREEN}$program ya está instalado. Omitiendo instalación${NC}"
        return 1
      fi
    else
      echo -e "${BLUE}$program no está instalado. Instalando...${NC}"
      return 0
    fi
  fi
}

# Función para mostrar cabecera
show_header() {
  echo -e "${BLUE}=== $1 ===${NC}"
}

# Función para mostrar estado de instalación
show_status() {
  local program=$1
  local command=$2
  local run_info=$3

  # Obtener el usuario real que ejecutó sudo
  REAL_USER=${SUDO_USER:-$USER}

  # Si se ejecuta como sudo, verificar la instalación como el usuario real
  if [ -n "$SUDO_USER" ]; then
    if su - $REAL_USER -c "$command" &>/dev/null; then
      VERSION_INFO=""
      if [ -n "$run_info" ]; then
        VERSION_INFO=$(su - $REAL_USER -c "$run_info" 2>/dev/null)
      fi
      echo -e "${GREEN}✓ $program está instalado para $REAL_USER $VERSION_INFO${NC}"
      if [ -n "$run_info" ]; then
        echo "   Ejecutar con: $run_info"
      fi
    else
      echo -e "${RED}✗ $program no está instalado para $REAL_USER${NC}"
    fi
  else
    # Comportamiento normal cuando no se usa sudo
    if eval "$command" &>/dev/null; then
      echo -e "${GREEN}✓ $program está instalado$(eval "$run_info" 2>/dev/null)${NC}"
      if [ -n "$run_info" ]; then
        echo "   Ejecutar con: $run_info"
      fi
    else
      echo -e "${RED}✗ $program no está instalado${NC}"
    fi
  fi
}

# Función para verificar si tenemos derechos de escritura
check_write_permissions() {
  local dir="$1"
  if [ ! -w "$dir" ]; then
    echo -e "${YELLOW}No tienes permisos de escritura en $dir${NC}"
    return 1
  fi
  return 0
}

# Verificar privilegios
check_privileges() {
  # Verificar si se está ejecutando como root/sudo
  if [ "$EUID" -ne 0 ]; then
    echo -e "${RED}Este script necesita privilegios de administrador.${NC}"
    echo -e "${RED}Por favor, ejecútalo con sudo.${NC}"
    echo -e "${YELLOW}Nota: La instalación se realizará para el usuario que ejecuta sudo, no para root.${NC}"
    exit 1
  fi

  # Verificar si tenemos acceso a directorios importantes
  if ! check_write_permissions "/etc/profile.d" 2>/dev/null; then
    echo -e "${YELLOW}Advertencia: No tienes permisos de escritura en /etc/profile.d${NC}"
    echo -e "${YELLOW}Se intentará una solución alternativa para la configuración del sistema${NC}"
  fi

  # Si estamos ejecutando como sudo, guardamos el usuario real para instalaciones específicas
  if [ -n "$SUDO_USER" ]; then
    echo -e "${BLUE}Ejecutando como root para el usuario: ${GREEN}$SUDO_USER${NC}"
  fi
}