
module part2;

import std.stdio;
import std.variant;
import std.conv;
import std.string;
import std.range;
import std.algorithm;

alias Number = Algebraic!(int, Branch!(This));

struct Branch(T) {
  T* first;
  T* second;
}

struct ExplosionState {
  Number* result;
  int left;
  int right;
}

struct HeapStr {
  string s;
}

// Does not check for reduction!
bool equal_numbers_primitive(Number* a, Number* b) {
  if ((a.peek!(int)() != null) && (b.peek!(int)() != null)) {
    return *a.peek!(int)() == *b.peek!(int)();
  } else if ((a.peek!(Branch!(Number))() != null) && (b.peek!(Branch!(Number))() != null)) {
    auto a_branch = a.peek!(Branch!(Number))();
    auto b_branch = b.peek!(Branch!(Number))();
    return equal_numbers_primitive(a_branch.first , b_branch.first ) &&
           equal_numbers_primitive(a_branch.second, b_branch.second);
  } else {
    return false;
  }
}

T* number_cata(T)(Number* x, T* delegate(int) func_int, T* delegate(Branch!(T)) func_branch) {
  return (*x).visit!(
    (int n) => func_int(n),
    (Branch!(Number) input_branch) {
      auto output_branch = Branch!(T)(
        number_cata(input_branch.first , func_int, func_branch),
        number_cata(input_branch.second, func_int, func_branch),
      );
      return func_branch(output_branch);
    },
  );
}

string number_to_string(Number* x) {
  return x.number_cata!(HeapStr)(
    (int n) {
      return new HeapStr(to!string(n));
    },
    (Branch!(HeapStr) branch) {
      return new HeapStr(format("[%s,%s]", branch.first.s, branch.second.s));
    },
  ).s;
}

Number* parse(HeapStr* input) {
  if (input.s.front() == '[') {
    input.s.popFront(); // [
    auto first = parse(input);
    input.s.popFront(); // ,
    auto second = parse(input);
    input.s.popFront(); // ]
    return new Number(Branch!(Number)(first, second));
  } else {
    auto pred = (dchar a) => a < '0' || a > '9';
    auto ipred = (dchar a) => !pred(a);
    string text = to!string(input.s.until!(pred)().array);
    input.s.skipOver!(ipred);
    return new Number(to!int(text));
  }
}

Number* parse(string input) {
  return parse(new HeapStr(input));
}

Number* change_leftmost(Number* input, int delegate(int) func) {
  if (input.peek!(int)() != null) {
    return new Number(func(*input.peek!(int)()));
  } else {
    auto input_branch = input.peek!(Branch!(Number))();
    return new Number(Branch!(Number)(change_leftmost(input_branch.first, func), input_branch.second));
  }
}

Number* change_rightmost(Number* input, int delegate(int) func) {
  if (input.peek!(int)() != null) {
    return new Number(func(*input.peek!(int)()));
  } else {
    auto input_branch = input.peek!(Branch!(Number))();
    return new Number(Branch!(Number)(input_branch.first, change_rightmost(input_branch.second, func)));
  }
}

ExplosionState explode(Number* x, int depth) {
  if (x.peek!(int) != null) {
    // Ordinary numbers don't explode
    return ExplosionState(x, 0, 0);
  } else {
    auto x_branch = x.peek!(Branch!(Number))();

    if ((x_branch.first.peek!(int) != null) && (x_branch.second.peek!(int) != null)) {
      // Candidate for explosion; are we deep enough?
      if (depth > 4) {
        return ExplosionState(new Number(0), *x_branch.first.peek!(int), *x_branch.second.peek!(int));
      } else {
        return ExplosionState(x, 0, 0);
      }
    }

    // Otherwise, do it recursively. Try left first.
    auto result_left = explode(x_branch.first, depth + 1);
    if (!equal_numbers_primitive(result_left.result, x_branch.first)) {
      // Exploded on the left, so evaluate
      auto new_left  = result_left.result;
      auto new_right = change_leftmost(x_branch.second, (int n) => n + result_left.right);
      return ExplosionState(new Number(Branch!(Number)(new_left, new_right)), result_left.left, 0);
    }

    // If not, try on the right
    auto result_right = explode(x_branch.second, depth + 1);
    if (!equal_numbers_primitive(result_right.result, x_branch.second)) {
      // Exploded on the right, so evaluate
      auto new_left  = change_rightmost(x_branch.first, (int n) => n + result_right.left);
      auto new_right = result_right.result;
      return ExplosionState(new Number(Branch!(Number)(new_left, new_right)), 0, result_right.right);
    }

    // Otherwise, no explosion
    return ExplosionState(x, 0, 0);

  }

}

Number* split(Number* x) {
  if (x.peek!(int) != null) {
    int n = *x.peek!(int);
    if (n >= 10) {
      return new Number(Branch!(Number)(new Number(n / 2), new Number((n + 1) / 2)));
    } else {
      return x;
    }
  } else {
    auto x_branch = x.peek!(Branch!(Number))();

    auto result_left = split(x_branch.first);
    if (!equal_numbers_primitive(result_left, x_branch.first)) {
      return new Number(Branch!(Number)(result_left, x_branch.second));
    }

    auto result_right = split(x_branch.second);
    if (!equal_numbers_primitive(result_right, x_branch.second)) {
      return new Number(Branch!(Number)(x_branch.first, result_right));
    }

    return x;
  }
}

Number* reduce(Number* x) {
  // Manual TCO so this doesn't stack overflow
  while (true) {
    // Try to explode
    auto explosion_state = explode(x, 1);
    if (!equal_numbers_primitive(explosion_state.result, x)) {
      x = explosion_state.result;
      continue;
    }
    // Try to split
    auto split_state = split(x);
    if (!equal_numbers_primitive(split_state, x)) {
      x = split_state;
      continue;
    }
    break;
  }
  return x;
}

Number* add(Number* a, Number* b) {
  auto value = new Number(Branch!(Number)(a, b));
  return reduce(value);
}

int magnitude(Number* x) {
  return *x.number_cata(
    (int n) => new int(n),
    (Branch!(int) branch) => new int(*branch.first * 3 + *branch.second * 2),
  );
}

void main(string[] args) {
  Number*[] lines = "input.txt".File.byLine.map!((char[] x) => parse(to!string(x))).array;
  int best_magnitude = 0;
  foreach (x; lines) {
    foreach (y; lines) {
      if (!equal_numbers_primitive(x, y)) {
        best_magnitude = max(best_magnitude, add(x, y).magnitude);
      }
    }
  }
  writeln(best_magnitude);
}
