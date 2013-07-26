(function () {
    "use strict";
    // <%= name %>
    
    var tzData = {
        rules: <%= rules %>,
        zones: <%= zones %>
    };

    if (typeof window == 'undefined') {
        module.exports = tzData;
    } else if (typeof define != 'undefined') {
        define("walltime-data", [], function () {
            return tzData;
        });
    } else {
        this.WallTime || (this.WallTime = {});
        this.WallTime.data = tzData;
        this.WallTime.autoinit = true;
    }
}).call(this);