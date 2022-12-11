module ElmUrl exposing (parse, toString)

import Page exposing (CommentId(..), Page(..), Slug(..))
import Url exposing (Url)
import Url.Builder as Builder
import Url.Parser as Parser exposing ((</>), (<?>), Parser)
import Url.Parser.Query as Query


parse : Url -> Maybe Page
parse url =
    Parser.parse parser url


{-| Compare with `Page.fromAppUrl`!
-}
parser : Parser (Page -> a) a
parser =
    Parser.oneOf
        [ Parser.top
            |> Parser.map Home
        , Parser.s "about"
            |> Parser.map About
        , Parser.s "blog"
            <?> Query.string "category"
            <?> Query.int "year"
            |> Parser.map (\category year -> BlogHome { category = category, year = year })
        , Parser.s "blog"
            </> Parser.string
            |> Parser.map (\slug -> BlogPost (Slug slug))
        , Parser.s "blog"
            </> Parser.string
            </> Parser.s "edit"
            |> Parser.map (\slug -> BlogEdit (Slug slug))
        , Parser.s "blog"
            </> Parser.string
            </> Parser.s "comment"
            </> Parser.int
            |> Parser.map (\slug commentId -> BlogComment (Slug slug) (CommentId commentId))
        , Parser.s "blog"
            </> Parser.string
            </> Parser.s "comment"
            </> Parser.int
            </> Parser.s "edit"
            |> Parser.map (\slug commentId -> BlogEditComment (Slug slug) (CommentId commentId))
        ]


{-| Compare with `Page.toAppUrl`!
-}
toString : Page -> String
toString page =
    case page of
        Home ->
            Builder.absolute [] []

        About ->
            Builder.absolute [ "about" ] []

        BlogHome { category, year } ->
            Builder.absolute [ "blog" ]
                ([ Maybe.map (Builder.string "category") category
                 , Maybe.map (Builder.int "year") year
                 ]
                    |> List.filterMap identity
                )

        BlogPost (Slug slug) ->
            Builder.absolute [ "blog", slug ] []

        BlogEdit (Slug slug) ->
            Builder.absolute [ "blog", slug, "edit" ] []

        BlogComment (Slug slug) (CommentId commentId) ->
            Builder.absolute [ "blog", slug, "comment", String.fromInt commentId ] []

        BlogEditComment (Slug slug) (CommentId commentId) ->
            Builder.absolute [ "blog", slug, "comment", String.fromInt commentId, "edit" ] []
