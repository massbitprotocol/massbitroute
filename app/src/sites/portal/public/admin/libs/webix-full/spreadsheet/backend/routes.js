module.exports = function(app){
	const root = "/spreadsheet/samples/server";
	require("./images")(app, root);
	require("./spreadsheets")(app, root);
	require("./pages")(app, root);
}