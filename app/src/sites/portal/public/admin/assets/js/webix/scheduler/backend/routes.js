module.exports = function(app){
	const root = "/scheduler/samples/server";
	require("./data")(app, root);
	require("./dyn_data")(app, root);
}