import neverwinter/twoda, streams, options, os, parseopt, strutils, system, times


var p = initOptParser("")
var
 start = 0
 ends: int
 file: Stream
 search = ""
 row: Row
 column = "ModelName"
 seqFiles: seq[string]
 model: string
 writeout: string
 fullFile: tuple[dir: string, name: string, ext: string]
 param: string
 i = 1
while i <= paramCount():
  param = paramStr(i)
  if param == "-s":
      i = i + 1
      start = parseInt(paramStr(i))
  elif param == "-e":
      i += 1
      ends = parseInt(paramStr(i))
  elif param == "-r":
      i += 1
      search = paramStr(i)
  elif param== "-c":
      i += 1
      column = paramStr(i)
  elif p.key == "h":
      echo "Created by Morderon in July 2019\n nwnmdelchk.exe -s ? -e ? -c ? -r ? file.ext\n  -c=? (Optional) Replace ? with the name of the model column, default ModelName.\n -s ? (Optional) replace ? with the row you want to start with.\n -e ? (Optional) replace ? with the row you want to end with.\n -r ? (Optional) replace ? with the directory to search for models. Default: Current working directory.\n file.ext - (Mandatory) path/to/file.ext"
      quit(QuitSuccess)
  else:
    file = newFileStream(param)
  i = i + 1     



if isNil(file):
  echo "Created by Morderon in July 2019\n nwnmdelchk.exe -s ? -e ? -c ? -r ? file.ext\n  -c=? (Optional) Replace ? with the name of the model column, default ModelName.\n -s ? (Optional) replace ? with the row you want to start with.\n -e ? (Optional) replace ? with the row you want to end with.\n -r ? (Optional) replace ? with the directory to search for models. Default: Current working directory.\n file.ext - (Mandatory) path/to/file.ext"
  quit(QuitFailure)

let ftwoDA = file.readTwoDA()
if ends == 0 or ends > ftwoDA.high():
  ends = ftwoDA.high()

writeout = "Rows with missing models:\n"
for x in start..ends:
  try:
    row = ftwoDA[x].get()
    model = row[ftwoDA.columns.find(column)].get().toLowerAscii()
    seqFiles.add(model)
    if not fileExists(search & model & ".mdl"):
      writeout.add(x.intToStr() & ", " & model & "\n")
  except:
    echo "Nothing in row: ", x

writeout &= "\nModels not within the 2da (note: May be supermodels or otherwise used):\n"
for file in walkDir(search):
  fullFile = splitFile(file.path)
  if not seqFiles.contains(fullFile.name.toLowerAscii()):
    writeout.add(fullFile.name & "\n")

let timestamp = now().format("YYYY-MM-dd-HH-mm-ss")
let report = newFileStream("Report"&timestamp, fmWrite)
report.write(writeout)
echo "Reached end of set."
file.close
report.close