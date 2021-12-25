<?php

$big = 999999;

$file = fopen("input.txt", "r");
$grid = [];
$dyn = [];
$xlen = 100;
$ylen = 100;

$y = 0;
while ($line = fgets($file)) {
    $line = rtrim($line);

    for ($x = 0; $x < strlen($line); $x++) {
        for ($shifty = 0; $shifty < 5; $shifty++) {
            for ($shiftx = 0; $shiftx < 5; $shiftx++) {
                $grid[($x+$shiftx*$xlen).",".($y+$shifty*$ylen)] = ((+$line[$x]) + $shifty + $shiftx - 1) % 9 + 1;
                $dyn[($x+$shiftx*$xlen).",".($y+$shifty*$ylen)] = $big;
            }
        }
    }

    $y += 1;
}
$dyn["0,0"] = 0;
fclose($file);

$xlen *= 5;
$ylen *= 5;

# Now iterate until we have nothing new to update
$frontier = new SplQueue;
$frontier->enqueue([0, 1]);
$frontier->enqueue([1, 0]);
while (!$frontier->isEmpty()) {
    $elem = $frontier->dequeue();
    $x = $elem[0];
    $y = $elem[1];
    $above = array_key_exists($x.",".($y-1), $dyn) ? $dyn[$x.",".($y-1)] : $big;
    $left  = array_key_exists(($x-1).",".$y, $dyn) ? $dyn[($x-1).",".$y] : $big;
    $right = array_key_exists(($x+1).",".$y, $dyn) ? $dyn[($x+1).",".$y] : $big;
    $below = array_key_exists($x.",".($y+1), $dyn) ? $dyn[$x.",".($y+1)] : $big;
    $cost = min($above, $left, $right, $below) + $grid[$x.",".$y];
    if ($cost < $dyn[$x.",".$y]) {
        $dyn[$x.",".$y] = $cost;
        if ($y < $ylen - 1) {
            $frontier->enqueue([$x, $y+1]);
        }
        if ($y > 0) {
            $frontier->enqueue([$x, $y-1]);
        }
        if ($x < $xlen - 1) {
            $frontier->enqueue([$x+1, $y]);
        }
        if ($x > 0) {
            $frontier->enqueue([$x-1, $y]);
        }
    }
}

print_r($dyn[($xlen-1).",".($ylen-1)]."\n");
?>
