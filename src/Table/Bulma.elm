module Table.Bulma exposing (defaultCustomizations, defaultCustomizationsPaginated, pagination)

import Html exposing (Attribute, Html)
import Html.Attributes as Attr
import Html.Events as E
import Table
import Table.Paginated as Paginated
import Table.Paginated.Internal as PaginatedInternal


defaultCustomizations : Table.Customizations data msg
defaultCustomizations =
    let
        defaultCustomizations_ =
            Table.defaultCustomizations
    in
    { defaultCustomizations_ | tableAttrs = [ Attr.class "table" ] }


{-| The customizations used in `config` by default.
-}
defaultCustomizationsPaginated : Paginated.Customizations data msg
defaultCustomizationsPaginated =
    let
        defaultCustomizations_ =
            Paginated.defaultCustomizations
    in
    { defaultCustomizations_
        | tableAttrs = [ Attr.class "table" ]
        , pagination = pagination []
    }


pagination : List (Attribute msg) -> (PaginatedInternal.State -> msg) -> PaginatedInternal.State -> Html msg
pagination attributes toMsg (PaginatedInternal.State ({ currentPage, total, pageSize } as state)) =
    let
        pageCount =
            ceiling (toFloat total / toFloat pageSize)

        pageButton page =
            Html.li []
                [ Html.a
                    [ Attr.class "pagination-link"
                    , Attr.classList [ ( "is-current", currentPage == page ) ]
                    , E.onClick (toMsg (PaginatedInternal.State { state | currentPage = page }))
                    ]
                    [ Html.text (String.fromInt page) ]
                ]

        ellipsisButton =
            Html.li []
                [ Html.span
                    [ Attr.style "class" "pagination-ellipsis"
                    ]
                    [ Html.text "…" ]
                ]
    in
    Html.nav (Attr.class "pagination" :: attributes)
        [ Html.a
            [ Attr.class "pagination-previous"
            , E.onClick
                (toMsg
                    (if currentPage > 1 then
                        PaginatedInternal.State { state | currentPage = currentPage - 1 }

                     else
                        PaginatedInternal.State state
                    )
                )
            ]
            [ Html.text "Previous" ]
        , Html.a
            [ Attr.class "pagination-next"
            , Attr.disabled (currentPage >= pageCount)
            , E.onClick
                (toMsg
                    (if currentPage < pageCount then
                        PaginatedInternal.State { state | currentPage = currentPage + 1 }

                     else
                        PaginatedInternal.State state
                    )
                )
            ]
            [ Html.text "Next" ]
        , Html.ul
            [ Attr.class "pagination-list"
            ]
            (let
                start =
                    if currentPage > 3 then
                        [ pageButton 1
                        , ellipsisButton
                        ]

                    else
                        List.range 1 (currentPage + 1)
                            |> List.map (\page -> pageButton page)

                middle =
                    if currentPage > 3 && currentPage < pageCount - 2 then
                        [ pageButton (currentPage - 1)
                        , pageButton currentPage
                        , pageButton (currentPage + 1)
                        ]

                    else
                        []

                end =
                    if currentPage < pageCount - 2 then
                        [ ellipsisButton
                        , pageButton pageCount
                        ]

                    else
                        List.range (currentPage - 2) pageCount
                            |> List.map (\page -> pageButton page)
             in
             [ start, middle, end ] |> List.concat
            )
        ]