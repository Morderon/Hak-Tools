import shared, math

let args = DOC """
Add to a palette



Supported input/output formats: .itp


Input and output default to stdin/stdout respectively.

Usage:
  $0 [options]
  $USAGE

Options:
  -i IN                       Input file [default: -]
  -o OUT                      Output file
  -f FILE                     Gff File to add
  -s SECTION                  Main list of the
  -p PALETTE ID               The Palette ID

  $OPT
"""
proc `==` (x: GffResRef, y: GffResRef): bool {.borrow.}



let gffName = $args["-f"]
let (dir, name, ext) = splitFile(gffName)
if ext != ".uti" and ext != ".utp" and ext != ".utc":
  quit(QuitSuccess)

let gffFile = openFileStream(gffName)

let outputfile = $args["-o"]
let input  = openFileStream($args["-i"])
let palID: byte = cast[byte](parseUInt($args["-p"]))
let palList = $args["-s"]

var root: GffRoot = input.readGffRoot(false)
let gff: GffRoot = gffFile.readGffRoot(false)

input.close
gffFile.close

var wrkList: GffList
var simple: bool
for i in 0 ..< root["MAIN", GffList].len:
  if root["MAIN", GffList].len != 2:
    wrkList = root["MAIN", GffList]
    simple = true
  elif root["MAIN", GffList][i].hasField("NAME", GffCExoString) and root["MAIN", GffList][i]["NAME", GffCExoString]==palList:
    wrkList = root["MAIN", GffList][i]["LIST", GffList]
    simple = false
    
  for n in 0 ..< wrkList.len:
   # echo "wtf" & $n
  #  echo "length" & $root["MAIN", GffList][i]["LIST", GffList].len
    if wrkList[n].hasField("ID", byte) and wrkList[n]["ID", byte]==palID:
      var list = wrkList[n]["LIST", GffList]
      var bFound = false
      var name: string
      if ext == ".uti":
        name = gff["LocalizedName", GffCExoLocString].entries[0]
      elif ext == ".utp":
        name = gff["LocName", GffCExoLocString].entries[0]
      elif ext == ".utc":
        if gff.hasField("FirstName", GffCExoLocString) and gff["FirstName", GffCExoLocString].entries.len > 0:
          name = gff["FirstName", GffCExoLocString].entries[0]
        if gff.hasField("LastName", GffCExoLocString) and gff["LastName", GffCExoLocString].entries.len > 0:        
          name &= " " & gff["LastName", GffCExoLocString].entries[0]
      for o in 0 ..< list.len:
        if list[o]["RESREF", GffResRef] == gff["TemplateResRef", GffResRef]:
          list[o]["NAME", GffCExoString] = name
          if ext == ".utc":
            list[o]["CR", GffFloat] = gff["ChallengeRating", GffFloat]
          bFound = true
          break

      if not bFound:
        var x: GffStruct
        x = newGffStruct()
        x["RESREF", GffResRef] = gff["TemplateResRef", GffResRef]
        x["NAME", GffCExoString] = name
        if ext == ".utc":
          x["CR", GffFloat] = gff["ChallengeRating", GffFloat]
        list.add(x)

      if simple:
        root["MAIN", GffList][n]["LIST", GffList] = list
      else:
        root["MAIN", GffList][i]["LIST", GffList][n]["LIST", GffList] = list
      let output = openFileStream(outputfile, fmWrite)
      output.write(root)
      output.close
      break
      
  if simple:
    break