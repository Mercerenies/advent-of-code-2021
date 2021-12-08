
array(mixed) new_array(int count, function f) {
  array(int) arr = ({});
  for (int i = 0; i < count; i++) {
    arr += ({f(i)});
  }
  return arr;
}

int main() {
  string input_text = Stdio.read_file("input.txt");
  array(int) input = map(input_text / ",", lambda(string s) { return (int)s; });
  int max = Array.reduce(max, input);

  array(int) costs = new_array(max, lambda(int i) { return 0; });

  foreach(input, int curr) {
    for (int index = 0; index < max; index++) {
      // Cost of going from curr to index is the sum from 1 to the
      // difference.
      int n = abs(curr - index);
      costs[index] += n * (n + 1) / 2;
    }
  }

  int mincost = Array.reduce(min, costs);
  write(mincost + "\n");
}
