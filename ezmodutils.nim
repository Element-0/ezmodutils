import ezmodutils/[cmd_winres, cmd_symbol]
import cligen

dispatchMulti(
  ["multi", cmdName = "ezmod"],
  [generate_resource],
  [find_symbol],
  [find_unique_symbol])
