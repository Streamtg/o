# === PEGA TODO ESTO EN TU TERMINAL ===
mkdir -p ~/.local/bin

# --- SCRIPT: TODO EN RAM, SE BORRA AUTOMÁTICO ---
cat > ~/.local/bin/keepalive.sh << 'EOF'
#!/bin/bash

# ========================================
# KeepAlive CentOS 8 - SIN ROOT - SIN SYSTEMD
# Todo en RAM → se borra al apagar
# Usa crontab @reboot
# ========================================

# Directorio único en RAM (se autodestruye al apagar)
RAM_DIR="/dev/shm/keepalive_$(whoami)_$$"
HEARTBEAT="$RAM_DIR/heartbeat.tmp"
INTERVAL=3600  # 1 hora

# Crear directorio en RAM
mkdir -p "$RAM_DIR"

# Bucle infinito
while true; do
    START=$(date +%s)

    # 1. CPU ligera
    for i in {1..50000}; do
        : $((i * i))
    done

    # 2. Escribir en RAM y BORRAR INMEDIATAMENTE
    echo "ACTIVO: $(date '+%Y-%m-%d %H:%M:%S')" > "$HEARTBEAT"
    sleep 1
    rm -f "$HEARTBEAT"  # ← BORRADO AUTOMÁTICO

    # 3. Tráfico de red (3 DNS de respaldo)
    ping -c 1 -W 2 8.8.8.8 > /dev/null 2>&1 || \
    ping -c 1 -W 2 1.1.1.1 > /dev/null 2>&1 || \
    ping -c 1 -W 2 208.67.222.222 > /dev/null 2>&1

    # 4. Ratón (solo si hay GUI y xdotool)
    if [ -n "$DISPLAY" ] && command -v xdotool &> /dev/null; then
        xdotool mousemove_relative 1 0 2>/dev/null
        sleep 0.1
        xdotool mousemove_relative -- -1 0 2>/dev/null
    fi

    # 5. Dormir hasta completar intervalo
    END=$(date +%s)
    SLEEP_TIME=$((INTERVAL - (END - START)))
    [ $SLEEP_TIME -gt 0 ] && sleep $SLEEP_TIME
done

# Al salir (nunca llega), borrar todo
rm -rf "$RAM_DIR"
EOF

# Hacer ejecutable
chmod +x ~/.local/bin/keepalive.sh

# --- AÑADIR A CRONTAB (SIN ROOT) ---
(crontab -l 2>/dev/null | grep -v "keepalive.sh"; echo "@reboot $HOME/.local/bin/keepalive.sh > /dev/null 2>&1 &") | crontab -

echo "¡KeepAlive instalado SIN ROOT NI SYSTEMD!"
echo "→ Se ejecuta al reiniciar con crontab @reboot"
echo "→ Todo en RAM → se borra al apagar"
echo "→ NO deja archivos permanentes"
echo ""
echo "Verifica que crontab se guardó:"
crontab -l | grep keepalive
echo ""
echo "Prueba manual:"
~/.local/bin/keepalive.sh &
echo "PID: $!"
echo "Mata con: kill $!"
