# elm-app-url

`AppUrl` is an attempt at making URL handling simpler than [elm/url]!

It’s based around this [AppUrl] type:

```elm
type alias AppUrl =
    { path : List String
    , queryParameters : QueryParameters
    , fragment : Maybe String
    }


type alias QueryParameters =
    Dict String (List String)
```

Which works really nicely with pattern matching!

```elm
import AppUrl exposing (AppUrl)
import Dict


parse : AppUrl -> Maybe Page
parse url =
    case url.path of
        [] ->
            Just Home

        [ "product", productId ] ->
            String.toInt productId |> Maybe.map (Product << ProductId)

        [ "products" ] ->
            Just
                (ListProducts
                    { color = Dict.get "color" url.queryParameters |> Maybe.andThen List.head
                    , size = Dict.get "size" url.queryParameters |> Maybe.andThen List.head
                    }
                )

        _ ->
            Nothing


type Page
    = Home
    | Product ProductId
    | ListProducts Filters


type ProductId
    = ProductId Int


type alias Filters =
    { color : Maybe String
    , size : Maybe String
    }
```

Creating URL strings is pretty smooth too:

```elm
import Maybe.Extra


toAppUrl : Page -> AppUrl
toAppUrl page =
    case page of
        Home ->
            AppUrl.fromPath []

        Product (ProductId productId) ->
            AppUrl.fromPath [ "product", String.fromInt productId ]

        ListProducts { color, size } ->
            { path = [ "products" ]
            , queryParameters =
                Dict.fromList
                    [ ( "color", Maybe.Extra.toList color )
                    , ( "size", Maybe.Extra.toList size )
                    ]
            , fragment = Nothing
            }


toString : Page -> String
toString =
    toAppUrl >> AppUrl.toString
```

👉 **[Full examples]**

## Design principles

- Parse: Avoid the complex types [Url.Parser] has, and use simple list pattern matching instead. Decode away all percentage escapes so you never need to think about them.
- Stringify: No separate API like [Url.Builder]. Escape the minimum needed with percentage escapes.
- Specification: Follow the [WHATWG URL Standard].
- Keep it simple: URLs shouldn’t be that complicated. List pattern matching, `Dict` and `Maybe` is the bread and butter of `AppUrl`, rather than parsers, tricky type annotations and the `</>` and `<?>` operators.

## Tip

It’s completely fine to have something like this:

```elm
parse : AppUrl -> Maybe Page
parse url =
    case url.path of
        [ "blog" ] -> x
        [ "blog", postId ] -> x
        [ "blog", postId, "edit" ] -> x
        [ "blog", postId, "comment", commentId ] -> x
        [ "blog", postId, "comment", commentId, "edit" ] -> x
        _ -> Nothing
```

It might feel wrong to repeat the URL segment `blog` so many times, for example. My advice is: Don’t try to be clever here for the sake of following the “Don’t Repeat Yourself (DRY)” principle! The above is very simple and easy to read, and gives a nice overview of what all your URLs look like. It’s easy to change too, since all the repetitions of `blog` are in the same place.

Do however avoid duplication in each branch by calling helper functions. But the pattern matching is better left “duplicated”.

[appurl]: https://package.elm-lang.org/packages/lydell/elm-app-url/1.0.3/AppUrl/#AppUrl
[elm/url]: https://package.elm-lang.org/packages/elm/url/latest
[full examples]: https://github.com/lydell/elm-app-url/blob/main/docs/examples.md
[url.builder]: https://package.elm-lang.org/packages/elm/url/latest/Url-Builder
[url.parser]: https://package.elm-lang.org/packages/elm/url/latest/Url-Parser
[whatwg url standard]: https://url.spec.whatwg.org/#urlencoded-parsing
