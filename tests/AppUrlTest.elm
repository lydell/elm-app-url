module AppUrlTest exposing (tests)

import AppUrl exposing (AppUrl, QueryParameters)
import Dict
import Expect
import Fuzz exposing (Fuzzer)
import Json.Decode
import Json.Encode
import Regex exposing (Regex)
import Test exposing (Test, describe, test)
import Url exposing (Url)


origin : String
origin =
    "http://example.com"


parseUrl : String -> Url
parseUrl urlString =
    case Url.fromString urlString of
        Just url ->
            url

        Nothing ->
            Debug.todo ("Could not parse URL: " ++ urlString)


contains : String -> ( String, String -> Bool )
contains string =
    ( string
    , String.contains string
    )


containsDisplay : String -> String -> ( String, String -> Bool )
containsDisplay display string =
    ( display
    , String.contains string
    )


containsCodes : String -> List Int -> ( String, String -> Bool )
containsCodes display codes =
    ( display
    , \fuzzedString ->
        codes
            |> List.any
                (\code ->
                    fuzzedString
                        |> String.contains (String.fromChar (Char.fromCode code))
                )
    )


controlCharacters : List Int
controlCharacters =
    List.range 0x00 0x1F


otherWhitespace : List Int
otherWhitespace =
    [ 0xA0, 0x1680 ] ++ List.range 0x2000 0x200A ++ [ 0x2028, 0x2029, 0x202F, 0x205F, 0x3000, 0xFEFF ]


whitespaceRegex : Regex
whitespaceRegex =
    Regex.fromString "\\s"
        |> Maybe.withDefault Regex.never


isCode : (Int -> Bool) -> String -> Bool
isCode f string =
    String.toList string
        |> List.any (f << Char.toCode)


isOtherAscii : String -> Bool
isOtherAscii =
    isCode (\code -> code >= 0x21 && code <= 0x7F)


isOtherNonAscii : String -> Bool
isOtherNonAscii =
    isCode (\code -> (code > 0x7F) && not (List.member code otherWhitespace))


roundtripFuzzer : Fuzzer String
roundtripFuzzer =
    Fuzz.list
        (Fuzz.frequency
            [ ( 9, Fuzz.char )
            , ( 1
              , Fuzz.oneOfValues otherWhitespace
                    |> Fuzz.map Char.fromCode
              )
            ]
        )
        |> Fuzz.map String.fromList


appUrlFuzzer : Fuzzer AppUrl
appUrlFuzzer =
    Fuzz.map3 AppUrl
        (Fuzz.list Fuzz.string)
        (Fuzz.list (Fuzz.pair Fuzz.string (Fuzz.map2 (::) Fuzz.string (Fuzz.list Fuzz.string))) |> Fuzz.map Dict.fromList)
        (Fuzz.maybe Fuzz.string)


roundtripRandomUrlString : Test
roundtripRandomUrlString =
    Test.fuzzWith
        { runs = 10000
        , distribution =
            Test.reportDistribution
                [ containsDisplay "space" " "
                , containsDisplay "tab" "\t"
                , containsDisplay "newline" "\n"
                , containsDisplay "\\r" "\u{000D}"
                , containsDisplay "\\f" "\u{000C}"
                , containsDisplay "\\v" "\u{000B}"
                , contains "/"
                , contains "?"
                , contains "="
                , contains "&"
                , contains "#"
                , contains "%"
                , containsCodes "control character" controlCharacters
                , containsCodes "other whitespace" otherWhitespace
                , ( "other ASCII", isOtherAscii )
                , ( "other non-ASCII", isOtherNonAscii )
                , ( "empty string", (==) "" )
                ]
        }
        roundtripFuzzer
        "roundtrip random URL string"
    <|
        \string ->
            let
                appUrl1 : AppUrl
                appUrl1 =
                    origin
                        ++ "/"
                        ++ string
                        |> parseUrl
                        |> trimTrailingSlash
                        |> AppUrl.fromUrl

                appUrl1String : String
                appUrl1String =
                    AppUrl.toString appUrl1

                url2 : Url
                url2 =
                    parseUrl (origin ++ appUrl1String)

                appUrl2 : AppUrl
                appUrl2 =
                    AppUrl.fromUrl url2
            in
            Expect.all
                [ \() ->
                    appUrl1
                        |> Expect.equal appUrl2
                , \() ->
                    Regex.contains whitespaceRegex appUrl1String
                        |> Expect.equal False
                        |> Expect.onFail ("URL string matches whitespace regex: " ++ appUrl1String)
                , \() ->
                    appUrl1String
                        |> String.startsWith "/"
                        |> Expect.equal True
                        |> Expect.onFail ("URL does not start with a slash: " ++ appUrl1String)
                , \() ->
                    case url2.query of
                        Just query ->
                            query
                                |> String.startsWith "&"
                                |> Expect.equal False
                                |> Expect.onFail ("URL query query starts with &: " ++ appUrl1String)

                        Nothing ->
                            Expect.pass
                , \() ->
                    case url2.query of
                        Just query ->
                            query
                                |> String.contains "&&"
                                |> Expect.equal False
                                |> Expect.onFail ("URL contains && in query: " ++ appUrl1String)

                        Nothing ->
                            Expect.pass
                ]
                ()


trimTrailingSlash : Url -> Url
trimTrailingSlash url =
    { url
        | path =
            if String.endsWith "/" url.path then
                String.dropRight 1 url.path

            else
                url.path
    }


roundtripRandomAppUrl : Test
roundtripRandomAppUrl =
    Test.fuzzWith
        { runs = 1000
        , distribution =
            Test.reportDistribution
                [ ( "with path", .path >> List.isEmpty >> not )
                , ( "with query", .queryParameters >> Dict.isEmpty >> not )
                , ( "with fragment", .fragment >> (==) Nothing >> not )
                , ( "empty", (==) { path = [], queryParameters = Dict.empty, fragment = Nothing } )
                ]
        }
        appUrlFuzzer
        "roundtrip random AppUrl"
    <|
        \appUrl1 ->
            let
                trimmedAppUrl1 : AppUrl
                trimmedAppUrl1 =
                    trimEmptyTrailingSegment appUrl1
            in
            Expect.all
                [ \() ->
                    origin
                        ++ AppUrl.toString appUrl1
                        |> parseUrl
                        |> AppUrl.fromUrl
                        |> Expect.equal trimmedAppUrl1
                , \() ->
                    AppUrl.toString appUrl1
                        |> AppUrl.fromString
                        |> Expect.equal (Just trimmedAppUrl1)
                , \() ->
                    AppUrl.encoder appUrl1
                        |> Json.Decode.decodeValue AppUrl.decoder
                        |> Expect.equal (Ok trimmedAppUrl1)
                ]
                ()


trimEmptyTrailingSegment : AppUrl -> AppUrl
trimEmptyTrailingSegment url =
    case List.reverse url.path of
        [ "", "" ] ->
            { url | path = [] }

        "" :: rest ->
            { url | path = List.reverse rest }

        _ ->
            url


fromPath : Test
fromPath =
    Test.fuzz (Fuzz.list Fuzz.string) "fromPath" <|
        \path ->
            AppUrl.fromPath path
                |> Expect.equal
                    { path = path
                    , queryParameters = Dict.empty
                    , fragment = Nothing
                    }


fromString : Test
fromString =
    describe "fromString"
        [ Test.fuzz Fuzz.string "never fails if starts with slash" <|
            \string ->
                Expect.all
                    [ (==) Nothing
                        >> Expect.equal False
                        >> Expect.onFail ("fromString failed to parse: " ++ string)
                    , Expect.equal (Just (AppUrl.fromUrl (parseUrl (origin ++ "/" ++ string))))
                    ]
                    (AppUrl.fromString ("/" ++ string))
        , test "fails if does not start with a slash" <|
            \() ->
                AppUrl.fromString "a"
                    |> Expect.equal Nothing
        , test "fails on the empty string" <|
            \() ->
                AppUrl.fromString ""
                    |> Expect.equal Nothing
        , test "nice example" <|
            \() ->
                AppUrl.fromString "/a/%C3%A4?c=ä&e=f#h"
                    |> Expect.equal
                        (Just
                            { path = [ "a", "ä" ]
                            , queryParameters = Dict.fromList [ ( "c", [ "ä" ] ), ( "e", [ "f" ] ) ]
                            , fragment = Just "h"
                            }
                        )
        ]


emptyUrl : Url
emptyUrl =
    { protocol = Url.Http
    , host = ""
    , port_ = Nothing
    , path = ""
    , query = Nothing
    , fragment = Nothing
    }


pathParsingTests : List ( String, String, List String )
pathParsingTests =
    [ ( "empty path"
      , ""
      , []
      )
    , ( "single slash"
      , "/"
      , []
      )
    , ( "double slash"
      , "//"
      , []
      )
    , ( "triple slash"
      , "///"
      , [ "", "" ]
      )
    , ( "not starting with a slash"
      , "a/b"
      , [ "a", "b" ]
      )
    , ( "one trailing slash"
      , "a/b/"
      , [ "a", "b" ]
      )
    , ( "two trailing slashes"
      , "a/b//"
      , [ "a", "b", "" ]
      )
    ]


testPath : ( String, String, List String ) -> Test
testPath ( name, path, expected ) =
    test name <|
        \() ->
            AppUrl.fromUrl { emptyUrl | path = path }
                |> .path
                |> Expect.equal expected


queryParameterTests : List ( String, String, QueryParameters )
queryParameterTests =
    [ ( "empty"
      , ""
      , Dict.empty
      )
    , ( "just a question mark"
      , "?"
      , Dict.empty
      )
    , ( "two question marks"
      , "??"
      , Dict.singleton "?" [ "" ]
      )
    , ( "two question marks and two equals signs"
      , "??=="
      , Dict.singleton "?" [ "=" ]
      )
    , ( "empty key"
      , "?=foo"
      , Dict.singleton "" [ "foo" ]
      )
    , ( "empty key and value"
      , "?="
      , Dict.fromList [ ( "", [ "" ] ) ]
      )
    , ( "multiple empty key and value"
      , "?=&="
      , Dict.fromList [ ( "", [ "", "" ] ) ]
      )
    , ( "with and without equals sign"
      , "?a&b="
      , Dict.fromList [ ( "a", [ "" ] ), ( "b", [ "" ] ) ]
      )
    , ( "empty spots"
      , "?&&"
      , Dict.empty
      )
    , ( "single value"
      , "?r=1"
      , Dict.singleton "r" [ "1" ]
      )
    , ( "multiple values"
      , "?r=1&r=2"
      , Dict.singleton "r" [ "1", "2" ]
      )
    , ( "plus"
      , "?a+b=c+d"
      , Dict.singleton "a b" [ "c d" ]
      )
    , ( "escaped plus"
      , "?a%2Bb=c%2Bd"
      , Dict.singleton "a+b" [ "c+d" ]
      )
    , ( "both escaped and unescaped plus"
      , "?a=%2B+"
      , Dict.singleton "a" [ "+ " ]
      )
    ]


testQueryParameters : ( String, String, QueryParameters ) -> Test
testQueryParameters ( name, input, expected ) =
    test name <|
        \() ->
            origin
                ++ input
                |> parseUrl
                |> AppUrl.fromUrl
                |> .queryParameters
                |> Expect.equal expected


escaping : Test
escaping =
    describe "escaping"
        [ test "never contains whitespace or control characters" <|
            \() ->
                let
                    all : List Int
                    all =
                        controlCharacters ++ otherWhitespace

                    allString : String
                    allString =
                        all
                            |> List.map Char.fromCode
                            |> String.fromList

                    urlString : String
                    urlString =
                        AppUrl.toString
                            { path = [ allString ]
                            , queryParameters = Dict.singleton allString [ allString ]
                            , fragment = Just allString
                            }
                in
                Expect.all
                    (urlString
                        |> String.toList
                        |> List.map
                            (\char () ->
                                let
                                    code : Int
                                    code =
                                        Char.toCode char
                                in
                                List.member code all
                                    |> Expect.equal False
                                    |> Expect.onFail ("Found " ++ String.fromInt code ++ " (char code in decimal) in: " ++ urlString)
                            )
                    )
                    ()
        , test "percent" <|
            \() ->
                AppUrl.toString
                    { path = [ "%" ]
                    , queryParameters = Dict.singleton "%" [ "%" ]
                    , fragment = Just "%"
                    }
                    |> Expect.equal "/%25?%25=%25#%25"
        , test "path escapes" <|
            \() ->
                AppUrl.toString
                    { path = [ "/", "?", "#" ]
                    , queryParameters = Dict.empty
                    , fragment = Nothing
                    }
                    |> Expect.equal "/%2F/%3F/%23"
        , test "path non-escapes" <|
            \() ->
                AppUrl.toString
                    { path = [ "=", "&", "+" ]
                    , queryParameters = Dict.empty
                    , fragment = Nothing
                    }
                    |> Expect.equal "/=/&/+"
        , test "query key escapes" <|
            \() ->
                AppUrl.toString
                    { path = []
                    , queryParameters = Dict.fromList [ ( "#", [ "a" ] ), ( "&", [ "a" ] ), ( "+", [ "a" ] ), ( "=", [ "a" ] ) ]
                    , fragment = Nothing
                    }
                    |> Expect.equal "/?%23=a&%26=a&%2B=a&%3D=a"
        , test "query key non-escapes" <|
            \() ->
                AppUrl.toString
                    { path = []
                    , queryParameters = Dict.fromList [ ( "/", [ "a" ] ), ( "?", [ "a" ] ) ]
                    , fragment = Nothing
                    }
                    |> Expect.equal "/?/=a&?=a"
        , test "query value escapes" <|
            \() ->
                AppUrl.toString
                    { path = []
                    , queryParameters = Dict.singleton "a" [ "&", "#", "+" ]
                    , fragment = Nothing
                    }
                    |> Expect.equal "/?a=%26&a=%23&a=%2B"
        , test "query value non-escapes" <|
            \() ->
                AppUrl.toString
                    { path = []
                    , queryParameters = Dict.singleton "a" [ "/", "?", "=" ]
                    , fragment = Nothing
                    }
                    |> Expect.equal "/?a=/&a=?&a=="
        , test "fragment non-escapes" <|
            \() ->
                AppUrl.toString
                    { path = []
                    , queryParameters = Dict.empty
                    , fragment = Just "/?&=#+"
                    }
                    |> Expect.equal "/#/?&=#+"
        , test "spaces and plus" <|
            \() ->
                AppUrl.toString
                    -- Only treated specially in `queryParameters`.
                    { path = [ " ", "+" ]
                    , queryParameters = Dict.fromList [ ( " ", [ " " ] ), ( "+", [ "+" ] ) ]
                    , fragment = Just " +"
                    }
                    |> Expect.equal "/%20/+?+=+&%2B=%2B#%20+"
        ]


empty : Test
empty =
    describe "empty"
        [ test "everything empty" <|
            \() ->
                AppUrl.toString { path = [], queryParameters = Dict.empty, fragment = Nothing }
                    |> Expect.equal "/"
        , test "one empty string path" <|
            \() ->
                AppUrl.toString { path = [ "" ], queryParameters = Dict.empty, fragment = Nothing }
                    |> Expect.equal "/"
        , test "two empty strings path" <|
            \() ->
                AppUrl.toString { path = [ "", "" ], queryParameters = Dict.empty, fragment = Nothing }
                    |> Expect.equal "//"
        , test "trailing slash" <|
            \() ->
                AppUrl.toString { path = [ "a", "" ], queryParameters = Dict.empty, fragment = Nothing }
                    |> Expect.equal "/a/"
        , test "query parameters with no values" <|
            \() ->
                AppUrl.toString { path = [], queryParameters = Dict.fromList [ ( "a", [] ), ( "b", [] ) ], fragment = Nothing }
                    |> Expect.equal "/"
        , test "query parameters with only empty strings" <|
            \() ->
                AppUrl.toString { path = [], queryParameters = Dict.singleton "" [ "", "" ], fragment = Nothing }
                    |> Expect.equal "/?=&="
        , test "empty string fragment" <|
            \() ->
                AppUrl.toString { path = [], queryParameters = Dict.empty, fragment = Just "" }
                    |> Expect.equal "/#"
        ]


misc : Test
misc =
    describe "misc"
        [ test "query keys are sorted" <|
            \() ->
                AppUrl.toString
                    { path = []
                    , queryParameters = Dict.fromList [ ( "b", [ "1" ] ), ( "c", [ "1" ] ), ( "a", [ "1" ] ), ( "0", [ "1" ] ) ]
                    , fragment = Nothing
                    }
                    |> Expect.equal "/?0=1&a=1&b=1&c=1"
        , test "nice example" <|
            \() ->
                let
                    url : AppUrl
                    url =
                        "http://example.com/product/123?size=large&color=red#description"
                            |> parseUrl
                            |> AppUrl.fromUrl
                in
                Expect.all
                    [ Expect.equal
                        { path = [ "product", "123" ]
                        , queryParameters = Dict.fromList [ ( "color", [ "red" ] ), ( "size", [ "large" ] ) ]
                        , fragment = Just "description"
                        }
                    , AppUrl.toString >> Expect.equal "/product/123?color=red&size=large#description"
                    ]
                    url
        , test "non-ascii" <|
            \() ->
                "http://example.com/Iñtërnâtiônàlizætiøn💩/искать/книги?søg=bøger#sök böcker"
                    |> parseUrl
                    |> AppUrl.fromUrl
                    |> AppUrl.toString
                    |> Expect.equal "/Iñtërnâtiônàlizætiøn💩/искать/книги?søg=bøger#sök%20böcker"
        , test "percent decoding" <|
            \() ->
                "http://example.com/%C3%A4?%E2%9C%85=%E2%84%AE#%23"
                    |> parseUrl
                    |> AppUrl.fromUrl
                    |> AppUrl.toString
                    |> Expect.equal "/ä?✅=℮##"
        , test "decoder error" <|
            \() ->
                Json.Decode.decodeValue
                    (Json.Decode.field "url" AppUrl.decoder)
                    (Json.Encode.object [ ( "url", Json.Encode.string "a/b?c=d#e" ) ])
                    |> Result.mapError Json.Decode.errorToString
                    |> Expect.equal (Err """Problem with the value at json.url:

    "a/b?c=d#e"

Expected a URL starting with a slash.""")
        ]


tests : Test
tests =
    describe "AppUrl"
        [ roundtripRandomUrlString
        , roundtripRandomAppUrl
        , fromPath
        , fromString
        , describe "path parsing" (List.map testPath pathParsingTests)
        , describe "query parameter parsing" (List.map testQueryParameters queryParameterTests)
        , escaping
        , empty
        , misc
        ]
