# Ubuntu Cache-only DNS Server Installation Guide
## BIND and Unbound Implementation Options (Using Service Commands)
Last Updated: 2025-11-17  
Author: manhal-mhd

## Table of Contents
1. [Overview](#overview)  
2. [Prerequisites](#prerequisites)  
3. [Identify Your VM IP](#identify-your-vm-ip)  
4. [Stop systemd-resolved (Important)](#stop-systemd-resolved-important)  
5. [Option A — Install & Configure BIND (bind9)](#option-a--install--configure-bind-bind9)  
6. [Option B — Install & Configure Unbound](#option-b--install--configure-unbound)  
7. [Ensure Only One DNS Service Is Running](#ensure-only-one-dns-service-is-running)  
8. [Firewall and Cloud Provider Network Rules](#firewall-and-cloud-provider-network-rules)  
9. [Test DNS Functionality (dig)](#test-dns-functionality-dig)  
10. [Validation Script (Automated Validation)](#validation-script-automated-validation)  
 

---

## Overview
This guide shows how to install and configure a caching DNS server on Ubuntu using either BIND (bind9) or Unbound. You must choose exactly ONE server (BIND OR Unbound). This guide uses traditional `service` commands instead of `systemctl`. Make sure only one DNS service listens on port 53, test with dig, and run the provided validation script.

**Important**: If switching from BIND to Unbound, you must completely remove BIND first.

## Prerequisites
- Ubuntu VM with sudo privileges
- Internet connectivity (for package installation and forwarders)
- Basic Linux command line knowledge
- dnsutils package (dig tool) will be installed if missing

Commands you'll use:
```bash
sudo apt update
sudo apt install -y dnsutils wget net-tools
```

## Identify Your VM IP
Find the non-loopback IPv4 address (this is YOUR_SERVER_IP for tests):
```bash
sudo ifconfig
```
or
```bash
ip addr show
```

Note the address that is **not** 127.0.0.1 (for example: 10.109.5.28 or 192.168.56.101). Use that IP in dig tests.

## Option A — Install & Configure BIND (bind9)

### Step 1: Install bind9
```bash
sudo apt update
sudo apt install -y bind9 bind9utils bind9-doc
```

### Step 2: Configure BIND
Edit main options file `/etc/bind/named.conf.options`:
```bash
sudo cp /etc/bind/named.conf.options /etc/bind/named.conf.options.bak
sudo nano /etc/bind/named.conf.options
```

Replace or edit the options section with the following (adjust the listen-on IP to match YOUR_SERVER_IP):

```conf
    
    recursion yes;                      // enable recursion (caching resolver)
    listen-on { 10.109.5.28; };        // listen on your IPv4 interface (change to your IP)
    listen-on-v6 { none; };            // disable IPv6 if not needed
    
    allow-query { 10.109.5.0/24; 127.0.0.1; };  // restrict queries to your subnet
    allow-recursion { 10.109.5.0/24; 127.0.0.1; };
    
```

**Important**: Replace `10.109.5.28` with your actual server IP and adjust the subnet `10.109.5.0/24` to match your network.

### Step 3: Check Configuration and Start BIND
Before starting the service, verify the configuration syntax:

```bash
# Check configuration syntax
sudo named-checkconf

# If no errors are shown, the configuration is valid
# Check zone files syntax (if any)
sudo named-checkconf -z
```

If the configuration is valid (no output means success), start the service:

```bash
# Start the service
sudo service bind9 start

# Enable it to start on boot
sudo update-rc.d bind9 enable

# Check status
sudo service bind9 status
```

### Step 4: Verify BIND is Running
```bash
# Check if bind9 is listening on port 53
sudo netstat -ulpn | grep :53

# Or use ss command
ss -ulpn | grep :53

# Test the configuration is working
dig @127.0.0.1 google.com +short
```

---

## Option B — Install & Configure Unbound

### Step 1: Remove BIND Completely (If Previously Installed)
**CRITICAL**: Before installing Unbound, you must completely remove BIND from the system:

```bash
# Stop bind9 service
sudo service bind9 stop

# Disable bind9 from starting on boot
sudo update-rc.d bind9 disable

# Remove bind9 packages completely
sudo apt remove --purge -y bind9* bind9utils bind9-doc

# Remove any leftover configuration files
sudo rm -rf /etc/bind
sudo rm -rf /var/cache/bind

# Clean up package database
sudo apt autoremove -y
sudo apt clean

# Verify bind9 is completely removed
dpkg -l | grep bind9
```

The last command should return no results. If it does, remove any remaining bind9 packages.

### Step 2: Install Unbound
```bash
sudo apt update
sudo apt install -y unbound
sudo service unbound start 
```

### Step 3: Configure Unbound
Create the configuration directory and local configuration file:

```bash
# Create unbound directory structure
sudo mkdir -p /etc/unbound/unbound.conf.d

# Create the local configuration file
sudo nano /etc/unbound/unbound.conf.d/local.conf
```

Add the following configuration (adjust interface and access-control to match your network):

```conf
server:                                                                                                                                                                   
      # the working directory.                                                                                                                                            
      directory: "/etc/unbound"                                                                                                                                           

      # run as the unbound user                                                                                                                                           
      username: unbound                                                                                                                                                   
                                                                                                                                                                          
      verbosity: 2      # uncomment and increase to get more logging.                                                                                                     
                                                                                                                                                                          
      # listen on all interfaces, answer queries from the local subnet.                                                                                                   
      interface: 10.109.5.28
      interface: 127.0.0.1                                                                                                                                                
      # comment out the following line if your system doesn't have IPv6.                                                                                                  
      #interface: ::0                                                                                                                                                     
                                                                                                                                                                          
      # perform prefetching of almost expired DNS cache entries.                                                                                                          
      prefetch: yes                                                                                                                                                       
                                                                                                                                                                          
      access-control: 10.0.0.0/8 allow                                                                                                                                    
      access-control: 127.0.0.1/24 allow                                                                                                                                  
      access-control: 2001:DB8::/64 allow                                                                                                                                 
                                                                                                                                                                          
      # hide server info from clients                                                                                                                                     
      hide-identity: yes                                                                                                                                                  
      hide-version: yes                       
```


**Important**: Replace `10.109.5.28` with your actual server IP and adjust the subnet `10.109.5.0/24` to match your network.

### Step 4: Check Configuration and Start Unbound
Before starting the service, verify the configuration syntax:

```bash
# Check configuration syntax
sudo unbound-checkconf

# Expected output if valid:
# unbound-checkconf: no errors in /etc/unbound/unbound.conf
```

If the configuration is valid, start the service:

```bash
# Start the service
sudo service unbound start

# Enable it to start on boot
sudo update-rc.d unbound enable

# Check status
sudo service unbound status
```

### Step 5: Verify Unbound is Running
```bash
# Check if unbound is listening on port 53
sudo netstat -ulpn | grep :53

# Or use ss command
ss -ulpn | grep :53

# Test the configuration is working
dig @127.0.0.1 google.com +short
```

---

## Ensure Only One DNS Service Is Running

Check which process is listening on port 53:
```bash
sudo netstat -ulpn | grep :53
```

Example output:
```
udp   UNCONN  0      0       10.109.5.28:53        0.0.0.0:*    users:(("named",pid=1234,fd=512))
```

Check service status:
```bash
sudo service bind9 status
sudo service unbound status
```

### If You Need to Switch Services

**To stop BIND and use Unbound:**
```bash
sudo service bind9 stop
sudo update-rc.d bind9 disable
sudo apt remove --purge -y bind9 bind9utils bind9-doc
sudo rm -rf /etc/bind /var/cache/bind
```

**To stop Unbound and use BIND:**
```bash
sudo service unbound stop
sudo update-rc.d unbound disable
sudo apt remove --purge -y unbound
sudo rm -rf /etc/unbound
```

---

## Test DNS Functionality (dig)

From any host that can reach YOUR_SERVER_IP (including the VM itself), run:

```bash
dig @YOUR_SERVER_IP google.com
```

Example with short output:
```bash
dig @10.109.5.28 google.com +short
```

This should return one or more IP addresses for google.com.

### Full Test Example:
```bash
dig @10.109.5.28 google.com
```

A successful output shows:
- `status: NOERROR`
- `ANSWER SECTION` containing A records for google.com
- Query time and server response

### Test Both UDP and TCP:
```bash
# Test UDP (default)
dig @10.109.5.28 google.com

# Test TCP
dig @10.109.5.28 google.com +tcp
```

### Additional Test Commands:
```bash
# Test from localhost
dig @127.0.0.1 google.com

# Test different domains
dig @10.109.5.28 cloudflare.com
dig @10.109.5.28 ubuntu.com

# Test reverse lookup
dig @10.109.5.28 -x 8.8.8.8
```

---

## Validation Script (Automated Validation)

The assignment includes a validation script to verify your DNS server setup.

### Step 1: Download the Validation Script
```bash
wget https://raw.githubusercontent.com/manhal-mhd/netops1/refs/heads/main/Validate_Forth_Week_Assignment-Ubuntu.sh
```

Or use curl:
```bash
curl -Lo https://raw.githubusercontent.com/manhal-mhd/netops1/refs/heads/main/Validate_Forth_Week_Assignment-Ubuntu.sh
```

### Step 2: Make Executable and Run
```bash
bash Validate_Forth_Week_Assignment.sh
```

### Expected Validator Behavior:
- Runs dig against YOUR_SERVER_IP
- Checks for `STATUS: NOERROR` and Answer section
- Verifies only one DNS service (bind9 OR unbound) is running
- On success prints "SUCCESS" message

**Take a screenshot of the SUCCESS output for your assignment submission.**

---


**Good luck with your assignment!** 
