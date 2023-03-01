module PathToString exposing (main)

import Benchmark
import Benchmark.Runner exposing (BenchmarkProgram)


main : BenchmarkProgram
main =
    let
        list : List String
        list =
            List.range 0 100
                |> List.map (Char.fromCode >> String.fromChar)
    in
    Benchmark.Runner.program <|
        Benchmark.compare "Path to string"
            "Map and then join"
            (\() ->
                mapThenJoin list
            )
            "Folding in one pass"
            (\() ->
                foldl list
            )

-- Using String.toUpper : String -> String to avoid exposing AppUrl.pathToString

mapThenJoin : List String -> String
mapThenJoin path =
    "/" ++ String.join "/" (List.map String.toUpper path)


foldl : List String -> String
foldl path =
    case path of
        [] ->
            "/"

        p ->
            List.foldl (\el acc -> acc ++ "/" ++ String.toUpper el) "" p
