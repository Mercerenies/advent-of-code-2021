
import java.io.File

// Amphipods are stored as strings: the first character is their type
// (A, B, C, or D), followed by an arbitrary number. Each amphipod has
// a unique string identifying it, so for example the two Amber
// amphipods are guaranteed to have different numbers after the A.
typealias Amphipod = String

data class Column(val bottom: Amphipod, val top: Amphipod)

data class InputParameters(
  val columns: List<Column>,
) {

  companion object {

    fun read(filename: String): InputParameters {
      val letterMatch = Regex("""[A-D]""")
      val contents = File(filename).readText().split("\n")
      val topRow = letterMatch.findAll(contents[2]).mapIndexed { index, v -> "${v.value[0]}${index}" }
      val botRow = letterMatch.findAll(contents[3]).mapIndexed { index, v -> "${v.value[0]}${index + 4}" }
      return InputParameters(
        (topRow zip botRow).map { Column(bottom=it.second, top=it.first) }.toList(),
      )
    }

  }

  fun toBoard(): Board =
    Board(
      mapOf(
            Pair(GraphNode.A2, columns[0].bottom),
            Pair(GraphNode.A1, columns[0].top),
            Pair(GraphNode.B2, columns[1].bottom),
            Pair(GraphNode.B1, columns[1].top),
            Pair(GraphNode.C2, columns[2].bottom),
            Pair(GraphNode.C1, columns[2].top),
            Pair(GraphNode.D2, columns[3].bottom),
            Pair(GraphNode.D1, columns[3].top),
      ),
    )

}

enum class GraphNode {
  // Our convention is that "2" is always blocked by "1", so FarLeft2
  // is to the left of FarLeft1 and FarRight2 is to the right of
  // FarRight1.
  //
  // #############
  // #...........#
  // ###.#.#.#.###
  //   #.#.#.#.#
  //   #########
  FarLeft2, FarLeft1,
  A2, A1,
  AB,
  B2, B1,
  BC,
  C2, C1,
  CD,
  D2, D1,
  FarRight2, FarRight1;

  fun adjacencies(): List<Pair<GraphNode, Int>> =
    when (this) {
      FarLeft2 -> listOf(Pair(FarLeft1, 1))
      FarLeft1 -> listOf(Pair(FarLeft2, 1), Pair(A1, 2), Pair(AB, 2))
      A2 -> listOf(Pair(A1, 1))
      A1 -> listOf(Pair(A2, 1), Pair(FarLeft1, 2), Pair(AB, 2))
      AB -> listOf(Pair(FarLeft1, 2), Pair(A1, 2), Pair(B1, 2), Pair(BC, 2))
      B2 -> listOf(Pair(B1, 1))
      B1 -> listOf(Pair(B2, 1), Pair(AB, 2), Pair(BC, 2))
      BC -> listOf(Pair(AB, 2), Pair(B1, 2), Pair(C1, 2), Pair(CD, 2))
      C2 -> listOf(Pair(C1, 1))
      C1 -> listOf(Pair(C2, 1), Pair(BC, 2), Pair(CD, 2))
      CD -> listOf(Pair(BC, 2), Pair(C1, 2), Pair(D1, 2), Pair(FarRight1, 2))
      D2 -> listOf(Pair(D1, 1))
      D1 -> listOf(Pair(D2, 1), Pair(CD, 2), Pair(FarRight1, 2))
      FarRight2 -> listOf(Pair(FarRight1, 1))
      FarRight1 -> listOf(Pair(FarRight2, 1), Pair(D1, 2), Pair(CD, 2))
    }

  fun obverse(): GraphNode? =
    when (this) {
      FarLeft2 -> FarLeft1
      FarLeft1 -> FarLeft2
      A2 -> A1
      A1 -> A2
      AB -> null
      B2 -> B1
      B1 -> B2
      BC -> null
      C2 -> C1
      C1 -> C2
      CD -> null
      D2 -> D1
      D1 -> D2
      FarRight2 -> FarRight1
      FarRight1 -> FarRight2
    }

  fun distance(destination: GraphNode): Int? =
    this.adjacencies().find { it.first == destination }?.second

  fun isHallway(): Boolean =
    hallways.contains(this)

  fun isDeep(): Boolean =
    deeps.contains(this)

  companion object {
    private val hallways = setOf(FarLeft2, FarLeft1, AB, BC, CD, FarRight2, FarRight1)
    private val deeps = setOf(FarLeft2, A2, B2, C2, D2, FarRight2)
  }

}

data class Board(val map: Map<GraphNode, Amphipod>) {

  // From a given starting position, where can we get (via
  // GraphNode.adjacencies) without hitting an occupied position?
  fun connectedTo(starting: GraphNode): Map<GraphNode, Int> {
    val connections = HashMap<GraphNode, Int>()
    // Do the first "step" here, since the starting position may be
    // occupied (hence _connectedTo would fail on it).
    for (pair in starting.adjacencies()) {
      _connectedTo(pair.first, pair.second, connections)
    }
    return connections
  }

  private fun _connectedTo(node: GraphNode, cost: Int, conn: HashMap<GraphNode, Int>): Unit {
    val prevCost = conn[node];
    if (map[node] != null) {
      // Can't visit this position at all.
      return
    } else if ((prevCost != null) && (prevCost <= cost)) {
      // We already know a more efficient way to get here, so forget
      // about it.
      return
    }

    // Visit the current place and all adjacent places.
    conn[node] = cost
    for (pair in node.adjacencies()) {
      _connectedTo(pair.first, cost + pair.second, conn)
    }

  }

  // Does NOT validate that the move is valid; I expect you to check
  // that first.
  fun doMove(start: GraphNode, end: GraphNode, distance: Int): Pair<Board, Int> {
    val startPod = map[start]!!
    val newMap = map - start + Pair(end, startPod)
    val costOfThisMove = distance * costPerMove(startPod[0])
    return Pair(
      Board(newMap),
      costOfThisMove,
    )
  }

  fun allValidNextStates(): List<Pair<Board, Int>> {
    val result = ArrayList<Pair<Board, Int>>()
    for (startNode in GraphNode.values()) {
      val startPod = this.map[startNode]
      if (startPod == null) {
        continue
      }
      for (endConn in this.connectedTo(startNode)) {
        val endNode = endConn.key
        val distance = endConn.value
        if (canMove(this, startPod[0], startNode, endNode)) {

          // Remove some obviously bad moves.

          // If we're moving into a destination, move all the way.
          if ((!endNode.isHallway()) && (!endNode.isDeep()) && (map[endNode.obverse()!!] == null)) {
            continue
          }

          result += this.doMove(startNode, endNode, distance)

        }
      }
    }
    return result
  }

  fun isFinished(): Boolean {
    for (entry in map) {
      if (!homeCells(entry.value[0]).contains(entry.key)) {
        return false
      }
    }
    return true
  }

  fun minCostToEnd(): Int =
    _minCostToEnd()

  private fun _minCostToEnd(): Int {
    val cached = cache[this]
    if (cached != null) {
      return cached
    }
    if (isFinished()) {
      return 0
    }
    var minCost = Int.MAX_VALUE / 2 // Make sure to provide enough "room" in the Int datatype for us to add new costs
    for (pair in allValidNextStates()) {
      val board = pair.first
      val costForMove = pair.second
      val minCostForRest = board._minCostToEnd()
      if (costForMove + minCostForRest < minCost) {
        minCost = costForMove + minCostForRest
      }
    }
    cache[this] = minCost
    return minCost
  }

}

val cache = HashMap<Board, Int>()

fun costPerMove(amphipodType: Char): Int =
  when (amphipodType) {
    'A' -> 1
    'B' -> 10
    'C' -> 100
    'D' -> 1000
    else -> throw IllegalArgumentException("Bad amphipod type ${amphipodType}")
  }

fun homeCells(amphipodType: Char): List<GraphNode> =
  when (amphipodType) {
    'A' -> listOf(GraphNode.A1, GraphNode.A2)
    'B' -> listOf(GraphNode.B1, GraphNode.B2)
    'C' -> listOf(GraphNode.C1, GraphNode.C2)
    'D' -> listOf(GraphNode.D1, GraphNode.D2)
    else -> throw IllegalArgumentException("Bad amphipod type ${amphipodType}")
  }

// Checks against the specific rules of the game, *not* against board
// connectivity. This should only be called on spaces which can be
// physically reached.
fun canMove(board: Board, amphipodType: Char, start: GraphNode, end: GraphNode): Boolean {
  if (start.isHallway() && end.isHallway()) {
    // Hallway-to-hallway moves are always illegal.
    return false
  } else if ((!end.isHallway()) && (!homeCells(amphipodType).contains(end))) {
    // Never move into a room that doesn't belong to you.
    return false
  } else if ((homeCells(amphipodType).contains(end)) && (board.map[end.obverse()!!] != null) && (board.map[end.obverse()!!]!![0] != amphipodType)) {
    // Never move into a destination if there's someone already there
    // and they don't belong there.
    return false
  } else if ((homeCells(amphipodType).contains(start)) && ((board.map[start.obverse()!!] == null) || (board.map[start.obverse()!!]!![0] == amphipodType))) {
    // Never move out of a destination unless it's to let someone else
    // (who doesn't belong there) get out.
    return false
  }
  return true
}

fun main() {
  val params = InputParameters.read("input.txt")
  val startingBoard = params.toBoard()
  println(startingBoard.minCostToEnd())
}
