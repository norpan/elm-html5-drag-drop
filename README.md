# HTML 5 Drag and Drop API

First, a word of warning. This package uses a technique known as event handler content attributes, which is part of the HTML standard. However, this functionality may be removed from Elm, see https://github.com/elm-lang/html/issues/56.

So, use this package with this in mind.

This library handles dragging and dropping using the API
from the HTML 5 recommendation at
https://www.w3.org/TR/html/editing.html#drag-and-drop.

It provides attributes and a model/update to handle
dragging and dropping between your elements.

To use on mobile, you can include the following polyfill:
https://github.com/Bernardo-Castilho/dragdroptouch

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
https://ellie-app.com/rrrGb7Z6Ra1/1
