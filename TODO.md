    "@bower_components/jquery-autosize": "jackmoore/autosize#2.0.0",
    "@bower_components/purl": "allmarkedup/purl#*"
    "postinstall": "node -e \"try { require('fs').symlinkSync(require('path').resolve('node_modules/@bower_components'), 'vendor/assets/components', 'junction') } catch (e) { }\"",

