#!/bin/bash

# Módulo para actualizar el sistema Fedora

# Actualizar sistema
update_system() {
  show_header "Actualizando el sistema"
  dnf update -y
}