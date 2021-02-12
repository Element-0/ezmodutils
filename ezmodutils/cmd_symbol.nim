{.experimental: "caseStmtMacros".}
import std/[terminal, sugar, strutils, options]
import ezsqlite3, ezsqlite3/extension, ezpdbparser, ezutils/matching

loadExtension("SymbolTokenizer.dll")

type SymbolKind* = enum
  stUnknown = "unknown"
  stVariable = "variable"
  stFunction = "function"
  stSpecial = "special"
  stLocal = "local"

type TypeInfoKind* = enum
  tiBase
  tiSingle
  tiMultiple

iterator querySymbol(query: string; kind: SymbolKind; noLinux: bool):
    tuple[key: string; raw: string; kind: SymbolKind; offset: int] {.
      importdb: """
  SELECT highlight(fts_symbols, 0, '{', '}') AS key, raw, type AS kind, offset
  FROM fts_symbols($query)
  WHERE
    ($noLinux = 0 OR original = 1) AND
    ($kind = 0 OR kind = $kind)
  ORDER BY rank""".} = discard

proc queryUniqueSymbol(query: string; kind: SymbolKind; orig: int = 1): tuple[raw: string; offset: int] {.
    importdb: "SELECT raw, offset FROM fts_symbols WHERE fts_symbols = $query AND original = $orig AND type = $kind".}

proc queryOptionalSymbol(query: string): Option[tuple[key: string; raw: string; offset: int]] {.
    importdb: "SELECT key, raw, offset FROM fts_symbols($query) WHERE original = 1 LIMIT 1".}

iterator queryVtable(key: int): tuple[name: string; prefix: string] {.
    importdb: """
  SELECT elfsym.key, symprefix(elfsym.key)
  FROM vtables AS vt
  JOIN symbols AS elfsym ON elfsym.offset = vt.target
  WHERE vt.key = $key
  ORDER BY vt.idx
  """.} = discard

proc queryTypeInfo(key: int): tuple[kind: TypeInfoKind] {.importdb: "SELECT type FROM typeinfos WHERE key = $key".}

iterator queryTypeInfoDef(key: int): tuple[name: string; target: int; offset: int] {.
    importdb: """
  SELECT substr(elfsym.key, 1, instr(elfsym.key, ' <- $type_info') - 1), tis.target, tis.offset
  FROM typeinfo_defs AS tis
  JOIN symbols AS elfsym ON elfsym.offset = tis.target
  WHERE tis.key = $key
  ORDER BY tis.offset
  """.} = discard

proc find_symbol*(database: string; querys: seq[string]; kind: SymbolKind = stUnknown; noLinux: bool = false) =
  var db = initDatabase database
  var query = "^"
  for item in querys:
    query.addQuoted item
    query.add " "
  for (key, raw, kind, offset) in db.querySymbol(query, kind, noLinux):
    stdout.write "key = "
    var hi = false
    for (token, isSep) in key.tokenize({'{', '}'}):
      if isSep:
        for _ in 0..<token.len: hi = not hi
      else:
        if hi:
          stdout.styledWrite(fgGreen, bgBlack, "\uE0B2", bgGreen, fgBlack, token, fgGreen, bgBlack, "\uE0B0", resetStyle)
        else:
          stdout.write token
    echo()
    dump raw
    let hash = symhash(raw)
    echo "hash = ", hash
    dump kind
    dump offset
    echo()

proc find_unique_symbol*(database: string; kind: SymbolKind; querys: seq[string]) =
  var db = initDatabase database
  var query = "^"
  for item in querys:
    query.addQuoted item
    query.add " "
  (raw: (symhash: @hash)) := db.queryUniqueSymbol(query, kind)
  stdout.write($hash)

proc dump_vtable*(database: string; name: string) =
  var db = initDatabase database
  let query = "^\"" & name & "::$vtable\""
  (offset: @vtoffset) := db.queryUniqueSymbol(query, stSpecial, 2)
  for (name, prefix) in db.queryVtable(vtoffset):
    case db.queryOptionalSymbol("^".dup(addQuoted(prefix)))
    of Some((key: @key, raw: @raw, offset: @offset)):
      styledEcho "[", fgGreen, key, resetStyle, "]"
      dump raw
      dump offset
    of None():
      styledEcho "[", fgRed, name, resetStyle, "]"

proc dump_typeinfo_by_offset(db: var Database; key: int): string =
  case db.queryTypeInfo(key).kind:
  of tiBase:
    return
  of tiSingle:
    for (name, target, _) in db.queryTypeInfoDef(key):
      result.add " <- " & name
      result.add db.dump_typeinfo_by_offset(target)
      break
  of tiMultiple:
    result.add " <- ("
    for (name, target, offset) in db.queryTypeInfoDef(key):
      result.add name & "[" & $offset & "]"
      result.add db.dump_typeinfo_by_offset(target)
      result.add ", "
    result.removeSuffix(", ")
    result.add ")"

proc dump_typeinfo*(database: string; name: string) =
  var db = initDatabase database
  let query = "^\"" & name & " <- $type_info\""
  (offset: @tioffset) := db.queryUniqueSymbol(query, stSpecial, 2)
  echo name & db.dump_typeinfo_by_offset(tioffset)
