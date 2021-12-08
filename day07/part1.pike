
int main() {
  string input_text = Stdio.read_file("input.txt");
  array(int) input = map(input_text / ",", lambda(string s) { return (int)s; });
  sort(input);
  int median = input[sizeof(input) / 2];
  array(int) movements = map(input, lambda(int crab) { return abs(crab - median); });
  write(`+(@(movements)) + "\n");
}
