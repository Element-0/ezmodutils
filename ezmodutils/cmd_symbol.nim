import std/[terminal, sugar, strutils]
import ezsqlite3, ezsqlite3/extension, ezpdbparser, ezutils/matching

loadExtension("SymbolTokenizer.dll")

type SymbolKind* = enum
  stUnknown = "unknown"
  stVariable = "variable"
  stFunction = "function"
  stSpecial = "special"
  stLocal = "local"

iterator querySymbol(query: string; kind: SymbolKind; noLinux: bool):
    tuple[key: string; raw: string; kind: SymbolKind; offset: int] {.
      importdb: """
  SELECT highlight(fts_symbols, 0, '{', '}') AS key, raw, type AS kind, offset
  FROM fts_symbols
  WHERE
    fts_symbols = $query AND
    ($noLinux = 0 OR original = 1) AND
    ($kind = 0 OR kind = $kind)
  ORDER BY rank""".} = discard

proc queryUniqueSymbol(query: string; kind: SymbolKind): tuple[raw: string] {.
    importdb: "SELECT raw FROM fts_symbols WHERE fts_symbols = $query AND original = 1 AND type = $kind".}

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
