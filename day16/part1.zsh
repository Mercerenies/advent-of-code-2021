#!/bin/zsh

function hex_to_binary {
    case $1 in
        0) print -n 0000 ;;
        1) print -n 0001 ;;
        2) print -n 0010 ;;
        3) print -n 0011 ;;
        4) print -n 0100 ;;
        5) print -n 0101 ;;
        6) print -n 0110 ;;
        7) print -n 0111 ;;
        8) print -n 1000 ;;
        9) print -n 1001 ;;
        A) print -n 1010 ;;
        B) print -n 1011 ;;
        C) print -n 1100 ;;
        D) print -n 1101 ;;
        E) print -n 1110 ;;
        F) print -n 1111 ;;
    esac
}

# packet_version $string, $index
function packet_version {
    print -n ${1:$2:3}
}

# packet_type $string, $index
function packet_type {
    local index=$2
    index=$((index + 3))
    print -n ${1:$index:3}
}

# subpacket_indices $string, $index
function subpacket_indices {
    local type=$(packet_type $1 $2)
    local index=$2
    index=$((index + 6))
    if [ "$type" != "100" ]; then
        # Operator packet
        local length_type=${1:$index:1}
        if [ "$length_type" = "0" ]; then
            # Total length in bits
            index=$((index + 1))
            local bits_length=$((2#${1:$index:15}))
            index=$((index + 15))
            local end_of_subpackets=$((index + bits_length))
            while (($index < $end_of_subpackets)); do
                print $index
                index=$(end_of_packet $1 $index)
            done
        else
            # Number of subpackets
            index=$((index + 1))
            local subpacket_count=$((2#${1:$index:11}))
            index=$((index + 11))
            for _ in $(seq 1 $subpacket_count); do
                print $index
                index=$(end_of_packet $1 $index)
            done
        fi
    fi
}

# end_of_packet $string, $index
function end_of_packet {
    local type=$(packet_type $1 $2)
    local index=$2
    index=$((index + 6))
    if [ "$type" = "100" ]; then
        # Literal value packet
        while [ ${1:$index:1} = 1 ]; do
            index=$((index + 5))
        done
        print -n $((index + 5))
    else
        # Operator packet
        local length_type=${1:$index:1}
        if [ "$length_type" = "0" ]; then
            # Total length in bits
            index=$((index + 1))
            bits_length=$((2#${1:$index:15}))
            print -n $((index + 15 + $bits_length))
        else
            # Number of subpackets
            index=$((index + 1))
            local subpacket_count=$((2#${1:$index:11}))
            index=$((index + 11))
            for _ in $(seq 1 $subpacket_count); do
                index=$(end_of_packet $1 $index)
            done
            print -n $index
        fi
    fi
}

function sum_versions {
    local subpacket
    local version=$(packet_version $1 $2)
    local version_sum=$((2#$version))
    for subpacket in $(subpacket_indices $1 $2); do
        version=$(sum_versions $1 $subpacket)
        version_sum=$((version_sum+version))
    done
    print $version_sum
}

input=$(<input.txt)

bin=""
for x in ${(s[])input}; do
    bin+=$(hex_to_binary $x)
done
sum_versions $bin 0
