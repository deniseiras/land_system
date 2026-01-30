#!/usr/bin/env python3

import os, re, sys

if len(sys.argv) != 4:
    name = os.path.basename(sys.argv[0])
    error = "{0}: wrong number of arguments (usage: {0} <path/to/odb/ddl/cma.h> -o <output>)\n".format(name)
    sys.stderr.write(error)
    sys.exit(1)

re_include = re.compile(r'^#include\s+\"(?P<file>.*)\".*') 
re_ifdef = re.compile(r'^\s*#ifdef\s+(\w+)')
re_ifndef = re.compile(r'^\s*#ifndef\s+(\w+)')
re_endif = re.compile(r'^\s*#endif')
re_set = re.compile(r'^\s*SET\s+\$(?P<name>\w+)\s*=\s*(?P<value>\w+)\s*;', re.IGNORECASE)
re_reset = re.compile(r'^\s*RESET\s+\w+\s*;', re.IGNORECASE)
re_align = re.compile(r'^\s*ALIGN\(.*\)\s*;', re.IGNORECASE)
re_onelooper = re.compile(r'^\s*ONELOOPER\(.*\)\s*;', re.IGNORECASE)
re_create_type = re.compile(r'^\s*CREATE\s+TYPE\s+(?P<name>\w+)\s+AS\s+.*', re.IGNORECASE)
re_type_member = re.compile(r'^\s*(?P<name>\w+)\s+(?P<type>\w+)\s*,.*')
re_closing_paren = re.compile(r'^\s*\);.*')
re_column = re.compile(r'^\s*(?P<name>\w+)(?P<range>\S+)?\s+(?P<type>\S+)(?P<rest>,.*)$')
re_create_table = re.compile(r'^\s*CREATE\s+TABLE\s+(?P<name>\w+)(?P<rest>.*)$', re.IGNORECASE)
re_variable_range = re.compile(r'^\[(?:1:)?\$(?P<name>\w+)(?:[+-]\d+)?\](?P<rest>.*)')
re_fixed_range = re.compile(r'^\[(?:1:)?(?P<count>\d+)\](?P<rest>.*)')
re_typeof = re.compile(r'^TYPEOF\((?P<column_at_table>\S+)\).*$', re.IGNORECASE)

ifdefs = []
definitions = {}
include_dir = None
empty_types = []
column_types = {}
variables = {}


def main():
    global include_dir
    include_dir = os.path.dirname(sys.argv[1])
    with open(sys.argv[3], "w") as output:
        for line in preprocess(iter(open(sys.argv[1]))):
            print(line, end='', file=output)


def preprocess(rest):
    try:
        while True:
            line = next_line(rest)
            match = None
            for r, f in [(re_set, set), (re_include, include),
                         (re_create_type, create_type), (re_create_table, create_table)]:
                match = r.match(line)
                if match:
                    yield from f(match, line, rest)
                    break
            if not match: yield line
    except: StopIteration


def include(match, line, rest):
    with open(os.path.join(include_dir, match.group(1))) as include_file:
        yield from preprocess(iter(include_file))


def set(match, line, rest):
    name, value = match.group(1 ,2)
    variables[name.upper()] = value
    yield line


def create_type(match, line, rest):
    name = match.group("name")
    lines = [line]
    member_count = 0
    while not re_closing_paren.match(line):
        line = next_line(rest)
        if re_type_member.match(line):
            member_count += 1
        lines.append(line)
    if member_count == 0:
        empty_types.append(name.lower())
        return
    else:
        yield from lines


def create_table(match, line, rest):
    table_name, rest_ = match.group("name", "rest")
    match = re_variable_range.match(rest_)
    if match:
        var_name, rest_ = match.group("name", "rest")
        table_count = int(variables[var_name.upper()])
        lines = []
        while not re_closing_paren.match(line):
            line = next_line(rest)
            lines.append(line)
        for i in range(1, table_count+1):
            yield f"CREATE TABLE {table_name}_{i}{rest_}\n"
            for line in lines[:-2]: # exclude closing paren
                yield from column(table_name, line)
            yield lines[-1] # closing paren
            yield "\n"
    else:
        yield line
        while not re_closing_paren.match(line):
            line = next_line(rest)
            yield from column(table_name, line)
        yield line
        yield "\n"


def column(table_name, line):
    match = re_column.match(line)
    if match:
        name, range_, type, rest = match.group("name", "range", "type", "rest")
        column_types[f"{name}@{table_name}".lower()] = type.lower()
        if range_:
            count = None
            match = re_variable_range.match(range_)
            if match:
                var_name = match.group("name")
                count = int(variables[var_name.upper()])
            else:
                match = re_fixed_range.match(range_)
                count = int(match.group("count"))
            for i in range(1, count+1):
                yield f"  {name}_{i} {type}{rest}\n"
        else:
            match = re_typeof.match(type)
            if match:
                column_at_table = match.group("column_at_table").lower()
                type = column_types[column_at_table]
            yield f"  {name} {type}{rest}\n"


def next_line(rest):
    while True:
        line = rest.__next__()
        if ignore(line):
            continue
        match = re_ifdef.match(line)
        if match:
            name = match.group(1)
            defined = name in definitions
            ifdefs.append((name, defined))
            continue
        match = re_ifndef.match(line)
        if match:
            name = match.group(1)
            defined = name not in definitions
            ifdefs.append((name, defined))
            continue
        match = re_endif.match(line)
        if match:
            ifdefs.pop()
            continue
        if ifdefs: # don't return if in the scope of a false #ifdef
            name, defined = ifdefs[-1]
            if not defined:
                continue
        break
    return line.replace("//", "--")


def ignore(line):
    return any([x.match(line) for x in [re_reset, re_align, re_onelooper]])


if __name__ == "__main__": main()

