#!/usr/bin/env stack
-- stack --resolver lts-15.01 script

module Main where

import Data.List (intercalate)

main :: IO ()
main = putStr $ (unlines prefix) ++ (getPrefixDef prefix) where
  getPrefixDef list = ("  prefix =\n    [\n    ") ++ (intercalate ",\n    " (map show list)) ++ "\n    ]"
  prefix =
    [
    "#!/usr/bin/env stack",
    "-- stack --resolver lts-15.01 script",
    "",
    "module Main where",
    "",
    "import Data.List (intercalate)",
    "",
    "main :: IO ()",
    "main = putStr $ (unlines prefix) ++ (getPrefixDef prefix) where",
    "  getPrefixDef list = (\"  prefix =\\n    [\\n    \") ++ (intercalate \",\\n    \" (map show list)) ++ \"\\n    ]\""
    ]
