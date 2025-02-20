# FreeBSD Cache-only DNS Server Installation Guide
## BIND and Unbound Implementation Options
Last Updated: 2025-02-19 11:45:11 UTC
Author: manhal-mhd

## Table of Contents
1. [Lab Environment Setup](#lab-environment-setup)
2. [DNS Server Options](#dns-server-options)
3. [Option A: Installing BIND](#option-a-installing-bind)
4. [Option B: Installing Unbound](#option-b-installing-unbound)
5. [Important Notes on Compatibility](#important-notes-on-compatibility)

## Lab Environment Setup

### Accessing Your Lab Environment
1. Open your web browser and navigate to:
   ```
   https://n2.nog-oc.org/youremailaddress/
   ```

2. Use the following default credentials:
   - Username: `afnog`
   - Password: `admin`

### Elevating Privileges
When first logged in, you'll need root access:
```bash
su -
```

### Verify Network Configuration
Check your network settings and note down your IP addresses:
```bash
ifconfig
```

In our lab environment as example :
- IPv4 Address: 192.168.0.217
- Loopback Address: 127.0.0.217

## DNS Server Options

> **IMPORTANT**: You cannot run both BIND and Unbound simultaneously as they both use port 53.

### Choosing Between BIND and Unbound

| Feature | BIND | Unbound |
|---------|------|----------|
| Resource Usage | Higher | Lower |
| Configuration Complexity | More Complex | Simpler |
| Feature Set | Full DNS server suite | Focused on resolving |
| Best Use Case | Full DNS server needs | Caching resolver |
| Memory Footprint | Larger | Smaller |

## Important Notes on Compatibility

Before installing either DNS server, check for existing installations:
```bash
# Check running DNS services
sockstat -l | grep ":53"

# Check for BIND
pkg info | grep bind

# Check for Unbound
pkg info | grep unbound
```

If you need to switch between servers:
1. Stop and disable existing service
2. Remove existing package
3. Clean up configuration files
4. Verify port 53 is free

## Option A: Installing BIND

### A1. Installation

#### Search for Available BIND Packages
```bash
pkg search bind
```

Expected output:
```
bind-tools-9.20.5              Command line tools from BIND
bind9-devel-9.21.4             BIND DNS suite with updated DNSSEC and DNS64
bind918-9.18.33                BIND DNS suite with updated DNSSEC and DNS64
bind920-9.20.5                 BIND DNS suite with updated DNSSEC and DNS64
```

#### Install BIND 9.20
```bash
pkg install bind920-9.20.5
```

### A2. Configuration

#### Enable BIND Service
```bash
sysrc named_enable=YES
```

#### Navigate to Configuration Directory
```bash
cd /usr/local/etc/namedb
```

#### Edit named.conf
```bash
vi named.conf
```

Add/modify these sections:
```
listen-on {
    127.0.0.217;
    192.168.0.217;
};

recursion yes;
```

### A3. Validation and Start

#### Check Configuration
```bash
named-checkconf
```

#### Start Service
```bash
service named restart
```

#### Test BIND
```bash
dig @192.168.0.217 google.com
```

![image](https://github.com/user-attachments/assets/7e1ed96b-ff80-4a1b-9eb4-b70166b64526)


## Option B: Installing Unbound

### Important: BIND and Unbound Compatibility

> **WARNING**: BIND and Unbound cannot run simultaneously as they both try to use port 53. You must remove BIND before installing Unbound.

#### 1. Check for Existing BIND Installation
First, check if BIND is installed and running:
```bash
# Check if BIND service is running
service named status

# Check for BIND package
pkg info | grep bind
```

#### 2. Remove BIND (If Installed)

1. Stop the BIND service:
   ```bash
   service named stop
   ```

2. Disable BIND from starting at boot:
   ```bash
   sysrc named_enable="NO"
   ```

3. Remove BIND package and its dependencies:
   ```bash
   pkg remove bind920
   ```

4. Verify port 53 is free:
   ```bash
   sockstat -l | grep ":53"
   ```
   If this command returns no output, port 53 is available.

5. Clean up BIND configuration files (optional):
   ```bash
   rm -rf /usr/local/etc/namedb/*
   ```
   > **Note**: Make sure to backup any important zone files or configurations before deletion.

Only after completing these steps should you proceed with the Unbound installation.
### B1. Installation

#### Search for Unbound Package
```bash
pkg search unbound
```

#### Install Unbound
```bash
pkg install unbound
```

### B2. Configuration

#### Enable Unbound Service
```bash
sysrc unbound_enable="YES"
```

#### Create Configuration
```bash
vi /usr/local/etc/unbound/unbound.conf
```

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

#### Check Configuration
   ```bash
   unbound-checkconf          
   ```
### B4. Start and Test

#### Start Unbound
```bash
service unbound start
```

#### Test Resolution
```bash
dig @127.0.0.217 google.com
```
![image](https://github.com/user-attachments/assets/d24ae920-6134-4ffd-ac03-49377b0c47a2)

## Maintenance and Monitoring

### For BIND
```bash
# Check logs
tail -f /var/log/messages | grep named

# Check status
service named status
```

### For Unbound
```bash
# View statistics
unbound-control stats

# Check logs
tail -f /var/log/messages | grep unbound

# Check status
service unbound status
```

## Troubleshooting

### Common Issues

1. **Service Won't Start**
   ```bash
   # Check port 53
   sockstat -l | grep ":53"
   
   # Check logs
   tail -f /var/log/messages
   ```

2. **DNS Resolution Problems**
   ```bash
   # Test local resolution
   dig @127.0.0.217 google.com
   
   # Check service status
   service named status   # for BIND
   service unbound status # for Unbound
   ```

## Security Recommendations

1. Regular Updates
   ```bash
   pkg update && pkg upgrade
   ```

2. Monitor Logs
   ```bash
   tail -f /var/log/messages
   ```

3. Verify Configuration
   ```bash
   named-checkconf              # for BIND
   unbound-checkconf           # for Unbound
   ```

## Additional Resources

### BIND Resources
- [BIND Documentation](https://www.isc.org/bind/)
- [BIND Administrator Reference Manual](https://bind9.readthedocs.io/)

### Unbound Resources
- [Unbound Documentation](https://nlnetlabs.nl/documentation/unbound/)
- [Unbound Security Guide](https://nlnetlabs.nl/documentation/unbound/howto-optimise/)

### FreeBSD Resources
- [FreeBSD Handbook - DNS Section](https://docs.freebsd.org/en/books/handbook/network-servers/#network-dns)

Last Updated: 2025-02-19 11:45:11 UTC
Author: manhal-mhd# netops1
# netops1
