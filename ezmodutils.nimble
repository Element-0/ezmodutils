# Package

version       = "0.1.0.0"
author        = "CodeHz"
description   = "A new awesome nimble package"
license       = "LGPL-3.0"
srcDir        = "."
bin           = @["ezmodutils"]
installExt    = @["dll", "pdb"]
namedBin["ezmodutils"] = "ezmod"


# Dependencies

requires "nim >= 1.4.2"
requires "ezutils, ezsqlite3 >= 0.1.4, ezpdbparser"
requires "winres"
requires "cligen >= 1.4.1"

from os import `/`
from strutils import strip

const link = "https://github.com/Element-0/SymbolsDatabase/releases/download/1.16.201.02-2021-02-11T17.30.10.9476182Z/SymbolTokenizer.dll"

task prepare, "Prepare dlls":
  if not fileExists "./SymbolTokenizer.dll":
    exec "curl -Lo SymbolTokenizer.dll " & link
  cpFile(gorge("nimble path ezsqlite3").strip / "sqlite3.dll", "sqlite3.dll")

before build:
  prepareTask()
