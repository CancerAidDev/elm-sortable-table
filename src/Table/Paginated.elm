module Table.Paginated exposing
    ( view
    , config, stringColumn, intColumn, floatColumn, dateColumn, posixColumn
    , State, initialState, getSortColumn, getCurrentPage, setCurrentPage, getPageSize, setPageSize, setTotal
    , SortOrder(..), sortOrder
    , Column, customColumn, veryCustomColumn, DateColumnConfig, PosixColumnConfig
    , Sorter, unsortable, increasingBy, decreasingBy
    , increasingOrDecreasingBy, decreasingOrIncreasingBy
    , Config, customConfig, Customizations, HtmlDetails, htmlDetails, Status(..)
    , defaultCustomizations
    )

{-| Variant of Table for paginated remote data that is sorted before being given
to the view. The Sorter type is only used for visually representing the sort
state of the table data that is sorted elsewhere (e.g. sorted paginated data
from a server).

This library helps you create sortable tables. The crucial feature is that it
lets you own your data separately and keep it in whatever format is best for
you. This way you are free to change your data without worrying about the table
&ldquo;getting out of sync&rdquo; with the data. Having a single source of
truth is pretty great!

We recommend checking out the [examples] to get a feel for how it works.

[examples]: https://github.com/canceraiddev/elm-sortable-table/tree/main/examples


# View

@docs view


# Configuration

@docs config, stringColumn, intColumn, floatColumn, dateColumn, posixColumn


# State

@docs State, initialState, getSortColumn, getCurrentPage, setCurrentPage, getPageSize, setPageSize, setTotal


# Sort Order

@docs SortOrder, sortOrder


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

import Date
import Dict
import Html exposing (Attribute, Html)
import Html.Attributes as Attr
import Html.Events as E
import Html.Keyed as Keyed
import Table.Paginated.Internal as Internal
import Time
import Time.Format



-- STATE


{-| Tracks pagination state of table.
-}
type alias State =
    Internal.State


{-| Create a table state. By providing a column name, you determine which
column should be used for sorting by default. So if you want your table of
yachts to be sorted by length by default, you might say:

    import Table

    Table.initialState "Length"

-}
initialState : String -> Int -> State
initialState sortColumn pageSize =
    Internal.State
        { currentPage = 1
        , pageSize = pageSize
        , total = 0
        , sortColumn = sortColumn
        , isReversed = False
        }


{-| Get the column currently sorted by.
-}
getSortColumn : State -> String
getSortColumn (Internal.State { sortColumn }) =
    sortColumn


{-| Get the current page number.
-}
getCurrentPage : State -> Int
getCurrentPage (Internal.State { currentPage }) =
    currentPage


{-| Set the current page number.

Useful for setting the page number base on URL query parameters.

-}
setCurrentPage : State -> Int -> State
setCurrentPage (Internal.State state) currentPage =
    Internal.State { state | currentPage = currentPage }


{-| Get the page size (i.e. the max number of items shown in the table
at one time).
-}
getPageSize : State -> Int
getPageSize (Internal.State { pageSize }) =
    pageSize


{-| Set the page size.
-}
setPageSize : State -> Int -> State
setPageSize (Internal.State state) pageSize =
    Internal.State { state | pageSize = pageSize }


{-| Set the total number of items that can be viewed in the table.

You will probably find this out when you do the first request for data and this
value maybe change on subsequent requests.

E.g. if there are 20 rows of data and the page size is 5, the total parameter is
20 (while the number of pages will be 4)

-}
setTotal : State -> Int -> State
setTotal (Internal.State state) total =
    Internal.State { state | total = total }



-- SORT ORDER


{-| Sort Order data type
-}
type SortOrder
    = Asc
    | Desc


{-| Get the sort order for the table. Used to request sorting of remote data.
-}
sortOrder : Config data msg -> State -> Maybe SortOrder
sortOrder (Config { columns }) (Internal.State { sortColumn, isReversed }) =
    columns
        |> List.map (\{ id, sorter } -> ( id, sorter ))
        |> Dict.fromList
        |> Dict.get sortColumn
        |> Maybe.andThen (sortOrderForSorter isReversed)


sortOrderForSorter : Bool -> Sorter -> Maybe SortOrder
sortOrderForSorter isReversed sorter =
    case sorter of
        None ->
            Nothing

        Increasing ->
            Just Asc

        Decreasing ->
            Just Desc

        IncOrDec ->
            if isReversed then
                Just Desc

            else
                Just Asc

        DecOrInc ->
            if isReversed then
                Just Asc

            else
                Just Desc



-- CONFIG


{-| Configuration for your table, describing your columns.

**Note:** Your `Config` should _never_ be held in your model.
It should only appear in `view` code.

-}
type Config data msg
    = Config
        { toId : data -> String
        , toMsg : State -> msg
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
[examples]: https://github.com/canceraiddev/elm-sortable-table/tree/main/examples

-}
config :
    { toId : data -> String
    , toMsg : State -> msg
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
    , toMsg : State -> msg
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
    , pagination : (State -> msg) -> State -> Html msg
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

Pagination controls are not included as there is not a standard way to layout
these components. See Table.Bulma for an configuration of pagination controls
using the bulma UI framework.

-}
defaultCustomizations : Customizations data msg
defaultCustomizations =
    { tableAttrs = []
    , caption = Nothing
    , thead = simpleThead
    , tfoot = Nothing
    , tbodyAttrs = []
    , rowAttrs = simpleRowAttrs
    , pagination = \_ _ -> Html.text ""
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
    Html.th
        [ onClickAction
        , Attr.style "cursor" "pointer"
        ]
        content


nbsp : String
nbsp =
    "\u{00A0}"


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
    , timeZone : Time.Zone
    , formatString : String
    }


{-| -}
posixColumn : String -> PosixColumnConfig data -> Column data msg
posixColumn id { name, toPosix, default, timeZone, formatString } =
    let
        toFormattedDate data =
            case toPosix data of
                Just posix ->
                    posix
                        |> Time.posixToMillis
                        |> Time.Format.format timeZone formatString

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
view : Config data msg -> State -> List data -> Html msg
view ((Config { toMsg, customizations }) as config_) state data =
    Html.div []
        [ viewTable config_ state data
        , customizations.pagination toMsg state
        ]


viewTable : Config data msg -> State -> List data -> Html msg
viewTable (Config { toId, toMsg, columns, customizations }) state data =
    let
        -- Data should be sorted by caller
        sortedData =
            data

        theadDetails =
            customizations.thead (List.map (toHeaderInfo state toMsg) columns)

        thead =
            Html.thead theadDetails.attributes theadDetails.children

        tbody =
            Keyed.node "tbody" customizations.tbodyAttrs <|
                List.map (viewRow toId columns customizations.rowAttrs) sortedData

        withFoot =
            case customizations.tfoot of
                Nothing ->
                    [ tbody ]

                Just { attributes, children } ->
                    [ Html.tfoot attributes children, tbody ]
    in
    Html.table customizations.tableAttrs <|
        case customizations.caption of
            Nothing ->
                thead :: withFoot

            Just { attributes, children } ->
                Html.caption attributes children :: thead :: withFoot


toHeaderInfo : State -> (Internal.State -> msg) -> ColumnData data msg -> ( String, Status, Attribute msg )
toHeaderInfo ((Internal.State { sortColumn, isReversed }) as state) toMsg { id, name, sorter } =
    case sorter of
        None ->
            ( name, Unsortable, onClick state sortColumn isReversed toMsg )

        Increasing ->
            ( name, Sortable (id == sortColumn), onClick state id False toMsg )

        Decreasing ->
            ( name, Sortable (id == sortColumn), onClick state id False toMsg )

        IncOrDec ->
            if id == sortColumn then
                ( name, Reversible (Just isReversed), onClick state id (not isReversed) toMsg )

            else
                ( name, Reversible Nothing, onClick state id False toMsg )

        DecOrInc ->
            if id == sortColumn then
                ( name, Reversible (Just isReversed), onClick state id (not isReversed) toMsg )

            else
                ( name, Reversible Nothing, onClick state id False toMsg )


onClick : State -> String -> Bool -> (Internal.State -> msg) -> Attribute msg
onClick (Internal.State state) sortColumn isReversed toMsg =
    E.onClick <| toMsg (Internal.State { state | sortColumn = sortColumn, isReversed = isReversed, currentPage = 1 })


viewRow : (data -> String) -> List (ColumnData data msg) -> (data -> List (Attribute msg)) -> data -> ( String, Html msg )
viewRow toId columns toRowAttrs data =
    ( toId data
    , viewRowHelp columns toRowAttrs data
    )


viewRowHelp : List (ColumnData data msg) -> (data -> List (Attribute msg)) -> data -> Html msg
viewRowHelp columns toRowAttrs data =
    let
        rowAttrs =
            data |> toRowAttrs
    in
    Html.tr rowAttrs (List.map (viewCell data) columns)


viewCell : data -> ColumnData data msg -> Html msg
viewCell data { viewData } =
    let
        details =
            viewData data
    in
    Html.td details.attributes details.children



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
