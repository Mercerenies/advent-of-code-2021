
-- Indices in 7-segment display
--
--  1111
-- 2    3
-- 2    3
--  4444
-- 5    6
-- 5    6
--  7777

local permutations, map, filter, table_eq

class Number

  new: (@segments) =>

  __eq: (other) =>
    return false unless rawequal(self.__class, other.__class)
    table_eq(self.segments, other.segments)

numbers =
  [0]: Number {1, 2, 3, 5, 6, 7},
  [1]: Number {3, 6},
  [2]: Number {1, 3, 4, 5, 7},
  [3]: Number {1, 3, 4, 6, 7},
  [4]: Number {2, 3, 4, 6},
  [5]: Number {1, 2, 4, 6, 7},
  [6]: Number {1, 2, 4, 5, 6, 7},
  [7]: Number {1, 3, 6},
  [8]: Number {1, 2, 3, 4, 5, 6, 7},
  [9]: Number {1, 2, 3, 4, 6, 7},

concat = (...) ->
  with result = {}
    for _, xs in ipairs{...}
      for _, x in ipairs(xs)
        result[#result+1] = x

table_eq = (a, b) ->
  a_keys, b_keys = 0, 0
  for k, v in pairs(a)
    if v ~= b[k]
      return false
    a_keys += 1
  for _, _ in pairs(b)
    b_keys += 1
  return a_keys == b_keys

class InputLine

  new: (@inputs, @outputs) =>

  all_text: =>
    concat(@inputs, @outputs)

class Assignment

  new: (@assignments) =>
    -- Takes a table with keys a through g and values indices in the
    -- above commented display.

  number: (str) =>
    active = [@assignments[n] for n in string.gmatch(str, ".")]
    table.sort(active)
    Number active

  identify_number: (str) =>
    for idx, n in pairs(numbers)
      if @number(str) == n
        return idx
    nil

  @_from_permutation: (perm) =>
    self
      a: perm[1],
      b: perm[2],
      c: perm[3],
      d: perm[4],
      e: perm[5],
      f: perm[6],
      g: perm[7],

  @all: =>
    map(self\_from_permutation, permutations({1, 2, 3, 4, 5, 6, 7}))

_permutations = (values, k) ->
  if k == 1
    coroutine.yield(values)
  else
    _permutations(values, k - 1)
    for i = 1, k - 1
      if k % 2 == 0
        values[i], values[k] = values[k], values[i]
      else
        values[1], values[k] = values[k], values[1]
      _permutations(values, k - 1)

permutations = (values) ->
  co = coroutine.create(-> _permutations(values, #values))
  ->
    ok, value = coroutine.resume(co)
    assert(ok, value)
    value

find_in = (tbl, elem) ->
  for idx, x in ipairs(tbl)
    if x == elem
      return idx
  nil

split = (line, sep) ->
  string.gmatch(line, "([^" .. sep .. "]+)")

iterator_to_table = (iter) ->
  [x for x in iter]

filter = (f, iter) ->
  ->
    while true
      value = iter()
      return value if value == nil or f(value)

map = (f, iter) ->
  ->
    value = iter()
    return nil if value == nil
    f(value)

parse_input_line = (line) ->
  local input, output -- Must be predeclared due to a Moonscript bug
  {input, output} = iterator_to_table(split(line, "|"))
  inputs = iterator_to_table(split(input, " "))
  outputs = iterator_to_table(split(output, " "))
  InputLine inputs, outputs

lines = [parse_input_line(line) for line in io.lines("input.txt")]

matching_lengths = {2, 3, 4, 7}

total_output_values = 0
for _, line in ipairs(lines)
  assignments = Assignment\all!
  for _, value in ipairs(line\all_text!)
    assignments = filter ((x) -> x\identify_number(value)), assignments
  assignments = iterator_to_table(assignments)
  assert(#assignments == 1) -- Should only be one correct solution
  assignment = assignments[1]
  this_output = 0
  for _, out in ipairs(line.outputs)
    this_output = this_output * 10 + assignment\identify_number(out)
  total_output_values += this_output
print(total_output_values)
