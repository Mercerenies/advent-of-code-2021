
data := Object()
line := 1
readingFolds := 0
loop {
  FileReadLine, contents, input.txt, %line%
  if Errorlevel {
	  break
  }
  if (readingFolds) {
    foldAxis := SubStr(contents, RegexMatch(contents, "\d"))
    if (RegexMatch(contents, "x")) {
      for key, value in data.Clone() {
        if (value) {
          StringSplit pos, key, `,
          x := pos1
          y := pos2
          if (x > foldAxis) {
            data[(2*foldAxis-x) "," y] := 1
            data[x "," y] := 0
          }
        }
      }
    } else {
      for key, value in data.Clone() {
        if (value) {
          StringSplit pos, key, `,
          x := pos1
          y := pos2
          if (y > foldAxis) {
            data[x "," (2*foldAxis-y)] := 1
            data[x "," y] := 0
          }
        }
      }
    }
  } else {
    if (contents = "") {
      readingFolds := 1
    } else {
      data[contents] := 1
    }
  }
  line += 1
}

count := 0
maxX := 0
maxY := 0
for key, value in data {
  if (value) {
    StringSplit pos, key, `,
    maxX := max(maxX, pos1)
    maxY := max(maxY, pos2)
    count += 1
  }
}

finalString := ""
x := 0
y := 0
while (y <= maxY) {
  x := 0
  while (x <= maxX) {
    if (data[x "," y]) {
      finalString := finalString "X"
    } else {
      finalString := finalString " "
    }
    x += 1
  }
  finalString := finalString "`n"
  y += 1
}

Gui, New
Gui, Font,, Courier
Gui, Add, Text,, %finalString%
Gui, Show
return

GuiClose:
  ExitApp