# HTML 5 Drag and Drop API

This library handles dragging and dropping using the API
from the HTML 5 recommendation at
https://www.w3.org/TR/html/editing.html#drag-and-drop.

It provides view attributes to make elements draggable and
droppable and a model/update to keep track of what is being
dragged and the drop target and position within it.

See the [`Html5.DragDrop`](Html5-DragDrop) module for more details.

## Basic usage
```elm
type alias Model =
    { ...
    , dragDrop : Html5.DragDrop.Model DragId DropId
    }


type Msg
    = ...
    | DragDropMsg (Html5.DragDrop.Msg DragId DropId)


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


view =
   ...
   div (... ++ Html5.DragDrop.draggable DragDropMsg dragId) [...]
   ...
   div (... ++ Html5.DragDrop.droppable DragDropMsg dropId) [...]
```

## Example
https://github.com/norpan/elm-html5-drag-drop/blob/master/example/Example.elm
