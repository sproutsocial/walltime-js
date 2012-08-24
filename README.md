walltime-js [![Build Status](https://secure.travis-ci.org/sproutsocial/walltime-js.png)](http://travis-ci.org/sproutsocial/walltime-js)
===========

A javascript library for easily translating a UTC time to a "Wall Time" for a particular time zone.

## Problems this solves

Dates in javascript do not properly account for daylight savings time for regions that use them.

walltime-js helps with translating a UTC time to a "Wall Time" for a particular time zone.

## Usage

    <script src="/path/to/walltime-data.js"></script>
    <script src="/path/to/walltime.js"></script>
    <script type="text/javascript">
        var someUTCDate = new Date(new Date().getTime()),
            chicagoWallTime = WallTime.UTCToWallTime(someUTCDate, "America/Chicago");
    </script>

## Building Data

To limit the size of WallTime.js you should only use the data for the time zone files you need.  

By default, `walltime-data.js` contains `northamerica`, `europe` and `australasia` which encompass most of the world but is 479k (minified).  By narrowing it down to just `northamerica` you could save 300k, adding gzip compression could get you down as low as 16k.

This project uses [node js](http://nodejs.org) and [CoffeeScript](http://coffeescript.org); go and install them if you don't have them.

To build all the data for all the time zone files

    cake data

To build data for `northamerica` only

    cake -f northamerica data

To build data for `northamerica` and `europe`

    cake -f northamerica -f europe data

By default the files are saved to `./client/walltime.js` etc.

## Development

To run tests

    cake test

To make new tests create a new spec coffee file in the test directory.
