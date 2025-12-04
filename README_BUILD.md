# 📦 Guía para Construir y Distribuir Essential

Esta guía te ayudará a crear un archivo `.app` y un `.dmg` para distribuir Essential.

## Opción 1: Construir desde Xcode (Más Fácil)

1. Abre el proyecto en Xcode
2. Selecciona el esquema **Essential** y la configuración **Release**
3. Ve a: **Product → Build** (⌘B)
4. Una vez construido, la app estará en:
   ```
   ~/Library/Developer/Xcode/DerivedData/Essential-*/Build/Products/Release/Essential.app
   ```

## Opción 2: Construir con Script Simple

Ejecuta el script `build_simple.sh`:

```bash
./build_simple.sh
```

Esto construirá la app y la copiará a `build_output/Essential.app`.

## Opción 3: Construir App + DMG Automáticamente

Ejecuta el script `build_release.sh`:

```bash
./build_release.sh
```

Este script:
- Construye la aplicación
- Crea un directorio `release/` con la app
- Genera un DMG listo para distribución

## Crear DMG desde una App Existente

Si ya tienes una app construida, puedes crear un DMG con:

```bash
./create_dmg.sh [ruta a Essential.app]
```

Ejemplo:
```bash
./create_dmg.sh ~/Desktop/Essential.app
```

## Estructura de Archivos Generados

```
release/
├── Essential.app          # La aplicación
└── Essential-1.0.dmg      # DMG para distribución
```

## Notas Importantes

1. **Firma de Código**: Los scripts deshabilitan la firma de código. Si necesitas firmar la app:
   - Configura tu certificado de desarrollador en Xcode
   - Elimina las opciones `CODE_SIGN_IDENTITY="-"` de los scripts

2. **Sandbox**: La app tiene el sandbox habilitado. Asegúrate de tener todos los permisos necesarios configurados.

3. **Versión**: Actualiza la versión en el proyecto de Xcode antes de construir para distribución.

## Solución de Problemas

### "No se encontró Essential.app"
- Asegúrate de que el proyecto se haya construido correctamente
- Verifica que el nombre del esquema sea "Essential"
- Intenta construir desde Xcode primero

### Error al crear DMG
- Verifica que tengas espacio en disco
- Asegúrate de que la app esté completamente construida antes de crear el DMG

### La app no se ejecuta
- Verifica los permisos: `chmod +x Essential.app/Contents/MacOS/Essential`
- Asegúrate de que todas las dependencias estén incluidas

