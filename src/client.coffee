vdf = require 'vdf'
fs = require 'fs'
iconv = require 'iconv-lite'

path = "C:\\Program Files (x86)\\Steam\\steamapps\\libraryfolders.vdf"

lfBuffer = fs.readFileSync path
rawVDF = iconv.decode lfBuffer, 'win1252'
parsedFolders = vdf.parse(rawVDF).LibraryFolders

keys = Object.getOwnPropertyNames(parsedFolders).filter (x) ->
  parseInt(x) > 0

libraryPaths = (parsedFolders[n].replace(/\\\\/g, "\\") for n in keys)
libraryPaths.push "C:\\Program Files (x86)\\Steam"

console.log libraryPaths
