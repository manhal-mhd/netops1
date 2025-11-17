```shell
#!/bin/bash
#
# Validate_Forth_Week_Assignment.sh
# Ubuntu-ready DNS Server Configuration Validation Script
# Checks for bind9 or unbound, ensures only one DNS service runs, and verifies DNS resolution.
#
# Usage: sudo bash Validate_Forth_Week_Assignment.sh
# (sudo may be required to read service/journal info on some systems)
#
set -euo pipefail

echo "================================================"
echo "DNS Server Assignment Validation Script (Ubuntu)"
echo "================================================"
echo ""

# Helper: print a heading
h() { echo ""; echo "=== $* ==="; }

# Detect available commands
command -v ip >/dev/null 2>&1 && HAVE_IP=true || HAVE_IP=false
command -v ifconfig >/dev/null 2>&1 && HAVE_IFCONFIG=true || HAVE_IFCONFIG=false
command -v dig >/dev/null 2>&1 && HAVE_DIG=true || HAVE_DIG=false

h "System Information"
if [ -f /etc/os-release ]; then
    . /etc/os-release
    echo "OS: $PRETTY_NAME"
else
    echo "OS: Unknown"
fi
uname -a
echo ""

h "Network Interfaces"
if $HAVE_IP; then
    ip addr show || true
elif $HAVE_IFCONFIG; then
    ifconfig || true
else
    echo "No ip/ifconfig command found"
fi

# Functions to check service/process/package status
is_active_systemctl() {
    local unit=$1
    if command -v systemctl >/dev/null 2>&1; then
        systemctl is-active --quiet "$unit" 2>/dev/null
        return $?
    fi
    return 1
}

is_process_running() {
    local name=$1
    if command -v pgrep >/dev/null 2>&1; then
        pgrep -x "$name" >/dev/null 2>&1 && return 0 || return 1
    else
        # fallback to ps
        ps aux | grep -v grep | grep -w "$name" >/dev/null 2>&1 && return 0 || return 1
    fi
}

is_package_installed() {
    local pkg=$1
    if command -v dpkg-query >/dev/null 2>&1; then
        dpkg-query -W -f='${Status}' "$pkg" 2>/dev/null | grep -q "install ok installed" && return 0 || return 1
    else
        # fallback: check for binary in PATH
        command -v "$pkg" >/dev/null 2>&1 && return 0 || return 1
    fi
}

# Check common DNS-related services
h "Checking for DNS-related services/packages"

# Bind detection: package is 'bind9' on Ubuntu, process is 'named', service unit is 'bind9'
bind_installed=false
bind_running=false
if is_package_installed "bind9" || command -v named >/dev/null 2>&1; then
    bind_installed=true
fi
if is_active_systemctl "bind9" || is_process_running "named"; then
    bind_running=true
fi
echo "BIND (bind9) installed: $bind_installed, running: $bind_running"

# Unbound detection: package is 'unbound', process/service is 'unbound'
unbound_installed=false
unbound_running=false
if is_package_installed "unbound" || command -v unbound >/dev/null 2>&1; then
    unbound_installed=true
fi
if is_active_systemctl "unbound" || is_process_running "unbound"; then
    unbound_running=true
fi
echo "Unbound installed: $unbound_installed, running: $unbound_running"

# systemd-resolved (common on Ubuntu)
resolved_installed=false
resolved_running=false
if command -v systemd-resolved >/dev/null 2>&1 || systemctl list-units --type=service 2>/dev/null | grep -q systemd-resolved; then
    resolved_installed=true
fi
if is_active_systemctl "systemd-resolved" || is_process_running "systemd-resolved"; then
    resolved_running=true
fi
echo "systemd-resolved installed: $resolved_installed, running: $resolved_running"

# dnsmasq detection (common in some images)
dnsmasq_installed=false
dnsmasq_running=false
if is_package_installed "dnsmasq" || command -v dnsmasq >/dev/null 2>&1; then
    dnsmasq_installed=true
fi
if is_active_systemctl "dnsmasq" || is_process_running "dnsmasq"; then
    dnsmasq_running=true
fi
echo "dnsmasq installed: $dnsmasq_installed, running: $dnsmasq_running"

# Summarize potential conflicts
h "Potential conflicts"
if $resolved_running; then
    echo "⚠ systemd-resolved is running and may bind to port 53. Consider disabling/masking it for testing."
fi
if $dnsmasq_running; then
    echo "⚠ dnsmasq is running and may bind to port 53."
fi

# Determine server IP (non-loopback)
h "Determining server IP (non-loopback)"
SERVER_IP=""
# Prefer ip command: look for global IPv4 addresses (scope global or not loopback)
if $HAVE_IP; then
    # Try primary source address used to reach internet:
    SERVER_IP=$(ip route get 8.8.8.8 2>/dev/null | awk '{for(i=1;i<=NF;i++) if($i=="src") print $(i+1)}' | head -n1 || true)
    if [ -z "$SERVER_IP" ]; then
        # fallback: take first non-loopback IPv4 from ip addr
        SERVER_IP=$(ip -4 addr show scope global | awk '/inet /{print $2}' | head -n1 | cut -d/ -f1 || true)
    fi
fi

# If ip not available or found nothing, fallback to ifconfig parsing
if [ -z "$SERVER_IP" ] && $HAVE_IFCONFIG; then
    SERVER_IP=$(ifconfig 2>/dev/null | awk '/inet / && $2 != "127.0.0.1" {print $2; exit}' || true)
fi

# Final fallback: parse ifconfig sample for 10.x/172.x/192.168.x
if [ -z "$SERVER_IP" ]; then
    if $HAVE_IFCONFIG; then
        SERVER_IP=$(ifconfig 2>/dev/null | grep -E "inet (10\.|172\.|192\.168\.)" | awk '{print $2}' | head -n1 || true)
    fi
fi

if [ -z "$SERVER_IP" ]; then
    echo "✗ Could not determine a non-loopback IPv4 address. Please specify the server IP as an argument."
    echo "Usage: sudo bash Validate_Forth_Week_Assignment.sh [SERVER_IP]"
    exit 1
fi

echo "Detected server IP: $SERVER_IP"

# If user provided an override argument, use it
if [ $# -ge 1 ]; then
    # allow passing explicit IP as first arg
    if [[ $1 =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
        SERVER_IP="$1"
        echo "Overriding server IP with argument: $SERVER_IP"
    fi
fi

# Function to test DNS resolution using dig
test_dns_resolution() {
    local dns_server=$1
    local domain="google.com"

    echo ""
    echo "Testing DNS resolution for $domain via $dns_server ..."
    if ! command -v dig >/dev/null 2>&1; then
        echo "✗ dig not found. Installing dnsutils may be required (sudo apt install -y dnsutils)."
        return 2
    fi

    # Query with a short timeout and limited tries
    RESOLVED=$(dig @"$dns_server" "$domain" +short +time=3 +tries=2 2>/dev/null || true)

    if [ -n "$RESOLVED" ]; then
        echo "✓ DNS resolution successful"
        echo "  Resolved $domain to:"
        echo "$RESOLVED" | sed 's/^/    /'
        return 0
    else
        # Try a verbose dig to show header for troubleshooting
        echo "✗ DNS resolution failed (no addresses returned). Verbose dig output below:"
        echo "---- dig output start ----"
        dig @"$dns_server" "$domain" +time=4 +tries=2
        echo "---- dig output end ----"
        return 1
    fi
}

# Run DNS resolution test
test_dns_resolution "$SERVER_IP"
DNS_RESULT=$?

h "Service status summary"
echo "BIND installed: $bind_installed, running: $bind_running"
echo "Unbound installed: $unbound_installed, running: $unbound_running"
echo "systemd-resolved running: $resolved_running"
echo "dnsmasq running: $dnsmasq_running"

echo ""
h "Port 53 listeners (udp/tcp)"
# Show actual processes/units listening on port 53
if command -v ss >/dev/null 2>&1; then
    ss -ulpn | grep -E ':53\b' || ss -tnlp | grep -E ':53\b' || true
elif command -v netstat >/dev/null 2>&1; then
    netstat -unp | grep ':53' || true
else
    echo "No ss/netstat available to list listeners"
fi

echo ""
h "Final validation"

# Check only one of bind or unbound is running
one_dns_running=false
if { [ "$bind_running" = true ] && [ "$unbound_running" = false ]; } || \
   { [ "$unbound_running" = true ] && [ "$bind_running" = false ]; }; then
    one_dns_running=true
fi

if [ $DNS_RESULT -eq 0 ] && [ "$one_dns_running" = true ]; then
    echo "✅ SUCCESS: Assignment completed correctly!"
    echo "   - DNS server at $SERVER_IP is responding to queries"
    if [ "$bind_running" = true ]; then
        echo "   - BIND (bind9) is running and Unbound is not"
    else
        echo "   - Unbound is running and BIND (bind9) is not"
    fi
    echo ""
    echo "=== Final dig output (for records) ==="
    dig @"$SERVER_IP" google.com
    exit 0
elif [ $DNS_RESULT -eq 0 ] && [ "$one_dns_running" = false ]; then
    echo "⚠ PARTIAL: DNS responded, but service state is unexpected."
    echo "   - Ensure only one DNS server (bind9 OR unbound) is running."
    if $resolved_running; then
        echo "   - Also note systemd-resolved is running and may conflict."
    fi
    exit 2
else
    echo "❌ FAILED: DNS server did not respond correctly from $SERVER_IP."
    echo "   - Verify the DNS service (bind9 or unbound) is running,"
    echo "   - Confirm the service is listening on $SERVER_IP:53 and firewall allows access,"
    echo "   - Check logs: sudo journalctl -u bind9 -n 200 OR sudo journalctl -u unbound -n 200"
    exit 1
fi
```
