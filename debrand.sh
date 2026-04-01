#!/bin/bash

set -e

echo "🚀 Starting ERP branding..."

# Create custom addons folder
mkdir -p /opt/odoo/custom-addons/erp_branding

# Create module structure
mkdir -p /opt/odoo/custom-addons/erp_branding/models
mkdir -p /opt/odoo/custom-addons/erp_branding/views

# __manifest__.py
cat <<EOF > /opt/odoo/custom-addons/erp_branding/__manifest__.py
{
    "name": "ERP Branding",
    "version": "1.0",
    "summary": "Custom ERP Branding",
    "author": "Your Company",
    "category": "Tools",
    "depends": ["web"],
    "data": [
        "views/webclient.xml"
    ],
    "installable": True,
    "application": False
}
EOF

# __init__.py
cat <<EOF > /opt/odoo/custom-addons/erp_branding/__init__.py
# empty
EOF

# webclient.xml (basic rename)
cat <<EOF > /opt/odoo/custom-addons/erp_branding/views/webclient.xml
<odoo>
    <template id="custom_title" inherit_id="web.layout">
        <xpath expr="//title" position="replace">
            <title>ERP</title>
        </xpath>
    </template>
</odoo>
EOF

# Add custom addons path
if ! grep -q "custom-addons" /etc/odoo.conf; then
    sed -i 's|addons_path = .*|addons_path = /opt/odoo/odoo-server/addons,/opt/odoo/custom-addons|' /etc/odoo.conf
fi

# Restart Odoo
systemctl restart odoo

echo "✅ Branding module created"
echo "👉 Now install 'ERP Branding' from Apps inside Odoo UI"
