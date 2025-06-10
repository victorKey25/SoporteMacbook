#!/bin/bash

# Versión 1.2 - Se agregó impresión de cuenta Apple ID y apertura automática del reporte

# Imprimir la cuenta Apple ID ingresada en la Mac (si está disponible)
echo "Cuenta Apple ID: $(defaults read MobileMeAccounts 2>/dev/null | grep AccountID | head -n 1 | awk -F '= ' '{print $2}' | tr -d ';\"')"

# Función para obtener el nombre del modelo de la Mac
obtener_modelo() {
  system_profiler SPHardwareDataType | awk '/Model Identifier/ {print $3}'
}

# Función para obtener la versión de macOS
obtener_version_mac() {
  sw_vers -productVersion
}

# Función para obtener el número de serie de la Mac
obtener_numero_serie() {
  system_profiler SPHardwareDataType | awk '/Serial Number/ {print $4}'
}

# Función para obtener el estado del disco
obtener_estado_disco() {
  diskutil verifyVolume / | grep "The volume"
}

# Función para obtener el estado de la memoria
obtener_estado_memoria() {
  vm_stat | grep "free"
}

# Función para obtener el estado de la batería
obtener_estado_bateria() {
  system_profiler SPPowerDataType | grep "Cycle Count"
}

# Función para generar el reporte HTML
generar_reporte() {
  cat <<EOF > diagnostico.html
<!DOCTYPE html>
<html lang="es">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Reporte de Diagnóstico</title>
  <style>
    body { font-family: Arial, sans-serif; margin: 20px; }
    h1 { color: #2c3e50; }
    h2 { color: #34495e; }
    pre { background-color: #ecf0f1; padding: 10px; border-radius: 5px; }
    .section { margin-bottom: 20px; }
  </style>
</head>
<body>
  <h1>Reporte de Diagnóstico de la Mac</h1>

  <div class="section">
    <h2>Información del Sistema</h2>
    <p><strong>Modelo:</strong> $(obtener_modelo)</p>
    <p><strong>Versión de macOS:</strong> $(obtener_version_mac)</p>
    <p><strong>Número de Serie:</strong> $(obtener_numero_serie)</p>
  </div>

  <div class="section">
    <h2>Estado del Sistema</h2>
    <p><strong>Estado del Disco:</strong> $(obtener_estado_disco)</p>
    <p><strong>Estado de la Memoria:</strong> $(obtener_estado_memoria)</p>
    <p><strong>Estado de la Batería:</strong> $(obtener_estado_bateria)</p>
  </div>

</body>
</html>
EOF
}

# Generar el reporte
generar_reporte

# Abrir el reporte HTML generado automáticamente
open diagnostico.html
