const WebSocket = require('ws');

//live updates for data sample
const wss = new WebSocket.Server({ port:8080});
wss.on('connection', function connection(ws) {
	ws.on('message', function incoming(message) {
		message = _dummySave(message);
		wss.clients.forEach(function each(client) {
			client.send(message);
		});
	});
});

//emulate saving to db, where record id usually defined 
function _dummySave(message){
	message = JSON.parse(message);
	if(message.operation == "insert"){
		message.data.id = "s"+ message.data.id;
	}
	message = JSON.stringify(message);
	return message;
}