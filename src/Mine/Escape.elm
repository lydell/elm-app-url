module Mine.Escape exposing (Part(..), forAll)


type Part
    = Path
    | Query
    | Fragment


shouldHandlePlusAndSpace : Part -> Bool
shouldHandlePlusAndSpace part =
    case part of
        Path ->
            False

        Query ->
            True

        Fragment ->
            False


escapePart : Part -> Char -> String
escapePart part =
    case part of
        Path ->
            forPath

        Query ->
            forQuery

        Fragment ->
            String.fromChar


forAll : Part -> Char -> String
forAll part char =
    case char of
        '\u{0000}' ->
            "%00"

        '\u{0001}' ->
            "%01"

        '\u{0002}' ->
            "%02"

        '\u{0003}' ->
            "%03"

        '\u{0004}' ->
            "%04"

        '\u{0005}' ->
            "%05"

        '\u{0006}' ->
            "%06"

        '\u{0007}' ->
            "%07"

        '\u{0008}' ->
            "%08"

        '\t' ->
            "%09"

        '\n' ->
            "%0A"

        '\u{000B}' ->
            "%0B"

        '\u{000C}' ->
            "%0C"

        '\u{000D}' ->
            "%0D"

        '\u{000E}' ->
            "%0E"

        '\u{000F}' ->
            "%0F"

        '\u{0010}' ->
            "%10"

        '\u{0011}' ->
            "%11"

        '\u{0012}' ->
            "%12"

        '\u{0013}' ->
            "%13"

        '\u{0014}' ->
            "%14"

        '\u{0015}' ->
            "%15"

        '\u{0016}' ->
            "%16"

        '\u{0017}' ->
            "%17"

        '\u{0018}' ->
            "%18"

        '\u{0019}' ->
            "%19"

        '\u{001A}' ->
            "%1A"

        '\u{001B}' ->
            "%1B"

        '\u{001C}' ->
            "%1C"

        '\u{001D}' ->
            "%1D"

        '\u{001E}' ->
            "%1E"

        '\u{001F}' ->
            "%1F"

        ' ' ->
            if shouldHandlePlusAndSpace part then
                "+"

            else
                "%20"

        '%' ->
            "%25"

        '+' ->
            if shouldHandlePlusAndSpace part then
                "%2B"

            else
                "+"

        '\u{00A0}' ->
            "%C2%A0"

        '\u{1680}' ->
            "%E1%9A%80"

        '\u{2000}' ->
            "%E2%80%80"

        '\u{2001}' ->
            "%E2%80%81"

        '\u{2002}' ->
            "%E2%80%82"

        '\u{2003}' ->
            "%E2%80%83"

        '\u{2004}' ->
            "%E2%80%84"

        '\u{2005}' ->
            "%E2%80%85"

        '\u{2006}' ->
            "%E2%80%86"

        '\u{2007}' ->
            "%E2%80%87"

        '\u{2008}' ->
            "%E2%80%88"

        '\u{2009}' ->
            "%E2%80%89"

        '\u{200A}' ->
            "%E2%80%8A"

        '\u{2028}' ->
            "%E2%80%A8"

        '\u{2029}' ->
            "%E2%80%A9"

        '\u{202F}' ->
            "%E2%80%AF"

        '\u{205F}' ->
            "%E2%81%9F"

        '\u{3000}' ->
            "%E3%80%80"

        '\u{FEFF}' ->
            "%EF%BB%BF"

        _ ->
            escapePart part char


forPath : Char -> String
forPath char =
    case char of
        '/' ->
            "%2F"

        '?' ->
            "%3F"

        '#' ->
            "%23"

        _ ->
            String.fromChar char


forQuery : Char -> String
forQuery char =
    case char of
        '=' ->
            "%3D"

        '&' ->
            "%26"

        '#' ->
            "%23"

        _ ->
            String.fromChar char
