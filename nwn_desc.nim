import neverwinter/twoda, streams, options, json, parsecfg, re, os, strutils

let start = 16777216
var tlkstart = 0
var state: TwoDA
let dict = loadConfig("description.ini")
let tlk = parseFile(dict.getSectionValue("General","Tlk"))

proc addTlkRow(itm: JsonNode, field: string, colName: string, row: Row): Row =
  var trow = row
  if itm.hasKey(field):
    trow[state.columns.find(colName)] = some($(tlkstart+start))
    var inst = %* {"id": tlkstart, "text": itm[field]}
    tlkstart = tlkstart + 1
    add(tlk["entries"], inst)

  trow



for file in walkDir(dict.getSectionValue("General","InputDesc")):
  var (dir, name, ext) = splitFile(file.path)
  
  if ext == ".json" and (name == "classes" or name == "spells" or name == "racialtypes" or name == "feat"):
    var colNames: array[5, string]
    case name:
      of "classes":
        colNames = ["Description", "Name", "Plural", "Lower", ""]  
      of "spells":
        colNames = ["SpellDesc", "Name", "", "", ""]   
      of "feat":
        colNames = ["DESCRIPTION", "FEAT", "", "", ""]
      of "racialtypes":
        colNames = ["Description", "Name", "ConverName", "ConverNameLower", "NamePlural"]
    
    let js = parseFile(file.path)
    tlkstart = parseInt(dict.getSectionValue("General","start"&name))
    let app = newFileStream(dict.getSectionValue("General","InputTwo")&name&".2da")
    state = app.readTwoDA()
    for itm in items(js):
      let rowID = getInt(itm["id"])
      var row = state[rowID].get()  
      row = addTlkRow(itm, "text", colNames[0], row)
      row = addTlkRow(itm, "name", colNames[1], row)
      for x in 2..4:
        if colNames[x] == "": break
        row = addTlkRow(itm, colNames[x].toLower, colNames[x], row)
      
      state[rowID] = row
 
    let appout = newFileStream(dict.getSectionValue("General","OutputTwo")&name&".2da", fmWrite)
    appout.writeTwoDA(state) 
     
let tlkout = newFileStream(dict.getSectionValue("General","OutTlk"), fmWrite) 
tlkout.write $tlk



