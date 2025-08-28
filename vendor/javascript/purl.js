// purl@1.0.4 downloaded from https://ga.jspm.io/npm:purl@1.0.4/index.js

var a={};var r=/(([\w\.\-\+]+:)\/{2}(([\w\d\.]+):([\w\d\.]+))?@?(([a-zA-Z0-9\.\-_]+)(?::(\d{1,5}))?))?(\/(?:[a-zA-Z0-9\.\-\/\+\%\_]+)?)(?:\?([a-zA-Z0-9=%\-_\.\*&;]+))?(?:#([a-zA-Z0-9\-=,&%;\/\\"'\?]+)?)?/;a=function purl(a){var e=r.exec(a),o=1;return e?{origin:e[o++],protocol:e[o++],userinfo:e[o++],username:e[o++],password:e[o++],host:e[o++],hostname:e[o++],port:e[o++],pathname:e[o++],search:e[o++],hash:e[o++]}:{}};var e=a;export default e;

