<?php

$big = 9999;

$file = fopen("input.txt", "r");
$grid = [];
$dyn = [];
$y = 0;
while ($line = fgets($file)) {
    $line = rtrim($line);

    for ($x = 0; $x < strlen($line); $x++) {
        $grid[$x.",".$y] = +$line[$x];
        $dyn[$x.",".$y] = $big;
    }
    $xlen = $x;

    $y += 1;
}
$dyn["0,0"] = 0;
$ylen = $y;
fclose($file);

# Now iterate until we have nothing new to update
$changed = true;
while ($changed) {
    $changed = false;
    for ($y = 0; $y < $ylen; $y++) {
        for ($x = 0; $x < $xlen; $x++) {
            $above = array_key_exists($x.",".($y-1), $dyn) ? $dyn[$x.",".($y-1)] : $big;
            $left  = array_key_exists(($x-1).",".$y, $dyn) ? $dyn[($x-1).",".$y] : $big;
            $right = array_key_exists(($x+1).",".$y, $dyn) ? $dyn[($x+1).",".$y] : $big;
            $below = array_key_exists($x.",".($y+1), $dyn) ? $dyn[$x.",".($y+1)] : $big;
            $cost = min($above, $left, $right, $below) + $grid[$x.",".$y];
            if ($cost < $dyn[$x.",".$y]) {
                $dyn[$x.",".$y] = $cost;
                $changed = true;
            }
        }
    }
}

print_r($dyn[($xlen-1).",".($ylen-1)]."\n");
?>
