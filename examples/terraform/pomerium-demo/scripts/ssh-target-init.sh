#!/bin/bash
set -e

# Update system
apt-get update
apt-get upgrade -y

# Install required packages
apt-get install -y \
  openssh-server \
  sudo \
  curl \
  wget \
  git \
  vim \
  htop \
  tmux \
  net-tools \
  dnsutils \
  tcpdump \
  iperf3 \
  jq

# Create demo user
useradd -m -s /bin/bash demo
echo "demo:pomerium-demo" | chpasswd
usermod -aG sudo demo

# Configure SSH for demo
cat > /etc/ssh/sshd_config.d/demo.conf <<EOF
# Demo SSH configuration
PasswordAuthentication yes
PermitRootLogin no
PubkeyAuthentication yes
ChallengeResponseAuthentication no
UsePAM yes
X11Forwarding yes
PrintMotd yes
AcceptEnv LANG LC_*
Subsystem sftp /usr/lib/openssh/sftp-server
EOF

# Create welcome message
cat > /etc/motd <<EOF
╔═══════════════════════════════════════════════════════════════╗
║                                                               ║
║            Welcome to Pomerium SSH Proxy Demo!                ║
║                                                               ║
║  This server is accessible through Pomerium's TCP proxy       ║
║  feature, demonstrating secure access to internal resources.  ║
║                                                               ║
║  Demo commands:                                               ║
║  - pomerium-info    : Show connection information             ║
║  - pomerium-test    : Run connectivity tests                  ║
║                                                               ║
╚═══════════════════════════════════════════════════════════════╝
EOF

# Create demo scripts
cat > /usr/local/bin/pomerium-info <<'SCRIPT'
#!/bin/bash
echo "=== Pomerium SSH Demo Information ==="
echo
echo "Hostname: $(hostname)"
echo "IP Address: $(hostname -I | cut -d' ' -f1)"
echo "Uptime: $(uptime -p)"
echo
echo "Connection Details:"
echo "- You are connected through Pomerium's TCP proxy"
echo "- Your identity has been verified by Pomerium"
echo "- This connection is fully encrypted end-to-end"
echo
if [ ! -z "$POMERIUM_JWT" ]; then
    echo "Pomerium JWT detected in environment"
    echo "Decoding JWT claims..."
    echo "$POMERIUM_JWT" | cut -d. -f2 | base64 -d 2>/dev/null | jq . 2>/dev/null || echo "Unable to decode JWT"
fi
SCRIPT

cat > /usr/local/bin/pomerium-test <<'SCRIPT'
#!/bin/bash
echo "=== Running Pomerium Demo Tests ==="
echo
echo "1. Testing DNS resolution..."
nslookup demo.pomerium.com || echo "DNS lookup failed"
echo
echo "2. Testing outbound connectivity..."
curl -s -o /dev/null -w "HTTP Status: %{http_code}\n" https://verify.demo.pomerium.com || echo "Connection failed"
echo
echo "3. Checking system resources..."
echo "CPU Usage: $(top -bn1 | grep "Cpu(s)" | sed "s/.*, *\([0-9.]*\)%* id.*/\1/" | awk '{print 100 - $1}')%"
echo "Memory Usage: $(free -m | awk 'NR==2{printf "%.2f%%", $3*100/$2}')"
echo "Disk Usage: $(df -h / | awk 'NR==2{print $5}')"
echo
echo "Tests complete!"
SCRIPT

chmod +x /usr/local/bin/pomerium-info
chmod +x /usr/local/bin/pomerium-test

# Create demo content in user home
sudo -u demo bash <<'USERSETUP'
cd /home/demo

# Create welcome file
cat > README.md <<EOF
# Pomerium SSH Proxy Demo

Welcome to the Pomerium SSH proxy demonstration server!

## What is this?

This server demonstrates Pomerium's TCP proxy capabilities, allowing secure SSH access to internal resources through Pomerium's authentication and authorization system.

## Available Commands

- \`pomerium-info\`: Display connection and identity information
- \`pomerium-test\`: Run basic connectivity tests

## Demo Files

This directory contains some example files to demonstrate file transfer capabilities through the proxied connection.

## Learn More

Visit https://www.pomerium.com/docs/tcp/ to learn more about Pomerium's TCP proxy features.
EOF

# Create some demo files
mkdir -p projects/demo
echo "This is a demo file accessible through Pomerium SSH proxy" > projects/demo/example.txt
echo '{"demo": true, "purpose": "pomerium-ssh-proxy", "secure": true}' > projects/demo/config.json

# Create a simple script
cat > projects/demo/hello.sh <<'EOF'
#!/bin/bash
echo "Hello from Pomerium SSH Demo!"
echo "Current time: $(date)"
echo "Your connection is secured by Pomerium"
EOF
chmod +x projects/demo/hello.sh
USERSETUP

# Restart SSH service
systemctl restart sshd

# Enable SSH service
systemctl enable sshd

echo "SSH demo target initialization complete!"