#!/bin/bash

# Sets up the necessary project structure for Ceylon to be able to
# understand our code. Pass (as argv) 1 to run Part 1 and 2 to run
# Part 2.

i=$1

(
    mkdir -p source/com/mercerenies/aoc2021
    cp "part$i.ceylon" source/com/mercerenies/aoc2021/

    cat <<EOF >source/com/mercerenies/aoc2021/module.ceylon
native("jvm")
module com.mercerenies.aoc2021 "1.0.0" {
    import ceylon.file "1.3.3";
    import ceylon.collection "1.3.3";
}
EOF

    ceylon compile com.mercerenies.aoc2021 && ceylon run "--run=part$i" com.mercerenies.aoc2021
)
rm -r source
rm -r modules
