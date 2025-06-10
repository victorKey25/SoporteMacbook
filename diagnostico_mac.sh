#!/bin/bash

TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
OUTPUT="diagnostico_mac_$TIMESTAMP.html"

add_section() {
  TITLE="$1"
  CONTENT="$2"
  echo "<section><h2>$TITLE</h2><pre>$CONTENT</pre></section>" >> "$OUTPUT"
}

add_scroll_section() {
  TITLE="$1"
  CONTENT="$2"
  echo "<section><h2>$TITLE</h2><div class=\"scroll-box\"><pre>$CONTENT</pre></div></section>" >> "$OUTPUT"
}

# Recopilación de información
HARDWARE_INFO=$(system_profiler SPHardwareDataType)
STORAGE_INFO=$(df -h)
PROCESS_INFO=$(ps aux)
NETWORK_INFO=$(networksetup -listallhardwareports; ifconfig)
KEXTS=$(kextstat | grep -v com.apple)
MALWARE=$(find /Users -name "*.virus" 2>/dev/null)
ERRORS=$(log show --predicate 'eventMessage contains[c] "error"' --last 15m 2>/dev/null)
USB_BT=$(system_profiler SPUSBDataType SPBluetoothDataType)

# HTML de salida
cat <<EOF > "$OUTPUT"
<!DOCTYPE html>
<html lang="es">
<head>
  <meta charset="UTF-8">
  <title>Diagnóstico Técnico Completo</title>
  <style>
    body {
      font-family: "Segoe UI", Helvetica, sans-serif;
      background-color: #fff;
      color: #111;
      margin: 0;
      padding: 0;
    }
    header {
      background-color: #f8f8f8;
      color: #111;
      text-align: center;
      padding: 40px 10px 20px;
    }
    header h1 {
      margin: 0;
      font-size: 40px;
    }
    header p {
      margin: 5px 0;
      font-size: 16px;
    }
    h2 {
      border-bottom: 2px solid #ccc;
      padding-bottom: 5px;
      margin-top: 40px;
    }
    section {
      padding: 20px;
      border-bottom: 1px solid #ddd;
    }
    pre {
      white-space: pre-wrap;
      word-wrap: break-word;
      background-color: #f4f4f4;
      padding: 10px;
      border-radius: 6px;
      overflow-x: auto;
    }
    .scroll-box {
      max-height: 300px;
      max-width: 100%;
      overflow: auto;
      border: 1px solid #ccc;
      background-color: #f4f4f4;
      border-radius: 6px;
    }
    footer {
      text-align: center;
      padding: 20px;
      font-size: 14px;
      color: #555;
