#!/bin/bash
cd ~
wget https://go.dev/dl/go1.21.4.linux-amd64.tar.gz
rm -rf /usr/local/go && tar -C /usr/local -xzf go1.21.4.linux-amd64.tar.gz
export PATH=$PATH:/usr/local/go/bin
apt install git -y
cd /opt
git clone https://github.com/netwatcherio/netwatcher-agent.git
cd ./netwatcher-agent
go build
chmod +x netwatcher-agent
# Define the service file path
SERVICE_FILE="/etc/systemd/system/netwatcher-agent.service"

# Check if running as root, exit if not
if [ "$(id -u)" -ne 0 ]; then
    echo "This script must be run as root."
    exit 1
fi

# Create and write the service configuration to the file
cat > "$SERVICE_FILE" << EOF
[Unit]
Description=Netwatcher Agent Service
After=network.target

[Service]
Type=simple
ExecStart=/opt/netwatcher-agent/netwatcher-agent
WorkingDirectory=/opt/netwatcher-agent
Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF

# Provide feedback
echo "Service file created at $SERVICE_FILE"

systemctl daemon-reload
systemctl enable netwatcher-agent

service netwatcher-agent start
