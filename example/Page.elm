module Page exposing (CommentId(..), Page(..), Slug(..), fromAppUrl, toString)

import AppUrl exposing (AppUrl)
import Dict
import Maybe.Extra


type Page
    = Home
    | About
    | BlogHome Filters
    | BlogPost Slug
    | BlogPostEdit Slug
    | BlogComment Slug CommentId
    | BlogCommentEdit Slug CommentId


type alias Filters =
    { category : Maybe String
    , year : Maybe Int
    }


type Slug
    = Slug String


type CommentId
    = CommentId Int


{-| Compare with `ElmUrl.parse`!
-}
fromAppUrl : AppUrl -> Maybe Page
fromAppUrl url =
    case url.path of
        -- /
        [] ->
            Just Home

        -- /about
        [ "about" ] ->
            Just About

        -- /blog?category=elm&year=2023
        [ "blog" ] ->
            Just
                (BlogHome
                    { category = Dict.get "category" url.queryParameters |> Maybe.andThen List.head
                    , year = Dict.get "year" url.queryParameters |> Maybe.andThen List.head |> Maybe.andThen String.toInt
                    }
                )

        -- /blog/slug-of-title
        [ "blog", slug ] ->
            Just (BlogPost (Slug slug))

        -- /blog/slug-of-title/edit
        [ "blog", slug, "edit" ] ->
            Just (BlogPostEdit (Slug slug))

        -- /blog/slug-of-title/comment/1
        [ "blog", slug, "comment", commentId ] ->
            String.toInt commentId
                |> Maybe.map (BlogComment (Slug slug) << CommentId)

        -- /blog/slug-of-title/comment/1/edit
        [ "blog", slug, "comment", commentId, "edit" ] ->
            String.toInt commentId
                |> Maybe.map (BlogCommentEdit (Slug slug) << CommentId)

        _ ->
            Nothing


{-| Compare with `ElmUrl.toString`!
-}
toAppUrl : Page -> AppUrl
toAppUrl page =
    case page of
        Home ->
            AppUrl.fromPath []

        About ->
            AppUrl.fromPath [ "about" ]

        BlogHome { category, year } ->
            { path = [ "blog" ]
            , queryParameters =
                Dict.fromList
                    [ ( "category", Maybe.Extra.toList category )
                    , ( "year", Maybe.Extra.toList (Maybe.map String.fromInt year) )
                    ]
            , fragment = Nothing
            }

        BlogPost (Slug slug) ->
            AppUrl.fromPath [ "blog", slug ]

        BlogPostEdit (Slug slug) ->
            AppUrl.fromPath [ "blog", slug, "edit" ]

        BlogComment (Slug slug) (CommentId commentId) ->
            AppUrl.fromPath [ "blog", slug, "comment", String.fromInt commentId ]

        BlogCommentEdit (Slug slug) (CommentId commentId) ->
            AppUrl.fromPath [ "blog", slug, "comment", String.fromInt commentId, "edit" ]


toString : Page -> String
toString =
    toAppUrl >> AppUrl.toString
