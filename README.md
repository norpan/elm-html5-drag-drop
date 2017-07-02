# HTML 5 Drag and Drop API for Style Elements
This library handles dragging and dropping using the API
from the HTML 5 recommendation at
https://www.w3.org/TR/html/editing.html#drag-and-drop.

It provides attributes and a model/update to handle
dragging and dropping between your elements.

This is a straight port of https://github.com/norpan/elm-html5-drag-drop to
support the [Style Elements](http://package.elm-lang.org/packages/mdgriffith/style-elements/latest)

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
   el (... ++ Html5.DragDrop.draggableElement DragDropMsg dragId) (...)
   ...
   row (... ++ Html5.DragDrop.droppableElement DragDropMsg dropId) [...]
```

