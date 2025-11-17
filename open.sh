#!/bin/bash

echo "🔨 Abriendo proyecto en Xcode..."

# Intentar abrir con Xcode explícitamente
if open -a Xcode ClaudeUsageTracker.xcodeproj 2>/dev/null; then
    echo ""
    echo "✅ Proyecto abierto en Xcode"
    echo ""
    echo "Para ejecutar la aplicación:"
    echo "  1. Presiona Cmd + R en Xcode"
    echo "  2. O haz clic en el botón ▶️ Play"
    echo ""
    echo "La aplicación aparecerá en tu barra de menú"
else
    echo ""
    echo "❌ ERROR: Xcode no está instalado"
    echo ""
    echo "Para instalar Xcode:"
    echo "  1. Abre la App Store"
    echo "  2. Busca 'Xcode'"
    echo "  3. Haz clic en Obtener/Instalar (gratis, ~15 GB)"
    echo ""
    echo "O instala las herramientas de línea de comandos:"
    echo "  xcode-select --install"
    echo ""
    exit 1
fi
