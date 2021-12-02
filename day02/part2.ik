
lines = FileSystem readLines("input.txt")

horiz = 0
depth = 0
aim = 0
lines each(line,
           (command, amount) = line asText split(" ")
           amount = amount toRational
           case(command,
                "forward", (horiz += amount
                            depth += amount * aim),
                "up", aim -= amount,
                "down", aim += amount))

(horiz * depth) println
