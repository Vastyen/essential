#!/bin/bash

# Script para convertir un archivo .icns a PNGs y reemplazar los iconos en el Asset Catalog
# Uso: ./convert_icns.sh /ruta/a/tu/icono.icns

if [ -z "$1" ]; then
    echo "❌ Error: Debes proporcionar la ruta al archivo .icns"
    echo "Uso: ./convert_icns.sh /ruta/a/tu/icono.icns"
    exit 1
fi

ICNS_FILE="$1"
ICON_SET_DIR="Essential/Assets.xcassets/AppIcon.appiconset"

if [ ! -f "$ICNS_FILE" ]; then
    echo "❌ Error: No se encontró el archivo: $ICNS_FILE"
    exit 1
fi

if [ ! -d "$ICON_SET_DIR" ]; then
    echo "❌ Error: No se encontró el directorio de iconos: $ICON_SET_DIR"
    exit 1
fi

echo "🎨 Extrayendo imágenes del archivo .icns..."

# Crear directorio temporal
TEMP_DIR=$(mktemp -d)
trap "rm -rf $TEMP_DIR" EXIT

# Extraer el .icns usando iconutil o sips
if command -v iconutil &> /dev/null; then
    # Convertir .icns a .iconset
    iconutil --convert iconset --output "$TEMP_DIR/icon.iconset" "$ICNS_FILE" 2>/dev/null
    
    if [ $? -eq 0 ]; then
        echo "✅ Archivo .icns extraído exitosamente"
        ICONSET_DIR="$TEMP_DIR/icon.iconset"
    else
        echo "⚠️  iconutil falló, intentando con sips..."
        ICONSET_DIR=""
    fi
else
    ICONSET_DIR=""
fi

# Si iconutil no funcionó, usar sips para extraer tamaños específicos
if [ -z "$ICONSET_DIR" ] || [ ! -d "$ICONSET_DIR" ]; then
    echo "📦 Extrayendo tamaños específicos con sips..."
    
    # Tamaños necesarios para macOS
    declare -A SIZES=(
        ["icon_16x16.png"]="16"
        ["icon_16x16@2x.png"]="32"
        ["icon_32x32.png"]="32"
        ["icon_32x32@2x.png"]="64"
        ["icon_128x128.png"]="128"
        ["icon_128x128@2x.png"]="256"
        ["icon_256x256.png"]="256"
        ["icon_256x256@2x.png"]="512"
        ["icon_512x512.png"]="512"
        ["icon_512x512@2x.png"]="1024"
    )
    
    for filename in "${!SIZES[@]}"; do
        size="${SIZES[$filename]}"
        output="$TEMP_DIR/$filename"
        sips -z "$size" "$size" "$ICNS_FILE" --out "$output" 2>/dev/null
        
        if [ -f "$output" ]; then
            echo "  ✅ Generado: $filename ($size x $size)"
        else
            echo "  ⚠️  No se pudo generar: $filename"
        fi
    done
    
    ICONSET_DIR="$TEMP_DIR"
fi

# Copiar archivos al Asset Catalog
echo ""
echo "📋 Copiando iconos al Asset Catalog..."

for filename in icon_16x16.png icon_16x16@2x.png icon_32x32.png icon_32x32@2x.png \
                icon_128x128.png icon_128x128@2x.png icon_256x256.png icon_256x256@2x.png \
                icon_512x512.png icon_512x512@2x.png; do
    if [ -f "$ICONSET_DIR/$filename" ]; then
        cp "$ICONSET_DIR/$filename" "$ICON_SET_DIR/$filename"
        echo "  ✅ Copiado: $filename"
    else
        echo "  ⚠️  No se encontró: $filename"
    fi
done

echo ""
echo "✨ ¡Iconos actualizados exitosamente!"
echo "💡 Nota: Es posible que necesites limpiar el build en Xcode (Product > Clean Build Folder)"
echo "   y reconstruir el proyecto para ver los cambios."

