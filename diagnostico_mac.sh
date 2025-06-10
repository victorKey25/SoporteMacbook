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

# Generar inicio del HTML
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
        .header { background: #002c54; color: white; padding: 20px; border-radius: 8px; margin-bottom: 20px; }
        .header h1 { margin: 0; font-size: 28px; }
        .header a, .footer a { color: #00d0ff; text-decoration: none; }
    </style>
</head>
<body>
    <div class="header">
        <h1>🛰️ KeysTelecom - Diagnóstico Técnico</h1>
        <p><strong>Sitio Web:</strong> <a href="https://keystelecom.com/" target="_blank">https://keystelecom.com/</a></p>
        <p><strong>Teléfono:</strong> +52 55 7434 7924</p>
        <p><strong>Correo:</strong> <a href="mailto:info@keystelecom.com">info@keystelecom.com</a> | <a href="mailto:victor.keymolen@keystelecom.com">victor.keymolen@keystelecom.com</a></p>
    </div>

    <h1>🔍 Diagnóstico Técnico Completo - $(hostname)</h1>
    <p>Generado: $(date)</p>
EOH

# (Las secciones intermedias permanecen exactamente igual: sistema, memoria, batería, red, seguridad...)

# Recomendaciones con contacto
cat >> "$HTML_REPORT" << EOH
    <div class="card">
        <h2>🔧 Recomendaciones Técnicas</h2>
        <ul>
            <li>Verificar espacio en disco: <code>sudo ncdu /</code></li>
            <li>Monitor en tiempo real: <code>htop</code> (instalar vía Homebrew)</li>
            <li>Ver logs del sistema: <code>log show --last 1h</code></li>
        </ul>
        <p>📞 Para más información o soporte técnico, contacta con nosotros:</p>
        <ul>
            <li><strong>Sitio Web:</strong> <a href="https://keystelecom.com/" target="_blank">https://keystelecom.com/</a></li>
            <li><strong>Teléfono:</strong> +52 55 7434 7924</li>
            <li><strong>Correo:</strong> <a href="mailto:info@keystelecom.com">info@keystelecom.com</a> | <a href="mailto:victor.keymolen@keystelecom.com">victor.keymolen@keystelecom.com</a></li>
        </ul>
    </div>
</body>
</html>
EOH

# Abrir reporte
open "$HTML_REPORT"
echo "✅ Reporte generado: $HTML_REPORT"
