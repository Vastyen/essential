#!/bin/bash

# Script simple para construir Essential.app
# Uso: ./build_simple.sh

set -e

PROJECT_NAME="Essential"
SCHEME_NAME="Essential"
PRODUCT_NAME="Essential"

echo "🚀 Construyendo ${PRODUCT_NAME}..."
echo ""

# Directorio de salida
OUTPUT_DIR="$(pwd)/build_output"
rm -rf "${OUTPUT_DIR}"
mkdir -p "${OUTPUT_DIR}"

# Construir la app (método más simple)
echo "🔨 Construyendo la aplicación..."
xcodebuild clean build \
    -project "${PROJECT_NAME}.xcodeproj" \
    -scheme "${SCHEME_NAME}" \
    -configuration Release \
    -derivedDataPath "${OUTPUT_DIR}/DerivedData" \
    CODE_SIGN_IDENTITY="-" \
    CODE_SIGNING_REQUIRED=NO \
    CODE_SIGNING_ALLOWED=NO

# Buscar la app construida
APP_PATH=$(find "${OUTPUT_DIR}/DerivedData" -name "${PRODUCT_NAME}.app" -type d | head -1)

if [ -z "${APP_PATH}" ]; then
    echo "❌ Error: No se encontró ${PRODUCT_NAME}.app"
    echo "💡 Intenta construir desde Xcode: Product → Build (⌘B)"
    exit 1
fi

# Copiar la app al directorio de salida
echo "📦 Copiando aplicación..."
cp -R "${APP_PATH}" "${OUTPUT_DIR}/${PRODUCT_NAME}.app"

echo ""
echo "✅ ¡Build completado!"
echo ""
echo "📦 App construida: ${OUTPUT_DIR}/${PRODUCT_NAME}.app"
echo ""
echo "💡 Para probar la app:"
echo "   open \"${OUTPUT_DIR}/${PRODUCT_NAME}.app\""

