# Instrucciones para ver los iconos en Xcode

Los iconos están generados y en su lugar, pero Xcode puede no reconocerlos automáticamente.

## Opción 1: Refrescar en Xcode (Recomendado)
1. Abre el proyecto en Xcode
2. Ve a: Essential/Assets.xcassets/AppIcon.appiconset
3. Si no ves los iconos, cierra Xcode completamente
4. Ejecuta: rm -rf ~/Library/Developer/Xcode/DerivedData/*
5. Vuelve a abrir Xcode y el proyecto
6. Los iconos deberían aparecer

## Opción 2: Arrastrar manualmente
1. Abre Xcode y ve a Assets.xcassets > AppIcon
2. Abre Finder y ve a: Essential/Assets.xcassets/AppIcon.appiconset/
3. Arrastra cada icono desde Finder al slot correspondiente en Xcode

## Verificar iconos generados:
