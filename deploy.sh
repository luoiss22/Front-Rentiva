#!/bin/bash
# Deploy del frontend Rentiva — córrelo desde tu máquina Windows en Git Bash
# Uso: bash deploy.sh

VPS="root@23.94.202.152"

echo ">>> Compilando Flutter web..."
flutter build web --release

echo ">>> Subiendo al VPS..."
scp -r build/web/* $VPS:/var/www/rentiva/frontend/

echo ">>> Listo. Frontend en http://23.94.202.152:8080"
