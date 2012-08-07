#!/bin/bash

echo "Removing existing Olson files"
rm -r ./files/

echo "Getting latest Olson files"
mkdir files && cd files

# Load the files from the iana.org site.
wget --retr-symlinks 'ftp://ftp.iana.org/tz/tz*-latest.tar.gz'

# Unzip them (Codes aren't necessary)
# gzip -dc tzcode*.tar.gz | tar -xf -
gzip -dc tzdata*.tar.gz | tar -xf -

# Remove the gz files since we don't need them.
rm tz*-latest.tar.gz

cd ..
echo "Parsing Olson files to: parsedFiles.js"
node sprout-preparse ./files/ > parsedFiles.js

echo "Cleaning up Olson files"
rm -r ./files/

echo "Done!"