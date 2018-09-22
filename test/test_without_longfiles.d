#!/usr/bin/env rund
//!importPath ..
//!debug
//!debugSymbols
import std.file;
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
