# killsite

Recursively GET all the pages of a given site through hyperlinks.
The tool is for the usage of testing and profiling.

Using memory monitor to find out the memory leaks within different URLs.

## Installation

Simply `gem install killsite`.

`ab` (ApacheBench) is require as an benchmark tool.

## Usage

Usage: killsite [options]
    -h, --help                       Show help message
    -l, --limit NUM                  Setting the limit of a single test
    -c, --concurrency NUM            Setting the number of concurrent connection
    -p, --pid PID                    The PID is the monitored server process

## Copyright

Copyright (c) 2011 Andrew Liu. See LICENSE.txt for
further details.

