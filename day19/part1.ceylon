
import ceylon.file { Reader, File, current }
import ceylon.collection { LinkedList, HashSet }

// Number of beacons we have to have in common before calling it a
// success.
Integer tolerance = 12;

class Matrix(values) {
    shared List<Integer> values;

    assert(values.size == 9);

    shared Matrix mul(Matrix that) =>
        Matrix([for (i in 0..2) for (k in 0..2) sum { for (j in 0..2) this.get(i, j) * that.get(j, k)}]);

    shared Matrix neg =>
        Matrix([for (a in values) -a]);

    shared Integer get(Integer y, Integer x) {
        assert (exists result = values[y * 3 + x]);
        return result;
    }

    shared actual String string => "Matrix(``values``)";

}

Matrix id    = Matrix([ 1,  0,  0,  0,  1,  0,  0,  0,  1]);
Matrix rotXY = Matrix([ 0,  1,  0, -1,  0,  0,  0,  0,  1]);
Matrix rotYZ = Matrix([ 1,  0,  0,  0,  0,  1,  0, -1,  0]);
Matrix rotZX = Matrix([ 0,  0, -1,  0,  1,  0,  1,  0,  0]);

List<Matrix> allRotations {
    // There are three "positive" faces (id, rotXY, rotYZ). Then each
    // of those can be transformed by rotXY^2 to get a new face.
    // Finally, we can change the up-vector to any of four
    // possibilities, making a total of 3 * 2 * 4 = 24 rotations. We
    // generate those here.
    value posFaces = [id, rotXY, rotYZ];
    value flipped = [id, rotXY.mul(rotXY)];
    value upVecs = [id, rotZX, rotZX.mul(rotZX), rotZX.mul(rotZX).mul(rotZX)];
    return [for ([[face, upVec], flip] in posFaces.product(upVecs).product(flipped)) face.mul(flip).mul(upVec)];
}

class Point(x, y, z) {
    shared Integer x;
    shared Integer y;
    shared Integer z;

    shared Point transform(Matrix m) {
        // Reuse the work we did in Matrix. Easier than writing it all
        // out again.
        value column = Matrix([x, 0, 0, y, 0, 0, z, 0, 0]);
        value transformed = m.mul(column);
        return Point(transformed.get(0, 0), transformed.get(1, 0), transformed.get(2, 0));
    }

    shared Point neg => Point(-x, -y, -z);

    shared Point add(Point that) =>
        Point(this.x + that.x, this.y + that.y, this.z + that.z);

    shared Point sub(Point that) => this.add(that.neg);

    shared actual String string => "Point(``x``, ``y``, ``z``)";

    shared actual Integer hash => [x, y, z].hash;

    shared actual Boolean equals(Object that) {
        if (!is Point that) {
            return false;
        }
        return this.x == that.x && this.y == that.y && this.z == that.z;
    }

}

// For efficiency, whenever we find two scanners completely
// incompatible, we cache that knowledge here so we don't recompute
// it.
HashSet<[Integer, Integer]> incompatibleScanners = HashSet<[Integer, Integer]>();

// The type representing the world as we've built it up from the
// scanner data.
alias World => Set<Point>;

class Scanner(index, elems) {
    shared Integer index;
    shared List<Point> elems;
    variable List<Scanner>? cachedRotations = null;

    shared Scanner transform(Matrix m) =>
        Scanner(index, [for (elem in elems) elem.transform(m)]);

    shared Iterable<Scanner> rotations {
        if (exists c = this.cachedRotations) {
            return c;
        } else {
            value list = [*allRotations.map(this.transform)];
            this.cachedRotations = list;
            return list;
        }
    }

    shared World toWorld(Point offset = Point(0, 0, 0)) =>
        set { for (elem in elems) elem.add(offset) };

    shared actual String string => "Scanner(``elems``)";

    // Given a scanner, determine where that scanner has to be
    // *relative* to this one for them to be compatible with one
    // another. If no compatibility can be determined up to the
    // specified tolerance in the problem, then null is returned. This
    // method does not try to rotate scanners. For that, use
    // offsetForCompatibility.
    shared Point? offsetForCompatibilityFixed(Scanner that) {
        for (thisPoint in this.elems) {
            for (thatPoint in that.elems) {
                value thatOffset = thisPoint.sub(thatPoint);
                value pointsInCommon = this.toWorld() & that.toWorld(thatOffset);
                if (pointsInCommon.size >= tolerance) {
                    return thatOffset;
                }
            }
        }
        return null;
    }

    // Do offsetForCompatibilityFixed but for every possible rotation
    // of that scanner. Note that this scanner *always* remains in its
    // current rotation state and at (0, 0, 0). Only that scanner is
    // rotated and translated to accommodate. As above, if no valid
    // configuration is found up to the tolerance, returns null.
    shared [Point, Scanner]? offsetForCompatibility(Scanner that) {
        if ([this.index, that.index] in incompatibleScanners) {
            return null;
        }
        for (thatRotated in that.rotations) {
            if (exists point = this.offsetForCompatibilityFixed(thatRotated)) {
                return [point, thatRotated];
            }
        }
        incompatibleScanners.add([this.index, that.index]);
        incompatibleScanners.add([that.index, this.index]);
        return null;
    }

}

Point readLine(String line) {
    value nums = [for (p in line.split(','.equals)) Integer.parse(p)];
    value x = nums[0];
    assert (                    is Integer x);
    assert (exists y = nums[1], is Integer y);
    assert (exists z = nums[2], is Integer z);
    return Point(x, y, z);
}

Scanner? readScanner(Integer index, Reader file) {
    // Read "--- scanner N ---" line; if it's not there then EOF
    if (!file.readLine() exists) {
        return null;
    }
    // Read numbers until we hit a blank line
    value points = LinkedList<Point>();
    while (exists line = file.readLine(), line != "") {
        points.add(readLine(line));
    }
    return Scanner(index, points);
}

List<Scanner> readAllScanners(Reader file) {
    value scanners = LinkedList<Scanner>();
    variable value index = 0;
    while (exists scanner = readScanner(index, file)) {
        scanners.add(scanner);
        index += 1;
    }
    return scanners;
}

void solveOnce(LinkedList<Scanner> input, LinkedList<[Point, Scanner]> result) {
    // Go through the input list and the result list and find a pair
    // that are compatible.
    for ([originalOffset, leftScanner] in result) {
        for (idx -> rightScanner in input.indexed) {
            if (exists [relativeOffset, rotRightScanner] = leftScanner.offsetForCompatibility(rightScanner)) {
                value totalOffset = originalOffset.add(relativeOffset);
                input.delete(idx);
                result.add([totalOffset, rotRightScanner]);
                return;
            }
        }
    }
}

List<[Point, Scanner]> solve(List<Scanner> scanners) {
    value input = LinkedList<Scanner>(scanners);
    value result = LinkedList<[Point, Scanner]>();

    // First, arbitrarily position the very first scanner at (0, 0, 0)
    // with default orientation, so we have somewhere to start.
    assert(exists first = input.accept());
    result.add([Point(0, 0, 0), first]);

    // Now, until we run out of elements in the input list, try to
    // find a scanner in the result list and a scanner in the input
    // list that are pairwise compatible.
    while (input.size > 0) {
        solveOnce(input, result);
    }

    return result;
}

shared void part1() {

    value file = current.childPath("input.txt").resource;
    assert(is File file);
    List<Scanner> scanners;
    try (reader = file.Reader()) {
        scanners = readAllScanners(reader);
    }

    value assignedScanners = solve(scanners);

    variable World world = set([]);
    for ([point, scanner] in assignedScanners) {
        world |= scanner.toWorld(point);
    }
    print(world.size);
}
