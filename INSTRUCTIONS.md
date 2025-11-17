# Claude Usage Tracker - Instrucciones de Uso

## 🎯 ¿Qué hace esta aplicación?

Esta app nativa de macOS te permite monitorear en tiempo real cuánto estás gastando en Claude directamente desde tu barra de menú.

## 📍 Ubicación del Proyecto

```
~/Documents/PERSONAL/ClaudeUsageTracker/
```

## 📋 Requisitos Previos

- **Xcode** instalado
- macOS 12.0 o superior

### 🏢 Para Macs de Empresa (sin cuenta personal de Apple)

Si estás en un Mac corporativo y no puedes instalar Xcode tú mismo:

**Opción 1: Pedir instalación de Xcode al departamento IT**
- Diles que necesitas Xcode para desarrollo
- Es software oficial de Apple y gratuito
- Lo pueden instalar desde: https://developer.apple.com/xcode/

**Opción 2: Si Xcode ya está en `/Applications/Xcode.app`**
```bash
# Configura el path de Xcode
sudo xcode-select --switch /Applications/Xcode.app
sudo xcodebuild -license accept
```

**Opción 3: Ejecutar sin compilar (limitado)**
- Si solo quieres ver los datos sin interfaz gráfica
- Puedes crear un script Python/Node que lea los archivos `.jsonl`

### 👤 Para Macs Personales

**Desde App Store:**
1. Abre la **App Store**
2. Busca "Xcode" y descárgalo (gratis, ~15 GB)

**Desde Apple Developer (necesitas Apple ID):**
1. Ve a: https://developer.apple.com/download/all/
2. Descarga Xcode `.xip` (~15 GB)
3. Extrae y mueve a `/Applications/`

⚠️ **Nota**: `xcode-select --install` (Command Line Tools) NO es suficiente

## �🚀 Inicio Rápido (3 pasos)

### Paso 1: Abrir el proyecto
```bash
cd ~/Documents/PERSONAL/ClaudeUsageTracker
open -a Xcode ClaudeUsageTracker.xcodeproj
```

### Paso 2: Ejecutar en Xcode
- Presiona `Cmd + R` en Xcode
- O haz clic en el botón ▶️ (Play) en la esquina superior izquierda

### Paso 3: ¡Listo!
- La app aparecerá en tu barra de menú (arriba a la derecha)
- Verás algo como: **💰 $177.83**
- Haz clic para ver los detalles

## 🎨 Capturas de lo que verás

### Barra de Menú
```
💰 $177.83
```
Este es el costo del mes actual (noviembre en tu caso)

### Al hacer clic se abre un panel con:

**Pestaña "Por Mes":**
```
📅 Noviembre 2025          $177.83
   • Input tokens: 90,989 → $0.27
   • Cache creation: 19,863,785 → $74.49
   • Cache read: 302,204,627 → $90.66
   • Output tokens: 826,818 → $12.40

📅 Octubre 2025            $308.54
   • Input tokens: 376,748 → $1.13
   • Cache creation: 31,984,560 → $119.94
   • Cache read: 514,108,692 → $154.23
   • Output tokens: 2,215,467 → $33.23

──────────────────────────────────
TOTAL                      $486.36
```

**Pestaña "Por Proyecto":**
```
📁 PERSONAL deraswap       $245.32
📁 PERSONAL HBANK-PROTOCOL $158.47
📁 Documents dynamic-templates $42.18
📁 PERSONAL ascension      $23.75
... etc
```

## 🔄 Actualización

- **Automática**: Cada 5 minutos
- **Manual**: Botón 🔄 en la esquina superior derecha del panel
- **Última actualización**: Se muestra en la parte inferior

## 🛠️ Compilar para Instalación Permanente

Si quieres que la app se ejecute siempre (incluso al reiniciar):

```bash
cd ~/Documents/PERSONAL/ClaudeUsageTracker
./build.sh

# Copiar a Applications
sudo cp -r ./build/Build/Products/Release/ClaudeUsageTracker.app /Applications/

# Abrir desde Applications
open /Applications/ClaudeUsageTracker.app
```

Luego:
1. Ve a **Preferencias del Sistema** > **Usuarios y Grupos** > **Elementos de Inicio**
2. Agrega **ClaudeUsageTracker** para que inicie automáticamente

## 📊 ¿De dónde lee los datos?

La app lee los archivos de historial de Claude ubicados en:
```
~/.claude/projects/
```

Cada proyecto tiene archivos `.jsonl` con el historial de conversaciones y uso de tokens.

## 🎯 Características Principales

✅ **Monitoreo en Tiempo Real**: Costo del mes actual siempre visible
✅ **Historial Completo**: Todos los meses desde que usas Claude
✅ **Por Proyecto**: Identifica qué proyectos consumen más
✅ **Desglose Detallado**: Tokens por tipo (input, cache, output)
✅ **Cálculo Preciso**: Usa los precios oficiales de Claude 3.5 Sonnet
✅ **Interfaz Nativa**: Diseño macOS con SwiftUI
✅ **Ligera**: No consume recursos, se ejecuta en segundo plano
✅ **Sin Internet**: Lee datos locales, no requiere conexión

## 💡 Próximas Mejoras (Ideas)

- [ ] Gráficos de tendencia mensual
- [ ] Alertas cuando superes un presupuesto
- [ ] Exportar reportes en CSV/PDF
- [ ] Comparación mes a mes
- [ ] Proyección de gasto mensual
- [ ] Dark mode / Light mode automático
- [ ] Notificaciones de alto consumo

## 🐛 Solución de Problemas

**Problema**: No aparece en la barra de menú
- Solución: Verifica que esté corriendo con Activity Monitor

**Problema**: Muestra $0.00
- Solución: Click en 🔄 para actualizar manualmente
- Verifica que exista `~/.claude/projects/`

**Problema**: No tiene permisos
- Solución: En Preferencias del Sistema > Seguridad > Permitir acceso

## 📝 Estructura del Proyecto

```
ClaudeUsageTracker/
├── ClaudeUsageTrackerApp.swift    # Punto de entrada y barra de menú
├── ClaudeUsageManager.swift       # Lógica de lectura y cálculo
├── MainView.swift                 # Interfaz de usuario SwiftUI
├── Assets.xcassets/               # Iconos y recursos
├── ClaudeUsageTracker.entitlements # Permisos de macOS
├── build.sh                       # Script de compilación
├── open.sh                        # Script para abrir en Xcode
└── README.md                      # Documentación
```

## 🎓 Para Desarrolladores

Si quieres modificar la app:

1. **Cambiar colores**: Edita `MainView.swift` → `TokenRow`
2. **Cambiar precios**: Edita `ClaudeUsageManager.swift` → `PRICES`
3. **Cambiar frecuencia de actualización**: Edita `ClaudeUsageTrackerApp.swift` → Timer (300 segundos = 5 minutos)
4. **Agregar nueva vista**: Crea un nuevo `View` en `MainView.swift` y agrégalo al `Picker`

## 💬 Feedback

Si encuentras bugs o tienes ideas de mejora, edita directamente los archivos Swift en Xcode.

---

**¡Disfruta monitoreando tus gastos de Claude!** 💰📊
