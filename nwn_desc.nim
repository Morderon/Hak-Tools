import neverwinter/twoda, streams, options, json, parsecfg, re, os, strutils

let start = 16777216
var tlkstart = 0
var state: TwoDA
let dict = loadConfig("description.ini")
let tlk = parseFile(dict.getSectionValue("General","Tlk"))


type
    ColPair = tuple[name: string, value: int]
    
proc addTlkRow(itm: JsonNode, field: string): int =
  var tlkNum = -1
  if itm.hasKey(field):
    tlkstart = tlkstart + 1
    var inst = %* {"id": tlkstart, "text": itm[field]}
    add(tlk["entries"], inst)
    tlkNum = tlkstart
    
  tlkNum

proc addTlkNum(rowID: int, colNames: array[5, ColPair]) =
    var row = state[rowID].get()
    for x in 0..4:
      if colNames[x].name == "" : break
      if colNames[x].value > -1:
        row[state.columns.find(colNames[x].name)] = some($(colNames[x].value+start))
      
    state[rowID] = row 


for file in walkDir(dict.getSectionValue("General","InputDesc")):
  var (dir, name, ext) = splitFile(file.path)
  
  if ext == ".json" and (name == "classes" or name == "spells" or name == "racialtypes" or name == "feat"):
    var colNames: array[5, ColPair]
    case name:
      of "classes":
        colNames = [("Description",0),("Name",0),("Plural",0),("Lower",0),("",0)]  
      of "spells":
        colNames = [("SpellDesc",0), ("Name",0), ("AltMessage",0), ("",0), ("",0)]   
      of "feat":
        colNames = [("DESCRIPTION",0), ("FEAT",0), ("", 0), ("",0), ("",0)]
      of "racialtypes":
        colNames = [("Description",0), ("Name",0), ("ConverName",0), ("ConverNameLower",0), ("NamePlural",0)]
    
    let js = parseFile(file.path)
    tlkstart = parseInt(dict.getSectionValue("General","start"&name))
    let app = newFileStream(dict.getSectionValue("General","InputTwo")&name&".2da")
    state = app.readTwoDA()
    for itm in items(js):
      colNames[0].value = addTlkRow(itm, "text")
      colNames[1].value = addTlkRow(itm, "name")
      for x in 2..4:
        if colNames[x].name == "": break
        colNames[x].value = addTlkRow(itm, colNames[x].name.toLower)
      
      let rowIDT = getStr(itm["id"])
      if rowIDT == "":
        let rowID = getInt(itm["id"])
        addTlkNum(rowID, colNames)
      else:
        for s in split(rowIDT, ","):
          addTlkNum(parseInt(s), colNames)  
 
    let appout = newFileStream(dict.getSectionValue("General","OutputTwo")&name&".2da", fmWrite)
    appout.writeTwoDA(state)
    app.close
    appout.close
     
let tlkout = newFileStream(dict.getSectionValue("General","OutTlk"), fmWrite) 
tlkout.write $tlk



