import winres/[helper, version_code]
import std/[osproc, json, strformat, strutils], ezutils/matching

type ModKind = enum
  modServerSide = "server"
  modManagerSide = "manager"

proc praseModKind(str: string): ModKind {.inline.} = parseEnum[ModKind](str)

proc generate_resource*() =
  {
    "name": JString(str: @name),
    "version": JString(str: (parseVersionCode: @version)),
    "author": JString(str: @author),
    "desc": JString(str: @desc),
    "license": JString(str: @license),
  } := parseJson execProcess("nimble", args = ["dump", "--json"], options = {poUsePath})
  {
    "copyright": JString(str: @copyright),
    "kind": JString(str: (praseModKind: @kind)),
    "comments": JString(str: @comments),
    "tags": JArray([all JString(str: @tags)]),
    "depends": JArray([all JString(str: @depends)]),
    "optionals": JArray([all JString(str: @optionals)]),
    "provides": JArray([all JString(str: @provides)]),
  } := parseFile fmt"{name}.json"

  output(fmt"{name}.res"):
    RT_VERSION(1, 1033, 1252, FixedVersionInfo(file: version, product: version, kind: ftDll)) do:
      FileDescription := desc
      FileVersion := $version
      ProductVersion := $version
      InternalName := name
      OriginalFilename := fmt"ezmod-{kind}-{name}.dll"
      CompanyName := author
      LegalCopyright := copyright
      Comments := comments
    do:
      Licence := license
      Tags := tags
      Depends := depends
      Optionals := optionals
      Provides := provides
