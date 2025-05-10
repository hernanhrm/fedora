#!/bin/bash

# Módulo para la instalación de Docker en Fedora
# Usa el script de conveniencia oficial de Docker

# Instalar Docker Engine
install_docker() {
  # Obtener el usuario real que ejecutó sudo
  REAL_USER=${SUDO_USER:-$USER}
  REAL_HOME=$(getent passwd "$REAL_USER" | cut -d: -f6)

  if should_install "Docker" "command -v docker"; then
    show_header "Instalando Docker Engine"

    # Paso 1: Eliminar versiones antiguas que pudieran causar conflictos
    show_header "Eliminando versiones antiguas de Docker (si existen)"
    dnf remove -y docker \
      docker-client \
      docker-client-latest \
      docker-common \
      docker-latest \
      docker-latest-logrotate \
      docker-logrotate \
      docker-selinux \
      docker-engine-selinux \
      docker-engine

    # Opción 1: Método oficial según la documentación
    show_header "Instalando Docker mediante método oficial"
    # Instalar dependencias
    dnf -y install dnf-plugins-core

    # Configurar el repositorio de Docker
    dnf config-manager --add-repo https://download.docker.com/linux/fedora/docker-ce.repo

    # Instalar Docker Engine y componentes relacionados
    dnf -y install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
    
    # Si falla el método oficial, intentamos con el script de conveniencia
    if [ $? -ne 0 ]; then
      show_header "Intentando instalación alternativa con script de conveniencia"
      curl -fsSL https://get.docker.com -o get-docker.sh
      sh get-docker.sh
      rm get-docker.sh
    fi

    # Iniciar y habilitar Docker para que se inicie automáticamente
    show_header "Iniciando y habilitando servicio Docker"
    systemctl enable --now docker

    # Verificar que el grupo docker existe (si no, la instalación probablemente falló)
    if getent group docker >/dev/null; then
      # Añadir el usuario al grupo docker para poder ejecutar Docker sin sudo
      if [ -n "$SUDO_USER" ]; then
        echo -e "${BLUE}Añadiendo usuario $REAL_USER al grupo docker${NC}"
        usermod -aG docker $REAL_USER
        echo -e "${GREEN}Usuario $REAL_USER añadido al grupo docker${NC}"
        echo -e "${YELLOW}Necesitarás cerrar sesión y volver a iniciarla, o ejecutar 'newgrp docker', para aplicar los cambios de grupo${NC}"
      fi
    else
      echo -e "${RED}No se encontró el grupo 'docker'. Es posible que la instalación haya fallado.${NC}"
    fi

    # Verificar que Docker funciona correctamente
    if command -v docker >/dev/null 2>&1; then
      show_header "Verificando la instalación"
      docker run --rm hello-world && echo -e "${GREEN}Docker instalado correctamente${NC}" || echo -e "${RED}La verificación de Docker falló. Puede requerir un reinicio del sistema o ejecutar manualmente: sudo systemctl start docker${NC}"
    else
      echo -e "${RED}No se pudo instalar Docker correctamente. Intenta reiniciar el sistema.${NC}"
    fi
  else
    echo -e "${GREEN}Docker ya está instalado. Omitiendo instalación${NC}"
    
    # Verificar si el usuario está en el grupo docker
    if getent group docker >/dev/null && ! groups $REAL_USER | grep -q docker; then
      echo -e "${YELLOW}El usuario $REAL_USER no está en el grupo docker. Añadiendo...${NC}"
      usermod -aG docker $REAL_USER
      echo -e "${GREEN}Usuario $REAL_USER añadido al grupo docker${NC}"
      echo -e "${YELLOW}Necesitarás cerrar sesión y volver a iniciarla, o ejecutar 'newgrp docker', para aplicar los cambios de grupo${NC}"
    fi
  fi
}