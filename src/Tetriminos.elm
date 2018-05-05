module Tetriminos exposing (..)

import Grid exposing (Grid)
import Random
import Color exposing (Color)


type alias Tetrimino =
    Grid Color


line : Tetrimino
line =
    Grid.create (Color.rgb 60 199 214) [ ( 0, 0 ), ( 1, 0 ), ( 2, 0 ), ( 3, 0 ) ]


square : Tetrimino
square =
    Grid.create (Color.rgb 251 180 20) [ ( 0, 0 ), ( 1, 0 ), ( 0, 1 ), ( 1, 1 ) ]


triangle : Tetrimino
triangle =
    Grid.create (Color.rgb 176 68 151) [ ( 1, 0 ), ( 0, 1 ), ( 1, 1 ), ( 2, 1 ) ]


rDog : Tetrimino
rDog =
    Grid.create (Color.rgb 57 147 208) [ ( 0, 0 ), ( 0, 1 ), ( 1, 1 ), ( 2, 1 ) ]


lDog : Tetrimino
lDog =
    Grid.create (Color.rgb 237 101 47) [ ( 2, 0 ), ( 0, 1 ), ( 1, 1 ), ( 2, 1 ) ]


rPeriscope : Tetrimino
rPeriscope =
    Grid.create (Color.rgb 149 196 61) [ ( 1, 0 ), ( 2, 0 ), ( 0, 1 ), ( 1, 1 ) ]


lPeriscope : Tetrimino
lPeriscope =
    Grid.create (Color.rgb 232 65 56) [ ( 0, 0 ), ( 1, 0 ), ( 1, 1 ), ( 2, 1 ) ]


blank : Tetrimino
blank =
    Grid.empty


tetriminos : List Tetrimino
tetriminos =
    [ line
    , square
    , triangle
    , rDog
    , lDog
    , rPeriscope
    , lPeriscope
    ]


random : Random.Seed -> ( Tetrimino, Random.Seed )
random seed =
    let
        number =
            Random.int 0 (List.length tetriminos - 1)

        toGrid n =
            Maybe.withDefault blank (List.head (List.drop n tetriminos))
    in
        Random.step (Random.map toGrid number) seed
