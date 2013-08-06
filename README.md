walltime-js [![Build Status](https://secure.travis-ci.org/sproutsocial/walltime-js.png)](http://travis-ci.org/sproutsocial/walltime-js)
===========

Walltime-js is a JavaScript library for easily translating a UTC time to a "Wall Time" for a particular time zone.

## Problems this solves

Dates in JavaScript do not properly account for daylight savings time for regions other than your own browser configured time zone.

For example:

- Your API sends UTC times in JSON but you need to display them for Chicago time zone to a user viewing your page in Los Angeles.
- What was the local time in Chicago when the first humans landed on the Moon?

## Usage

Here is an example unit test showing how to use the WallTime API to get the local time in Chicago for the Moon landing.

```html
<script src="/path/to/walltime-data.js"></script>
<script src="/path/to/walltime.js"></script>
<script type="text/javascript">
    it("can convert first moon landing time", function () {
        // Apollo 11 was the spaceflight that landed the first humans on the Moon,
        // Americans Neil Armstrong and Buzz Aldrin, on July 20, 1969, at 20:18 UTC.
        var landingTime = Date.UTC(1969, 6, 20, 20, 18, 0, 0),
            chicagoLandingTime = WallTime.UTCToWallTime(landingTime, "America/Chicago");
        
        chicagoLandingTime.getFullYear().should.equal(1969);
        chicagoLandingTime.getMonth().should.equal(6);
        chicagoLandingTime.getDate().should.equal(20);
        chicagoLandingTime.getHours().should.equal(15);
        chicagoLandingTime.getMinutes().should.equal(18);
    });
</script>
```

## Using with RequireJS

```html
<script type="text/javascript" src="require.js"></script>
<script type="text/javascript" src="path/to/walltime-data.js"></script>
<script type="text/javascript">
    require.config({
      paths: {
        walltime: 'path/to/walltime'
      }
    });

    define(['walltime'], function(WallTime){
      var someUTCDate = new Date(),
          chicagoWallTime = WallTime.UTCToWallTime(someUTCDate, "America/Chicago");
    });
</script>
```

## Building Data

To limit the size of WallTime.js, you should only use the data for the time zone files you need.  

By default, `walltime-data.js` contains `northamerica`, `europe` and `australasia`, which encompass most of the world, but is 479k (minified).  By narrowing it down to just `northamerica`, you could save 300k. Adding gzip compression could get you down as low as 16k.

To get the latest Olson files

    git submodule init && git submodule update

To build all the data for all the time zone files

    grunt data

To build data for `northamerica` only

    grunt data --filename=northamerica

To build data for `northamerica` and `europe`

    grunt data --filename=northamerica,europe

To build data for `America/Chicago` only

    grunt data --filename=northamerica --zonename=America/Chicago

To build individual data files for each time zone

    grunt individual
    
    # Optionally, pass a format parameter for naming
    grunt individual --format "walltime-data_%s" # Becomes `walltime-data_America-Chicago.min.js`

By default the files are saved to `./client/walltime.js` etc.

## Development

This project uses [Node.js](http://nodejs.org) and [Grunt](http://gruntjs.com).

To get setup

    # Clone the repo
    git clone https://github.com/sproutsocial/walltime-js.git && cd walltime-js
    # Install the dependencies
    npm install

To run tests and lint source code

    grunt test

To make new tests, create a new spec coffee file in the test directory.

## MIT License

Copyright (c) 2013 Sprout Social, Inc.

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
