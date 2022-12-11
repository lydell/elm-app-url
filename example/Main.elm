module Main exposing (main)

import AppUrl
import Browser
import Browser.Navigation
import ElmUrl
import Html exposing (Html)
import Html.Attributes
import Html.Events
import Page exposing (Page)
import Url exposing (Url)


main : Program () Model Msg
main =
    Browser.application
        { init = init
        , view = view
        , update = update
        , subscriptions = subscriptions
        , onUrlRequest = LinkClicked
        , onUrlChange = UrlChanged
        }


type Msg
    = LinkClicked Browser.UrlRequest
    | UrlChanged Url
    | ModeChanged Mode


type alias Model =
    { key : Browser.Navigation.Key
    , page : Maybe Page
    , mode : Mode
    }


type Mode
    = UseAppUrl
    | UseElmUrl


init : () -> Url -> Browser.Navigation.Key -> ( Model, Cmd Msg )
init () url key =
    ( { key = key
      , page = Page.fromAppUrl (AppUrl.fromUrl url)
      , mode = UseAppUrl
      }
    , Cmd.none
    )


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        LinkClicked urlRequest ->
            case urlRequest of
                Browser.Internal url ->
                    ( model, Browser.Navigation.pushUrl model.key (Url.toString url) )

                Browser.External url ->
                    ( model, Browser.Navigation.load url )

        UrlChanged url ->
            case model.mode of
                UseAppUrl ->
                    ( { model | page = Page.fromAppUrl (AppUrl.fromUrl url) }, Cmd.none )

                UseElmUrl ->
                    ( { model | page = ElmUrl.parse url }, Cmd.none )

        ModeChanged mode ->
            ( { model | mode = mode }, Cmd.none )


subscriptions : Model -> Sub Msg
subscriptions _ =
    Sub.none


view : Model -> Browser.Document Msg
view model =
    { title = "elm-app-url example"
    , body =
        [ viewNavigation model
        , case model.page of
            Just page ->
                viewPage page

            Nothing ->
                viewNotFound
        ]
    }


navigationLinks : List ( String, Page )
navigationLinks =
    [ ( "Home", Page.Home )
    , ( "About", Page.About )
    , ( "Blog", Page.BlogHome { category = Nothing, year = Nothing } )
    ]


viewNavigation : Model -> Html Msg
viewNavigation model =
    Html.nav []
        [ Html.ul []
            (navigationLinks
                |> List.map
                    (\( title, page ) ->
                        Html.li []
                            [ if model.page == Just page then
                                Html.strong [] [ Html.text title ]

                              else
                                Html.a [ Html.Attributes.href (Page.toString page) ]
                                    [ Html.text title ]
                            ]
                    )
            )
        , Html.span [ Html.Attributes.style "flex" "1" ] []
        , viewModeRadio model UseAppUrl "lydell/elm-app-url"
        , viewModeRadio model UseElmUrl "elm/url"
        ]


viewModeRadio : Model -> Mode -> String -> Html Msg
viewModeRadio model mode text =
    Html.label []
        [ Html.input
            [ Html.Attributes.type_ "radio"
            , Html.Attributes.name "mode"
            , Html.Attributes.checked (model.mode == mode)
            , Html.Events.onInput (always (ModeChanged mode))
            ]
            []
        , Html.text text
        ]


viewPage : Page -> Html msg
viewPage page =
    case page of
        Page.Home ->
            Html.h1 [] [ Html.text "Home" ]

        Page.About ->
            Html.h1 [] [ Html.text "About" ]

        Page.BlogHome { category, year } ->
            Html.div []
                [ Html.h1 [] [ Html.text "Blog" ]
                , Html.p [] [ Html.text ("Category: " ++ Maybe.withDefault "None" category) ]
                , Html.p [] [ Html.text ("Year: " ++ Maybe.withDefault "None" (Maybe.map String.fromInt year)) ]
                , Html.ul []
                    (List.map
                        (\( title, slug ) ->
                            Html.li [] [ Html.a [ Html.Attributes.href (Page.toString (Page.BlogPost slug)) ] [ Html.text title ] ]
                        )
                        [ ( "Post 1", Page.Slug "post-1" )
                        , ( "Post 2", Page.Slug "post-2" )
                        , ( "Post 3", Page.Slug "post-3" )
                        ]
                    )
                ]

        Page.BlogPost (Page.Slug slug) ->
            Html.div []
                [ Html.h1 [] [ Html.text slug ]
                , Html.p [] [ Html.a [ Html.Attributes.href (Page.toString (Page.BlogEdit (Page.Slug slug))) ] [ Html.text "Edit" ] ]
                , Html.ul []
                    (List.map
                        (\( title, commentId ) ->
                            Html.li [] [ Html.a [ Html.Attributes.href (Page.toString (Page.BlogComment (Page.Slug slug) commentId)) ] [ Html.text title ] ]
                        )
                        [ ( "Comment 1", Page.CommentId 1 )
                        , ( "Comment 2", Page.CommentId 2 )
                        , ( "Comment 3", Page.CommentId 3 )
                        ]
                    )
                ]

        Page.BlogEdit (Page.Slug slug) ->
            Html.h1 [] [ Html.text ("Edit: " ++ slug) ]

        Page.BlogComment (Page.Slug slug) (Page.CommentId commentId) ->
            Html.div []
                [ Html.h1 [] [ Html.text slug ]
                , Html.p [] [ Html.text ("Comment: " ++ String.fromInt commentId) ]
                , Html.p [] [ Html.a [ Html.Attributes.href (Page.toString (Page.BlogEditComment (Page.Slug slug) (Page.CommentId commentId))) ] [ Html.text "Edit" ] ]
                ]

        Page.BlogEditComment (Page.Slug slug) (Page.CommentId commentId) ->
            Html.div []
                [ Html.h1 [] [ Html.text slug ]
                , Html.p [] [ Html.text ("Edit comment: " ++ String.fromInt commentId) ]
                ]


viewNotFound : Html msg
viewNotFound =
    Html.h1 [] [ Html.text "Not found" ]
