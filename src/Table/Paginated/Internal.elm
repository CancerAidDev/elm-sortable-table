module Table.Paginated.Internal exposing (State(..))


type State
    = State
        { currentPage : Int
        , pageSize : Int
        , total : Int
        , sortColumn : String
        , isReversed : Bool
        }
