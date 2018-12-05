module Table.Remote exposing
    ( view
    , config, stringColumn, intColumn, floatColumn, dateColumn, posixColumn
    , State, initialSort, remoteOrder
    , Column, customColumn, veryCustomColumn, DateColumnConfig, PosixColumnConfig
    , Sorter, unsortable, increasingBy, decreasingBy
    , increasingOrDecreasingBy, decreasingOrIncreasingBy
    , Config, customConfig, Customizations, HtmlDetails, htmlDetails, Status(..)
    , defaultCustomizations
    , getId
    )

{-| This library helps you create sortable tables. The crucial feature is that it
lets you own your data separately and keep it in whatever format is best for
you. This way you are free to change your data without worrying about the table
&ldquo;getting out of sync&rdquo; with the data. Having a single source of
truth is pretty great!

Useful for remote data that is sorted before being given to the view. The Sorter type is purely for visually representing the sort state of the table data that is sorted elsewhere (e.g. sorted paginated data from a server).

I recommend checking out the [examples] to get a feel for how it works.

[examples]: https://github.com/evancz/elm-sortable-table/tree/master/examples


# View

@docs view


# Configuration

@docs config, stringColumn, intColumn, floatColumn, dateColumn, posixColumn


# State

@docs State, initialSort, id, remoteOrder


# Crazy Customization

If you are new to this library, you can probably stop reading here. After this
point are a bunch of ways to customize your table further. If it does not
provide what you need, you may just want to write a custom table yourself. It
is not that crazy.


## Custom Columns

@docs Column, customColumn, veryCustomColumn, DateColumnConfig, PosixColumnConfig
@docs Sorter, unsortable, increasingBy, decreasingBy
@docs increasingOrDecreasingBy, decreasingOrIncreasingBy


## Custom Tables

@docs Config, customConfig, Customizations, HtmlDetails, htmlDetails, Status
@docs defaultCustomizations

-}

import Bootstrap.Table as Table
import Date
import Html exposing (Attribute, Html)
import Html.Attributes as Attr
import Html.Events as E
import Json.Decode as Json
import Time
import Time.Format



-- STATE


{-| Tracks which column to sort by.
-}
type State data msg
    = State (Column data msg) Bool


{-| -}
getId : State data msg -> String
getId (State (Column columnData) _) =
    columnData.id


{-| -}
remoteOrder : State data msg -> String
remoteOrder (State (Column columnData) isReversed) =
    case columnData.sorter of
        None ->
            "asc"

        Increasing ->
            "asc"

        Decreasing ->
            "desc"

        IncOrDec ->
            if isReversed then
                "desc"

            else
                "asc"

        DecOrInc ->
            if isReversed then
                "asc"

            else
                "desc"


{-| Create a table state. By providing a column name, you determine which
column should be used for sorting by default. So if you want your table of
yachts to be sorted by length by default, you might say:

    import Table

    Table.initialSort "Length"

-}
initialSort : Column data msg -> State data msg
initialSort column =
    State column False



-- CONFIG


{-| Configuration for your table, describing your columns.

**Note:** Your `Config` should _never_ be held in your model.
It should only appear in `view` code.

-}
type Config data msg
    = Config
        { toId : data -> String
        , toMsg : State data msg -> msg
        , columns : List (ColumnData data msg)
        , customizations : Customizations data msg
        }


{-| Create the `Config` for your `view` function. Everything you need to
render your columns efficiently and handle selection of columns.

Say we have a `List Person` that we want to show as a table. The table should
have a column for name and age. We would create a `Config` like this:

    import Table

    type Msg = NewTableState State | ...

    config : Table.Config Person Msg
    config =
      Table.config
        { toId = .name
        , toMsg = NewTableState
        , columns =
            [ Table.stringColumn "Name" .name
            , Table.intColumn "Age" .age
            ]
        }

You provide the following information in your table configuration:

  - `toId` &mdash; turn a `Person` into a unique ID. This lets us use
    [`Html.Keyed`][keyed] under the hood to make resorts faster.
  - `columns` &mdash; specify some columns to show.
  - `toMsg` &mdash; a way to send new table states to your app as messages.

See the [examples] to get a better feel for this!

[keyed]: http://package.elm-lang.org/packages/elm-lang/html/latest/Html-Keyed
[examples]: https://github.com/evancz/elm-sortable-table/tree/master/examples

-}
config :
    { toId : data -> String
    , toMsg : State data msg -> msg
    , columns : List (Column data msg)
    }
    -> Config data msg
config { toId, toMsg, columns } =
    Config
        { toId = toId
        , toMsg = toMsg
        , columns = List.map (\(Column cData) -> cData) columns
        , customizations = defaultCustomizations
        }


{-| Just like `config` but you can specify a bunch of table customizations.
-}
customConfig :
    { toId : data -> String
    , toMsg : State data msg -> msg
    , columns : List (Column data msg)
    , customizations : Customizations data msg
    }
    -> Config data msg
customConfig { toId, toMsg, columns, customizations } =
    Config
        { toId = toId
        , toMsg = toMsg
        , columns = List.map (\(Column cData) -> cData) columns
        , customizations = customizations
        }


{-| There are quite a lot of ways to customize the `<table>` tag. You can add
a `<caption>` which can be styled via CSS. You can do crazy stuff with
`<thead>` to group columns in weird ways. You can have a `<tfoot>` tag for
summaries of various columns. And maybe you want to put attributes on `<tbody>`
or on particular rows in the body. All these customizations are available to you.

**Note:** The level of craziness possible in `<thead>` and `<tfoot>` are so
high that I could not see how to provide the full functionality _and_ make it
impossible to do bad stuff. So just be aware of that, and share any stories
you have. Stories make it possible to design better!

-}
type alias Customizations data msg =
    { tableAttrs : List (Attribute msg)
    , caption : Maybe (HtmlDetails msg)
    , thead : List ( String, Status, Attribute msg ) -> HtmlDetails msg
    , tfoot : Maybe (HtmlDetails msg)
    , tbodyAttrs : List (Attribute msg)
    , rowAttrs : data -> List (Attribute msg)
    , tableOptions : List (Table.TableOption msg)
    }


{-| Sometimes you must use a `<td>` tag, but the attributes and children are up
to you. This type lets you specify all the details of an HTML node except the
tag name.
-}
type alias HtmlDetails msg =
    { attributes : List (Attribute msg)
    , children : List (Html msg)
    }


{-| The customizations used in `config` by default.
-}
defaultCustomizations : Customizations data msg
defaultCustomizations =
    { tableAttrs = []
    , caption = Nothing
    , thead = simpleThead
    , tfoot = Nothing
    , tbodyAttrs = []
    , rowAttrs = simpleRowAttrs
    , tableOptions = []
    }


simpleThead : List ( String, Status, Attribute msg ) -> HtmlDetails msg
simpleThead headers =
    HtmlDetails [] (List.map simpleTheadHelp headers)


simpleTheadHelp : ( String, Status, Attribute msg ) -> Html msg
simpleTheadHelp ( name, status, onClickAction ) =
    let
        content =
            case status of
                Unsortable ->
                    [ Html.text name ]

                Sortable selected ->
                    [ Html.text name
                    , if selected then
                        darkGrey "↓"

                      else
                        lightGrey "↓"
                    ]

                Reversible Nothing ->
                    [ Html.text name
                    , lightGrey "↕"
                    ]

                Reversible (Just isReversed) ->
                    [ Html.text name
                    , darkGrey
                        (if isReversed then
                            "↑"

                         else
                            "↓"
                        )
                    ]
    in
    Html.div
        [ onClickAction
        , Attr.style "cursor" "pointer"
        ]
        content


nbsp : String
nbsp =
    " "


icon : String -> String -> Html msg
icon color symbol =
    Html.span [ Attr.style "color" color ] [ Html.text (nbsp ++ symbol) ]


darkGrey : String -> Html msg
darkGrey symbol =
    icon "#555" symbol


lightGrey : String -> Html msg
lightGrey symbol =
    icon "#ccc" symbol


simpleRowAttrs : data -> List (Attribute msg)
simpleRowAttrs _ =
    []


{-| The status of a particular column, for use in the `thead` field of your
`Customizations`.

  - If the column is unsortable, the status will always be `Unsortable`.
  - If the column can be sorted in one direction, the status will be `Sortable`.
    The associated boolean represents whether this column is selected. So it is
    `True` if the table is currently sorted by this column, and `False` otherwise.
  - If the column can be sorted in either direction, the status will be `Reversible`.
    The associated maybe tells you whether this column is selected. It is
    `Just isReversed` if the table is currently sorted by this column, and
    `Nothing` otherwise. The `isReversed` boolean lets you know which way it
    is sorted.

This information lets you do custom header decorations for each scenario.

-}
type Status
    = Unsortable
    | Sortable Bool
    | Reversible (Maybe Bool)



-- COLUMNS


{-| Describes how to turn `data` into a column in your table.
-}
type Column data msg
    = Column (ColumnData data msg)


type alias ColumnData data msg =
    { id : String
    , name : String
    , viewData : data -> HtmlDetails msg
    , sorter : Sorter
    }


{-| -}
stringColumn : String -> String -> (data -> String) -> Column data msg
stringColumn id name toStr =
    Column
        { id = id
        , name = name
        , viewData = textDetails << toStr
        , sorter = increasingOrDecreasingBy
        }


{-| -}
intColumn : String -> String -> (data -> Int) -> Column data msg
intColumn id name toInt =
    Column
        { id = id
        , name = name
        , viewData = textDetails << String.fromInt << toInt
        , sorter = increasingOrDecreasingBy
        }


{-| -}
floatColumn : String -> String -> (data -> Float) -> Column data msg
floatColumn id name toFloat =
    Column
        { id = id
        , name = name
        , viewData = textDetails << String.fromFloat << toFloat
        , sorter = increasingOrDecreasingBy
        }


{-| -}
type alias DateColumnConfig data =
    { name : String
    , toIsoDate : data -> String
    , default : String
    , formatString : String
    }


{-| -}
dateColumn : String -> DateColumnConfig data -> Column data msg
dateColumn id { name, toIsoDate, default, formatString } =
    let
        toFormattedDate data =
            case Date.fromIsoString <| toIsoDate data of
                Err _ ->
                    default

                Ok date ->
                    Date.format formatString date
    in
    Column
        { id = id
        , name = name
        , viewData = textDetails << toFormattedDate
        , sorter = increasingOrDecreasingBy
        }


{-| -}
type alias PosixColumnConfig data =
    { name : String
    , toPosix : data -> Maybe Time.Posix
    , default : String
    , formatString : String
    }


{-| -}
posixColumn : String -> PosixColumnConfig data -> Column data msg
posixColumn id { name, toPosix, default, formatString } =
    let
        toFormattedDate data =
            case toPosix data of
                Just posix ->
                    posix
                        |> Time.posixToMillis
                        |> Time.Format.format Time.utc formatString

                Nothing ->
                    default
    in
    Column
        { id = id
        , name = name
        , viewData = textDetails << toFormattedDate
        , sorter = increasingOrDecreasingBy
        }


textDetails : String -> HtmlDetails msg
textDetails str =
    HtmlDetails [] [ Html.text str ]


{-| -}
htmlDetails : Html msg -> HtmlDetails msg
htmlDetails html =
    HtmlDetails [] [ html ]


{-| Perhaps the basic columns are not quite what you want. Maybe you want to
display monetary values in thousands of dollars, and `floatColumn` does not
quite cut it. You could define a custom column like this:

    import Table

    dollarColumn : String -> (data -> Float) -> Column data msg
    dollarColumn name toDollars =
        Table.customColumn
            { name = name
            , viewData = \data -> viewDollars (toDollars data)
            , sorter = Table.decreasingBy toDollars
            }

    viewDollars : Float -> String
    viewDollars dollars =
        "$" ++ String.fromInt (round (dollars / 1000)) ++ "k"

The `viewData` field means we will displays the number `12345.67` as `$12k`.

The `sorter` field specifies how the column can be sorted. In `dollarColumn` we
are saying that it can _only_ be shown from highest-to-lowest monetary value.
More about sorters soon!

-}
customColumn :
    { id : String
    , name : String
    , viewData : data -> String
    , sorter : Sorter
    }
    -> Column data msg
customColumn { id, name, viewData, sorter } =
    Column <|
        ColumnData id name (textDetails << viewData) sorter


{-| It is _possible_ that you want something crazier than `customColumn`. In
that unlikely scenario, this function lets you have full control over the
attributes and children of each `<td>` cell in this column.

So maybe you want to a dollars column, and the dollar signs should be green.

    import Html exposing (Attribute, Html, span, text)
    import Html.Attributes exposing (style)
    import Table

    dollarColumn : String -> (data -> Float) -> Column data msg
    dollarColumn name toDollars =
        Table.veryCustomColumn
            { name = name
            , viewData = \data -> viewDollars (toDollars data)
            , sorter = Table.decreasingBy toDollars
            }

    viewDollars : Float -> Table.HtmlDetails msg
    viewDollars dollars =
        Table.HtmlDetails []
            [ span [ style "color" "green" ] [ text "$" ]
            , text (String.fromInt (round (dollars / 1000)) ++ "k")
            ]

-}
veryCustomColumn :
    { id : String
    , name : String
    , viewData : data -> HtmlDetails msg
    , sorter : Sorter
    }
    -> Column data msg
veryCustomColumn { id, name, viewData, sorter } =
    Column <|
        ColumnData id name viewData sorter



-- VIEW


{-| Take a list of data and turn it into a table. The `Config` argument is the
configuration for the table. It describes the columns that we want to show. The
`State` argument describes which column we are sorting by at the moment.

**Note:** The `State` and `List data` should live in your `Model`. The `Config`
for the table belongs in your `view` code. I very strongly recommend against
putting `Config` in your model. Describe any potential table configurations
statically, and look for a different library if you need something crazier than
that.

-}
view : Config data msg -> State data msg -> List data -> Html msg
view (Config { toId, toMsg, columns, customizations }) state data =
    let
        -- Data should be sorted by caller
        sortedData =
            data

        theadDetails =
            customizations.thead (List.map (toHeaderInfo state toMsg) columns)

        theadCells =
            List.map (\cell -> Table.th [] [ cell ]) theadDetails.children

        theadAttrs =
            List.map Table.headAttr theadDetails.attributes
    in
    Table.table
        { options = customizations.tableOptions
        , thead = Table.thead theadAttrs [ Table.tr [] theadCells ]
        , tbody =
            Table.keyedTBody customizations.tbodyAttrs
                (List.map (viewRow toId columns customizations.rowAttrs) sortedData)
        }


toHeaderInfo : State data msg -> (State data msg -> msg) -> ColumnData data msg -> ( String, Status, Attribute msg )
toHeaderInfo (State (Column stateColumnData) isReversed) toMsg columnData =
    case columnData.sorter of
        None ->
            ( columnData.name, Unsortable, onClick stateColumnData isReversed toMsg )

        Increasing ->
            ( columnData.name, Sortable (columnData.id == stateColumnData.id), onClick columnData False toMsg )

        Decreasing ->
            ( columnData.name, Sortable (columnData.id == stateColumnData.id), onClick columnData False toMsg )

        IncOrDec ->
            if columnData.id == stateColumnData.id then
                ( columnData.name, Reversible (Just isReversed), onClick columnData (not isReversed) toMsg )

            else
                ( columnData.name, Reversible Nothing, onClick columnData False toMsg )

        DecOrInc ->
            if columnData.id == stateColumnData.id then
                ( columnData.name, Reversible (Just isReversed), onClick columnData (not isReversed) toMsg )

            else
                ( columnData.name, Reversible Nothing, onClick columnData False toMsg )


onClick : ColumnData data msg -> Bool -> (State data msg -> msg) -> Attribute msg
onClick columnData isReversed toMsg =
    E.on "click" <|
        Json.map toMsg <|
            Json.map2 State (Json.succeed <| Column columnData) (Json.succeed isReversed)


viewRow : (data -> String) -> List (ColumnData data msg) -> (data -> List (Attribute msg)) -> data -> ( String, Table.Row msg )
viewRow toId columns toRowAttrs data =
    ( toId data
    , viewRowHelp columns toRowAttrs data
    )


viewRowHelp : List (ColumnData data msg) -> (data -> List (Attribute msg)) -> data -> Table.Row msg
viewRowHelp columns toRowAttrs data =
    let
        rowAttrs =
            data |> toRowAttrs |> List.map Table.rowAttr
    in
    Table.tr rowAttrs (List.map (viewCell data) columns)


viewCell : data -> ColumnData data msg -> Table.Cell msg
viewCell data { viewData } =
    let
        details =
            viewData data

        cellAttributes =
            List.map Table.cellAttr details.attributes
    in
    Table.td cellAttributes details.children



-- SORTERS


{-| Specifies a particular way of sorting data.
-}
type Sorter
    = None
    | Increasing
    | Decreasing
    | IncOrDec
    | DecOrInc


{-| A sorter for columns that are unsortable. Maybe you have a column in your
table for delete buttons that delete the row. It would not make any sense to
sort based on that column.
-}
unsortable : Sorter
unsortable =
    None


{-| Create a sorter that can only display the data in increasing order. If we
want a table of people, sorted alphabetically by name, we would say this:
-}
increasingBy : Sorter
increasingBy =
    Increasing


{-| Create a sorter that can only display the data in decreasing order. If we
want a table of countries, sorted by population from highest to lowest, we
would say this:
-}
decreasingBy : Sorter
decreasingBy =
    Decreasing


{-| Sometimes you want to be able to sort data in increasing _or_ decreasing
order. Maybe you have a bunch of data about orange juice, and you want to know
both which has the most sugar, and which has the least sugar. Both interesting!
This function lets you see both, starting with decreasing order.
-}
decreasingOrIncreasingBy : Sorter
decreasingOrIncreasingBy =
    DecOrInc


{-| Sometimes you want to be able to sort data in increasing _or_ decreasing
order. Maybe you have race times for the 100 meter sprint. This function lets
sort by best time by default, but also see the other order.
-}
increasingOrDecreasingBy : Sorter
increasingOrDecreasingBy =
    IncOrDec
