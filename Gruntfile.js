var LibBuilder = require("./lib/build");
var WebpackConfig=require('./webpack.config');
module.exports = function (grunt) {
    grunt.loadNpmTasks('grunt-webpack');
    // load all grunt tasks
    require('matchdep').filterDev('grunt-*').forEach(grunt.loadNpmTasks);

    // The config info
    var cfg = {
        webpack: {
            main: WebpackConfig
        },
        pkg: grunt.file.readJSON('package.json'),

        // Remove any compiled js files
        clean: {
            lib: [
                'build/'
            ]
        },

        // Compile the coffeescript files to js
        coffee: {
            lib: {
                files: [{
                    expand: true,
                    cwd: 'lib',
                    src: "**/*.coffee",
                    dest: 'build/lib',
                    ext: '.js'
                }]
            }
        },

        // Copy relevant files over for a commonjs build (i.e. Titanium)
        copy: {
            data: {
                expand: true,
                cwd: 'lib/',
                src: 'walltime-data.json',
                dest: 'build/lib/'
            }
        },

        // Lint coffee files (indendation and style consistency)
        coffeelint: {
            options: {
                max_line_length: {
                    level: "ignore"
                },
                indentation: {
                    value: 4
                }
            },

            lib: ["lib/**/*.coffee"]
        },

        // Lint the javascript files
        jshint2: {
            options: {
                jshintrc: ".jshintrc"
            },

            all: ["Gruntfile.js", "index.js"]
        },

        // Run mocha unit tests
        simplemocha: {
            options: {
                compilers: ["coffee:coffee-script"],
                ui: 'bdd',
                // reporter: 'spec'
            },

            all: ["test/*_spec.coffee"]
        },

        // Start a connect server to serve client side mocha html tests for mocha_phantomjs
        connect: {
            server: {
                options: {
                    port: 7000,
                    base: __dirname
                }
            }
        },

        // Load the mocha client side test page with phantomjs to test that the library works
        // in a browser.
        mocha_phantomjs: {
            webpack: {
                options: {
                    verbose: true,
                    urls: ["http://localhost:<%= connect.server.options.port %>/test/client/index-require.html"]
                }
            },

            release: {
                options: {
                    verbose: true,
                    urls: ["http://localhost:<%= connect.server.options.port %>/test/client/release.html"]
                }
            }
        },

        // Bump the version of the package.json for releases
        bump: {
            options: {
                files: ['package.json', 'bower.json'],
                updateConfigs: ['pkg'],
                commitFiles: ["-a"],
                push: true,
                pushTo: "origin"
            }
        }
    };

    grunt.initConfig(cfg);

    // Load the data building walltime- grunt tasks
    LibBuilder.registerGruntTask(grunt);

    // Build lib
    grunt.registerTask("compile",[
        "webpack",
        "coffee:lib",
        "copy:data"
    ]);

    grunt.registerTask("lib", [
        "clean:lib",
        "compile",
        "test"
    ]);


    // Lint and test code
    grunt.registerTask("test", [
        "coffeelint:lib",
        "jshint2:all",
        "simplemocha:all"
    ]);

    // Test lib and data in phantomjs browser
    grunt.registerTask("browsertest", [
        "connect:server",
        "mocha_phantomjs:release",
        "mocha_phantomjs:webpack"
    ]);

    // Do build and test
    grunt.registerTask("stage", [
        "test",
        "lib",
        "browsertest"
    ]);

    // Bump version and do build
    grunt.registerTask("release", [
        "bump-only:minor",
        "stage",
        "bump-commit"
    ]);

    grunt.registerTask("default", function () {
        grunt.log.writeln("");
        grunt.log.writeln("grunt lib");
        grunt.log.writeln(" - build the client library");
        grunt.log.writeln("grunt test");
        grunt.log.writeln(" - run unit tests and lint code");
    });
};