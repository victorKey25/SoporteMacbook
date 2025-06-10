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
        .critical { color: #e74c3c; }
        .warning { color: #f39c12; }
        pre { background: #f0f0f0; padding: 10px; border-radius: 5px; overflow-x: auto; }
    </style>
</head>
<body>
    <h1>🔍 Diagnóstico Técnico Completo - $(hostname)</h1>
    <p>Generado: $(date)</p>
    
    <!-- Sistema -->
    <div class="card">
        <h2>🖥️ Sistema</h2>
        <table>
            <tr><th>Modelo:</th><td>$(sysctl -n hw.model)</td></tr>
            <tr><th>macOS:</th><td>$(sw_vers -productVersion) (Build $(sw_vers -buildVersion))</td></tr>
            <tr><th>Arquitectura:</th><td>$(uname -m)</td></tr>
            <tr><th>CPU:</th><td>$(sysctl -n machdep.cpu.brand_string)</td></tr>
            <tr><th>Núcleos:</th><td>$(sysctl -n hw.ncpu)</td></tr>
            <tr><th>Uptime:</th><td>$(uptime | awk -F'( |,|:)+' '{print $6"h "$7"m"}')</td></tr>
        </table>
    </div>

    <!-- Memoria -->
    <div class="card">
        <h2>🧠 Memoria</h2>
        <table>
            <tr><th>Total RAM:</th><td>$(sysctl -n hw.memsize | awk '{print $0/1073741824" GB"}')</td></tr>
            <tr><th>Uso Actual:</th><td>$(top -l 1 | grep -E "^PhysMem" | awk '{print "Used: "$2", Free: "$6}')</td></tr>
            <tr><th>Swap:</th><td>$(sysctl vm.swapusage | awk '{print $3" used, "$7" free"}')</td></tr>
        </table>
        <h3>Top Procesos (RAM):</h3>
        <pre>$(ps -ercmo %mem,pid,command | head -6)</pre>
    </div>

    <!-- Almacenamiento -->
    <div class="card">
        <h2>💾 Almacenamiento</h2>
        <table>
            <tr><th>Disco Principal:</th><td>$(df -h / | tail -1 | awk '{print $4 " libres de " $2 " ("$5" usado)"}')</td></tr>
        </table>
        <h3>Archivos Más Grandes (Top 10):</h3>
        <pre>$(find ~ -type f -exec du -h {} + 2>/dev/null | sort -rh | head -10)</pre>
    </div>

    <!-- Batería -->
EOH

if system_profiler SPPowerDataType | grep -q "Battery Information"; then
    BATTERY_INFO=$(system_profiler SPPowerDataType | awk -F': ' '
        /Cycle Count/ {cycles=$2}
        /Condition/ {condition=$2}
        /Maximum Capacity/ {capacity=$2}
        END {print cycles, capacity, condition}')
    
    echo "<div class='card'><h2>🔋 Batería</h2><table>" >> "$HTML_REPORT"
    echo "<tr><th>Ciclos:</th><td>$(echo $BATTERY_INFO | awk '{print $1}')</td></tr>" >> "$HTML_REPORT"
    echo "<tr><th>Capacidad Máxima:</th><td>$(echo $BATTERY_INFO | awk '{print $2}')</td></tr>" >> "$HTML_REPORT"
    
    BATTERY_CONDITION=$(echo $BATTERY_INFO | awk '{print $3}')
    if [[ "$BATTERY_CONDITION" == "Normal" ]]; then
        echo "<tr><th>Estado:</th><td>$BATTERY_CONDITION ✅</td></tr>" >> "$HTML_REPORT"
    else
        echo "<tr><th>Estado:</th><td class='warning'>$BATTERY_CONDITION ⚠️</td></tr>" >> "$HTML_REPORT"
    fi
    echo "</table></div>" >> "$HTML_REPORT"
fi

# Red
cat >> "$HTML_REPORT" << EOH
    <div class="card">
        <h2>🌐 Red</h2>
        <table>
            <tr><th>IP Pública:</th><td>$(curl -s ifconfig.me)</td></tr>
            <tr><th>DNS:</th><td>$(scutil --dns | grep nameserver | awk '{print $3}' | uniq | tr '\n' ' ')</td></tr>
        </table>
    </div>

    <!-- Seguridad y Errores -->
    <div class="card">
        <h2>🛡️ Seguridad y Errores</h2>
        <h3>Procesos Sospechosos:</h3>
        <pre>$(ps aux | grep -E 'cryptominer|malware|coinminer' || echo "No se encontraron amenazas evidentes")</pre>

        <h3>Extensiones Kernel no Apple:</h3>
        <pre>$(kextstat | grep -v com.apple)</pre>

        <h3>Últimos Errores (15 min):</h3>
        <pre>$(log show --last 15m --predicate 'eventMessage contains "error"' --style syslog | tail -n 30)</pre>
    </div>

    <!-- Aplicaciones Instaladas -->
    <div class="card">
        <h2>📦 Aplicaciones Instaladas</h2>
        <pre>$(ls -lt /Applications | awk '{print $6, $7, $8, $9}' | tail -n +2)</pre>
    </div>

    <!-- Periféricos -->
    <div class="card">
        <h2>📡 Periféricos Conocidos</h2>
        <h3>Bluetooth:</h3>
        <pre>$(system_profiler SPBluetoothDataType | grep -E 'Connected:|Name:|Manufacturer:')</pre>
        <h3>USB:</h3>
        <pre>$(system_profiler SPUSBDataType)</pre>
    </div>

    <!-- Recomendaciones -->
    <div class="card">
        <h2>🔧 Recomendaciones Técnicas</h2>
        <ul>
            <li>Verifica espacio en disco: <code>sudo ncdu /</code></li>
            <li>Monitor en tiempo real: <code>htop</code> (requiere Homebrew)</li>
            <li>Ver logs del sistema: <code>log show --last 1h</code></li>
            <li>Test de velocidad de red: <code>networkQuality</code></li>
        </ul>
    </div>
</body>
</html>
EOH

# Finalización
open "$HTML_REPORT"
echo "✅ Reporte generado: $HTML_REPORT"
