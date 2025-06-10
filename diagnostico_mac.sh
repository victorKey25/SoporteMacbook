#!/bin/bash

# Configuración
REPORT_DIR="$HOME/Desktop/MacDiagnostic"
HTML_REPORT="$REPORT_DIR/report_$(date +%Y%m%d_%H%M%S).html"
mkdir -p "$REPORT_DIR"

# Función para formatear tamaños
format_size() {
    echo $1 | awk '
        function human(x) {
            s="KB MB GB TB";
            while( x>=1024 && length(s)>1 ) {
                x/=1024;
                s=substr(s,4);
            }
            return sprintf("%.1f %s", x, s);
        }
        {print human($1)}'
}

# Generar encabezado HTML
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
        .critical { color: #e74c3c; }
        .warning { color: #f39c12; }
        pre { background: #f0f0f0; padding: 10px; border-radius: 5px; overflow-x: auto; }
    </style>
</head>
<body>
    <h1>🔍 Diagnóstico Técnico Completo - $(hostname)</h1>
    <p>Generado: $(date)</p>
</body>
</html>
EOH

# Sistema
echo '<div class="card">' >> "$HTML_REPORT"
echo '<h2>🖥️ Sistema</h2><table>' >> "$HTML_REPORT"
echo "<tr><th>Modelo:</th><td>$(sysctl -n hw.model)</td></tr>" >> "$HTML_REPORT"
echo "<tr><th>macOS:</th><td>$(sw_vers -productVersion) (Build $(sw_vers -buildVersion))</td></tr>" >> "$HTML_REPORT"
echo "<tr><th>Arquitectura:</th><td>$(uname -m)</td></tr>" >> "$HTML_REPORT"
echo "<tr><th>CPU:</th><td>$(sysctl -n machdep.cpu.brand_string)</td></tr>" >> "$HTML_REPORT"
echo "<tr><th>Núcleos:</th><td>$(sysctl -n hw.ncpu)</td></tr>" >> "$HTML_REPORT"
echo "<tr><th>Uptime:</th><td>$(uptime | awk -F'( |,|:)+' '{print $6"h "$7"m"}')</td></tr>" >> "$HTML_REPORT"
echo '</table></div>' >> "$HTML_REPORT"

# Memoria
echo '<div class="card">' >> "$HTML_REPORT"
echo '<h2>🧠 Memoria</h2><table>' >> "$HTML_REPORT"
echo "<tr><th>Total RAM:</th><td>$(sysctl -n hw.memsize | awk '{printf \"%.2f GB\", $1/1073741824}') </td></tr>" >> "$HTML_REPORT"
echo "<tr><th>Uso Actual:</th><td>$(top -l 1 | grep -E '^PhysMem' | awk '{print \"Used: \"\$2\", Free: \"\$6}') </td></tr>" >> "$HTML_REPORT"
echo "<tr><th>Swap:</th><td>$(sysctl vm.swapusage | awk '{print $3" used, "$7" free"}') </td></tr>" >> "$HTML_REPORT"
echo '</table>' >> "$HTML_REPORT"
echo '<h3>Top Procesos (RAM):</h3>' >> "$HTML_REPORT"
echo "<pre>$(ps -ercmo %mem,pid,command | head -6)</pre>" >> "$HTML_REPORT"
echo '</div>' >> "$HTML_REPORT"

# Continuar integrando de forma equivalente las secciones siguientes...

# Finalización
open "$HTML_REPORT"
echo "✅ Reporte generado: $HTML_REPORT"
