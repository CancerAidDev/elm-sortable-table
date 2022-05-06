module Travel exposing (Model, Msg(..), Sight, checkboxColumn, config, init, main, missionSights, timeColumn, timeToString, toRowAttrs, toggle, update, view, viewCheckbox, viewSummary)

import Browser
import Duration
import Html exposing (Attribute, Html, div, h1, input, p, text)
import Html.Attributes exposing (checked, style, type_)
import Html.Events exposing (onClick)
import Html.Lazy exposing (lazy)
import Table exposing (defaultCustomizations)


main : Program {} Model Msg
main =
    Browser.element
        { init = always (init missionSights)
        , update = update
        , view = view
        , subscriptions = \_ -> Sub.none
        }



-- MODEL


type alias Model =
    { sights : List Sight
    , tableState : Table.State
    }


init : List Sight -> ( Model, Cmd Msg )
init sights =
    let
        model =
            { sights = sights
            , tableState = Table.initialSort "Year"
            }
    in
    ( model, Cmd.none )



-- UPDATE


type Msg
    = ToggleSelected String
    | SetTableState Table.State


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        ToggleSelected name ->
            ( { model | sights = List.map (toggle name) model.sights }
            , Cmd.none
            )

        SetTableState newState ->
            ( { model | tableState = newState }
            , Cmd.none
            )


toggle : String -> Sight -> Sight
toggle name sight =
    if sight.name == name then
        { sight | selected = not sight.selected }

    else
        sight



-- VIEW


view : Model -> Html Msg
view { sights, tableState } =
    div []
        [ h1 [] [ text "Trip Planner" ]
        , lazy viewSummary sights
        , Table.view config tableState sights
        ]


viewSummary : List Sight -> Html msg
viewSummary allSights =
    case List.filter .selected allSights of
        [] ->
            p [] [ text "Click the sights you want to see on your trip!" ]

        sights ->
            let
                time =
                    List.sum (List.map (.time >> Duration.inMilliseconds) sights)

                price =
                    List.sum (List.map .price sights)

                summary =
                    "That is " ++ timeToString (Duration.milliseconds time) ++ " of fun, costing $" ++ String.fromFloat price
            in
            p [] [ text summary ]


timeToString : Duration.Duration -> String
timeToString time =
    let
        hours =
            case floor (Duration.inHours time) of
                0 ->
                    ""

                1 ->
                    "1 hour"

                n ->
                    String.fromInt n ++ " hours"

        minutes =
            case remainderBy 60 (round (Duration.inMinutes time)) of
                0 ->
                    ""

                1 ->
                    "1 minute"

                n ->
                    String.fromInt n ++ " minutes"
    in
    hours ++ " " ++ minutes



-- TABLE CONFIGURATION


config : Table.Config Sight Msg
config =
    Table.customConfig
        { toId = .name
        , toMsg = SetTableState
        , columns =
            [ checkboxColumn
            , Table.stringColumn "Name" .name
            , timeColumn
            , Table.floatColumn "Price" .price
            , Table.floatColumn "Rating" .rating
            ]
        , customizations =
            { defaultCustomizations | rowAttrs = toRowAttrs }
        }


toRowAttrs : Sight -> List (Attribute Msg)
toRowAttrs sight =
    [ onClick (ToggleSelected sight.name)
    , style "background"
        (if sight.selected then
            "#CEFAF8"

         else
            "white"
        )
    ]


timeColumn : Table.Column Sight Msg
timeColumn =
    Table.customColumn
        { name = "Time"
        , viewData = timeToString << .time
        , sorter = Table.increasingOrDecreasingBy (.time >> Duration.inMilliseconds)
        }


checkboxColumn : Table.Column Sight Msg
checkboxColumn =
    Table.veryCustomColumn
        { name = ""
        , viewData = viewCheckbox
        , sorter = Table.unsortable
        }


viewCheckbox : Sight -> Table.HtmlDetails Msg
viewCheckbox { selected } =
    Table.HtmlDetails []
        [ input [ type_ "checkbox", checked selected ] []
        ]



-- SIGHTS


type alias Sight =
    { name : String
    , time : Duration.Duration
    , price : Float
    , rating : Float
    , selected : Bool
    }


missionSights : List Sight
missionSights =
    [ Sight "Eat a Burrito" (Duration.minutes 30) 7 4.6 False
    , Sight "Buy drugs in Dolores park" Duration.hour 20 4.8 False
    , Sight "Armory Tour" (Duration.hours 1.5) 27 4.5 False
    , Sight "Tartine Bakery" Duration.hour 10 4.1 False
    , Sight "Have Brunch" (Duration.hours 2) 25 4.2 False
    , Sight "Get catcalled at BART" (Duration.minutes 5) 0 1.6 False
    , Sight "Buy a painting at \"Stuff\"" (Duration.minutes 45) 400 4.7 False
    , Sight "McDonalds at 24th" (Duration.minutes 20) 5 2.8 False
    ]
