var path = require('path');
var ExtractTextPlugin = require("extract-text-webpack-plugin");
var LiveReloadPlugin = require('webpack-livereload-plugin');

var config = {
	entry: {
		"hint":'./sources/hint'
	},
	output: {
		path: path.join(__dirname, 'codebase'),
		publicPath:"/codebase/",
		filename: '[name].js'
	},
	module: {
		rules: [
			{
				test: /\.js$/,
				use: [{
					loader: 'babel-loader',
					options: { presets: ['es2015'] },
				}]
			},
			{
				test: /\.(png|jpg|gif)$/,
				loader: 'url?limit=25000'
			},
			{
				test: /\.less/,
				loader: ExtractTextPlugin.extract(
					"css-loader!less-loader!postcss-loader"
				)
			}
		]
	},
	resolve: {
		extensions: ['*', '.js'],
		modules: ["./sources", "node_modules"],
	},
	plugins: [
		new ExtractTextPlugin("./hint.css"),
		new LiveReloadPlugin()
	]
};

module.exports = config;