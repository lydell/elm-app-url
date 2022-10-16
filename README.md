# elm-app-url

`AppUrl` is a pretty small module that works in tandem with [elm/url]: It replaces some, but not all, parts of it. `AppUrl` tries to be as simple as possible and as useful to a [Browser.application] as possible.

Design principles:

- Parsing: Avoid the complex types [Url.Parser] has, and use simple list pattern matching instead. Decode away all percentage escapes so you never need to think about them.
- To string: No separate API like [Url.Builder]. Escape the minimum needed with percentage escapes.
- Follow the [WHATWG URL Standard].
- Handle the most common use cases rather than _all_ cases. (Use plain [Url] for full freedom).
- Keep it simple. URLs shouldn’t be that complicated. `AppUrl` lets you use the parts of Elm you already know and be done with it, instead of having to learn about parsers, tricky type annotations and the `</>` and `<?>` operators.

The package is centered around the [AppUrl][appurl-type] type. Read things from it. Turn it into a string. That’s it.

## Example

Turn a [Url] into an [AppUrl][appurl-type]:

```elm
import AppUrl exposing (AppUrl)
import Url exposing (Url)


myFunction : Url -> whatever
myFunction fullUrl =
    let
        url : AppUrl
        url =
            AppUrl.fromUrl fullUrl
    in
    doSomething url
```

Parse:

```elm
import AppUrl exposing (AppUrl)
import Dict


type Page
    = Home
    | Product ProductId
    | ListProducts Filters


type ProductId
    = ProductId String


type alias Filters =
    { color : Maybe String
    , size : Maybe String
    }


parse : AppUrl -> Maybe Page
parse url =
    -- Don’t forget to check out the tip further down as well!
    case url.path of
        [] ->
            Just Home

        [ "product", productId ] ->
            Just (Product (ProductId productId))

        [ "products" ] ->
            Just
                (ListProducts
                    { color = Dict.get "color" url.queryParameters |> Maybe.andThen List.head
                    , size = Dict.get "size" url.queryParameters |> Maybe.andThen List.head
                    }
                )

        _ ->
            Nothing
```

To string:

```elm
import AppUrl exposing (AppUrl)
import Html exposing (Html)
import Html.Attributes


viewLink : AppUrl -> Html msg
viewLink url =
    Html.a [ Html.Attributes.href (AppUrl.toString url) ]
        [ Html.text "My link" ]
```

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

It might feel wrong to repeat the URL segment `blog` so many times, for example. My advice is: Don’t try to be clever here for the sake of following the “Don’t Repeat Yourself (DRY)” principle! The above is very simple and easy to read, and gives a nice overview of what all your URLs look like. It’s easy to change too, since all the repetitions of `blog` is in the same place.

Do however avoid duplication in each branch by calling helper functions. But the pattern matching is better left “duplicated”.

## Real world example

[Concourse] is a big open source project with the frontend written in Elm. To try out `AppUrl`, I changed it from using [Url.Parser] and [Url.Builder] to `AppUrl`.

1. A first almost 1:1 translation: https://github.com/lydell/concourse/commit/8b5779dfe1b0e423bac2d9a5803c0032c924924c

   There are quite a few changes in that commit, but the most interesting ones are in `Routes.elm`. That commit shows that using `AppUrl` doesn’t result in much more code, even though it doesn’t have as many helper functions as [elm/url].

2. A second commit which simplifies by not trying to be so DRY: https://github.com/lydell/concourse/commit/c2c7b94b359896e078dae140082406327c2b9c1a

   This is a much smaller and much more interesting commit. It shows how repeating the same URL structure a couple of times results in shorter and simpler code that is also easier to get an overview of.

3. Direct link to the most interesting part: https://github.com/lydell/concourse/blob/c2c7b94b359896e078dae140082406327c2b9c1a/web/elm/src/Routes.elm#L541-L581

If you want to play around with this example yourself (requires Node.js):

1. `git clone --recurse-submodules git@github.com:lydell/elm-app-url.git`
2. `cd elm-app-url`
3. `npm ci`
4. `npm start`
5. `open http://localhost:8080`

## Details

Here are some extra details if you need them. Some functions link to these from their documentation – you might prefer to come back to these as you read through [AppUrl][appurl-module] module.

### Choosing a query parameter

If you expect a single parameter, should you take the first or last?

- [URLSearchParams.get()] in JavaScript and [Values.Get()] in Go take the first.
- [Django] takes the last.
- [elm/url] takes neither if there are duplicates.

But really – don’t worry about it! It’s an edge case. You won’t generate URLs with duplicate params in the first place. Only advanced users edit query params in URLs, and they should know not to make duplicates. I’d say use `|> Maybe.andThen List.head` and be done with it.

I’ve considered adding a helper function for getting a single value, but in practice I’ve used query parameters so seldom that I don’t mind the verbosity and explicitness of `|> Maybe.andThen List.head`.

### Query parameter parsing

See [Plus and space] for the specification the below follows.

- `?=foo` results in `Dict.singleton "" [ "foo" ]`. In other words, the empty string is a valid key name. (So is only whitespace, by the way.)
- `?a&b=` results in `Dict.fromList [ ( "a", [ "" ] ), ( "b", [ "" ] ) ]`. In other words, a missing equals sign and an equals sign followed by nothing are both parsed as having the empty string as value.
- `?=` results in `Dict.fromList [ ( "", [ "" ] ) ]`. In other words, just an equals sign is parsed as having the empty string both as key and value. When turning this back to a string, this is the only time the an equals sign is printed despite the value being the empty string. Otherwise you’d lose this “parameter” next time you parsed!
- `?&&` is parsed as `Dict.empty`. It _could_ have been parsed as the key being the empty string, and the value being the empty string as well, but empty spots are ignored.
- `?r=1&r=2` is parsed as `Dict.singleton "r" [ "1", "2" ]`. Note how the `r` key has multiple values.
- `?a+b=c+d` is parsed as `Dict.singleton "a b" [ "c d" ]`. Plus characters are turned into spaces – see [Plus and space].
- Creating an [AppUrl][appurl-type] using [AppUrl.fromUrl] never results in a key with the empty list as values. So we _could_ have typed the values as a non-empty list. That’s usually nice because you can get the first item without worrying about `Maybe`s. However, in this case we have a `Dict` so there are `Maybe`s to worry about anyway. Also, it’s convenient to be able to use the empty list when creating URLs and only sometimes wanting to output a query parameter.

### Escaping

Some characters are escaped for all parts of the [AppUrl][appurl-type]:

- C0 control characters (`0x00`–`0x1f`). (<https://url.spec.whatwg.org/#concept-basic-url-parser>)
- Whitespace characters (`\f`, `\n`, `\r`, `\t`, `\v`, `\u00a0`, `\u1680`, `\u2000`–`\u200a`, `\u2028`, `\u2029`, `\u202f`, `\u205f`, `\u3000`, `\ufeff`). (<https://developer.mozilla.org/en-US/docs/Web/JavaScript/Guide/Regular_Expressions/Character_Classes> – see `\s`.)
- The percent symbol (`%`). It’s the escape meta character.

Note that there is some overlap between the first two categories.

The specification linked to above says that all tabs and newlines should be removed while parsing, so those _definitely_ need to be escaped. For the rest, I think it’s a nice property if `AppUrl.toString` always returns a string without any whitespace – just one “chunk” of stuff. Control characters should never be used in URLs, but are escaped just in case.

Then there are different escaping rules for different parts of [AppUrl][appurl-type]:

- path: `/`, `?` and `#` are escaped as well. Slash because it starts a new segment. Question mark and hash since it starts the query and fragment, respectively.
- query key: `=`, `&`, `#` and `+` are escaped as well. Equals since it starts the value, ampersand since it starts a new query parameter, hash since it starts the fragment and plus since it’s treated as a space in the query part. Also, spaces are escaped as `+` – see [Plus and space].
- query value: `&`, `#` and `+` are escaped as well, for the same reasons as above. Note that `?k=1=2` is valid; the value is `1=2`. Also, spaces are escaped as `+` – see [Plus and space].
- fragment: No more escaping. The fragment goes on til the end of the URL.

The idea is that URLs are very loosely defined in what characters are allowed and which ones aren’t. Browsers seem to support basically any characters (possibly looser than some specification says, but hey – we run Elm code in browsers!). Escaping just the bare minimum means we don’t escape letters from non-English languages (like `ä` or `π`) into ugly percent sequences.

The escaping mindset is the same as for `Html`: When using `Html.text` you can give it any text you want and never have to worry about `<` creating an element. Similarly, you can’t expect `&nbsp;` to give you a non-breaking space; it will be the literal string `&nbsp;` (5 characters). Same idea with URLs here: You can put any strings in path segments, query parameter keys, query parameter values and the fragment and you never need to worry about a slash causing an extra segment or an ampersand causing an extra query parameter etc. Similarly, you can’t put slashes in path segment strings and expect them to end up as slashes (they’ll be escaped as `%2F`), and you can’t expect `%20` to be an escape for a space (it will be escaped as `%2520`).

### Plus and space

The [WHATWG URL Standard] defines a format for URLs, as well as the `new URL()` API in JavaScript, which is really good. The `URL` class has a `.searchParams` property which `AppUrl`’s `.queryParameters` is inspired by. `.searchParams` is an instance of the `URLSearchParams` class, which is [specified][urlsearchparams] to use the [application/x-www-form-urlencoded] format. That format says how to parse query parameters, and that `+` should be treated as space.

This package follows `URLSearchParams` and decodes `+` into space, and escapes `+` into `%2B` where needed.

Note that this is only for the query part, not for the path or the fragment.

### Full and relative URLs

[AppUrl][appurl-type] is only for URLs that start with a `/`.

- Full URL – [Url]: `http://example.com/path`
- “Origin absolute” URL – [AppUrl][appurl-type]: `/path`
- Relative URL: `../path`, `./path`, `path`

If you need a full URL with protocol, hostname and possibly a port there is nothing wrong with doing something like this:

```elm
"https://example.com" ++ AppUrl.toString myUrl
```

A hardcoded string for the origin is fine – I don’t think there’s much to gain from having an “Origin” type with `parse` and `toString` functions or something like that.

Finally, what about relative URLs? I recommend not using them at all. This package has nothing to offer on that front.

[application/x-www-form-urlencoded]: https://url.spec.whatwg.org/#urlencoded-parsing
[appurl-module]: https://package.elm-lang.org/packages/lydell/elm-app-url/1.0.0/AppUrl
[appurl-type]: https://package.elm-lang.org/packages/lydell/elm-app-url/1.0.0/AppUrl#AppUrl
[appurl.fromurl]: https://package.elm-lang.org/packages/lydell/elm-app-url/1.0.0/AppUrl#fromUrl
[browser.application]: https://package.elm-lang.org/packages/elm/browser/latest/Browser#application
[concourse]: https://github.com/concourse/concourse/
[django]: https://docs.djangoproject.com/en/4.1/ref/request-response/#django.http.QueryDict.__getitem__
[elm/url]: https://package.elm-lang.org/packages/elm/url/latest
[plus and space]: #plus-and-space
[url.builder]: https://package.elm-lang.org/packages/elm/url/latest/Url-Builder
[url.parser]: https://package.elm-lang.org/packages/elm/url/latest/Url-Parser
[url]: https://package.elm-lang.org/packages/elm/url/latest/Url#Url
[urlsearchparams.get()]: https://developer.mozilla.org/en-US/docs/Web/API/URLSearchParams/get
[urlsearchparams]: https://url.spec.whatwg.org/#example-constructing-urlsearchparams
[values.get()]: https://pkg.go.dev/net/url#example-Values
[whatwg url standard]: https://url.spec.whatwg.org/#urlencoded-parsing
