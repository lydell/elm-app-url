# Details

The [AppUrl][appurl-module] module docs links to these sections for extra details.

## Choosing a query parameter

If you expect a single parameter, should you take the first or last?

- [URLSearchParams.get()] in JavaScript and [Values.Get()] in Go take the first.
- [Django] takes the last.
- [elm/url] takes neither if there are duplicates.

But really – don’t worry about it! It’s an edge case. You won’t generate URLs with duplicate params in the first place. Only advanced users edit query params in URLs, and they should know not to make duplicates. I’d say use `|> Maybe.andThen List.head` and be done with it.

I’ve considered adding a helper function for getting a single value, but in practice I’ve used query parameters so seldom that I don’t mind the verbosity and explicitness of `|> Maybe.andThen List.head`.

## Query parameter parsing

See [Plus and space] for the specification the below follows.

- `?=foo` results in `Dict.singleton "" [ "foo" ]`. In other words, the empty string is a valid key name. (So is only whitespace, by the way.)
- `?a&b=` results in `Dict.fromList [ ( "a", [ "" ] ), ( "b", [ "" ] ) ]`. In other words, a missing equals sign and an equals sign followed by nothing are both parsed as having the empty string as value.
- `?=` results in `Dict.fromList [ ( "", [ "" ] ) ]`. In other words, just an equals sign is parsed as having the empty string both as key and value. When turning this back to a string, this is the only time the an equals sign is printed despite the value being the empty string. Otherwise you’d lose this “parameter” next time you parsed!
- `?&&` is parsed as `Dict.empty`. It _could_ have been parsed as the key being the empty string, and the value being the empty string as well, but empty spots are ignored.
- `?r=1&r=2` is parsed as `Dict.singleton "r" [ "1", "2" ]`. Note how the `r` key has multiple values.
- `?a+b=c+d` is parsed as `Dict.singleton "a b" [ "c d" ]`. Plus characters are turned into spaces – see [Plus and space].
- Creating an [AppUrl][appurl-type] using [AppUrl.fromUrl] never results in a key with the empty list as values. So we _could_ have typed the values as a non-empty list. That’s usually nice because you can get the first item without worrying about `Maybe`s. However, in this case we have a `Dict` so there are `Maybe`s to worry about anyway. Also, it’s convenient to be able to use the empty list when creating URLs and only sometimes wanting to output a query parameter.

## Escaping

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

## Plus and space

The [WHATWG URL Standard] defines a format for URLs, as well as the `new URL()` API in JavaScript, which is really good. The `URL` class has a `.searchParams` property which `AppUrl`’s `.queryParameters` is inspired by. `.searchParams` is an instance of the `URLSearchParams` class, which is [specified][urlsearchparams] to use the [application/x-www-form-urlencoded] format. That format says how to parse query parameters, and that `+` should be treated as space.

This package follows `URLSearchParams` and decodes `+` into space, and escapes `+` into `%2B` where needed.

Note that this is only for the query part, not for the path or the fragment.

## Full and relative URLs

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
[django]: https://docs.djangoproject.com/en/4.1/ref/request-response/#django.http.QueryDict.__getitem__
[elm/url]: https://package.elm-lang.org/packages/elm/url/latest
[plus and space]: #plus-and-space
[url]: https://package.elm-lang.org/packages/elm/url/latest/Url#Url
[urlsearchparams.get()]: https://developer.mozilla.org/en-US/docs/Web/API/URLSearchParams/get
[urlsearchparams]: https://url.spec.whatwg.org/#example-constructing-urlsearchparams
[values.get()]: https://pkg.go.dev/net/url#example-Values
[whatwg url standard]: https://url.spec.whatwg.org/#urlencoded-parsing
