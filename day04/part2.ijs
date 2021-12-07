
intervalsplitpos =: 0 = 3 | i. 14

removeblanks =: (~:&(<''))#]
spliton =: 1 : '(u;._1) @: ,'
partitionrow =: intervalsplitpos & (".;.1)

hascolumnofones =: (+./) @: (*./)
hasrowofones =: hascolumnofones @: |:
iswinningboard =: hasrowofones +. hascolumnofones

chars =: freads 'input.txt'
lines =: LF <spliton chars
input =: ',' ".spliton > {. lines

NB. Drop the input text line
bingotext =: }. lines
bingotext =: removeblanks bingotext
bingocount =: (#bingotext) % 5

bingo =: (bingocount , 5 5) $, (partitionrow@:>)"0 bingotext
marked =: ($bingo) $ 0

echo 3 : 0 '' NB. Explicit definition so we can use looping constructs
  for_i. input do.
    priormarked =: marked
    marked =: marked +. (bingo = i)
    totalwins =: +/ iswinningboard"2 marked
    if. totalwins = bingocount do.
      break.
    end.
  end.
  losingboardidx =: (iswinningboard"2 priormarked) i. 0
  losingboard =: losingboardidx { bingo
  losingmarks =: losingboardidx { marked
  score =: i * +/, losingboard * -.losingmarks
  score
)
