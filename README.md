walltime-js
===========

A javascript library for easily translating a UTC time to a "Wall Time" for a particular time zone.

[![Build Status](https://secure.travis-ci.org/sproutsocial/walltime-js.png)](http://travis-ci.org/sproutsocial/walltime-js)

## Problems this solves

Dates in javascript do not account for daylight savings time for regions that use them.

walltime-js helps with:

- Translating a UTC time to a "Wall Time" for a particular time zone.
- Translating a "Wall Time" for a particular time zone to a UTC time.

## Key Terms

### UTC
- The universal time that other time zones define their offset from.  The most effective way in javascript to represent this is with milliseconds since Unix Epoch (1/1/1970 00:00:00 UTC)

### Time Zone
- A specific geographic region (usually a large city or island) that maintains, maintained a consistent time convention over a period of time.

### Wall Time
- The time that would be showing on a wall clock in a certain Time Zone at a specific UTC.


