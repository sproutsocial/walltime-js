var path = require("path");
var webpack = require("webpack");

module.exports = function(env) {
  var outputFile = '[name].js',
      libraryName = 'WallTime'
  console.log("Env: ", env);
  // if(env=="production") outputFile = '[name].min.js'
  return {
    devtool: 'source-map',
    output: {
      path: __dirname + '/build',
      filename: outputFile,
      library: libraryName,
      libraryTarget: 'umd',
      umdNamedDefine: true
    },
    resolve: {
        extensions: ['.js', '.json', '.coffee', 'html'],
        alias: {
          'walltime-data':  __dirname + '/lib/walltime/walltime-data.js'
        }
    },
    entry: {
      walltime: "./lib/walltime.coffee"
    },
    plugins: [
        new webpack.DefinePlugin({
          "define": () => true,
          "process.env": {
              BROWSER: JSON.stringify(true)
          },
          'require.specified':'require.resolve'
      }),
    ],
    module:{
      rules: [
          {
            test: /\.json$/,
            loader: "json-loader"
          },
          {
            test: /\.coffee$/,
            loader: "coffee-loader"
          },
          {
            test: /\.js$/,
            loader: 'babel-loader',
            exclude: [
              /node_modules/,
              /\.spec\.js$/
            ],
            query: {
              presets: ['es2015']
            }
          }
      ]
    }
  }
};
