{
    'name': 'ERP Branding',
    'version': '1.0',
    'category': 'Tools',
    'summary': 'Custom ERP Branding',
    'depends': ['web'],
    'data': [
        'views/webclient.xml',
    ],
    'assets': {
        'web.assets_backend': [
            'erp_branding/static/src/img/logo.png',
        ],
    },
    'installable': True,
    'application': False,
}
