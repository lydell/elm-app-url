module PercentEncode exposing (main)

import Benchmark
import Benchmark.Runner exposing (BenchmarkProgram)


main : BenchmarkProgram
main =
    let
        str : String
        str =
            List.range 0 100
                |> List.map (Char.fromCode >> String.fromChar)
                |> String.concat
    in
    Benchmark.Runner.program <|
        Benchmark.compare "Percent encode"
            "String to list, then map and join"
            (\() ->
                mapListAndConcat str
            )
            "Folding in one pass"
            (\() ->
                foldr str
            )


-- Using String.fromChar : Char -> String to avoid exposing AppUrl.percentEncode

mapListAndConcat : String -> String
mapListAndConcat string =
    String.toList string
        |> List.map String.fromChar
        |> String.concat


foldr : String -> String
foldr string =
    String.foldr (\char acc -> String.fromChar char ++ acc) "" string
