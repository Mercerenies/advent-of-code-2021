
lines = FileSystem readLines("input.txt")

horiz = 0
depth = 0
lines each(line,
           (command, amount) = line asText split(" ")
           amount = amount toRational
           case(command,
                "forward", horiz += amount,
                "up", depth -= amount,
                "down", depth += amount))

(horiz * depth) println
