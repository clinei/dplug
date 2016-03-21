import core.memory;

import std.stdio;
import std.typecons;
import std.string;
import std.algorithm;
import std.conv;

import derelict.util.sharedlib;
import dplug.host;

void usage()
{
    writeln("Auburn Sounds ldvst VST checker\n");
    writeln("usage: ldvst [-w | -wait] [-t times] [-chunk chunk.bin] [-get-program] {plugin.vst|plugin.so|plugin.dll}\n");

}

void main(string[]args)
{
    int times = 1;
    string vstpath = null;
    bool gui = true;
    bool wait = false;
    bool dumpChunk = false;
    string chunkFile;
    bool getProgram = false;

    for(int i = 1; i < args.length; ++i)
    {
        string arg = args[i];
        if (arg == "-no-gui")
            gui = true;
        else if (arg == "-get-program")
            getProgram = true;
        else if (arg == "-w" || arg == "-wait")
            wait = true;
        else if (arg == "-t")
        {
            ++i;
            times = to!int(args[i]);
        }
        else if (arg == "-chunk")
        {
            ++i;
            dumpChunk = true;
            chunkFile = args[i];
        }
        else
        {
            if (!vstpath)
                vstpath = arg;
            else
            {
                usage();
                throw new Exception(format("Excess argument '%s'", arg));
            }
        }
    }
    if (vstpath is null)
    {
        usage();
        return;
    }

    if (wait)
    {
        writeln("Press ENTER to start the VST hosting...");
        readln;
    }

    // just a dyn lib, try to load it
    for (int t = 0; t < times; ++t)
    {
       auto host = createPluginHost(vstpath);

       if (dumpChunk)
       {
           import std.file;
           std.file.write(chunkFile, host.saveState());
       }

       if (getProgram)
       {
           writefln("Current program is %s", host.getCurrentProgram());
       }
       host.close();
    }

    if (wait)
    {
        writeln("Press ENTER to end the program...");
        readln;
    }


}
