port module Update exposing (update)

import Tetriminos exposing (blank)
import Model exposing (..)
import Messages exposing (..)
import Time exposing (Time)
import Grid


port save : String -> Cmd msg


saveToStorage : Model -> ( Model, Cmd Msg )
saveToStorage model =
    ( model, save (Model.encode 2 model) )


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        Resize size ->
            ( { model | size = size }, Cmd.none )

        Start ->
            ( { model
                | state = Playing
                , lines = 0
                , score = 0
                , grid = Grid.empty
              }
            , Cmd.none
            )

        Pause ->
            saveToStorage { model | state = Paused }

        Resume ->
            ( { model | state = Playing }
            , Cmd.none
            )

        MoveLeft on ->
            ( startMove { model | moveLeft = on }
            , Cmd.none
            )

        MoveRight on ->
            ( startMove { model | moveRight = on }
            , Cmd.none
            )

        Rotate False ->
            ( { model | rotation = Nothing }
            , Cmd.none
            )

        Rotate True ->
            ( { model | rotation = Just { active = True, elapsed = 0 } }
            , Cmd.none
            )

        Accelerate on ->
            ( { model | acceleration = on }
            , Cmd.none
            )

        UnlockButtons ->
            ( { model | rotation = Nothing, direction = Nothing, acceleration = False }
            , Cmd.none
            )

        Tick time ->
            model
                |> animate (min time 25)
                |> saveToStorage

        StoreTetrimino ->
            if model.stored == blank then
                ( { model | stored = model.active }
                    |> Model.spawnTetrimino
                , Cmd.none
                )
            else
                ( { model
                    | stored = model.active
                    , active = model.stored
                  }
                , Cmd.none
                )

        Noop ->
            ( model, Cmd.none )


animate : Time -> Model -> Model
animate elapsed model =
    model
        |> moveTetrimino elapsed
        |> rotateTetrimino elapsed
        |> dropTetrimino elapsed
        |> checkEndGame


direction : Model -> Int
direction { moveLeft, moveRight } =
    case ( moveLeft, moveRight ) of
        ( True, False ) ->
            -1

        ( False, True ) ->
            1

        _ ->
            0


startMove : Model -> Model
startMove model =
    if direction model /= 0 then
        { model | direction = Just { active = True, elapsed = 0 } }
    else
        { model | direction = Nothing }


moveTetrimino : Time -> Model -> Model
moveTetrimino elapsed model =
    case model.direction of
        Just state ->
            { model | direction = Just (activateButton 150 elapsed state) }
                |> (if state.active then
                        moveTetrimino_ (direction model)
                    else
                        identity
                   )

        Nothing ->
            model


moveTetrimino_ : Int -> Model -> Model
moveTetrimino_ dx model =
    let
        ( x, y ) =
            model.position

        x_ =
            x + dx
    in
        if Grid.collide model.width model.height x_ (floor y) model.active model.grid then
            model
        else
            { model | position = ( x_, y ) }


activateButton : Time -> Time -> { a | active : Bool, elapsed : Time } -> { a | active : Bool, elapsed : Time }
activateButton interval elapsed state =
    let
        elapsed_ =
            state.elapsed + elapsed
    in
        if elapsed_ > interval then
            { state | active = True, elapsed = elapsed_ - interval }
        else
            { state | active = False, elapsed = elapsed_ }


rotateTetrimino : Time -> Model -> Model
rotateTetrimino elapsed model =
    case model.rotation of
        Just rotation ->
            { model | rotation = Just (activateButton 300 elapsed rotation) }
                |> (if rotation.active then
                        rotateTetrimino_
                    else
                        identity
                   )

        Nothing ->
            model


rotateTetrimino_ : Model -> Model
rotateTetrimino_ model =
    let
        ( x, y ) =
            model.position

        rotated =
            Grid.rotate True model.active

        shiftPosition deltas =
            case deltas of
                dx :: remainingDeltas ->
                    if Grid.collide model.width model.height (x + dx) (floor y) rotated model.grid then
                        shiftPosition remainingDeltas
                    else
                        { model
                            | active = rotated
                            , position = ( x + dx, y )
                        }

                [] ->
                    model
    in
        shiftPosition [ 0, 1, -1, 2, -2 ]


checkEndGame : Model -> Model
checkEndGame model =
    if List.any identity (Grid.mapToList (\_ ( _, y ) -> y < 0) model.grid) then
        { model | state = Stopped }
    else
        model


dropTetrimino : Time -> Model -> Model
dropTetrimino elapsed model =
    let
        ( x, y ) =
            model.position

        speed =
            if model.acceleration then
                25
            else
                max 25 (800 - 25 * toFloat (level model - 1))

        y_ =
            y + elapsed / speed
    in
        if Grid.collide model.width model.height x (floor y_) model.active model.grid then
            let
                score =
                    List.length (Grid.mapToList (\_ _ _ -> True) model.active)
            in
                { model
                    | grid = Grid.stamp x (floor y) model.active model.grid
                    , score =
                        model.score
                            + score
                            * (if model.acceleration then
                                2
                               else
                                1
                              )
                }
                    |> Model.spawnTetrimino
                    |> clearLines
        else
            { model | position = ( x, y_ ) }


clearLines : Model -> Model
clearLines model =
    let
        ( grid, lines ) =
            Grid.clearLines model.width model.grid

        bonus =
            case lines of
                0 ->
                    0

                1 ->
                    100

                2 ->
                    300

                3 ->
                    500

                _ ->
                    800
    in
        { model
            | grid = grid
            , score = model.score + bonus * level model
            , lines = model.lines + lines
        }


level : Model -> Int
level model =
    model.lines // 10 + 1
