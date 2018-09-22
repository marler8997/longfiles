#!/usr/bin/env rund
//!importPath ..
//!debug
//!debugSymbols
import stdx.longfiles;
import std.stdio;

import common;

void main()
{
    const paths = makePaths();
    foreach_reverse (path; paths)
    {
        if (exists(path))
        {
            writefln("rmdir(length=%s) '%s'", path.length, path);
            stdout.flush();
            rmdir(path);
        }
    }
    writefln("Success");
}
