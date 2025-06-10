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

# Generar inicio del HTML con bloque de KeysTelecom centrado y texto blanco
cat > "$HTML_REPORT" << EOH
<!DOCTYPE html>
<html>
<head>
    <title>Diagnóstico Mac - $(hostname)</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 20px; background: #fff; color: #333; }
        h1, h2, h3 { color: #333; }
        .header {
            background-color: #222;
            color: white;
            border-radius: 8px;
            padding: 15px;
            text-align: center;
            font-size: 18px;
            margin-bottom: 20px;
            user-select:none;
        }
        .card { background: #f9f9f9; border-radius: 8px; padding: 15px; margin-bottom: 20px; }
        table { width: 100%; border-collapse: collapse; }
        th, td { padding: 8px; text-align: left; border-bottom: 1px solid #ddd; }
        .critical { color: #e74c3c; }
        .warning { color: #f39c12; }
        pre { background: #f0f0f0; padding: 10px; border-radius: 5px; overflow-x: auto; }
        a { color: #1a73e8; text-decoration: none; }
        a:hover { text-decoration: underline; }
    </style>
</head>
<body>
    <div class="header">
        🛰️ <strong>KeysTelecom</strong> - 
        <a href="https://keystelecom.com/" target="_blank" rel="noopener noreferrer">🌐 https://keystelecom.com/</a> | 
        📞 52 5574347924 | 
        ✉️ info@keystelecom.com | 
        📧 victor.keymolen@keystelecom.com
    </div>
    <h1>🔍 Diagnóstico Técnico Completo - $(hostname)</h1>
    <p>Generado: $(date)</p>
EOH

# Información del sistema
cat >> "$HTML_REPORT" << EOH
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
EOH

# Memoria
cat >> "$HTML_REPORT" << EOH
    <div class="card">
        <h2>🧠 Memoria</h2>
        <table>
            <tr><th>Total RAM:</th><td>$(sysctl -n hw.memsize | awk '{printf "%.2f GB\n", $0/1073741824}')</td></tr>
            <tr><th>Uso Actual:</th><td>$(top -l 1 | grep -E "^PhysMem" | awk '{print "Used: "$2", Free: "$6}')</td></tr>
            <tr><th>Swap:</th><td>$(sysctl vm.swapusage | awk '{print $3" used, "$7" free"}')</td></tr>
        </table>
        <h3>Top Procesos (RAM):</h3>
        <pre>$(ps -ercmo %mem,pid,command | head -6)</pre>
    </div>
EOH

# Almacenamiento
cat >> "$HTML_REPORT" << EOH
    <div class="card">
        <h2>💾 Almacenamiento</h2>
        <table>
            <tr><th>Disco Principal:</th><td>$(df -h / | tail -1 | awk '{print $4 " libres de " $2 " ("$5" usado)"}')</td></tr>
        </table>
        <h3>Archivos Más Grandes (Top 10):</h3>
        <pre>$(find ~ -type f -exec du -h {} + 2>/dev/null | sort -rh | head -10)</pre>
    </div>
EOH

# Batería
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
        <h3>Recomendación:</h3>
        <p>Ejecuta manualmente: <code>networkQuality</code> para test de velocidad avanzado</p>
    </div>
EOH

# Apps instaladas + último uso (si disponible)
INSTALLED_APPS=$(mdfind "kMDItemKind == 'Application'" | while read -r app; do
    name=$(basename "$app")
    last_open=$(mdls -name kMDItemLastUsedDate "$app" | awk -F'= ' '{print $2}')
    echo "$name - Último uso: $last_open"
done)

cat >> "$HTML_REPORT" << EOH
    <div class="card">
        <h2>📦 Aplicaciones Instaladas</h2>
        <pre>$INSTALLED_APPS</pre>
    </div>
EOH

# 🛡️ Procesos Sospechosos (malware básico)
cat >> "$HTML_REPORT" << EOH
    <div class="card">
        <h2>🛡️ Procesos Sospechosos</h2>
        <pre>$(ps aux | grep -E 'cryptominer|malware|coinminer' | grep -v grep || echo "No se encontraron amenazas evidentes")</pre>
    </div>
EOH

# 🧩 Extensiones Kernel no Apple
cat >> "$HTML_REPORT" << EOH
    <div class="card">
        <h2>🧩 Extensiones Kernel</h2>
        <pre>$(kextstat | grep -v com.apple)</pre>
    </div>
EOH

# ⚠️ Últimos errores del sistema (15 minutos)
cat >> "$HTML_REPORT" << EOH
    <div class="card">
        <h2>⚠️ Últimos Errores (15 min)</h2>
        <pre>$(log show --last 15m --predicate 'eventMessage contains "error"' --style syslog)</pre>
    </div>
EOH

# Dispositivos Bluetooth emparejados o conectados
BT_DEVICES=$(system_profiler SPBluetoothDataType | awk '/Connected: Yes|Paired: Yes/ {print $0}')
cat >> "$HTML_REPORT" << EOH
    <div class="card">
        <h2>🔵 Dispositivos Bluetooth Conocidos</h2>
        <pre>${BT_DEVICES:-No se detectaron dispositivos Bluetooth conectados o emparejados}</pre>
    </div>
EOH

# Dispositivos USB conectados
USB_DEVICES=$(system_profiler SPUSBDataType)
cat >> "$HTML_REPORT" << EOH
    <div class="card">
        <h2>🔌 Dispositivos USB Conectados</h2>
        <pre>$USB_DEVICES</pre>
    </div>
EOH

# Recomendaciones técnicas con contacto KeysTelecom
cat >> "$HTML_REPORT" << EOH
    <div class="card">
        <h2>🔧 Recomendaciones Técnicas</h2>
        <ul>
            <li>Verificar espacio en disco: <code>sudo ncdu /</code></li>
            <li>Monitor en tiempo real: <code>htop</code> (instalar via Homebrew)</li>
            <li>Ver logs del sistema: <code>log show --last 1h</code></li>
            <li>Para soporte, contacta a:</li>
        </ul>
        <p>🌐 <a href="https://keystelecom.com/" target="_blank" rel="noopener noreferrer">https://keystelecom.com/</a> | 📞 52 5574347924 | ✉️ info@keystelecom.com | 📧 victor.keymolen@keystelecom.com</p>
    </div>
</body>
</html>
EOH

echo "Reporte generado en: $HTML_REPORT"



