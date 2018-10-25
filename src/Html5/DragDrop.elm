module Html5.DragDrop exposing (Model, Msg, Position, draggable, droppable, getDragId, getDropId, getDroppablePosition, init, update, updateSticky)

{-| This library handles dragging and dropping using the API
from the HTML 5 recommendation at
<https://www.w3.org/TR/html/editing.html#drag-and-drop>.

It provides attributes and a model/update to handle
dragging and dropping between your elements.

Types are parametrized with a `dragId` and a `dropId` parameter, which are the
types for the drag identifier passed to the [`draggable`](#draggable) function
and the drop identifier passed to the [`droppable`](#droppable) function.
You can put whatever data you like in these, but don't use function types.

You can use several instances of this model at the same time and they won't
interfere with each other. Drag and drop are connected to an instance by the
Msg constructor used, and the update function will not send a result if a drop
was made from another instance.

To use on mobile, you can include the following polyfill:
<https://github.com/Bernardo-Castilho/dragdroptouch>


# Model and update

@docs Model, init, Msg, Position, update, updateSticky


# View attributes

@docs draggable, droppable


# Status functions

@docs getDragId, getDropId, getDroppablePosition

-}

import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import Json.Decode as Json


{-| The drag and drop state.

This should be placed inside your application's model like this:

    type alias Model =
        { ...
        , dragDrop : Html5.DragDrop.Model DragId DropId
        }

-}
type Model dragId dropId
    = NotDragging
    | Dragging dragId
    | DraggedOver dragId dropId (Maybe Position)


{-| The position inside a droppable. Contains the droppable's
width and height, as well as the current x and y position,
using the `target.clientWidth`, `target.clientHeight`, `offsetX`, and `offsetY`
from the `ondragover` event.

Note, that in some cases, x and y may be negative, or larger than the clientWidth and height,
if a drop event is registered outside the CSS padding edge.

-}
type alias Position =
    { width : Int
    , height : Int
    , x : Int
    , y : Int
    }


{-| The initial drag and drop state.

You should use this as the initital value for the drag and drop state in your model.

-}
init : Model dragId dropId
init =
    NotDragging


{-| The drag and drop messages.

This should be placed inside your application's messages like this:

    type Msg
        = ...
        | DragDropMsg (Html5.DragDrop.Msg DragId DropId)

-}
type Msg dragId dropId
    = DragStart dragId
    | DragEnd
    | DragEnter dropId
    | DragLeave dropId
    | DragOver dropId Position
    | Drop dropId Position


{-| The update function.

When a successful drag and drop is made, this function will return a result
consisting of the `dragId` and `dropId` that was specified in the
[`draggable`](#draggable) and [`droppable`](#droppable)
calls for the corresponding nodes. It will also return a [`Position`](#Position)
for the drop event.

This should be placed inside your application's update function, like this:

    update msg model =
        case msg of
            ...
            DragDropMsg msg_ ->
                let
                    ( model_, result ) =
                        Html5.DragDrop.update msg_ model.dragDrop
                in
                    { model
                        | dragDrop = model_
                        , ...use result if available...
                    }

-}
update : Msg dragId dropId -> Model dragId dropId -> ( Model dragId dropId, Maybe ( dragId, dropId, Position ) )
update =
    updateCommon False


{-| A "sticky" version of the [`update`](#update) function.

It's used the same way as the [`update`](#update) function, but when you use this version,
droppables are "sticky" so when you drag out of them and release the mouse button,
a drop will still be registered at the last droppable. You should preferably
provide some sort of indication (using [`getDropId`](#getDropId)) where the drop will take
place if you use this function.

-}
updateSticky : Msg dragId dropId -> Model dragId dropId -> ( Model dragId dropId, Maybe ( dragId, dropId, Position ) )
updateSticky =
    updateCommon True


updateCommon :
    Bool
    -> Msg dragId dropId
    -> Model dragId dropId
    -> ( Model dragId dropId, Maybe ( dragId, dropId, Position ) )
updateCommon sticky msg model =
    case ( msg, model, sticky ) of
        ( DragStart dragId, _, _ ) ->
            ( Dragging dragId, Nothing )

        ( DragEnd, _, _ ) ->
            ( NotDragging, Nothing )

        ( DragEnter dropId, Dragging dragId, _ ) ->
            ( DraggedOver dragId dropId Nothing, Nothing )

        ( DragEnter dropId, DraggedOver dragId _ pos, _ ) ->
            ( DraggedOver dragId dropId pos, Nothing )

        -- Only handle DragLeave if it is for the current dropId.
        -- DragLeave and DragEnter sometimes come in the wrong order
        -- when two droppables are next to each other.
        ( DragLeave dropId_, DraggedOver dragId dropId _, False ) ->
            if dropId_ == dropId then
                ( Dragging dragId, Nothing )
            else
                ( model, Nothing )

        ( DragOver dropId pos, Dragging dragId, _ ) ->
            ( DraggedOver dragId dropId (Just pos), Nothing )

        ( DragOver dropId pos, DraggedOver dragId currentDropId currentPos, _ ) ->
            if Just pos == currentPos && dropId == currentDropId then
                -- Don't change model if coordinates have not changed
                ( model, Nothing )
            else
                -- Update coordinates
                ( DraggedOver dragId dropId (Just pos), Nothing )

        ( Drop dropId pos, Dragging dragId, _ ) ->
            ( NotDragging, Just ( dragId, dropId, pos ) )

        ( Drop dropId pos, DraggedOver dragId _ _, _ ) ->
            ( NotDragging, Just ( dragId, dropId, pos ) )

        _ ->
            ( model, Nothing )


{-| Attributes to make a node draggable.

The node you put these attributes on will be draggable with the `dragId` you provide.
It should be used like this:

    view =
       ...
       div (... ++ Html5.DragDrop.draggable DragDropMsg dragId) [...]

-}
draggable : (Msg dragId dropId -> msg) -> dragId -> List (Attribute msg)
draggable wrap drag =
    [ attribute "draggable" "true"
    , on "dragstart" <| Json.succeed <| wrap <| DragStart drag
    , on "dragend" <| Json.succeed <| wrap <| DragEnd
    ]


{-| Attributes to make a node droppable.

The node you put these attributes on will be droppable with the `dropId` you provide.
It should be used like this:

    view =
       ...
       div (... ++ Html5.DragDrop.droppable DragDropMsg dropId) [...]

-}
droppable : (Msg dragId dropId -> msg) -> dropId -> List (Attribute msg)
droppable wrap dropId =
    [ on "dragenter" <| Json.succeed <| wrap <| DragEnter dropId
    , on "dragleave" <| Json.succeed <| wrap <| DragLeave dropId
    , onWithOptions "dragover" { stopPropagation = False, preventDefault = True } <| Json.map (wrap << DragOver dropId) positionDecoder
    , onWithOptions "drop" { stopPropagation = False, preventDefault = True } <| Json.map (wrap << Drop dropId) positionDecoder
    ]


positionDecoder : Json.Decoder Position
positionDecoder =
    Json.map4 Position
        (Json.at [ "target", "clientWidth" ] Json.int)
        (Json.at [ "target", "clientHeight" ] Json.int)
        (Json.at [ "offsetX" ] Json.int)
        (Json.at [ "offsetY" ] Json.int)


{-| Get the current `dragId` if available.

This function can be used for instance to hide the draggable when dragging.

-}
getDragId : Model dragId dropId -> Maybe dragId
getDragId model =
    case model of
        NotDragging ->
            Nothing

        Dragging dragId ->
            Just dragId

        DraggedOver dragId dropId _ ->
            Just dragId


{-| Get the current `dropId` if available.

This function can be used for instance to highlight the droppable when dragging over it.

-}
getDropId : Model dragId dropId -> Maybe dropId
getDropId model =
    case model of
        NotDragging ->
            Nothing

        Dragging dragId ->
            Nothing

        DraggedOver dragId dropId _ ->
            Just dropId


{-| Get the current `Position` when dragging over the droppable.
-}
getDroppablePosition : Model dragId dropId -> Maybe Position
getDroppablePosition model =
    case model of
        DraggedOver _ _ pos ->
            pos

        _ ->
            Nothing


{-| polyfill for onWithOptions
-}
onWithOptions :
    String
    ->
        { stopPropagation : Bool
        , preventDefault : Bool
        }
    -> Json.Decoder msg
    -> Attribute msg
onWithOptions name { stopPropagation, preventDefault } decoder =
    decoder
        |> Json.map (\msg -> { message = msg, stopPropagation = stopPropagation, preventDefault = preventDefault })
        |> custom name
