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

        concat: {
            options: {
                banner: grunt.file.read('masthead.tpl')
            },

            lib: {
                expand: true,
                src: ['client/walltime*.js', '!client/walltime-data*.js']
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

        // Run mocha unit tests
        simplemocha: {
            options: {
                compilers: ["coffee:coffee-script"],
                ui: 'bdd',
                reporter: 'spec'
            },

            all: ["test/*_spec.coffee"]
        },

        "walltime-data": {
            all: {}
        },

        "walltime-individual": {
            all: {}
        },

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

        bump: {
            options: {
                push: false,
                updateConfigs: ['pkg']
            }
        }
    };

    grunt.initConfig(cfg);

    LibBuilder.registerGruntTask(grunt);

    grunt.registerTask("lib", [
        "test",
        "clean:lib",
        "coffee:lib",
        "requirejs:lib",
        "requirejs:libmin",
        "concat:lib",
        "clean:lib"
    ]);

    grunt.registerTask("data", [
        "test",
        "clean:data",
        "walltime-data:all",
        "walltime-verify:data",
        "concat:data"
    ]);

    grunt.registerTask("individual", [
        "test",
        "clean:individual",
        "walltime-individual:all",
        "walltime-verify:individual",
        "concat:individual",
        "compress:individual",
        "compress:individual-min"
    ]);

    grunt.registerTask("test", ["simplemocha:all"]);

    grunt.registerTask("release", [
        "test",
        "bump",
        "lib",
        "data",
        "individual",
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
        grunt.log.writeln(" - run unit tests");
    });
};