import neverwinter/twoda, streams, options, json, parsecfg, re, os, strutils, typetraits

let start = 16777216
var tlkstart = 0
var ptrTD: ptr TwoDA
var state: TwoDA
let dict = loadConfig("description.ini")
let tlk = parseFile(dict.getSectionValue("General","Tlk"))
let spellsf = newFileStream(dict.getSectionValue("General","InputTwo")&"spells.2da")
var spells: TwoDA
if not isNil(spellsf):
  spells = spellsf.readTwoDA()
  spellsf.close
let ip_spellf = newFileStream(dict.getSectionValue("General","InputTwo")&"iprp_spells.2da")
var ip_spell: TwoDA
if not isNil(ip_spellf):
  ip_spell = ip_spellf.readTwoDA()
  ip_spellf.close
let ip_featf = newFileStream(dict.getSectionValue("General","InputTwo")&"iprp_feats.2da")
var ip_feat: TwoDA
if not isNil(ip_featf):
  ip_feat = ip_featf.readTwoDA()
  ip_featf.close

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

proc InsertRow(row: Row, otwoda: TwoDA, name: string, value: int): Row =
  var row = row
  row[otwoda.columns.find(name)] = some($(value+start))
  row

proc addTlkNum(rowID: int, colNames: array[5, ColPair]) =
    var row = ptrTD[][rowID].get()
    for x in 0..4:
      if colNames[x].name == "" : break
      if colNames[x].value > -1:
        row = InsertRow(row, ptrTD[], colNames[x].name, colNames[x].value)

    ptrTD[][rowID] = row

var colNames: array[2, array[5, ColPair]]
var ovrstart_s = dict.getSectionValue("General","start")

var ovrstart = -1
if ovrstart_s.len>0:
  ovrstart=parseInt(ovrstart_s)

let da_numf = newFileStream(dict.getSectionValue("General","InputTwo")&"iprp_number.2da")
if not isNil(da_numf):
  var da_num = da_numf.readTwoDA()
  da_numf.close
  if(ovrstart > 0):
    tlkstart= ovrstart
  else:
    tlkstart = parseInt(dict.getSectionValue("General","start"&"iprp_number"))
  var getRow: Row
  for i in 51..100:
    add(tlk["entries"], %* {"id": tlkstart, "text": intToStr(i)})
    getRow = da_num[i].get()
    getRow[da_num.columns.find("Name")] = some($(start+tlkstart))
    tlkstart=tlkstart+1
    da_num[i]=getRow

  
  let appout = newFileStream(dict.getSectionValue("General","OutputTwo")&"iprp_number.2da", fmWrite)
  appout.writeTwoDA(da_num)
  appout.close
  ovrstart=tlkstart  

colNames[1] = [("SpellDesc",0), ("Name",0), ("AltMessage",0), ("",0), ("",0)]
for file in walkDir(dict.getSectionValue("General","InputDesc")):
  var (dir, name, ext) = splitFile(file.path)
  if ext == ".json" and (name == "classes" or name == "spells" or name == "racialtypes" or name == "feat" or name == "genericdoors" or name == "placeables"):
    case name:
      of "classes":
        colNames[0] = [("Description",0),("Name",0),("Plural",0),("Lower",0),("",0)]
      of "spells":
        colNames[0] = colNames[1]
      of "feat":
        colNames[0] = [("DESCRIPTION",0), ("FEAT",0), ("", 0), ("",0), ("",0)]
      of "racialtypes":
        colNames[0] = [("Description",0), ("Name",0), ("ConverName",0), ("ConverNameLower",0), ("NamePlural",0)]
      of "genericdoors":
        colNames[0] = [("DUMMY",0), ("Name", 0), ("",0), ("",0), ("",0)]
      of "placeables":
        colNames[0] = [("DUMMY",0), ("StrRef", 0), ("",0), ("",0), ("",0)]

    let js = parseFile(file.path)
    if ovrstart > 0:
        tlkstart=ovrstart
    else:
        tlkstart =parseInt(dict.getSectionValue("General","start"&name))
    var app: FileStream
    if name != "spells":
      app = newFileStream(dict.getSectionValue("General","InputTwo")&name&".2da")
      state = app.readTwoDA()
      ptrTD = addr state
    else:
      ptrTD = addr spells

    for itm in items(js):
      colNames[0][0].value = addTlkRow(itm, "text")
      colNames[0][1].value = addTlkRow(itm, "name")
      for x in 2..4:
        if colNames[0][x].name == "": break
        colNames[0][x].value = addTlkRow(itm, colNames[0][x].name.toLower)

      let rowIDT = getStr(itm["id"])
      if rowIDT == "":
        let rowID = getInt(itm["id"])
        addTlkNum(rowID, colNames[0])
      else:
        for s in split(rowIDT, ","):
          addTlkNum(parseInt(s), colNames[0])

      if name == "feat" or name == "spells":
        if itm.hasKey("iprp_spells"):
            let ispellID = getInt(itm["iprp_spells"])
            var row = ip_spell[ispellID].get()
            row = InsertRow(row, ip_spell, "Name", colNames[0][1].value)
            ip_spell[ispellID] = row

        if name == "feat":
          if itm.hasKey("spells"):
            let spellID = getInt(itm["spells"])
            var row = spells[spellID].get()
            row = InsertRow(row, spells, colNames[1][1].name, colNames[0][1].value)
            spells[spellID] = row

          if itm.hasKey("iprp_feats"):
            let ifeatID = getInt(itm["iprp_feats"])
            var row = ip_feat[ifeatID].get()
            row = InsertRow(row, ip_feat, "Name", colNames[0][1].value)
            ip_feat[ifeatID] = row

    if name != "spells": #we close out spells at the end
      let appout = newFileStream(dict.getSectionValue("General","OutputTwo")&name&".2da", fmWrite)
      appout.writeTwoDA(state)
      app.close
      appout.close

    if ovrstart > 0:
      ovrstart=tlkstart

let tlkout = newFileStream(dict.getSectionValue("General","OutTlk"), fmWrite)
tlkout.write $tlk
if not isNil(spells):
  let outspell = newFileStream(dict.getSectionValue("General","OutputTwo")&"spells.2da", fmWrite)
  outspell.writeTwoDA(spells)
  outspell.close
if not isNil(ip_spell):
  let outspell = newFileStream(dict.getSectionValue("General","OutputTwo")&"iprp_spells.2da", fmWrite)
  outspell.writeTwoDA(ip_spell)
  outspell.close
if not isNil(ip_feat):
  let outspell = newFileStream(dict.getSectionValue("General","OutputTwo")&"iprp_feats.2da", fmWrite)
  outspell.writeTwoDA(ip_feat)
  outspell.close


