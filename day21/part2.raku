
sub rem1(Int $a, Int $b --> Int) {
    # The modulo operator ($a % $b) returns a value from 0 to $b-1.
    # This function does the same operation but shifted so that the
    # result is from 1 to $b.
    ($a - 1) % $b + 1
}

class GameState {
    has Int $.p1_score = 0;
    has Int $.p2_score = 0;
    has Int $.p1_space;
    has Int $.p2_space;

    method swap_players {
        GameState.new(
            p1_score => $.p2_score,
            p2_score => $.p1_score,
            p1_space => $.p2_space,
            p2_space => $.p1_space,
        )
    }

    method move_player(Int $die) {
        my $new_space = rem1($.p1_space + $die, 10);
        GameState.new(
            p1_score => $.p1_score + $new_space,
            p2_score => $.p2_score,
            p1_space => $new_space,
            p2_space => $.p2_space,
        )
    }

    method to_hash_key(--> Str) {
        qq[$.p1_score,$.p2_score,$.p1_space,$.p2_space]
    }

}

# All possible rolls with 3 Dirac dice.
my @dirac_rolls = gather {
    for (1..3) -> $i {
        for (1..3) -> $j {
            for (1..3) -> $k {
                take $i + $j + $k;
            }
        }
    }
};

my %remembered_states;

sub do_one_turn(GameState $state) {
    gather {
        for @dirac_rolls -> $die {
            take $state.move_player($die).swap_players;
        }
    }
}

sub finish_game(GameState $state) {
    # Check our cache.
    my $hash_key = $state.to_hash_key;
    if (%remembered_states{$hash_key}:!exists) {
        # See if P2 has won (P2 was last to move).
        if ($state.p2_score >= 21) {
            # There is one ending condition: P2 wins.
            %remembered_states{$hash_key} = [0, 1];
        } else {
            # Roll all of the dice.
            my ($totalp1wins, $totalp2wins) = (0, 0);
            for do_one_turn($state) -> $new_state {
                # Note: P1 and P2 are swapped here, since the
                # "current" player is swapped after do_one_turn.
                my ($p2wins, $p1wins) = finish_game($new_state);
                $totalp1wins += $p1wins;
                $totalp2wins += $p2wins;
            }
            %remembered_states{$hash_key} = [$totalp1wins, $totalp2wins];
        }
    }
    %remembered_states{$hash_key}
}

my ($p1_space, $p2_space) = "input.txt".IO.slurp.lines.map({ /\d+$$/ and +$/ });
my $start_state = GameState.new(:$p1_space, :$p2_space);
my ($p1_wins, $p2_wins) = finish_game($start_state);
say max($p1_wins, $p2_wins);
