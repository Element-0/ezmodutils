import ezmodutils/[cmd_winres, cmd_symbol]
import cligen

dispatchMulti(
  ["multi", cmdName = "ezmod"],
  [generate_resource],
  [dump_typeinfo],
  [dump_vtable],
  [find_subclass],
  [find_symbol],
  [find_unique_symbol, doc = "used by codegen"])
