# Examples

## Small example

This repo contains a small `Browser.application` program to give a fuller picture on how you can use `AppUrl`. It also contains a comparison with [elm/url]. It’s in the [example folder].

## Concourse

[Concourse] is a big open source project with the frontend written in Elm. To try out `AppUrl`, I changed it from using [Url.Parser] and [Url.Builder] to `AppUrl`.

1. A first almost 1:1 translation: https://github.com/lydell/concourse/commit/93c737175d4c49916e4f4774fbbdd412b222daf1

   There are quite a few changes in that commit, but the most interesting ones are in `Routes.elm`. That commit shows that using `AppUrl` doesn’t result in much more code, even though it doesn’t have as many helper functions as [elm/url].

2. A second commit which simplifies by not trying to be so DRY: https://github.com/lydell/concourse/commit/a6f9c674e4927ead637f0f9c9906a83ea69f0bfe

   This is a much smaller and much more interesting commit. It shows how repeating the same URL structure a couple of times results in shorter and simpler code that is also easier to get an overview of.

3. Direct link to the most interesting part: https://github.com/lydell/concourse/blob/a6f9c674e4927ead637f0f9c9906a83ea69f0bfe/web/elm/src/Routes.elm#L541-L581

### Note

In the above commits you can see how I used [Dict.union] to merge two sets of [QueryParameters]. While it might work for the Concourse app, it does not work in all cases!

For example, let’s say you want to merge these two:

```elm
queryParametersA = Dict.fromList [ ( "a", [ "A" ] ), ( "b", [ "B1" ] ) ]

queryParametersB = Dict.fromList [ ( "b", [ "B2" ] ), ( "c", [ "C" ] ) ]
```

[Dict.union] gives the following result:

```elm
Dict.union queryParametersA queryParametersB
   == Dict.fromList [ ( "a", [ "A" ] ), ( "b", [ "B1" ] ), ( "c", [ "C" ] ) ]
```

Notice how the merged query parameters contains all the keys (`a`, `b` and `c`), but how `b` only contains the value `B1` and not `B2`.

The “correct” way to merge two sets of [QueryParameters] is:

```elm
Dict.merge
   Dict.insert
   (\key a b -> Dict.insert key (a ++ b))
   Dict.insert
   queryParametersA
   queryParametersB
   Dict.empty
```

That is much easier to write using [Dict.Extra.unionWith]:

```elm
Dict.Extra.unionWith (++) queryParametersA queryParametersB
```

That results in `b` getting both the `B1` and `B2` values:

```elm
Dict.Extra.unionWith (++) queryParametersA queryParametersB
   == Dict.fromList [ ( "a", [ "A" ] ), ( "b", [ "B1", "B2" ] ), ( "c", [ "C" ] ) ]
```

## Try it

If you want to play around with these examples yourself (requires [Node.js]):

1. `git clone --recurse-submodules git@github.com:lydell/elm-app-url.git`
2. `cd elm-app-url`
3. `npm ci`
4. `npm start`
5. `open http://localhost:8080` (small example)
6. `open http://localhost:8081` (Concourse)

[concourse]: https://github.com/concourse/concourse/
[dict.extra.unionwith]: https://package.elm-lang.org/packages/elmcraft/core-extra/latest/Dict-Extra#unionWith
[dict.union]: https://package.elm-lang.org/packages/elm/core/latest/Dict#union
[elm/url]: https://package.elm-lang.org/packages/elm/url/latest
[example folder]: https://github.com/lydell/elm-app-url/tree/main/example
[node.js]: https://nodejs.org/
[queryparameters]: https://package.elm-lang.org/packages/lydell/elm-app-url/latest/AppUrl#QueryParameters
[url.builder]: https://package.elm-lang.org/packages/elm/url/latest/Url-Builder
[url.parser]: https://package.elm-lang.org/packages/elm/url/latest/Url-Parser
