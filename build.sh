#!/bin/bash

# Costruisce l'app Flutter Web nei server di Vercel (che non hanno Flutter preinstallato)

echo "Scaricando Flutter SDK..."
git clone https://github.com/flutter/flutter.git -b stable --depth 1

export PATH="$PATH:`pwd`/flutter/bin"

echo "Installando dipendenze..."
flutter pub get

echo "Compilando App Web per Produzione..."
flutter build web --release
