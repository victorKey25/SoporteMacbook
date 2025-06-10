#!/bin/bash

# Configuración
REPORT_DIR="$HOME/Desktop/MacDiagnostic"
HTML_REPORT="$REPORT_DIR/report_$(date +%Y%m%d_%H%M%S).html"
mkdir -p "$REPORT_DIR"

# Generar inicio del HTML
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
        .scroll-vertical {
            max-height: 300px;
            overflow-y: scroll;
            background: #f8f8f8;
            padding: 10px;
            border-radius: 5px;
        }
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
        <h2>🖥️ Información del Sistema</h2>
        <pre>$(system_profiler SPHardwareDataType)</pre>
    </div>

    <div class="card">
        <h2>💽 Almacenamiento</h2>
        <pre>$(df -h)</pre>
    </div>

    <div class="card">
        <h2>🌐 Red</h2>
        <pre>$(ifconfig)</pre>
    </div>

    <div class="card">
        <h2>🔵 Dispositivos Bluetooth</h2>
        <pre>$(system_profiler SPBluetoothDataType)</pre>
    </div>

    <div class="card">
        <h2>🔌 Dispositivos USB</h2>
        <pre>$(system_profiler SPUSBDataType)</pre>
    </div>

    <div class="card">
        <h2>🧩 Extensiones de Kernel no Apple</h2>
        <pre>$(kextstat | grep -v com.apple)</pre>
    </div>

    <div class="card">
        <h2>🛡️ Procesos Sospechosos (malware básico)</h2>
        <pre>$(ps aux | grep -v root | egrep -i "launch|dropbox|bitcoin|minerd|kext|vpn|trojan|malware" | grep -v grep)</pre>
    </div>

    <div class="card">
        <h2>⚠️ Últimos Errores (15 min)</h2>
        <div class="scroll-vertical"><pre>$(log show --last 15m --predicate 'eventMessage contains "error"' --style syslog)</pre></div>
    </div>
EOH

# Cierre del HTML
cat >> "$HTML_REPORT" << EOH
</body>
</html>
EOH

# Mostrar resultado
if [[ -f "$HTML_REPORT" ]]; then
    open "$HTML_REPORT" && echo "✅ Informe generado con éxito: $HTML_REPORT"
else
    echo "❌ Error al generar el informe"
    exit 1
fi
