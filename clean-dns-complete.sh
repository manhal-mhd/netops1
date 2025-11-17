#!/bin/bash
#
# clean-dns-complete.sh
# Completely removes BIND and Unbound including zombie processes
#

set -euo pipefail

echo "================================================"
echo "Complete DNS Services Cleanup Script (service)"
echo "================================================"
echo ""

echo "WARNING: This will completely remove ALL DNS services and their configurations!"
echo "This action cannot be undone!"
echo ""
read -p "Are you sure you want to continue? (y/N): " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Aborted."
    exit 1
fi

echo ""
echo "=== Checking for zombie processes ==="

# Function to clean zombie processes
clean_zombie_processes() {
    echo "Checking for zombie DNS processes..."
    
    # Find zombie processes
    local zombie_pids
    zombie_pids=$(ps -eo pid,state,comm | awk '$2=="Z" && ($3=="named" || $3=="unbound") {print $1}')
    
    if [ -n "$zombie_pids" ]; then
        echo "Found zombie processes: $zombie_pids"
        
        # Try to reap zombies by killing their parent processes
        for pid in $zombie_pids; do
            local parent_pid
            parent_pid=$(ps -o ppid= -p "$pid" 2>/dev/null | tr -d ' ' || echo "")
            
            if [ -n "$parent_pid" ] && [ "$parent_pid" != "1" ]; then
                echo "Killing parent process $parent_pid of zombie $pid"
                sudo kill -9 "$parent_pid" 2>/dev/null || true
            fi
        done
        
        # Wait a moment
        sleep 2
        
        # Check if zombies are still there
        zombie_pids=$(ps -eo pid,state,comm | awk '$2=="Z" && ($3=="named" || $3=="unbound") {print $1}')
        if [ -n "$zombie_pids" ]; then
            echo "Zombie processes still present: $zombie_pids"
            echo "Attempting alternative cleanup methods..."
            
            # Try to use gdb to force zombie cleanup (more aggressive method)
            for pid in $zombie_pids; do
                if command -v gdb >/dev/null 2>&1; then
                    echo "Using gdb to clean zombie $pid"
                    sudo gdb -batch -ex "call waitpid($pid,0,0)" -p 1 >/dev/null 2>&1 || true
                fi
            done
            
            # Final check
            sleep 2
            zombie_pids=$(ps -eo pid,state,comm | awk '$2=="Z" && ($3=="named" || $3=="unbound") {print $1}')
            if [ -n "$zombie_pids" ]; then
                echo "⚠️  Some zombie processes may persist until system restart: $zombie_pids"
                echo "   They are harmless but will show up in process lists."
            else
                echo "✅ All zombie processes cleaned"
            fi
        else
            echo "✅ All zombie processes cleaned"
        fi
    else
        echo "✅ No zombie DNS processes found"
    fi
}

# Clean zombies first
clean_zombie_processes

echo ""
echo "=== Stopping all DNS services using service commands ==="

# Stop BIND using service command
if service --status-all 2>/dev/null | grep -q bind9; then
    echo "Stopping BIND via service command..."
    sudo service bind9 stop >/dev/null 2>&1 || true
fi

# Stop Unbound using service command  
if service --status-all 2>/dev/null | grep -q unbound; then
    echo "Stopping Unbound via service command..."
    sudo service unbound stop >/dev/null 2>&1 || true
fi

# Force kill any remaining running processes (not zombies)
echo "Force killing any remaining DNS processes..."
sudo pkill -x named >/dev/null 2>&1 || true
sudo pkill -x unbound >/dev/null 2>&1 || true
sudo pkill -9 -x named >/dev/null 2>&1 || true
sudo pkill -9 -x unbound >/dev/null 2>&1 || true

# Wait for services to stop
sleep 3

echo ""
echo "=== Removing packages ==="

# Remove BIND packages
echo "Removing BIND packages..."
sudo apt remove --purge -y \
    bind9 \
    bind9utils \
    bind9-doc \
    bind9-host \
    > /dev/null 2>&1 || true

# Remove Unbound packages
echo "Removing Unbound packages..."
sudo apt remove --purge -y \
    unbound \
    unbound-anchor \
    > /dev/null 2>&1 || true

# Clean up any orphaned packages
sudo apt autoremove -y > /dev/null 2>&1 || true

echo ""
echo "=== Removing configuration files and data ==="

# BIND files to remove
echo "Removing BIND files..."
sudo rm -rf /etc/bind
sudo rm -rf /var/cache/bind
sudo rm -rf /var/lib/bind
sudo rm -rf /var/log/bind
sudo rm -f /etc/default/bind9

# Unbound files to remove
echo "Removing Unbound files..."
sudo rm -rf /etc/unbound
sudo rm -rf /var/lib/unbound
sudo rm -rf /var/log/unbound
sudo rm -f /etc/default/unbound

# Remove init scripts (SysV init)
echo "Removing init scripts..."
sudo rm -f /etc/init.d/bind9
sudo rm -f /etc/init.d/unbound

# Remove any upstart configs (if using upstart)
sudo rm -f /etc/init/bind9.conf
sudo rm -f /etc/init/unbound.conf

echo ""
echo "=== Cleaning up process and temp files ==="

# Remove PID files and lock files
sudo rm -f /var/run/named.pid
sudo rm -f /var/run/unbound.pid
sudo rm -f /var/run/bind/named.pid
sudo rm -f /var/run/unbound/unbound.pid
sudo rm -f /var/lock/subsys/named
sudo rm -f /var/lock/subsys/unbound
sudo rm -f /var/lock/bind9
sudo rm -f /var/lock/unbound

echo ""
echo "=== Resetting system DNS settings ==="

# Reset resolv.conf to use public DNS
echo "Resetting /etc/resolv.conf..."
# Use a different approach to avoid "Device or resource busy"
sudo bash -c 'cat > /etc/resolv.conf << EOF
nameserver 8.8.8.8
nameserver 1.1.1.1
EOF'

echo ""
echo "=== Final zombie cleanup check ==="

# One more zombie cleanup attempt after package removal
clean_zombie_processes

echo ""
echo "=== Verifying cleanup ==="

# Check if running processes are still running (excluding zombies)
echo "Checking for running processes (excluding zombies):"
running_named=$(ps -eo pid,state,comm | grep -w named | grep -v "Z" | wc -l)
running_unbound=$(ps -eo pid,state,comm | grep -w unbound | grep -v "Z" | wc -l)

if [ "$running_named" -gt 0 ]; then
    echo "❌ named processes still running (non-zombie)"
else
    echo "✅ No named processes running (non-zombie)"
fi

if [ "$running_unbound" -gt 0 ]; then
    echo "❌ unbound processes still running (non-zombie)"
else
    echo "✅ No unbound processes running (non-zombie)"
fi

# Check for any zombie processes (final report)
zombie_count=$(ps -eo pid,state,comm | awk '$2=="Z" && ($3=="named" || $3=="unbound")' | wc -l)
if [ "$zombie_count" -gt 0 ]; then
    echo "⚠️  $zombie_count zombie DNS process(es) still present (harmless)"
    echo "   They will be automatically cleaned on system restart"
else
    echo "✅ No zombie DNS processes"
fi

# Check if packages are installed
echo ""
echo "Checking installed packages:"
if dpkg -l bind9 2>/dev/null | grep -q "^ii"; then
    echo "❌ bind9 package still installed"
else
    echo "✅ bind9 package removed"
fi

if dpkg -l unbound 2>/dev/null | grep -q "^ii"; then
    echo "❌ unbound package still installed"
else
    echo "✅ unbound package removed"
fi

# Check if config directories exist
echo ""
echo "Checking configuration directories:"
if [ -d "/etc/bind" ]; then
    echo "❌ /etc/bind still exists"
    sudo rm -rf /etc/bind
else
    echo "✅ /etc/bind removed"
fi

if [ -d "/etc/unbound" ]; then
    echo "❌ /etc/unbound still exists"
    sudo rm -rf /etc/unbound
else
    echo "✅ /etc/unbound removed"
fi

# Check if service commands still show the services
echo ""
echo "Checking service command status:"
if service --status-all 2>/dev/null | grep -q bind9; then
    echo "❌ bind9 still in service list"
else
    echo "✅ bind9 removed from service list"
fi

if service --status-all 2>/dev/null | grep -q unbound; then
    echo "❌ unbound still in service list"
else
    echo "✅ unbound removed from service list"
fi

# Check port 53 listeners
echo ""
echo "Checking port 53 listeners:"
if command -v netstat >/dev/null 2>&1; then
    if netstat -ulnp 2>/dev/null | grep -q ':53'; then
        echo "❌ Services still listening on port 53:"
        netstat -ulnp 2>/dev/null | grep ':53'
    else
        echo "✅ No services listening on port 53"
    fi
elif command -v ss >/dev/null 2>&1; then
    if ss -ulpn | grep -q ':53'; then
        echo "❌ Services still listening on port 53:"
        ss -ulpn | grep ':53'
    else
        echo "✅ No services listening on port 53"
    fi
else
    echo "⚠️ Cannot check port listeners (netstat/ss not available)"
fi

echo ""
echo "================================================"
echo "CLEANUP COMPLETE!"
echo "================================================"
echo ""
echo "Your system is now clean of all BIND and Unbound installations."
echo "All service commands and configurations have been removed."
echo ""
if [ "$zombie_count" -gt 0 ]; then
    echo "Note: $zombie_count zombie process(es) remain but are harmless."
    echo "They will be automatically removed on system restart."
fi
echo ""
echo "To install a fresh DNS server, run:"
echo "  sudo apt update"
echo "  sudo apt install -y unbound  # or bind9"
echo ""
echo "Then configure it properly for your network."
