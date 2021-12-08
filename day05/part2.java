
import java.nio.file.Files;
import java.nio.file.Paths;
import java.nio.charset.Charset;
import java.util.*;
import java.util.stream.*;
import java.util.function.*;
import java.io.IOException;

public class part2 {

  public static class Pair {
    public int first;
    public int second;

    public Pair(int first, int second) {
      this.first = first;
      this.second = second;
    }

    public boolean equals(Object that) {
      return (that instanceof Pair) && ((Pair)that).first == first && ((Pair)that).second == second;
    }

    public int hashCode() {
      return first ^ second;
    }

  }

  public static class Entry {
    public int x0;
    public int y0;
    public int x1;
    public int y1;

    public Entry(int x0, int y0, int x1, int y1) {
      this.x0 = x0;
      this.y0 = y0;
      this.x1 = x1;
      this.y1 = y1;
    }

    public Entry(String s) {
      String[] tok = s.split(" -> ");
      String[] pos0 = tok[0].split(",");
      String[] pos1 = tok[1].split(",");
      this.x0 = Integer.parseInt(pos0[0]);
      this.y0 = Integer.parseInt(pos0[1]);
      this.x1 = Integer.parseInt(pos1[0]);
      this.y1 = Integer.parseInt(pos1[1]);
    }

    public boolean isHorizOrVert() {
      return (x0 == x1) || (y0 == y1);
    }

    public void runOnRange(Consumer<Pair> f) {
      int steps = Math.max(Math.abs(this.x1 - this.x0), Math.abs(this.y1 - this.y0));
      int dx = (int)Math.signum(this.x1 - this.x0);
      int dy = (int)Math.signum(this.y1 - this.y0);
      part1.runOnRange((i) -> f.accept(new Pair(x0 + i * dx, y0 + i * dy)), 0, steps);
    }

  }

  // If statements :)
  public static class RunOnRangeException extends RuntimeException {}
  public static class ForEachException extends RuntimeException {}
  public static class BiggerThanOneException extends RuntimeException {}

  public static void noop(int a) {
    // Need this to get around Java's statement/expression issues.
  }

  public static void throwIfTrue(boolean condition, RuntimeException exception) {
    try {
      noop(1 / Boolean.compare(condition, true));
    } catch (ArithmeticException ignore) {
      throw exception;
    }
  }

  private static void _runOnRange(Consumer<Integer> f, int min, int max) {
    throwIfTrue(min > max, new RunOnRangeException());
    f.accept(min);
    _runOnRange(f, min + 1, max);
  }

  public static void runOnRange(Consumer<Integer> f, int min, int max) {
    try {
      _runOnRange(f, min, max);
    } catch (RunOnRangeException e) {}
  }

  private static <T> void _forEach(Iterator<T> iter, Consumer<T> f) {
    throwIfTrue(!iter.hasNext(), new ForEachException());
    f.accept(iter.next());
    _forEach(iter, f);
  }

  public static <T> void forEach(Iterator<T> iter, Consumer<T> f) {
    try {
      _forEach(iter, f);
    } catch (ForEachException e) {}
  }

  public static int biggerThanOne(int value) {
    try {
      throwIfTrue(value > 1, new BiggerThanOneException());
      return 0;
    } catch (BiggerThanOneException e) {
      return 1;
    }
  }

  public static void main(String[] args) throws IOException {
    List<String> lines = Files.readAllLines(Paths.get("input.txt"), Charset.defaultCharset());
    List<Entry> relevantLines =
      lines.stream().map((s) -> new Entry(s)).collect(Collectors.toList());
    Map<Pair, Integer> map = new HashMap<Pair, Integer>();

    forEach(relevantLines.iterator(), (entry) -> {
      entry.runOnRange((pair) -> {
        map.put(pair, map.getOrDefault(pair, 0) + 1);
      });
    });

    int count = map.values().stream().mapToInt(part1::biggerThanOne).sum();
    System.out.println(count);

  }

}
