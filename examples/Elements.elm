module Elements exposing (main)

import Browser
import Html exposing (Html, div, h1, text)
import Http
import Json.Decode as Decode
import Json.Decode.Pipeline as DecodePipeline
import Table.Paginated as PaginatedTable exposing (defaultCustomizations)
import Url.Builder as UrlBuilder


main : Program {} Model Msg
main =
    Browser.element
        { init = always init
        , update = update
        , view = view
        , subscriptions = \_ -> Sub.none
        }



-- MODEL


type alias Model =
    { elements : List Element
    , tableState : PaginatedTable.State
    }


init : ( Model, Cmd Msg )
init =
    let
        model =
            { elements = []
            , tableState = PaginatedTable.initialSort "atomic_number"
            }
    in
    ( model, getElements model.tableState )



-- UPDATE


type Msg
    = SetTableState PaginatedTable.State
    | GotElements (Result Http.Error (List Element))


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        SetTableState newState ->
            ( { model | tableState = newState }
            , getElements newState
            )

        GotElements result ->
            case result of
                Ok elements ->
                    ( { model | elements = elements }, Cmd.none )

                Err _ ->
                    ( model, Cmd.none )



-- VIEW


view : Model -> Html Msg
view { elements, tableState } =
    div []
        [ h1 [] [ text "Paginated Table of Elements" ]
        , PaginatedTable.view config tableState elements
        ]



-- TABLE CONFIGURATION


config : PaginatedTable.Config Element Msg
config =
    PaginatedTable.customConfig
        { toId = String.fromInt << .atomicNumber
        , toMsg = SetTableState
        , columns =
            [ PaginatedTable.intColumn "atomic_number" "Atomic Number" .atomicNumber
            , PaginatedTable.stringColumn "element" "Element" .element
            , PaginatedTable.stringColumn "symbol" "Symbol" .symbol
            , PaginatedTable.stringColumn "type" "Type" .tipe
            ]
        , customizations = defaultCustomizations
        }



-- API


getElements : PaginatedTable.State -> Cmd Msg
getElements state =
    Http.get
        { url =
            UrlBuilder.absolute [ "api", "elements" ]
                [ UrlBuilder.string "orderBy" (PaginatedTable.getSortColumn state)
                , UrlBuilder.string "orderDir"
                    (PaginatedTable.sortOrder config state
                        |> Maybe.map sortOrderToString
                        |> Maybe.withDefault "asc"
                    )
                ]
        , expect = Http.expectJson GotElements (Decode.list decoderElement)
        }


sortOrderToString : PaginatedTable.SortOrder -> String
sortOrderToString order =
    case order of
        PaginatedTable.Asc ->
            "asc"

        PaginatedTable.Desc ->
            "desc"



-- ELEMENTS


type alias Element =
    { atomicNumber : Int
    , element : String
    , symbol : String
    , tipe : String
    }


decoderElement : Decode.Decoder Element
decoderElement =
    Decode.succeed Element
        |> DecodePipeline.required "atomic_number" Decode.int
        |> DecodePipeline.required "element" Decode.string
        |> DecodePipeline.required "symbol" Decode.string
        |> DecodePipeline.required "type" Decode.string
