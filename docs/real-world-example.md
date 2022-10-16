# Real world example

[Concourse] is a big open source project with the frontend written in Elm. To try out `AppUrl`, I changed it from using [Url.Parser] and [Url.Builder] to `AppUrl`.

1. A first almost 1:1 translation: https://github.com/lydell/concourse/commit/93c737175d4c49916e4f4774fbbdd412b222daf1

   There are quite a few changes in that commit, but the most interesting ones are in `Routes.elm`. That commit shows that using `AppUrl` doesn’t result in much more code, even though it doesn’t have as many helper functions as [elm/url].

2. A second commit which simplifies by not trying to be so DRY: https://github.com/lydell/concourse/commit/a6f9c674e4927ead637f0f9c9906a83ea69f0bfe

   This is a much smaller and much more interesting commit. It shows how repeating the same URL structure a couple of times results in shorter and simpler code that is also easier to get an overview of.

3. Direct link to the most interesting part: https://github.com/lydell/concourse/blob/a6f9c674e4927ead637f0f9c9906a83ea69f0bfe/web/elm/src/Routes.elm#L541-L581

If you want to play around with this example yourself (requires [Node.js]):

1. `git clone --recurse-submodules git@github.com:lydell/elm-app-url.git`
2. `cd elm-app-url`
3. `npm ci`
4. `npm start`
5. `open http://localhost:8080`

[concourse]: https://github.com/concourse/concourse/
[node.js]: https://nodejs.org/
[url.builder]: https://package.elm-lang.org/packages/elm/url/latest/Url-Builder
[url.parser]: https://package.elm-lang.org/packages/elm/url/latest/Url-Parser
