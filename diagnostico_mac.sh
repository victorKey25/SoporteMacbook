#!/bin/bash

# Configuración
REPORT_DIR="$HOME/Desktop/MacDiagnostic"
HTML_REPORT="$REPORT_DIR/report_$(date +%Y%m%d_%H%M%S).html"
mkdir -p "$REPORT_DIR"

# Función para obtener último uso de apps
get_last_used() {
    sqlite3 ~/Library/Preferences/com.apple.LaunchServices.QuarantineEventsV2* \
    "SELECT datetime(LSQuarantineTimeStamp + 978307200, 'unixepoch') as date, LSQuarantineAgentName, LSQuarantineOriginURLString \
    FROM LSQuarantineEvent \
    ORDER BY LSQuarantineTimeStamp DESC \
    LIMIT 10" 2>/dev/null | awk -F'|' '{print $1, $2}'
}

# Generar reporte HTML
cat > "$HTML_REPORT" << EOH
<!DOCTYPE html>
<html>
<head>
    <title>Diagnóstico Mac - $(hostname)</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 20px; }
        h1 { color: #333; } 
        .card { background: #f9f9f9; border-radius: 8px; padding: 15px; margin-bottom: 20px; }
        table { width: 100%; border-collapse: collapse; }
        th, td { padding: 8px; text-align: left; border-bottom: 1px solid #ddd; }
        pre { background: #f0f0f0; padding: 10px; border-radius: 5px; }
    </style>
</head>
<body>
    <h1>🔍 Diagnóstico Técnico - $(hostname)</h1>
    <p>Generado: $(date)</p>

    <!-- Sección Programas Instalados -->
    <div class="card">
        <h2>📦 Programas Instalados (Homebrew)</h2>
        <pre>$(brew list --versions || echo "Homebrew no instalado")</pre>
        
        <h2>🖥 Aplicaciones /Applications</h2>
        <pre>$(ls -lh /Applications | awk 'NR<=20 {print $9, $5}')</pre>
    </div>

    <!-- Sección Último Uso -->
    <div class="card">
        <h2>⏳ Últimas Apps Usadas</h2>
        <table>
            $(get_last_used | while read -r date app; do
                echo "<tr><td>$app</td><td>$date</td></tr>"
            done)
        </table>
    </div>

    <!-- [Otras secciones del diagnóstico previo] -->
</body>
</html>
EOH

open "$HTML_REPORT"
echo "✅ Reporte generado: $HTML_REPORT"
