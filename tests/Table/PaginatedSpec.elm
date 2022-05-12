module Table.PaginatedSpec exposing (..)

import Expect
import Table.Paginated as Paginated
import Test exposing (..)


suite : Test
suite =
    let
        renderSettings =
            { windowSize = 3, minPages = 5 }
    in
    describe "renderPageButton"
        [ describe "one page"
            (let
                state =
                    Paginated.initialState "id" 5
                        |> Paginated.setTotal 4

                pages =
                    [ ( 1, True ) ]
             in
             pages
                |> List.map
                    (\( page, expected ) ->
                        test ("page " ++ String.fromInt page) <|
                            \_ -> Paginated.renderPageButton renderSettings state page |> Expect.equal expected
                    )
            )
        , describe "two pages"
            (let
                state =
                    Paginated.initialState "id" 5
                        |> Paginated.setTotal 10

                pages =
                    [ ( 1, True )
                    , ( 2, True )
                    ]
             in
             pages
                |> List.map
                    (\( page, expected ) ->
                        test ("page " ++ String.fromInt page) <|
                            \_ -> Paginated.renderPageButton renderSettings state page |> Expect.equal expected
                    )
            )
        , describe "ten pages at beginning"
            (let
                state =
                    Paginated.initialState "id" 5
                        |> Paginated.setTotal 50

                pages =
                    [ ( 1, True )
                    , ( 2, True )
                    , ( 3, True )
                    , ( 4, True )
                    , ( 5, True )
                    , ( 6, False )
                    , ( 7, False )
                    , ( 8, False )
                    , ( 9, False )
                    , ( 10, True )
                    ]
             in
             pages
                |> List.map
                    (\( page, expected ) ->
                        test ("page " ++ String.fromInt page) <|
                            \_ -> Paginated.renderPageButton renderSettings state page |> Expect.equal expected
                    )
            )
        , describe "ten pages at middle"
            (let
                state =
                    Paginated.initialState "id" 5
                        |> Paginated.setTotal 50
                        |> Paginated.setCurrentPage 5

                pages =
                    [ ( 1, True )
                    , ( 2, False )
                    , ( 3, False )
                    , ( 4, True )
                    , ( 5, True )
                    , ( 6, True )
                    , ( 7, False )
                    , ( 8, False )
                    , ( 9, False )
                    , ( 10, True )
                    ]
             in
             pages
                |> List.map
                    (\( page, expected ) ->
                        test ("page " ++ String.fromInt page) <|
                            \_ -> Paginated.renderPageButton renderSettings state page |> Expect.equal expected
                    )
            )
        , describe "ten pages at end"
            (let
                state =
                    Paginated.initialState "id" 5
                        |> Paginated.setTotal 50
                        |> Paginated.setCurrentPage 10

                pages =
                    [ ( 1, True )
                    , ( 2, False )
                    , ( 3, False )
                    , ( 4, False )
                    , ( 5, False )
                    , ( 6, True )
                    , ( 7, True )
                    , ( 8, True )
                    , ( 9, True )
                    , ( 10, True )
                    ]
             in
             pages
                |> List.map
                    (\( page, expected ) ->
                        test ("page " ++ String.fromInt page) <|
                            \_ -> Paginated.renderPageButton renderSettings state page |> Expect.equal expected
                    )
            )
        ]
