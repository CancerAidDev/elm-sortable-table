module Elements exposing (main)

import Browser
import Html exposing (Html, div, h1, text)
import Html.Attributes exposing (class)
import Http
import Json.Decode as Decode
import Json.Decode.Pipeline as DecodePipeline
import Table exposing (defaultCustomizations)
import Table.Bulma as BulmaTable
import Table.Paginated as PaginatedTable
import Url.Builder as UrlBuilder


main : Program {} Model Msg
main =
    Browser.element
        { init = always init
        , update = update
        , view = view
        , subscriptions = always Sub.none
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
            , tableState = PaginatedTable.initialState "atomic_number" 10
            }
    in
    ( model, getElements model.tableState )



-- UPDATE


type Msg
    = SetTableState PaginatedTable.State
    | GotPage (Result Http.Error (Page Element))


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        SetTableState newState ->
            ( { model | tableState = newState }
            , getElements newState
            )

        GotPage result ->
            case result of
                Ok page ->
                    ( { model
                        | elements = page.data
                        , tableState = PaginatedTable.setTotal model.tableState page.total
                      }
                    , Cmd.none
                    )

                Err _ ->
                    ( model, Cmd.none )



-- VIEW


view : Model -> Html Msg
view { elements, tableState } =
    div [ class "p-4" ]
        [ h1 [ class "title" ] [ text "Paginated Table of Elements" ]
        , PaginatedTable.view config tableState elements
        ]



-- TABLE CONFIGURATION


config : PaginatedTable.Config Element Msg
config =
    let
        defaultCustomizations =
            BulmaTable.defaultCustomizationsPaginated
    in
    PaginatedTable.customConfig
        { toId = String.fromInt << .atomicNumber
        , toMsg = SetTableState
        , columns =
            [ PaginatedTable.intColumn "atomic_number" "Atomic Number" .atomicNumber
            , PaginatedTable.stringColumn "element" "Element" .element
            , PaginatedTable.stringColumn "symbol" "Symbol" .symbol
            , PaginatedTable.stringColumn "type" "Type" .tipe
            ]
        , customizations =
            { defaultCustomizations
                | tableAttrs = defaultCustomizations.tableAttrs ++ [ class "is-fullwidth is-hoverable" ]
                , pagination = BulmaTable.pagination [ class "is-centered" ]
            }
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
                , UrlBuilder.string "currentPage" (String.fromInt (PaginatedTable.getCurrentPage state))
                , UrlBuilder.string "perPage" (String.fromInt (PaginatedTable.getPageSize state))
                ]
        , expect = Http.expectJson GotPage decoderPage
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



-- PAGINATION RESULT


type alias Page data =
    { total : Int
    , data : List data
    }


decoderPage : Decode.Decoder (Page Element)
decoderPage =
    Decode.succeed Page
        |> DecodePipeline.required "total" Decode.int
        |> DecodePipeline.required "data" (Decode.list decoderElement)
