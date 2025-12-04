#!/bin/bash

# Script para construir Essential.app y crear un DMG para distribución
# Uso: ./build_release.sh

set -e

PROJECT_NAME="Essential"
SCHEME_NAME="Essential"
PRODUCT_NAME="Essential"
BUNDLE_ID="open.Essential"
VERSION=$(/usr/libexec/PlistBuddy -c "Print CFBundleShortVersionString" Essential/Info.plist 2>/dev/null || echo "1.0")
BUILD_NUMBER=$(/usr/libexec/PlistBuddy -c "Print CFBundleVersion" Essential/Info.plist 2>/dev/null || echo "1")

# Directorios
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
BUILD_DIR="${SCRIPT_DIR}/build"
RELEASE_DIR="${SCRIPT_DIR}/release"
DMG_DIR="${RELEASE_DIR}/dmg"

echo "🚀 Construyendo ${PRODUCT_NAME} v${VERSION}..."
echo ""

# Limpiar builds anteriores
echo "🧹 Limpiando builds anteriores..."
rm -rf "${BUILD_DIR}"
rm -rf "${RELEASE_DIR}"
mkdir -p "${BUILD_DIR}"
mkdir -p "${RELEASE_DIR}"
mkdir -p "${DMG_DIR}"

# Construir la app
echo "🔨 Construyendo la aplicación..."
xcodebuild clean build \
    -project "${PROJECT_NAME}.xcodeproj" \
    -scheme "${SCHEME_NAME}" \
    -configuration Release \
    -derivedDataPath "${BUILD_DIR}/DerivedData" \
    -archivePath "${BUILD_DIR}/${PRODUCT_NAME}.xcarchive" \
    CODE_SIGN_IDENTITY="-" \
    CODE_SIGNING_REQUIRED=NO \
    CODE_SIGNING_ALLOWED=NO \
    -quiet

# Buscar la app construida
APP_PATH=$(find "${BUILD_DIR}/DerivedData" -name "${PRODUCT_NAME}.app" -type d | head -1)

if [ -z "${APP_PATH}" ]; then
    echo "❌ Error: No se encontró ${PRODUCT_NAME}.app"
    echo "💡 Intentando construcción alternativa..."
    
    # Construcción alternativa sin archivar
    xcodebuild clean build \
        -project "${PROJECT_NAME}.xcodeproj" \
        -scheme "${SCHEME_NAME}" \
        -configuration Release \
        -derivedDataPath "${BUILD_DIR}/DerivedData" \
        CODE_SIGN_IDENTITY="-" \
        CODE_SIGNING_REQUIRED=NO \
        CODE_SIGNING_ALLOWED=NO
    
    APP_PATH=$(find "${BUILD_DIR}/DerivedData" -name "${PRODUCT_NAME}.app" -type d | head -1)
fi

if [ -z "${APP_PATH}" ]; then
    echo "❌ Error: No se pudo construir la aplicación"
    exit 1
fi

echo "✅ App construida: ${APP_PATH}"
echo ""

# Copiar la app al directorio de release
echo "📦 Copiando aplicación al directorio de release..."
cp -R "${APP_PATH}" "${RELEASE_DIR}/${PRODUCT_NAME}.app"

# Verificar que la app existe
if [ ! -d "${RELEASE_DIR}/${PRODUCT_NAME}.app" ]; then
    echo "❌ Error: La aplicación no se copió correctamente"
    exit 1
fi

echo "✅ Aplicación copiada a: ${RELEASE_DIR}/${PRODUCT_NAME}.app"
echo ""

# Crear DMG
echo "💿 Creando DMG..."
DMG_NAME="${PRODUCT_NAME}-${VERSION}.dmg"
DMG_PATH="${RELEASE_DIR}/${DMG_NAME}"

# Limpiar DMG anterior si existe
rm -f "${DMG_PATH}"

# Crear un directorio temporal para el DMG
DMG_TEMP_DIR="${RELEASE_DIR}/dmg_temp"
rm -rf "${DMG_TEMP_DIR}"
mkdir -p "${DMG_TEMP_DIR}"

# Copiar la app al directorio temporal
cp -R "${RELEASE_DIR}/${PRODUCT_NAME}.app" "${DMG_TEMP_DIR}/"

# Crear un enlace simbólico a Applications (opcional, para arrastrar la app)
ln -s /Applications "${DMG_TEMP_DIR}/Applications"

# Crear el DMG usando hdiutil
hdiutil create -volname "${PRODUCT_NAME}" \
    -srcfolder "${DMG_TEMP_DIR}" \
    -ov -format UDZO \
    "${DMG_PATH}"

# Limpiar directorio temporal
rm -rf "${DMG_TEMP_DIR}"

if [ -f "${DMG_PATH}" ]; then
    DMG_SIZE=$(du -h "${DMG_PATH}" | cut -f1)
    echo "✅ DMG creado: ${DMG_PATH} (${DMG_SIZE})"
else
    echo "❌ Error: No se pudo crear el DMG"
    exit 1
fi

echo ""
echo "🎉 ¡Build completado!"
echo ""
echo "📦 Archivos generados:"
echo "   • App: ${RELEASE_DIR}/${PRODUCT_NAME}.app"
echo "   • DMG: ${DMG_PATH}"
echo ""
echo "💡 Puedes encontrar los archivos en: ${RELEASE_DIR}/"

