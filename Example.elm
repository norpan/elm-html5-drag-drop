module Example exposing (..)

import Html exposing (..)
import Html.Attributes exposing (..)
import Html5.DragDrop as DragDrop


type Position
    = Up
    | Middle
    | Down


type alias Model =
    { data : { count : Int, position : Position }
    , dragDrop : DragDrop.Model Int Position
    }


type Msg
    = DragDropMsg (DragDrop.Msg Int Position)


model =
    { data = { count = 0, position = Up }
    , dragDrop = DragDrop.init
    }


update msg model =
    case msg of
        DragDropMsg msg_ ->
            let
                ( model_, result ) =
                    DragDrop.update msg_ model.dragDrop
            in
                { model
                    | dragDrop = model_
                    , data =
                        case result of
                            Nothing ->
                                model.data

                            Just ( count, position ) ->
                                { count = count + 1, position = position }
                }
                    ! []


divStyle =
    style [ ( "border", "1px solid black" ), ( "padding", "50px" ), ( "text-align", "center" ) ]


view model =
    let
        dropId =
            DragDrop.getDropId model.dragDrop
    in
        div []
            [ viewDiv Up model.data dropId
            , viewDiv Middle model.data dropId
            , viewDiv Down model.data dropId
            ]


isNothing maybe =
    case maybe of
        Just _ ->
            False

        Nothing ->
            True


viewDiv position data dropId =
    let
        highlight =
            if dropId |> Maybe.map ((==) position) |> Maybe.withDefault False then
                [ style [ ( "background-color", "cyan" ) ] ]
            else
                []
    in
        div
            (divStyle
                :: highlight
                ++ if data.position /= position then
                    DragDrop.droppable DragDropMsg position
                   else
                    []
            )
            (if data.position == position then
                [ img (src "https://upload.wikimedia.org/wikipedia/commons/f/f3/Elm_logo.svg" :: width 100 :: DragDrop.draggable DragDropMsg data.count) []
                , text (toString data.count)
                ]
             else
                []
            )


main =
    program
        { init = ( model, Cmd.none )
        , update = update
        , view = view
        , subscriptions = always Sub.none
        }
