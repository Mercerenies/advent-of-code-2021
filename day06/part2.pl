% -*- Prolog -*-

:-
    use_module(library(readutil)).

%% Original implementation (used in the short term, but slower)

% newborns(+OldFish, ?NewFish).
newborns([], []).
newborns([0 | T1], [8 | T2]) :-
    newborns(T1, T2).
newborns([_ | T1], T2) :-
    newborns(T1, T2).

% decrement(?N, ?M).
decrement(0, 6).
decrement(N, M) :-
    succ(M, N).

% next_day(+F0, -F1).
next_day(F0, F1) :-
    newborns(F0, Newborns),
    maplist(decrement, F0, ExistingFish),
    append(ExistingFish, Newborns, F1).

% advance_days(+F0, +N, -F1).
advance_days(F0, 0, F0).
advance_days(F0, N, F2) :-
    !,
    succ(M, N),
    next_day(F0, F1),
    advance_days(F1, M, F2).

%% We're going to calculate this in 8-step intervals

step_size(64).

:- dynamic do_steps/2.

% do_steps(+F0, -F1) % Takes a single object, NOT a list, and produces a list.
do_steps(F0, F1) :-
    step_size(StepSize),
    advance_days([F0], StepSize, F1),
    !,
    asserta(do_steps(F0, F1)).

:- dynamic do_steps_till/3.

% do_steps_till(F, N, L)
do_steps_till(F, N, L) :-
    succ(M, N),
    do_steps(F, F1),
    step(F1, M, L),
    asserta(do_steps_till(F, N, L)).

% step(+F0, +S, -FinalCount).
step(F0, 0, L) :-
    !,
    length(F0, L).
step([], _, 0) :-
    !.
step([F | FT], N, L) :-
    !,
    do_steps_till(F, N, L1),
    !,
    step(FT, N, L2),
    L is L1 + L2.

:-
    read_file_to_string("input.txt", FileContents, []),
    split_string(FileContents, ",", "\n", FishStr),
    maplist(number_codes, Fish, FishStr),
    step(Fish, 4, Answer),
    writeln(Answer).

