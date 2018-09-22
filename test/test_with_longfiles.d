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
    foreach (path; paths)
    {
        if (!exists(path))
        {
            writefln("mkdir(length=%s) '%s'", path.length, path);
            stdout.flush();
            mkdir(path);
        }
    }
    writeln("Success");
}
