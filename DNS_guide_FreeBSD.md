# FreeBSD Cache-only DNS Server Installation Guide
## BIND and Unbound Implementation Options
Last Updated: 2025-02-20 01:25:27 UTC
Author: manhal-mhd

## Table of Contents
1. [Lab Environment Setup](#lab-environment-setup)
2. [DNS Server Options](#dns-server-options)
3. [Option A: Installing BIND](#option-a-installing-bind)
4. [Option B: Installing Unbound](#option-b-installing-unbound)
5. [Important Notes on Compatibility](#important-notes-on-compatibility)
6. [List of Dig Status and Flags](#list-of-dig-status-and-flags)
7. [FreeBSD Ports and Packages System](#freebsd-ports-and-packages-system)
8. [Fun Practice Tasks for Ports and Packages Management](#fun-practice-tasks-for-ports-and-packages-management)


## Lab Environment Setup

### Accessing Your Lab Environment
1. Open your web browser and navigate to:
   ```
   https://n2.nog-oc.org/youremailaddress/
   ```
   This URL provides access to your lab environment. Replace `youremailaddress` with your actual email address to log in.

2. Use the following default credentials:
   - Username: `afnog`
   - Password: `admin`
   These credentials are provided for initial access to the lab environment.

### Elevating Privileges
When first logged in, you'll need root access:
```bash
su -
```
This command switches to the root user, providing administrative privileges required for subsequent steps.

### Verify Network Configuration
Check your network settings and note down your IP addresses:
```bash
ifconfig
```
The `ifconfig` command displays network interface configuration, including IP addresses. This information is important for configuring the DNS server.

In our lab environment as example :
- IPv4 Address: 192.168.0.217
- Loopback Address: 127.0.0.217

## DNS Server Options

> **IMPORTANT**: You cannot run both BIND and Unbound simultaneously as they both use port 53.
This note is crucial because running both DNS servers on the same port will cause conflicts.

### Choosing Between BIND and Unbound

| Feature | BIND | Unbound |
|---------|------|----------|
| Resource Usage | Higher | Lower |
| Configuration Complexity | More Complex | Simpler |
| Feature Set | Full DNS server suite | Focused on resolving |
| Best Use Case | Full DNS server needs | Caching resolver |
| Memory Footprint | Larger | Smaller |

This table helps you decide which DNS server to use based on your requirements.

## Important Notes on Compatibility

Before installing either DNS server, check for existing installations:
```bash
# Check running DNS services
sockstat -l | grep ":53"
```
The `sockstat` command checks for services running on port 53, which is used by DNS servers.

```bash
# Check for BIND
pkg info | grep bind
```
The `pkg info` command checks if BIND is installed.

```bash
# Check for Unbound
pkg info | grep unbound
```
Similarly, this command checks if Unbound is installed.

If you need to switch between servers:
1. Stop and disable existing service
2. Remove existing package
3. Clean up configuration files
4. Verify port 53 is free

These steps ensure a clean transition from one DNS server to another.

## Option A: Installing BIND

### A1. Installation

#### Search for Available BIND Packages
```bash
pkg search bind
```
This command searches for available BIND packages in the FreeBSD package repository.

Expected output:
```
bind-tools-9.20.5              Command line tools from BIND
bind9-devel-9.21.4             BIND DNS suite with updated DNSSEC and DNS64
bind918-9.18.33                BIND DNS suite with updated DNSSEC and DNS64
bind920-9.20.5                 BIND DNS suite with updated DNSSEC and DNS64
```
You will see a list of available BIND packages.

#### Install BIND 9.20
```bash
pkg install bind920-9.20.5
```
This command installs the specified version of the BIND package.

### A2. Configuration

#### Enable BIND Service
```bash
sysrc named_enable=YES
```
This command configures the system to start the BIND service at boot.

#### Navigate to Configuration Directory
```bash
cd /usr/local/etc/namedb
```
This command changes the directory to the BIND configuration directory.

#### Edit named.conf
```bash
vi named.conf
```
Use the `vi` editor to open the BIND configuration file `named.conf`.

Add/modify these sections:
```
listen-on {
    127.0.0.217;
    192.168.0.217;
};

recursion yes;
```
These settings configure BIND to listen on specified IP addresses and enable recursion.

### A3. Validation and Start

#### Check Configuration
```bash
named-checkconf
```
This command validates the BIND configuration file for any syntax errors.

#### Start Service
```bash
service named restart
```
This command starts or restarts the BIND service to apply the new configuration.

#### Test BIND
```bash
dig @192.168.0.217 google.com
```
The `dig` command tests the DNS resolution using the configured BIND server.

![image](https://github.com/user-attachments/assets/7e1ed96b-ff80-4a1b-9eb4-b70166b64526)


## Option B: Installing Unbound

### Important: BIND and Unbound Compatibility

> **WARNING**: BIND and Unbound cannot run simultaneously as they both try to use port 53. You must remove BIND before installing Unbound.
This warning is crucial to avoid conflicts between the two DNS servers.

#### 1. Check for Existing BIND Installation
First, check if BIND is installed and running:
```bash
# Check if BIND service is running
service named status
```
This command checks the status of the BIND service.

```bash
# Check for BIND package
pkg info | grep bind
```
This command checks if the BIND package is installed.

#### 2. Remove BIND (If Installed)

1. Stop the BIND service:
   ```bash
   service named stop
   ```
   This command stops the BIND service.

2. Disable BIND from starting at boot:
   ```bash
   sysrc named_enable="NO"
   ```
   This command prevents BIND from starting automatically at boot.

3. Remove BIND package and its dependencies:
   ```bash
   pkg remove bind920
   ```
   This command removes the BIND package and its dependencies.

4. Verify port 53 is free:
   ```bash
   sockstat -l | grep ":53"
   ```
   This command checks if port 53 is free. If this command returns no output, port 53 is available.

5. Clean up BIND configuration files (optional):
   ```bash
   rm -rf /usr/local/etc/namedb/*
   ```
   This command removes BIND configuration files. Ensure you backup important files before deletion.

Only after completing these steps should you proceed with the Unbound installation.
### B1. Installation

#### Search for Unbound Package
```bash
pkg search unbound
```
This command searches for available Unbound packages in the FreeBSD package repository.

#### Install Unbound
```bash
pkg install unbound
```
This command installs the Unbound package.

### B2. Configuration

#### Enable Unbound Service
```bash
sysrc unbound_enable="YES"
```
This command configures the system to start the Unbound service at boot.

#### Create Configuration
```bash
vi /usr/local/etc/unbound/unbound.conf
```
Use the `vi` editor to create and edit the Unbound configuration file `unbound.conf`.

Add the following configuration:
```yaml

    
    # Network Interface Settings
    interface: 127.0.0.217
    interface: 192.168.0.217
    port: 53
    
    # Access Control
    access-control: 127.0.0.217/32 allow
    access-control: 192.168.0.217/32 allow
    access-control: 192.168.0.0/24 allow
    
    
```
These settings configure Unbound to listen on specified IP addresses and set access control rules.

#### Check Configuration
   ```bash
   unbound-checkconf          
   ```
   This command validates the Unbound configuration file for any syntax errors.
### B4. Start and Test

#### Start Unbound
```bash
service unbound start
```
This command starts the Unbound service.

#### Test Resolution
```bash
dig @127.0.0.217 google.com
```
The `dig` command tests the DNS resolution using the configured Unbound server.

![image](https://github.com/user-attachments/assets/d24ae920-6134-4ffd-ac03-49377b0c47a2)

## Maintenance and Monitoring

### For BIND
```bash
# Check logs
tail -f /var/log/messages | grep named
```
This command monitors the BIND logs for any issues.

```bash
# Check status
service named status
```
This command checks the status of the BIND service.

### For Unbound
```bash
# View statistics
unbound-control stats
```
This command displays Unbound statistics.

```bash
# Check logs
tail -f /var/log/messages | grep unbound
```
This command monitors the Unbound logs for any issues.

```bash
# Check status
service unbound status
```
This command checks the status of the Unbound service.

## Troubleshooting

### Common Issues

1. **Service Won't Start**
   ```bash
   # Check port 53
   sockstat -l | grep ":53"
   ```
   This command checks if port 53 is being used by another service.

   ```bash
   # Check logs
   tail -f /var/log/messages
   ```
   This command monitors the system logs for any errors.

2. **DNS Resolution Problems**
   ```bash
   # Test local resolution
   dig @127.0.0.217 google.com
   ```
   The `dig` command tests the DNS resolution.

   ```bash
   # Check service status
   service named status   # for BIND
   service unbound status # for Unbound
   ```
   These commands check the status of the DNS services.

## Security Recommendations

1. Regular Updates
   ```bash
   pkg update && pkg upgrade
   ```
   This command updates the system packages to the latest versions.

2. Monitor Logs
   ```bash
   tail -f /var/log/messages
   ```
   This command monitors the system logs for any security issues.

3. Verify Configuration
   ```bash
   named-checkconf              # for BIND
   unbound-checkconf           # for Unbound
   ```
   These commands validate the DNS server configuration files.

## Additional Resources

### BIND Resources
- [BIND Documentation](https://www.isc.org/bind/)
- [BIND Administrator Reference Manual](https://bind9.readthedocs.io/)

### Unbound Resources
- [Unbound Documentation](https://nlnetlabs.nl/documentation/unbound/)
- [Unbound Security Guide](https://nlnetlabs.nl/documentation/unbound/howto-optimise/)

### FreeBSD Resources
- [FreeBSD Handbook - DNS Section](https://docs.freebsd.org/en/books/handbook/network-servers/#network-dns)

## List of Dig Status and Flags

`dig` is a powerful DNS query tool. Here are some common status codes and flags returned by `dig` along with their meanings:

### Status Codes
- `NOERROR`: The query completed successfully.
- `FORMERR`: The server was unable to process the query due to a format error.
- `SERVFAIL`: The server failed to complete the DNS request.
- `NXDOMAIN`: The domain name does not exist.
- `NOTIMP`: The server does not support the requested kind of query.
- `REFUSED`: The server refused to answer for the query.

### Flags
- `qr`: Query/Response flag. Set to `1` for a response, and `0` for a query.
- `aa`: Authoritative Answer flag. Indicates that the responding server is authoritative for the domain.
- `tc`: Truncation flag. Indicates that the message was truncated.
- `rd`: Recursion Desired flag. Indicates that the client wants recursion.
- `ra`: Recursion Available flag. Indicates that the server supports recursion.
- `ad`: Authentic Data flag. Indicates that the response has been authenticated.
- `cd`: Checking Disabled flag. Indicates that DNSSEC validation was not performed.

## FreeBSD Ports and Packages System
FreeBSD offers two primary methods for installing software: Ports and Packages. Understanding both systems is crucial for managing DNS servers and other software on your FreeBSD system.

### 1. Package System (pkg)

The package system is the simplest and fastest way to install software on FreeBSD. For DNS servers like BIND and Unbound, here are the specific commands:

#### Installing BIND using packages:
```bash
# Update package repository
pkg update

# Search for BIND packages
pkg search bind
# Output will show available versions like:
# bind920-9.20.5                 BIND DNS suite with updated DNSSEC and DNS64

# Install BIND
pkg install bind920

# Start BIND service
service named start
```

#### Installing Unbound using packages:
```bash
# Update package repository
pkg update

# Search for Unbound package
pkg search unbound

# Install Unbound
pkg install unbound

# Start Unbound service
service unbound start
```

### 2. Ports System

The ports system allows you to compile software from source, offering more customization options.

#### Initial Ports Setup:
```bash
# Install the ports tree
portsnap fetch extract

# Update existing ports tree
portsnap fetch update
```

#### Installing BIND using ports:
```bash
# Navigate to BIND port directory
cd /usr/ports/dns/bind920

# View available options
make showconfig

# Configure options (optional)
make config

# Build and install
make install clean

# Start the service
service named start
```

#### Installing Unbound using ports:
```bash
# Navigate to Unbound port directory
cd /usr/ports/dns/unbound

# View available options
make showconfig

# Configure options (optional)
make config

# Build and install
make install clean

# Start the service
service unbound start
```

### Comparison: Ports vs Packages for DNS Servers

| Feature | Ports | Packages |
|---------|-------|----------|
| Installation Time | Longer (compilation required) | Quick (binary installation) |
| Customization | High (build-time options) | None (pre-built binaries) |
| Resource Usage | Temporary high usage during compilation | Minimal installation resources |
| Update Process | Manual compilation needed | Simple `pkg upgrade` command |
| Version Control | Latest versions available | Slightly delayed updates |

### Best Practices for DNS Server Installation

1. **Choose Installation Method**:
   - Use packages (`pkg`) for:
     - Quick installation
     - Standard configurations
     - Production systems requiring rapid deployment
   - Use ports for:
     - Custom compile options
     - Specific security requirements
     - Testing latest versions

2. **Version Consistency**:
   - Stick to one installation method per software
   - Don't mix ports and packages for the same software
   - Document your installation method for future reference

3. **Security Considerations**:
   ```bash
   # For packages: Keep system updated
   pkg audit
   pkg update && pkg upgrade

   # For ports: Update vulnerabilities database
   pkg audit -F
   portsnap fetch update
   ```

4. **Maintenance Tips**:
   ```bash
   # Clean old package/port data
   pkg clean
   pkg autoremove

   # For ports:
   make clean
   make cleandir
   ```

### Specific Examples for DNS Servers

#### Example 1: Installing BIND with Custom SSL Support (Ports)
```bash
cd /usr/ports/dns/bind920
make config
# Enable SSL support in the configuration menu
make install clean
```

#### Example 2: Upgrading Unbound using Packages
```bash
# Check for updates
pkg update
# Upgrade Unbound
pkg upgrade unbound
# Restart service
service unbound restart
```

### Troubleshooting Port/Package Installation

1. **Common Package Issues**:
   ```bash
   # Refresh package repository
   pkg update -f
   
   # Check package integrity
   pkg check -d -a
   ```

2. **Common Ports Issues**:
   ```bash
   # Clean work directory
   make clean
   
   # Update ports tree
   portsnap fetch update
   ```
 ## Using Portinstall for Port Installation and Management
Last Updated: 2025-02-21 12:08:15 UTC
Author: manhal-mhd

Portinstall is part of the portupgrade suite of tools and provides an efficient way to install ports with dependency handling. It's particularly useful for installing DNS servers and related software.

#### Basic Portinstall Usage

1. **Simple Port Installation**:
   ```bash
   # Install BIND
   portinstall dns/bind920

   # Install Unbound
   portinstall dns/unbound
   ```

2. **Installation with Options**:
   ```bash
   # Install with dependency handling
   portinstall -R dns/bind920

   # Install with interactive configuration
   portinstall -c dns/unbound
   ```

#### Advanced Features

1. **Batch Installation**:
   ```bash
   # Install multiple ports at once
   portinstall dns/bind920 dns/unbound dns/dnscrypt-proxy

   # Install with specific options
   portinstall -N dns/bind920  # Don't upgrade dependencies
   ```

2. **Pre-Installation Checks**:
   ```bash
   # Check dependencies without installing
   portinstall -n dns/bind920

   # Check for conflicts
   portinstall -C dns/unbound
   ```

#### Common Portinstall Options

| Option | Description | Example Use Case |
|--------|-------------|-----------------|
| `-R` | Also install dependencies | `portinstall -R dns/bind920` |
| `-n` | Dry run mode | `portinstall -n dns/unbound` |
| `-c` | Configure before building | `portinstall -c dns/bind920` |
| `-N` | Don't upgrade dependencies | `portinstall -N dns/unbound` |
| `-f` | Force reinstall | `portinstall -f dns/bind920` |

#### Best Practices with Portinstall

1. **Before Installation**:
   ```bash
   # Update ports tree
   portsnap fetch update

   # Verify port existence
   whereis bind920
   whereis unbound
   ```

2. **During Installation**:
   ```bash
   # Monitor installation progress
   tail -f /var/log/messages

   # Check port build logs
   ls -l /usr/ports/dns/bind920/work/
   ```

#### Example Installation Workflows

1. **Fresh DNS Server Installation**:
   ```bash
   # Install BIND with all dependencies
   portinstall -R dns/bind920

   # Post-installation configuration
   cd /usr/local/etc/namedb
   cp named.conf.sample named.conf
   ```

2. **Upgrading Existing Installation**:
   ```bash
   # Stop service
   service named stop

   # Reinstall with force option
   portinstall -Rf dns/bind920

   # Restart service
   service named start
   ```

#### Troubleshooting Common Issues

1. **Build Failures**:
   ```bash
   # Clean and retry
   cd /usr/ports/dns/bind920
   make clean
   portinstall -f dns/bind920
   ```

2. **Dependency Issues**:
   ```bash
   # Rebuild dependencies
   portinstall -rR dns/bind920

   # Check installed dependencies
   pkg info -d bind920
   ```

#### Integration with Other Port Tools

1. **Using with Portupgrade**:
   ```bash
   # Install new port
   portinstall dns/bind920

   # Later upgrade using portupgrade
   portupgrade -R dns/bind920
   ```

2. **Combining with Package System**:
   ```bash
   # Check if package exists
   pkg search bind920

   # If not, use portinstall
   portinstall dns/bind920
   ```

#### Maintenance and Cleanup

1. **Post-Installation Cleanup**:
   ```bash
   # Clean work directories
   portsclean -WD

   # Remove unused dependencies
   pkg autoremove
   ```

2. **Regular Maintenance**:
   ```bash
   # Update ports tree
   portsnap fetch update

   # Check for stale dependencies
   pkg check -d
   ```

#### Example: Complete DNS Server Setup Using Portinstall

```bash
# 1. Prepare system
portsnap fetch extract
portsnap fetch update

# 2. Install BIND with custom options
portinstall -c dns/bind920

# 3. Install Unbound as backup
portinstall dns/unbound

# 4. Post-installation setup
# For BIND
sysrc named_enable="YES"
cd /usr/local/etc/namedb
cp named.conf.sample named.conf

# For Unbound
sysrc unbound_enable="YES"
cd /usr/local/etc/unbound
cp unbound.conf.sample unbound.conf

# 5. Start services
service named start
# or
service unbound start
```

#### Integration with System Maintenance

1. **Automated Update Script**:
   ```bash
   #!/bin/sh
   # Update script for DNS servers
   
   # Update ports tree
   portsnap fetch update
   
   # Check for updates
   portinstall -n dns/bind920 dns/unbound
   
   # Perform updates if needed
   portinstall -R dns/bind920 dns/unbound
   
   # Clean up
   portsclean -DD
   pkg autoremove
   ```

2. **Monitoring Script**:
   ```bash
   #!/bin/sh
   # Monitor DNS server versions
   
   echo "Installed versions:"
   pkg info | grep -E 'bind920|unbound'
   
   echo "\nAvailable ports:"
   cd /usr/ports/dns
   make search name=bind920
   make search name=unbound
   ```

## Fun Practice Tasks for Ports and Packages Management


### Challenge 1: The Package Explorer
**Goal**: Learn basic package management while installing useful tools

```bash
# Task 1: Install these fun and useful tools using pkg
pkg install \
    fortune-mod-freebsd \
    cowsay \
    figlet \
    lolcat

# Now try these commands:
fortune | cowsay
figlet "FreeBSD" | lolcat
```

**Extra Challenge**: 
- Create a script that combines all three commands
- Try different cowsay characters (-f flag)
- Make a colorful system greeting

### Challenge 2: Port vs Package Race
**Goal**: Compare installation times between ports and packages

```bash
# Task 1: Time a package installation
time pkg install nano

# Task 2: Time the same program via ports
time (cd /usr/ports/editors/nano && make install clean)

# Record your findings:
echo "Package installation time: " > ~/port_vs_pkg.txt
echo "Port installation time: " >> ~/port_vs_pkg.txt
```

**Extra Challenge**:
- Try with different sizes of programs
- Graph the time differences
- Document which method was faster for which type of software

### Challenge 3: DNS Server Deployment Race
**Goal**: Practice quick deployment of DNS servers

```bash
# Task 1: Time yourself setting up BIND
time (
    pkg install bind920
    sysrc named_enable="YES"
    cp /usr/local/etc/namedb/named.conf.sample /usr/local/etc/namedb/named.conf
    service named start
)

# Task 2: Time yourself setting up Unbound
time (
    pkg install unbound
    sysrc unbound_enable="YES"
    cp /usr/local/etc/unbound/unbound.conf.sample /usr/local/etc/unbound/unbound.conf
    service unbound start
)
```

**Extra Challenge**:
- Create automation scripts for both installations
- Add configuration customizations
- Test which server starts up faster

### Challenge 4: The Dependency Detective
**Goal**: Understand package dependencies

```bash
# Task 1: Investigate dependencies
pkg info -d bind920 > ~/bind_deps.txt
pkg info -d unbound > ~/unbound_deps.txt

# Task 2: Compare dependencies
diff ~/bind_deps.txt ~/unbound_deps.txt

# Task 3: Create a dependency tree
pkg info -d -r bind920 | sort > ~/bind_tree.txt
```

**Extra Challenge**:
- Visualize the dependency tree using graphviz
- Find common dependencies between different DNS servers
- Calculate total installation size including all dependencies

### Challenge 5: Port Configuration Master
**Goal**: Learn port configuration options

```bash
# Task 1: Explore BIND options
cd /usr/ports/dns/bind920
make showconfig > ~/bind_options.txt
make rmconfig
make config

# Task 2: Create different configurations
# Create three different configurations and document the differences
```

**Extra Challenge**:
- Create a configuration comparison chart
- Test performance with different options
- Document which options are most useful for different scenarios

### Challenge 6: The Update Game
**Goal**: Practice system update procedures

```bash
# Task 1: Create update status script
cat << 'EOF' > ~/check_updates.sh
#!/bin/sh
echo "=== Package Updates ==="
pkg version -vL=
echo "\n=== Port Updates ==="
portmaster -L | grep "New version"
EOF
chmod +x ~/check_updates.sh

# Task 2: Monitor for updates daily
crontab -e
# Add: 0 0 * * * ~/check_updates.sh | mail -s "Update Status" your@email.com
```

**Extra Challenge**:
- Add update statistics
- Create update automation
- Implement rollback procedures

### Challenge 7: The Port Builder
**Goal**: Create a simple port from scratch

```bash
# Task 1: Create a simple program
mkdir -p ~/myport
cat << 'EOF' > ~/myport/hello.c
#include <stdio.h>
int main() {
    printf("Hello from my first port!\n");
    return 0;
}
EOF

# Task 2: Create port files
mkdir -p /usr/ports/local/hello
# Create Makefile, pkg-descr, and distinfo
```

**Extra Challenge**:
- Add configuration options
- Create multiple versions
- Submit your port to FreeBSD ports tree

### Challenge 8: The Cleanup Champion
**Goal**: Master system maintenance

```bash
# Task 1: Create cleanup script
cat << 'EOF' > ~/cleanup.sh
#!/bin/sh
echo "=== Starting System Cleanup ==="
pkg clean
pkg autoremove
portsclean -DD
portsclean -WD
echo "=== Cleanup Complete ==="
df -h
EOF
chmod +x ~/cleanup.sh

# Task 2: Monitor disk space usage
du -h /usr/ports/distfiles > ~/distfiles_before.txt
./cleanup.sh
du -h /usr/ports/distfiles > ~/distfiles_after.txt
```

**Extra Challenge**:
- Add more cleanup tasks
- Create space usage reports
- Implement automatic cleanup triggers

### Challenge 9: The Version Hunter
**Goal**: Track software versions across different installation methods

```bash
# Task 1: Create version tracking script
cat << 'EOF' > ~/version_track.sh
#!/bin/sh
echo "=== Package Version ==="
pkg info bind920 | grep Version
echo "=== Port Version ==="
make -C /usr/ports/dns/bind920 -V PORTVERSION
echo "=== Upstream Version ==="
fetch -q -o - https://www.isc.org/downloads/ | grep -o 'BIND [0-9.]*' | head -1
EOF
chmod +x ~/version_track.sh
```

**Extra Challenge**:
- Add version comparison
- Create update notifications
- Track multiple packages

### Challenge 10: The Integration Master
**Goal**: Combine multiple tools and methods

```bash
# Task 1: Create a comprehensive management script
cat << 'EOF' > ~/port_manager.sh
#!/bin/sh
case "$1" in
    "update")
        portsnap fetch update
        pkg update
        ;;
    "install")
        if [ -z "$2" ]; then
            echo "Specify package name"
            exit 1
        fi
        pkg install "$2" || (cd /usr/ports/*/"$2" && make install clean)
        ;;
    "clean")
        pkg clean
        portsclean -DD
        ;;
    *)
        echo "Usage: $0 {update|install|clean}"
        ;;
esac
EOF
chmod +x ~/port_manager.sh
```

**Extra Challenge**:
- Add more management features
- Create a TUI interface
- Implement logging and reporting

### Bonus: Points System
Keep track of your progress:
- Basic task completion: 1 point
- Extra challenge completion: 2 points
- Creative solution implementation: 3 points
- Documentation and sharing: 4 points

Create a progress tracker:
```bash
cat << 'EOF' > ~/progress.sh
#!/bin/sh
echo "Challenge Progress Tracker"
echo "========================"
read -p "Challenge number (1-10): " chal
read -p "Points earned (1-4): " points
echo "Challenge $chal: $points points" >> ~/progress.txt
total=$(awk '{sum += $NF} END {print sum}' ~/progress.txt)
echo "Total points: $total"
EOF
chmod +x ~/progress.sh
```


Last Updated: 2025-02-21 12:08:15 UTC
Author: manhal-mhd


