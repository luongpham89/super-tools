#!/bin/bash

# Exit immediately if a command exits with a non-zero status
set -e

echo "----------------------------------------------------"
echo "  Starting Professional Node Exporter Installation  "
echo "----------------------------------------------------"

# 1. Check for root privileges
if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root (use sudo)"
   exit 1
fi

# 2. Identify System Architecture
ARCH=$(uname -m)
case $ARCH in
    x86_64) ARCH="amd64" ;;
    aarch64) ARCH="arm64" ;;
    armv7l) ARCH="armv7" ;;
    *) echo "Unsupported architecture: $ARCH"; exit 1 ;;
esac

# 3. Fetch Latest Version from GitHub API
echo "Fetching latest version info..."
VERSION=$(curl -s https://api.github.com/repos/prometheus/node_exporter/releases/latest | grep tag_name | cut -d '"' -f 4 | sed 's/v//')

if [ -z "$VERSION" ]; then
    echo "Failed to fetch version. Falling back to 1.8.2"
    VERSION="1.8.2"
fi

echo "Installing version: $VERSION for $ARCH"

# 4. Create System User
if ! id "node_exporter" &>/dev/null; then
    echo "Creating node_exporter user..."
    useradd --no-create-home --shell /bin/false node_exporter
else
    echo "User node_exporter already exists."
fi

# 5. Download and Extract
TEMP_DIR=$(mktemp -d)
cd "$TEMP_DIR"
URL="https://github.com/prometheus/node_exporter/releases/download/v${VERSION}/node_exporter-${VERSION}.linux-${ARCH}.tar.gz"

echo "Downloading from: $URL"
curl -LO "$URL"
tar -xvf "node_exporter-${VERSION}.linux-${ARCH}.tar.gz"

# 6. Install Binary
cp "node_exporter-${VERSION}.linux-${ARCH}/node_exporter" /usr/local/bin/
chown node_exporter:node_exporter /usr/local/bin/node_exporter

# 7. Create Systemd Service
echo "Creating Systemd service..."
cat <<EOF > /etc/systemd/system/node_exporter.service
[Unit]
Description=Node Exporter
Wants=network-online.target
After=network-online.target

[Service]
User=node_exporter
Group=node_exporter
Type=simple
ExecStart=/usr/local/bin/node_exporter
Restart=always

[Install]
WantedBy=multi-user.target
EOF

# 8. Reload and Start
systemctl daemon-reload
systemctl enable node_exporter
systemctl start node_exporter

# 9. Cleanup
rm -rf "$TEMP_DIR"

echo "----------------------------------------------------"
echo "SUCCESS: Node Exporter is running on port 9100"
echo "Check metrics at: http://$(hostname -I | awk '{print $1}'):9100/metrics"
echo "----------------------------------------------------"
