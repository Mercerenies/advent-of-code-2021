% -*- Prolog -*-

:-
    use_module(library(readutil)).

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

:-
    read_file_to_string("input.txt", FileContents, []),
    split_string(FileContents, ",", "\n", FishStr),
    maplist(number_codes, Fish, FishStr),
    advance_days(Fish, 80, NewFish),
    length(NewFish, Answer),
    writeln(Answer).
