
my $total_dice_rolls = 0;
my $next_die = 1;

sub rem1(Int $a, Int $b --> Int) {
    # The modulo operator ($a % $b) returns a value from 0 to $b-1.
    # This function does the same operation but shifted so that the
    # result is from 1 to $b.
    ($a - 1) % $b + 1
}

sub roll_die(--> Int) {
    my $curr = $next_die;
    $total_dice_rolls += 1;
    $next_die = rem1($next_die + 1, 100);
    $curr
}

sub term:<roll_die> { roll_die() }

sub roll_three_dice(--> Int) {
    [+] (roll_die xx 3)
}

my ($p1_score, $p2_score) = (0, 0);
my ($p1_space, $p2_space) = "input.txt".IO.slurp.lines.map({ /\d+$$/ and $/ });

while ($p2_score < 1000) {
    my $rolls = roll_three_dice;
    $p1_space = rem1($p1_space + $rolls, 10);
    $p1_score += $p1_space;
    # It's now the other player's turn.
    ($p1_space, $p2_space) = ($p2_space, $p1_space);
    ($p1_score, $p2_score) = ($p2_score, $p1_score);
}
say $p1_score * $total_dice_rolls;
