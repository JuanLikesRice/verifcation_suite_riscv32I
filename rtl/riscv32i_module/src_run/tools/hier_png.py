#!/usr/bin/env python3
import glob
import pydot
from pyverilog.vparser.parser import parse
from pyverilog.vparser.ast import ModuleDef, InstanceList

files = [f for f in glob.glob("*.v") if not f.endswith("TB.v")]
ast, _ = parse(files, preprocess_include=["."], preprocess_define=[])

mods = set()
edges = set()
for d in ast.description.definitions:
    if isinstance(d, ModuleDef):
        mods.add(d.name)
        for it in (d.items or []):
            if isinstance(it, InstanceList):
                edges.add((d.name, it.module))

# keep edges that point to known modules
edges = {(a,b) for (a,b) in edges if b in mods}

g = pydot.Dot(graph_type="digraph", rankdir="LR")
nodes = {m: pydot.Node(m, shape="box") for m in mods}
for n in nodes.values(): g.add_node(n)
for a,b in edges:
    g.add_edge(pydot.Edge(nodes[a], nodes[b]))
g.write_png("hierarchy.png")
print("Wrote hierarchy.png")
