#!/bin/bash

set -e

echo "🚀 Starting ERP 19 installation..."

export DEBIAN_FRONTEND=noninteractive

# Update system
apt-get update -y
apt-get upgrade -y

# Install dependencies
apt-get install -y \
git python3 python3-venv python3-pip python3-dev \
libxml2-dev libxslt1-dev libffi-dev libpq-dev \
libjpeg-dev zlib1g-dev libsasl2-dev libldap2-dev \
build-essential curl wget nginx ufw

# PostgreSQL
systemctl start postgresql
sudo -u postgres createuser -s odoo || true

# Odoo user
id -u odoo &>/dev/null || useradd -m -d /opt/odoo -U -r -s /bin/bash odoo

# Clone Odoo 19
rm -rf /opt/odoo/odoo-server
git clone https://github.com/odoo/odoo --depth 1 --branch 19.0 /opt/odoo/odoo-server
chown -R odoo:odoo /opt/odoo

# Python env
sudo -u odoo python3 -m venv /opt/odoo/venv

# Fix pip + wheel
sudo -u odoo /opt/odoo/venv/bin/pip install --upgrade pip wheel setuptools

# Install SAFE gevent stack (critical fix)
sudo -u odoo /opt/odoo/venv/bin/pip install gevent==22.10.2 greenlet==3.0.3

# Remove broken gevent requirement
sed -i '/gevent/d' /opt/odoo/odoo-server/requirements.txt

# Install requirements
sudo -u odoo /opt/odoo/venv/bin/pip install -r /opt/odoo/odoo-server/requirements.txt

# Config
cat <<EOF > /etc/odoo.conf
[options]
admin_passwd = admin
db_user = odoo
addons_path = /opt/odoo/odoo-server/addons
logfile = /var/log/odoo.log
xmlrpc_port = 8069
proxy_mode = False
EOF

touch /var/log/odoo.log
chown odoo:odoo /var/log/odoo.log
chown odoo:odoo /etc/odoo.conf
chmod 640 /etc/odoo.conf

# Service
cat <<EOF > /etc/systemd/system/odoo.service
[Unit]
Description=ERP19
After=postgresql.service

[Service]
User=odoo
ExecStart=/opt/odoo/venv/bin/python3 /opt/odoo/odoo-server/odoo-bin -c /etc/odoo.conf
Restart=always

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable odoo
systemctl restart odoo

# Firewall
ufw allow 8069 || true

echo "✅ ERP 19 installed successfully!"
echo "👉 Access: http://YOUR-IP:8069"
