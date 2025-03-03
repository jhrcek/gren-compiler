module Gren.Platform
  ( Platform (..),
    --
    compatible,
    --
    encode,
    decoder,
    fromString,
  )
where

import Data.Utf8 qualified as Utf8
import Json.Decode qualified as D
import Json.Encode qualified as E
import Reporting.Exit qualified as Exit

data Platform
  = Common
  | Browser
  | Node
  deriving (Eq)

-- COMPATIBILITY

compatible :: Platform -> Platform -> Bool
compatible rootPlatform comparison =
  rootPlatform == comparison || comparison == Common

-- JSON

encode :: Platform -> E.Value
encode platform =
  case platform of
    Common -> E.chars "common"
    Browser -> E.chars "browser"
    Node -> E.chars "node"

decoder :: D.Decoder Exit.OutlineProblem Platform
decoder =
  do
    platformStr <- D.string
    case fromString $ Utf8.toChars platformStr of
      Just platform -> D.succeed platform
      Nothing -> D.failure Exit.OP_BadPlatform

fromString :: String -> Maybe Platform
fromString value =
  case value of
    "common" -> Just Common
    "browser" -> Just Browser
    "node" -> Just Node
    _ -> Nothing
