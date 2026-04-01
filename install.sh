#!/bin/bash

set -e

LOGFILE="/var/log/erp_install.log"

echo "🚀 Starting ERP 19 installation..." | tee -a $LOGFILE

export DEBIAN_FRONTEND=noninteractive

apt-get update -y >> $LOGFILE 2>&1
apt-get upgrade -y >> $LOGFILE 2>&1

apt-get install -y \
git python3 python3-venv python3-pip python3-dev \
libxml2-dev libxslt1-dev libffi-dev libpq-dev \
libjpeg-dev zlib1g-dev libsasl2-dev libldap2-dev \
build-essential curl wget >> $LOGFILE 2>&1

systemctl start postgresql
sudo -u postgres createuser -s odoo || true

id -u odoo &>/dev/null || useradd -m -d /opt/odoo -U -r -s /bin/bash odoo

rm -rf /opt/odoo
mkdir -p /opt/odoo

git clone https://github.com/odoo/odoo --depth 1 --branch 19.0 /opt/odoo/odoo-server >> $LOGFILE 2>&1

chown -R odoo:odoo /opt/odoo

sudo -u odoo python3 -m venv /opt/odoo/venv

sudo -u odoo /opt/odoo/venv/bin/pip install --upgrade pip wheel setuptools >> $LOGFILE 2>&1

sudo -u odoo /opt/odoo/venv/bin/pip install gevent==22.10.2 greenlet==3.0.3 >> $LOGFILE 2>&1

sed -i '/gevent/d' /opt/odoo/odoo-server/requirements.txt

sudo -u odoo /opt/odoo/venv/bin/pip install -r /opt/odoo/odoo-server/requirements.txt >> $LOGFILE 2>&1

cat <<EOF > /etc/odoo.conf
[options]
admin_passwd = admin
db_user = odoo
addons_path = /opt/odoo/odoo-server/addons
logfile = /var/log/odoo.log

xmlrpc_interface = 0.0.0.0
xmlrpc_port = 8069

longpolling_port = 8072
proxy_mode = False

workers = 2
EOF

touch /var/log/odoo.log
chown odoo:odoo /var/log/odoo.log
chown odoo:odoo /etc/odoo.conf
chmod 640 /etc/odoo.conf

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

systemctl daemon-reexec
systemctl daemon-reload
systemctl enable odoo.service
systemctl restart odoo.service

echo "✅ ERP installed: http://YOUR-IP:8069"
