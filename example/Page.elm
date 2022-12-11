module Page exposing (CommentId(..), Page(..), Slug(..), fromAppUrl, toString)

import AppUrl exposing (AppUrl)
import Dict
import Maybe.Extra


type Page
    = Home
    | About
    | BlogHome Filters
    | BlogPost Slug
    | BlogEdit Slug
    | BlogComment Slug CommentId
    | BlogEditComment Slug CommentId


type Slug
    = Slug String


type CommentId
    = CommentId Int


type alias Filters =
    { category : Maybe String
    , year : Maybe Int
    }


{-| Compare with `ElmUrl.parse`!
-}
fromAppUrl : AppUrl -> Maybe Page
fromAppUrl url =
    case url.path of
        [] ->
            Just Home

        [ "about" ] ->
            Just About

        [ "blog" ] ->
            Just
                (BlogHome
                    { category = Dict.get "category" url.queryParameters |> Maybe.andThen List.head
                    , year = Dict.get "year" url.queryParameters |> Maybe.andThen List.head |> Maybe.andThen String.toInt
                    }
                )

        [ "blog", slug ] ->
            Just (BlogPost (Slug slug))

        [ "blog", slug, "edit" ] ->
            Just (BlogEdit (Slug slug))

        [ "blog", slug, "comment", commentId ] ->
            String.toInt commentId
                |> Maybe.map (BlogComment (Slug slug) << CommentId)

        [ "blog", slug, "comment", commentId, "edit" ] ->
            String.toInt commentId
                |> Maybe.map (BlogEditComment (Slug slug) << CommentId)

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

        BlogEdit (Slug slug) ->
            AppUrl.fromPath [ "blog", slug, "edit" ]

        BlogComment (Slug slug) (CommentId commentId) ->
            AppUrl.fromPath [ "blog", slug, "comment", String.fromInt commentId ]

        BlogEditComment (Slug slug) (CommentId commentId) ->
            AppUrl.fromPath [ "blog", slug, "comment", String.fromInt commentId, "edit" ]


toString : Page -> String
toString =
    toAppUrl >> AppUrl.toString
