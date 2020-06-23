%%%-----------------------------------------------------------------------------
%%%                    Revenge of the Towers of Hanoi 2.0
%%%                Copyright © 2015 Ben Goldsworthy (rumps)        
%%% 
%%%   A program to create and solve the Towers of Hanoi problem
%%%  
%%%   This program is free software: you can redistribute it and/or modify  
%%%   it under the terms of the GNU General Public License as published by
%%%   the Free Software Foundation, either version 3 of the License, or
%%%   (at your option) any later version.
%%%
%%%   This program is distributed in the hope that it will be useful,
%%%   but WITHOUT ANY WARRANTY; without even the implied warranty of
%%%   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
%%%   GNU General Public License for more details.
%%%
%%%   You should have received a copy of the GNU General Public License
%%%   along with this program.  If not, see <http://www.gnu.org/licenses/>.
%%%-----------------------------------------------------------------------------
%%%   Exports
%%%-----------------------------------------------------------------------------
%%%   create_towers(# of disks, arbitrary initial config)
%%%      returns game state representation
%%%   display_towers(game state)
%%%   move(game state, from, to, false)
%%%      returns updated game state
%%%   solve(game state)
%%%      returns solved game state
%%%-----------------------------------------------------------------------------

-module(hanoi).
-export([create_towers/2, display_towers/1, move/4, solve/1]).
-author('Ben Goldsworthy (rumps)').

%%------------------------------------------------------------------------------
%% Function:   create_towers/2
%% Purpose:    Create an initial game state.
%% Args:       Boolean is whether to start with arbitrary configuration or 
%%             not.
%% Returns:    A list of {towers, [disks]}.
%%------------------------------------------------------------------------------
create_towers(A, false) ->
   [{tower1, lists:seq(1,A)}, {tower2, []}, {tower3, []}, A];
create_towers(A, true) ->
   Game = [{tower1, lists:seq(1,A)}, {tower2, []}, {tower3, []}, A],
   random_juggling(Game, A * 200).

%%------------------------------------------------------------------------------
%% Function:   random_juggling/2
%% Purpose:    Randomly juggles around the disks to create an arbitrary starting
%%             configuration.
%% Returns:    A randomly-juggled list of {towers, [disks]}.
%%------------------------------------------------------------------------------
random_juggling(Game, 0) ->
   Game;
random_juggling(Game, A) ->
   RandomNum = rand:uniform(6),
   case RandomNum of
      N when N == 1 -> random_juggling(move(Game, tower1, tower2, false), A-1);
      N when N == 2 -> random_juggling(move(Game, tower1, tower3, false), A-1);
      N when N == 3 -> random_juggling(move(Game, tower2, tower1, false), A-1);
      N when N == 4 -> random_juggling(move(Game, tower2, tower3, false), A-1);
      N when N == 5 -> random_juggling(move(Game, tower3, tower1, false), A-1);
      N when N == 6 -> random_juggling(move(Game, tower3, tower2, false), A-1)
   end.

%%------------------------------------------------------------------------------
%% Function:   display_towers/1
%% Purpose:    Displays the current game state.
%%------------------------------------------------------------------------------
display_towers(Game) ->
   lists:foreach(fun(A) -> 
                   io:format("~w: ~w~n", [element(1,A), element(2,A)]) 
                 end, Game),
   io:format("---------------~n").

%%------------------------------------------------------------------------------
%% Function:   move/4
%% Purpose:    Moves a disk from one tower to another.
%% Args:       Boolean is true once the move-from peg is determined to not be
%%             empty.
%% Returns:    An updated game state in the form of a list of {towers, [disks]}.
%%------------------------------------------------------------------------------
move(Game, A, B, false) ->
   Peg = is_empty(element(2, lists:keyfind(A, 1, Game))),
   if Peg == false -> move(Game, A, B, true)
   ;  Peg == true -> Game
   end;
move(Game, A, B, true) ->
   ValuetoMove = hd(get_top_disk(A, Game)),
   % removes the value to move from its peg
   Intermed = take_disk(A, Game),
   % checks that the requested move is legal, and if so, adds the moved disk to
   % the indicated peg and returns the new game state
   case get_top_disk(B, Intermed) of
      % checks that the top disk on the indicated peg is larger than the moving 
      % disk...
      N when hd(N) > ValuetoMove ->
         add_disk(B, Intermed, ValuetoMove);
      % ...or that the indicated peg is empty
      N when N =:= [] ->
         add_disk(B, Intermed, ValuetoMove);
      % else return the original game state
      N when N >= ValuetoMove ->
         Game
   end.
    
%%------------------------------------------------------------------------------
%% Functions:  get_top_disk/2, remove_top_disk/2, add_top_disk/3, take_disk/2,
%%             add_disk/3
%% Purpose:    Handful of game manipulation functions to make move/4 neater.
%%------------------------------------------------------------------------------ 
get_top_disk(A, Game) ->
   element(2, lists:keyfind(A, 1, Game)).
remove_top_disk(A, Game) ->
   setelement(2, lists:keyfind(A, 1, Game), tl(element(2,lists:keyfind(A, 1, Game)))).
add_top_disk(A, Game, Value) ->
   setelement(2, lists:keyfind(A, 1, Game), [Value|get_top_disk(A, Game)]).
take_disk(A, Game) ->
   lists:keyreplace(A, 1, Game, remove_top_disk(A, Game)).
add_disk(A, Game, Value) ->
   lists:keyreplace(A, 1, Game, add_top_disk(A, Game, Value)).
   
%%------------------------------------------------------------------------------
%% Function:   is_empty/1
%% Purpose:    Determines if a given peg is currently empty.
%%------------------------------------------------------------------------------
is_empty([]) -> true;
is_empty(_Peg) -> false.

%%------------------------------------------------------------------------------
%% Function:   solve/1
%% Purpose:    Calls solution/5 to solve the puzzle for n disks with an ordered
%%             starting configuration, or hard_solution/4 for n disks with
%%             an arbitrary starting configuration.
%% Returns:    The final game state.
%%------------------------------------------------------------------------------
solve(Game) ->
   N = lists:nth(4, Game),
   Ideal = create_towers(N, false),
   case Game =:= Ideal of
      Arbitrary when Arbitrary =:= true  ->
         % gets n from the largest disk on the leftmost peg and calls solution/5
         solution(N, tower1, tower2, tower3, Game -- [N]);
      Arbitrary when Arbitrary =:= false ->
         % otherwise tries to push the arbitrary start state to a known one
         io:format("Restoring to familiar state~n"
                   "---------------~n"),
         hard_solution(Game -- [N], create_towers(N, false) -- [N], Game -- [N], [])
   end.

%%------------------------------------------------------------------------------
%% Function:   solution/5
%% Purpose:    Recursively moves disks to sold the puzzle.
%% Returns:    The final game state.
%%------------------------------------------------------------------------------   
solution(1, T1, _T2, T3, Game) ->
   Game2 = move(Game, T1, T3, false),
   display_towers(Game2),
   Game2;
solution(A, T1, T2, T3, Game) ->
   Game2 = solution(A-1, T1, T3, T2, Game),
   Game3 = move(Game2, T1, T3, false),
   display_towers(Game3),
   solution(A-1, T2, T1, T3, Game3).

%%------------------------------------------------------------------------------
%% Function:   hard_solution/4
%% Purpose:    Recursively move disks to convert an arbitrary initial 
%%             configuration into a known state that can be solved.
%% Returns:    An ordered game state.
%%------------------------------------------------------------------------------
hard_solution(Game, Ideal, Original, IntermedStates) ->
   % randomly move a disk
   case random_juggling(Game, 1) of
      % if the new game state is the ordered state, display the moves taken
      % to achieve it and run solution/5 on the state
      New when New =:= Ideal ->
         lists:foreach(fun(A) -> 
                          display_towers(A) 
                       end, IntermedStates),
         display_towers(New),
         io:format("---------------~n"
                   "Familiar state achieved - solving~n"
                   "---------------~n"
                   "---------------~n"),
         N = lists:last(element(2, hd(New))),
         solution(N, tower1, tower2, tower3, New);
      % if the new game state is the same as started with, drop the list of
      % moves taken to achieve it and continue randomly moving
      New when New =:= Original ->
         hard_solution(New, Ideal, Original, []);
      % if the new game state is neither, randomly move another disk
      New when New =/= Ideal ->
         hard_solution(New, Ideal, Original, [New|IntermedStates])
   end.