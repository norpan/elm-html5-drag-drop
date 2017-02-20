# HTML 5 Drag and Drop API
This library handles dragging and dropping using the API
from the HTML 5 recommendation at
https://www.w3.org/TR/html/editing.html#drag-and-drop.

It provides attributes and a model/update to handle
dragging and dropping between your elements.

## Usage
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
https://ellie-app.com/rP5HtD5Mvya1/0
