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

Last Updated: 2025-02-20 01:25:27 UTC
Author: manhal-mhd
