module Benchmarks exposing (main)

import AppUrl
import Benchmark exposing (describe)
import Benchmark.Alternative exposing (rank)
import Benchmark.Runner.Alternative as BenchmarkRunner
import Escape
import Mine.AppUrl
import Mine.Escape
import New.AppUrl
import New.Escape


main : BenchmarkRunner.Program
main =
    let
        str1 : String
        str1 =
            List.range 0 100
                |> List.map (Char.fromCode >> String.fromChar)
                |> String.concat

        str2 : String
        str2 =
            "products/väsksport & älgjakt"

        list1 : List String
        list1 =
            List.range 0 100
                |> List.map (Char.fromCode >> String.fromChar)

        list2 : List String
        list2 =
            [ "products", "väsksport & älgjakt", "1843" ]
    in
    BenchmarkRunner.program <|
        describe "Benchmarks"
            [ describe "Percent encode"
                ([ ( "100 first chars", str1 ), ( "example", str2 ) ]
                    |> List.map
                        (\( description, str ) ->
                            describe description
                                [ rank "Synthetic"
                                    (\f -> f str)
                                    [ ( "String to list, then map and join", mapListAndConcat )
                                    , ( "Folding in one pass", foldr )
                                    ]
                                , rank "Real"
                                    (\f -> f str)
                                    [ ( "main", AppUrl.percentEncode Escape.Path )
                                    , ( "new", New.AppUrl.percentEncode New.Escape.Path )
                                    , ( "mine", Mine.AppUrl.percentEncode Mine.Escape.Path )
                                    ]
                                ]
                        )
                )
            , describe "Path to string"
                ([ ( "first 100 chars", list1 ), ( "example", list2 ) ]
                    |> List.map
                        (\( description, list ) ->
                            describe description
                                [ rank "Synthetic"
                                    (\f -> f list)
                                    [ ( "Map and then join", mapThenJoin )
                                    , ( "Folding in one pass", foldl )
                                    ]
                                , rank "Real"
                                    (\f -> f list)
                                    [ ( "main", AppUrl.pathToString )
                                    , ( "new", New.AppUrl.pathToString )
                                    , ( "mine", Mine.AppUrl.pathToString )
                                    ]
                                ]
                        )
                )
            ]



-- Using String.fromChar : Char -> String to avoid exposing AppUrl.percentEncode


mapListAndConcat : String -> String
mapListAndConcat string =
    String.toList string
        |> List.map String.fromChar
        |> String.concat


foldr : String -> String
foldr string =
    String.foldr (\char acc -> String.fromChar char ++ acc) "" string



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
