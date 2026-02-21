var websockify = require('@maximegris/node-websockify');

websockify({
  source: 'localhost:8080',
  target: 'localhost:5900'
});