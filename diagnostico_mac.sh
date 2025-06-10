#!/bin/bash

VERSION="1.3"

# Configuración
REPORT_DIR="$HOME/Desktop/MacDiagnostic"
HTML_REPORT="$REPORT_DIR/report_$(date +%Y%m%d_%H%M%S)_v$VERSION.html"
mkdir -p "$REPORT_DIR"

# Función para verificar y/o instalar Homebrew
install_brew_if_needed() {
    if ! command -v brew &> /dev/null; then
        echo "Homebrew no encontrado, instalando..."
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
        echo "Homebrew instalado."
    else
        echo "Homebrew ya está instalado."
    fi
}

# Ejecutar instalación de brew si falta
install_brew_if_needed

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

# Función para verificar y mostrar estado de la cuenta Apple
check_apple_account_status() {
    echo "<div class='card'><h2>🍏 Estado Cuenta Apple</h2><pre>" >> "$HTML_REPORT"

    apple_accounts=$(defaults read MobileMeAccounts Accounts 2>/dev/null)
    if [[ -z "$apple_accounts" ]]; then
        echo "❌ No hay sesión activa de Apple ID en este equipo." >> "$HTML_REPORT"
    else
        # Intentamos extraer estado de cuenta de la salida (puede variar)
        account_status=$(defaults read MobileMeAccounts Accounts | grep -i "AccountStatus" | head -1 2>/dev/null)
        if [[ -z "$account_status" ]]; then
            echo "ℹ️ La sesión Apple ID parece activa, pero no se encontró estado detallado." >> "$HTML_REPORT"
        else
            if [[ "$account_status" =~ Restricted|Error|Inactive ]]; then
                echo "⚠️ La cuenta Apple presenta problemas o está restringida: $account_status" >> "$HTML_REPORT"
            else
                echo "✅ La cuenta Apple está activa y sin restricciones aparentes." >> "$HTML_REPORT"
            fi
        fi
    fi

    echo "</pre></div>" >> "$HTML_REPORT"
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
        /* Scroll vertical para errores */
        .scrollable {
            max-height: 300px;
            overflow-y: scroll;
            background: #f0f0f0;
            padding: 10px;
            border-radius: 5px;
        }
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
    <p>Generado: $(date) | Versión: $VERSION</p>
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

# Aquí se llama a la función para verificar la cuenta Apple y se imprime en el reporte
check_apple_account_status

# --- Continúa aquí con el resto de tu script original ---

# Por ejemplo, podrías seguir con más pruebas o informes

# Cierre del HTML
cat >> "$HTML_REPORT" << EOH
</body>
</html>
EOH

# Mensaje final
echo "Reporte generado en: $HTML_REPORT"

