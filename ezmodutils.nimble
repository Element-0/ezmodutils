# Package

version       = "0.1.0.0"
author        = "CodeHz"
description   = "A new awesome nimble package"
license       = "LGPL-3.0"
srcDir        = "."
bin           = @["ezmodutils"]
namedBin["ezmodutils"] = "ezmod"


# Dependencies

requires "nim >= 1.4.2"
requires "ezutils"
requires "winres"
requires "cligen >= 1.4.1"
