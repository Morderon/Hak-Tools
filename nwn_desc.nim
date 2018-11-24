import neverwinter/twoda, streams, options, json, parsecfg, re, os, strutils

let start = 16777216

var tlkstart = 0
var js: JsonNode
var tlk: JsonNode
var dict = loadConfig("description.ini")

tlk = parseFile(dict.getSectionValue("General","Tlk"))

for file in walkDir(dict.getSectionValue("General","InputDesc")):
  var (dir, name, ext) = splitFile(file.path)
  if ext == ".json" and (name == "classes" or name == "spells" or name == "racialtypes" or name == "feat"):

    tlkstart = parseInt(dict.getSectionValue("General","start"&name))
    let app = newFileStream(dict.getSectionValue("General","InputTwo")&name&".2da")
    let state = app.readTwoDA()
    js = parseFile(file.path)
    echo file
    for itm in items(js):
      var row = state[getInt(itm["id"])].get()
      var colName = ""
      case name:
        of "spells":
          colName = "SpellDesc"  
        of "feat":
          colName = "DESCRIPTION"
        else:
          colName = "Description"
      row[state.columns.find(colName)] = some($(tlkstart+start))
      state[getInt(itm["id"])] = row
      var inst = %* {"id": tlkstart, "text": itm["text"]}
      tlkstart = tlkstart + 1
      add(tlk["entries"], inst)
 
    let appout = newFileStream(dict.getSectionValue("General","OutputTwo")&name&".2da", fmWrite)
    appout.writeTwoDA(state) 
     
let tlkout = newFileStream(dict.getSectionValue("General","OutTlk"), fmWrite) 
tlkout.write $tlk
