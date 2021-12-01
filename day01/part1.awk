
BEGIN {
  increases = -1; # We will overcount the first row always.
  prev = 0;
}

{
  if (prev < $0) {
    increases += 1;
  }
  prev = $0;
}

END {
  print increases;
}
