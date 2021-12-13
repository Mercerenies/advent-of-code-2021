
class InputLine

  new: (@inputs, @outputs) =>

find_in = (tbl, elem) ->
  for idx, x in ipairs(tbl)
    if x == elem
      return idx
  nil

split = (line, sep) ->
  string.gmatch(line, "([^" .. sep .. "]+)")

iterator_to_table = (iter) ->
  [x for x in iter]

parse_input_line = (line) ->
  local input, output -- Must be predeclared due to a Moonscript bug
  {input, output} = iterator_to_table(split(line, "|"))
  inputs = iterator_to_table(split(input, " "))
  outputs = iterator_to_table(split(output, " "))
  InputLine inputs, outputs

lines = [parse_input_line(line) for line in io.lines("input.txt")]

matching_lengths = {2, 3, 4, 7}

count = 0
for _, line in ipairs(lines)
  for _, out in ipairs(line.outputs)
    if find_in(matching_lengths, #out)
      count += 1

print(count)
