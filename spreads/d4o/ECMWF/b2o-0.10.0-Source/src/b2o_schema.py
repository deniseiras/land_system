#!/usr/bin/env python3

import os, re, sys

if len(sys.argv) != 4:
    name = os.path.basename(sys.argv[0])
    error = "{0}: wrong number of arguments (usage: {0} <path/to/varno.h> -o <output>)\n".format(name)
    sys.stderr.write(error)
    sys.exit(1)

lines = list(open(sys.argv[1]))
pattern = re.compile("^\s*[sS][eE][tT]\s+\$(?P<name>\w+)\s*=\s*(?P<value>[0-9]+)\s*;")
matches = [pattern.match(l) for l in lines]
definitions = ["integer, parameter :: g_{name} = {value}".format(**m.groupdict()) for m in matches if m]
source = "\n".join(definitions) + "\n"

open(sys.argv[3], "w").write(source)
