module ElmUrl exposing (fromUrl, toString)

import Page exposing (CommentId(..), Page(..), Slug(..))
import Url exposing (Url)
import Url.Builder as Builder
import Url.Parser as Parser exposing ((</>), (<?>), Parser)
import Url.Parser.Query as Query


fromUrl : Url -> Maybe Page
fromUrl url =
    Parser.parse parser url


{-| Compare with `Page.fromAppUrl`!
-}
parser : Parser (Page -> a) a
parser =
    Parser.oneOf
        [ -- /
          Parser.top
            |> Parser.map Home

        -- /about
        , Parser.s "about"
            |> Parser.map About

        -- /blog?category=elm&year=2023
        , Parser.s "blog"
            <?> Query.string "category"
            <?> Query.int "year"
            |> Parser.map (\category year -> BlogHome { category = category, year = year })

        -- /blog/slug-of-title
        , Parser.s "blog"
            </> Parser.string
            |> Parser.map (\slug -> BlogPost (Slug slug))

        -- /blog/slug-of-title/edit
        , Parser.s "blog"
            </> Parser.string
            </> Parser.s "edit"
            |> Parser.map (\slug -> BlogPostEdit (Slug slug))

        -- /blog/slug-of-title/comment/1
        , Parser.s "blog"
            </> Parser.string
            </> Parser.s "comment"
            </> Parser.int
            |> Parser.map (\slug commentId -> BlogComment (Slug slug) (CommentId commentId))

        -- /blog/slug-of-title/comment/1/edit
        , Parser.s "blog"
            </> Parser.string
            </> Parser.s "comment"
            </> Parser.int
            </> Parser.s "edit"
            |> Parser.map (\slug commentId -> BlogCommentEdit (Slug slug) (CommentId commentId))
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

        BlogPostEdit (Slug slug) ->
            Builder.absolute [ "blog", slug, "edit" ] []

        BlogComment (Slug slug) (CommentId commentId) ->
            Builder.absolute [ "blog", slug, "comment", String.fromInt commentId ] []

        BlogCommentEdit (Slug slug) (CommentId commentId) ->
            Builder.absolute [ "blog", slug, "comment", String.fromInt commentId, "edit" ] []
