var express = require("express");
var bodyParser = require("body-parser");
var path = require("path");

module.exports = function(host="localhost", port="3000"){

	var app = express();

	app.use(bodyParser.json()); // for parsing application/json
	app.use(bodyParser.urlencoded({ extended: true })); // for parsing application/x-www-form-urlencoded

	require("./routes")(app);
	// load other assets
	app.use(express.static(__dirname+"/../"));

	const server = app.listen(port, host, function () {
		console.log("Server is running on port " + port + "...");
		console.log(`Open http://${host}:${port}/samples in browser`);
	});

	require("./websockets");
};
