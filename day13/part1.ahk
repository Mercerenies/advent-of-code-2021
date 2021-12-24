
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
    break
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
for key, value in data {
  if (value) {
    count += 1
  }
}

MsgBox % count