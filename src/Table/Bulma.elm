module Table.Bulma exposing
    ( defaultCustomizations, defaultCustomizationsPaginated
    , pagination
    )

{-| [Bulma](https://bulma.io) specific customizations for `Table` and `Table.Paginated`.

We recommend checking out the [examples] to get a feel for how it works.

[examples]: https://github.com/canceraiddev/elm-sortable-table/tree/main/examples


# Customization


## Custom Tables

@docs defaultCustomizations, defaultCustomizationsPaginated


## Pagination

@docs pagination

-}

import Accessibility.Aria as Aria
import Html exposing (Attribute, Html)
import Html.Attributes as Attr
import Html.Events as E
import Table
import Table.Paginated as Paginated


{-| Default `Table` customizations for Bulma.
-}
defaultCustomizations : Table.Customizations data msg
defaultCustomizations =
    let
        defaultCustomizations_ =
            Table.defaultCustomizations
    in
    { defaultCustomizations_ | tableAttrs = [ Attr.class "table" ] }


{-| Default `Table.Paginated` customizations for Bulma.
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


{-| Pagination view component using Bulma structure and classes. See Bulma
[docs](https://bulma.io/documentation/components/pagination/).

For customization pass in attributes as required. E.g.

    { defaultCustomizations | pagination = pagination [ class "is-centered" ] }

-}
pagination : List (Attribute msg) -> (Paginated.State -> msg) -> Paginated.State -> Html msg
pagination attributes toMsg state =
    let
        currentPage =
            Paginated.getCurrentPage state

        pageCount =
            Paginated.getPageCount state

        pageButton page =
            let
                currentPageAttrs =
                    if currentPage == page then
                        [ Attr.class "is-current"
                        , Aria.currentPage
                        , Aria.label ("Page " ++ String.fromInt page)
                        ]

                    else
                        [ Aria.label ("Go to page " ++ String.fromInt page) ]
            in
            Html.li []
                [ Html.a
                    (currentPageAttrs
                        ++ [ Attr.class "pagination-link"
                           , E.onClick (toMsg (Paginated.setCurrentPage state page))
                           ]
                    )
                    [ Html.text (String.fromInt page) ]
                ]

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

        buttons =
            if pageCount <= 5 then
                List.range 1 pageCount
                    |> List.map (\page -> pageButton page)

            else
                [ start, middle, end ] |> List.concat
    in
    Html.nav
        ([ Attr.class "pagination"
         , Attr.attribute "role" "navigation"
         , Aria.label "pagination"
         ]
            ++ attributes
        )
        [ Html.a
            [ Attr.class "pagination-previous"
            , E.onClick (toMsg (Paginated.previousPage state))
            ]
            [ Html.text "Previous" ]
        , Html.a
            [ Attr.class "pagination-next"
            , Attr.disabled (currentPage >= pageCount)
            , E.onClick (toMsg (Paginated.nextPage state))
            ]
            [ Html.text "Next" ]
        , Html.ul
            [ Attr.class "pagination-list" ]
            buttons
        ]


ellipsisButton : Html msg
ellipsisButton =
    Html.li []
        [ Html.span
            [ Attr.style "class" "pagination-ellipsis"
            ]
            [ Html.text "…" ]
        ]
