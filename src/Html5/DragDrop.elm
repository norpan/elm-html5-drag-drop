module Html5.DragDrop exposing (Model, init, Msg, update, updateSticky, draggable, droppable, getDragId, getDropId)

{-| This library handles dragging and dropping using the API
from the HTML 5 recommendation at
https://www.w3.org/TR/html/editing.html#drag-and-drop.

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

# Model and update
@docs Model, init, Msg, update, updateSticky

# View attributes
@docs draggable, droppable

# Status functions
@docs getDragId, getDropId
-}

import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import Json.Decode as Json


{-| The drag and drop state.

This should be placed inside your application's model like this:
```elm
type alias Model =
    { ...
    , dragDrop : Html5.DragDrop.Model DragId DropId
    }
```
-}
type Model dragId dropId
    = NotDragging
    | Dragging dragId
    | DraggedOver dragId dropId


{-| The initial drag and drop state.

You should use this as the initital value for the drag and drop state in your model.
-}
init : Model dragId dropId
init =
    NotDragging


{-| The drag and drop messages.

This should be placed inside your application's messages like this:
```elm
type Msg
    = ...
    | DragDropMsg (Html5.DragDrop.Msg DragId DropId)
```

-}
type Msg dragId dropId
    = DragStart dragId
    | DragEnd
    | DragEnter dropId
    | DragLeave dropId
    | Drop dropId


{-| The update function.

When a successful drag and drop is made, this function will return a result
consisting of the `dragId` and `dropId` that was specified in the
[`draggable`](#draggable) and [`droppable`](#droppable)
calls for the corresponding nodes.

This should be placed inside your application's update function, like this:
```elm
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
```
-}
update : Msg dragId dropId -> Model dragId dropId -> ( Model dragId dropId, Maybe ( dragId, dropId ) )
update =
    updateCommon False


{-| A "sticky" version of the `update` function.

It's used the same way as the `update` function, but when you use this version,
droppables are "sticky" so when you drag out of them and release the mouse button,
a drop will still be registered at the last droppable. You should preferably
provide some sort of indication (using `getDropId`) where the drop will take
place if you use this function.
-}
updateSticky : Msg dragId dropId -> Model dragId dropId -> ( Model dragId dropId, Maybe ( dragId, dropId ) )
updateSticky =
    updateCommon True


updateCommon sticky msg model =
    case ( msg, model, sticky ) of
        ( DragStart dragId, _, _ ) ->
            ( Dragging dragId, Nothing )

        ( DragEnd, DraggedOver dragId dropId, True ) ->
            ( NotDragging, Just ( dragId, dropId ) )

        ( DragEnd, _, _ ) ->
            ( NotDragging, Nothing )

        ( DragEnter dropId, Dragging dragId, _ ) ->
            ( DraggedOver dragId dropId, Nothing )

        ( DragEnter dropId, DraggedOver dragId _, _ ) ->
            ( DraggedOver dragId dropId, Nothing )

        -- Only handle DragLeave if it is for the current dropId.
        -- DragLeave and DragEnter sometimes come in the wrong order
        -- when two droppables are next to each other.
        ( DragLeave dropId_, DraggedOver dragId dropId, False ) ->
            if dropId_ == dropId then
                ( Dragging dragId, Nothing )
            else
                ( model, Nothing )

        ( Drop dropId, Dragging dragId, _ ) ->
            ( NotDragging, Just ( dragId, dropId ) )

        ( Drop dropId, DraggedOver dragId _, _ ) ->
            ( NotDragging, Just ( dragId, dropId ) )

        _ ->
            ( model, Nothing )


{-| Attributes to make a node draggable.

The node you put these attributes on will be draggable with the `dragId` you provide.
It should be used like this:
```elm
view =
   ...
   div (... ++ Html5.DragDrop.draggable DragDropMsg dragId) [...]
```
-}
draggable : (Msg dragId dropId -> msg) -> dragId -> List (Attribute msg)
draggable wrap drag =
    [ attribute "draggable" "true"
    , on "dragstart" <| Json.succeed <| wrap <| DragStart drag
    , on "dragend" <| Json.succeed <| wrap <| DragEnd
    , attribute "ondragstart" "event.dataTransfer.setData('text/plain', '');"
    ]


{-| Droppable attributes for your view function.

The node you put these attributes on will be droppable with the `dropId` you provide.
It should be used like this:
```elm
view =
   ...
   div (... ++ Html5.DragDrop.droppable DragDropMsg dropId) [...]
```
-}
droppable : (Msg dragId dropId -> msg) -> dropId -> List (Attribute msg)
droppable wrap dropId =
    [ on "dragenter" <| Json.succeed <| wrap <| DragEnter dropId
    , on "dragleave" <| Json.succeed <| wrap <| DragLeave dropId
    , onWithOptions "drop" { stopPropagation = True, preventDefault = True } <| Json.succeed <| wrap <| Drop dropId
    , attribute "ondragover" "event.stopPropagation(); event.preventDefault();"
    ]


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

        DraggedOver dragId dropId ->
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

        DraggedOver dragId dropId ->
            Just dropId
