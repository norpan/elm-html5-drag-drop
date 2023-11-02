port module Example exposing (Model, Msg(..), Position(..), divStyle, init, main, update, view, viewDiv)

import Browser
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Attributes.Extra
import Html5.DragDrop as DragDrop
import Json.Decode exposing (Value)


port dragstart : Value -> Cmd msg


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


init : () -> ( Model, Cmd Msg )
init () =
    ( { data = { count = 0, position = Up }
      , dragDrop = DragDrop.init
      }
    , Cmd.none
    )


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        DragDropMsg msg_ ->
            let
                ( model_, result ) =
                    DragDrop.update msg_ model.dragDrop
            in
            ( { model
                | dragDrop = model_
                , data =
                    case result of
                        Nothing ->
                            model.data

                        Just ( count, position, _ ) ->
                            { count = count + 1, position = position }
              }
            , DragDrop.getDragstartEvent msg_
                |> Maybe.map (.event >> dragstart)
                |> Maybe.withDefault Cmd.none
            )


subscriptions _ =
    Sub.none


divStyle =
    [ style "border" "1px solid black"
    , style "padding" "50px"
    , style "text-align" "center"
    ]


view : Model -> Html Msg
view model =
    let
        widthAttributes =
            [ style "min-width" "30vw", style "max-width" "90vw", style "display" "flex", style "flex-direction" "column" ]

        attributes =
            -- While we are dragging we can set the cursor on the parent div.
            if DragDrop.isDraggedOver model.dragDrop then
                style "cursor" "move" :: widthAttributes

            else if DragDrop.isDragging model.dragDrop then
                style "cursor" "grabbing" :: widthAttributes

            else
                widthAttributes
    in
    div [ style "display" "flex", style "justify-content" "center" ]
        [ div attributes
            [ viewDiv Up model.data model.dragDrop
            , viewDiv Middle model.data model.dragDrop
            , viewDiv Down model.data model.dragDrop
            ]
        ]


viewDiv : Position -> { count : Int, position : Position } -> DragDrop.Model Int Position -> Html Msg
viewDiv position data dragDrop =
    let
        maybeDropId : Maybe Position
        maybeDropId =
            DragDrop.getDropId dragDrop

        highlight : List (Html.Attribute Msg)
        highlight =
            if maybeDropId |> Maybe.map ((==) position) |> Maybe.withDefault False then
                case maybeDroppablePosition of
                    Nothing ->
                        []

                    Just pos ->
                        if pos.y < pos.height // 2 then
                            [ style "background-color" "cyan" ]

                        else
                            [ style "background-color" "magenta" ]

            else
                []

        maybeDroppablePosition : Maybe DragDrop.Position
        maybeDroppablePosition =
            DragDrop.getDroppablePosition dragDrop

        cursorStyle =
            -- While we are dragging the cursor is set on the parent div.
            if DragDrop.isDraggedOver dragDrop then
                Html.Attributes.Extra.empty

            else if DragDrop.isDragging dragDrop then
                Html.Attributes.Extra.empty

            else
                style "cursor" "grab"
    in
    div
        (divStyle
            ++ highlight
            ++ (if data.position /= position then
                    DragDrop.droppable DragDropMsg position

                else
                    []
               )
        )
        (if data.position == position then
            [ img
                (src "https://upload.wikimedia.org/wikipedia/commons/f/f3/Elm_logo.svg"
                    :: width 100
                    :: cursorStyle
                    :: DragDrop.draggable DragDropMsg data.count
                )
                []
            , text (String.fromInt data.count)
            ]

         else
            []
        )


main =
    Browser.element
        { init = init
        , update = update
        , subscriptions = subscriptions
        , view = view
        }
