var LibBuilder = require("./lib/build");

module.exports = function (grunt) {
    // load all grunt tasks
    require('matchdep').filterDev('grunt-*').forEach(grunt.loadNpmTasks);

    // The config info
    var cfg = {
        pkg: grunt.file.readJSON('package.json'),

        // Remove any compiled js files
        clean: {
            lib: [
                'lib/**/*.js'
            ],
            data: [
                'client/walltime-data*.js'
            ],
            individual: [
                'client/individual/*.{js,zip}'
            ]
        },

        // Compile the coffeescript files to js
        coffee: {
            lib: {
                files: [{
                    expand: true,
                    cwd: 'lib',
                    src: "**/*.coffee",
                    dest: 'lib',
                    ext: '.js'
                }]
            }
        },

        // Add the masthead information to each built file
        concat: {
            options: {
                banner: grunt.file.read('masthead.tpl')
            },

            lib: {
                expand: true,
                src: ['client/walltime*.js', 'client/commonjs/**/*.js', '!client/walltime-data*.js']
            },

            data: {
                expand: true,
                src: ['client/walltime-data*.js']
            },

            individual: {
                expand: true,
                src: ['client/individual/walltime-data*.js']
            }

        },

        // Build the walltime library with requirejs
        requirejs: {
            options: {
                baseUrl: "lib",
                name: "walltime",
                optimize: "none"
            },

            lib: {
                options: {
                    out: "client/walltime.js"
                }
            },
            
            libmin: {
                options: {
                    out: "client/walltime.min.js",
                    optimize: "uglify"
                }
            }
        },

        // Copy relevant files over for a commonjs build (i.e. Titanium)
        copy: {
            commonjs: {
                files: [{
                    expand: true,
                    cwd: 'lib/',
                    src: ['walltime.js', 'olson/helpers.js', 'olson/rule.js', 'olson/zone.js', 'olson/timezonetime.js'],
                    dest: "client/commonjs"
                }]
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
                reporter: 'spec'
            },

            all: ["test/*_spec.coffee"]
        },

        // Build the big walltime-data.js file
        "walltime-data": {
            all: {}
        },

        // Build the individual files; i.e. walltime-data[Africa-Cairo].js
        "walltime-individual": {
            all: {}
        },

        // Verify that a data file has rules or zones
        "walltime-verify": {
            data: {
                options: {
                    allowEmptyRules: false,
                    allowEmptyZones: false
                },

                files: {
                    src: ["client/walltime-data.js"]
                }
            },

            individual: ["client/individual/*.js"]
        },

        // Zip up all the individual data files.
        compress: {
            individual: {
                options: {
                    archive: "client/individual/walltime-data.zip"
                },
                expand: true,
                cwd: "client/individual",
                src: ["*.js", "!*.min.js"]
            },
            "individual-min": {
                options: {
                    archive: "client/individual/walltime-data-min.zip"
                },
                expand: true,
                cwd: "client/individual",
                src: ["*.min.js"]
            }
        },

        // Start a connect server to serve client side mocha html tests for mocha_phantomjs
        connect: {
            server: {
                options: {
                    port: 8000,
                    base: '.'
                }
            }
        },

        // Load the mocha client side test page with phantomjs to test that the library works
        // in a browser.
        mocha_phantomjs: {
            requirejs: {
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
    grunt.registerTask("lib", [
        "test",
        "clean:lib",
        "coffee:lib",
        "requirejs:lib",
        "requirejs:libmin",
        "copy:commonjs",
        "concat:lib",
        "clean:lib"
    ]);

    // Build entire data file
    grunt.registerTask("data", [
        "test",
        "clean:data",
        "walltime-data:all",
        "walltime-verify:data",
        "concat:data"
    ]);

    // Build individual data files
    grunt.registerTask("individual", [
        "test",
        "clean:individual",
        "walltime-individual:all",
        "walltime-verify:individual",
        "concat:individual",
        "compress:individual",
        "compress:individual-min"
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
        "mocha_phantomjs:requirejs"
    ]);

    // Do build and test
    grunt.registerTask("stage", [
        "test",
        "lib",
        "data",
        "individual",
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
        grunt.log.writeln("grunt data");
        grunt.log.writeln(" - build data files");
        grunt.log.writeln("grunt individual");
        grunt.log.writeln(" - build data files");
        grunt.log.writeln("grunt test");
        grunt.log.writeln(" - run unit tests and lint code");
    });
};