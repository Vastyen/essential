#!/bin/bash

# Script para crear un DMG desde una app existente
# Uso: ./create_dmg.sh [ruta a Essential.app]

set -e

APP_PATH="${1:-$(pwd)/Essential.app}"

if [ ! -d "${APP_PATH}" ]; then
    echo "❌ Error: No se encontró la aplicación en: ${APP_PATH}"
    echo ""
    echo "Uso: ./create_dmg.sh [ruta a Essential.app]"
    echo "Ejemplo: ./create_dmg.sh ~/Desktop/Essential.app"
    exit 1
fi

PRODUCT_NAME="Essential"
VERSION="1.0"
DMG_NAME="${PRODUCT_NAME}-${VERSION}.dmg"
OUTPUT_DIR="$(pwd)/release"
DMG_PATH="${OUTPUT_DIR}/${DMG_NAME}"

echo "💿 Creando DMG para ${PRODUCT_NAME}..."
echo ""

# Crear directorio de salida
mkdir -p "${OUTPUT_DIR}"

# Limpiar DMG anterior si existe
rm -f "${DMG_PATH}"

# Crear un directorio temporal para el DMG
DMG_TEMP_DIR="${OUTPUT_DIR}/dmg_temp"
rm -rf "${DMG_TEMP_DIR}"
mkdir -p "${DMG_TEMP_DIR}"

# Copiar la app al directorio temporal
echo "📦 Preparando contenido del DMG..."
cp -R "${APP_PATH}" "${DMG_TEMP_DIR}/"

# Crear un enlace simbólico a Applications (para arrastrar la app)
ln -s /Applications "${DMG_TEMP_DIR}/Applications"

# Crear el DMG usando hdiutil
echo "🔨 Creando imagen DMG..."
hdiutil create -volname "${PRODUCT_NAME}" \
    -srcfolder "${DMG_TEMP_DIR}" \
    -ov -format UDZO \
    "${DMG_PATH}"

# Limpiar directorio temporal
rm -rf "${DMG_TEMP_DIR}"

if [ -f "${DMG_PATH}" ]; then
    DMG_SIZE=$(du -h "${DMG_PATH}" | cut -f1)
    echo ""
    echo "✅ DMG creado exitosamente!"
    echo ""
    echo "📦 DMG: ${DMG_PATH} (${DMG_SIZE})"
    echo ""
    echo "💡 Para abrir el DMG:"
    echo "   open \"${DMG_PATH}\""
else
    echo "❌ Error: No se pudo crear el DMG"
    exit 1
fi

