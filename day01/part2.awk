
BEGIN {
  increases = -3; # We will overcount the first three sums always.
  prev_sum = 0;
  running_sum = 0;
  # Last three rows
  three = 0;
  two = 0;
  one = 0;
}

{
  running_sum += $0;
  running_sum -= three;
  if (prev_sum < running_sum) {
    increases += 1;
  }
  three = two;
  two = one;
  one = $0;
  prev_sum = running_sum;
}

END {
  print increases;
}
