module.exports = function(app){

	const root = "/kanban/samples/server";
	require("./collections")(app, root);
	require("./tasks-common")(app, root);
	require("./tasks-attachments")(app, root);
	require("./tasks-normalized")(app, root);

}