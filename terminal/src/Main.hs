{-# LANGUAGE OverloadedStrings #-}

module Main
  ( main,
  )
where

import Bump qualified
import Data.List qualified as List
import Diff qualified
-- import qualified Format
import Gren.Platform qualified as Platform
import Gren.Version qualified as V
import Init qualified
import Install qualified
import Make qualified
import Publish qualified
import Repl qualified
import Terminal
import Terminal.Helpers
import Text.PrettyPrint.ANSI.Leijen qualified as P
import Prelude hiding (init)

-- MAIN

main :: IO ()
main =
  Terminal.app
    intro
    outro
    [ repl,
      init,
      make,
      install,
      -- format,
      bump,
      diff,
      publish
    ]

intro :: P.Doc
intro =
  P.vcat
    [ P.fillSep
        [ "Hi,",
          "thank",
          "you",
          "for",
          "trying",
          "out",
          P.green "Gren",
          P.green (P.text (V.toChars V.compiler)) <> ".",
          "I hope you like it!"
        ],
      "",
      P.black "-------------------------------------------------------------------------------",
      P.black "I highly recommend working through <https://gren-lang.org/learn> to get started.",
      P.black "It teaches many important concepts, including how to use `gren` in the terminal.",
      P.black "-------------------------------------------------------------------------------"
    ]

outro :: P.Doc
outro =
  P.fillSep $
    map P.text $
      words
        "Be sure to ask on the Gren zulip if you run into trouble! Folks are friendly and\
        \ happy to help out. They hang out there because it is fun, so be kind to get the\
        \ best results!"

-- INIT

init :: Terminal.Command
init =
  let summary =
        "Start an Gren project. It creates a starter gren.json file."

      details =
        "The `init` command helps start Gren projects:"

      example =
        reflow
          "It will ask permission to create an gren.json file, the one thing common\
          \ to all Gren projects."

      initFlags =
        flags Init.Flags
          |-- onOff "package" "Create a package (as opposed to an application)."
          |-- flag "platform" initPlatformParser "Which platform to target"
   in Terminal.Command "init" (Common summary) details example noArgs initFlags Init.run

initPlatformParser :: Parser Platform.Platform
initPlatformParser =
  Parser
    { _singular = "platform",
      _plural = "platforms",
      _parser = Platform.fromString,
      _suggest = \_ -> return ["common", "browser", "node"],
      _examples = \_ -> return ["common", "browser", "node"]
    }

-- REPL

repl :: Terminal.Command
repl =
  let summary =
        "Open up an interactive programming session. Type in Gren expressions\
        \ like (2 + 2) or (String.length \"test\") and see if they equal four!"

      details =
        "The `repl` command opens up an interactive programming session:"

      example =
        reflow
          "Start working through <https://gren-lang.org/learn> to learn how to use this!\
          \ It has a whole chapter that uses the REPL for everything, so that is probably\
          \ the quickest way to get started."

      replFlags =
        flags Repl.Flags
          |-- flag "interpreter" interpreter "Path to a alternate JS interpreter, like node or nodejs."
          |-- onOff "no-colors" "Turn off the colors in the REPL. This can help if you are having trouble reading the values. Some terminals use a custom color scheme that diverges significantly from the standard ANSI colors, so another path may be to pick a more standard color scheme."
   in Terminal.Command "repl" (Common summary) details example noArgs replFlags Repl.run

interpreter :: Parser String
interpreter =
  Parser
    { _singular = "interpreter",
      _plural = "interpreters",
      _parser = Just,
      _suggest = \_ -> return [],
      _examples = \_ -> return ["node", "nodejs"]
    }

-- MAKE

make :: Terminal.Command
make =
  let details =
        "The `make` command compiles Gren code into JS or HTML:"

      example =
        stack
          [ reflow
              "For example:",
            P.indent 4 $ P.green "gren make src/Main.gren",
            reflow
              "This tries to compile an Gren file named src/Main.gren, generating an index.html\
              \ file if possible."
          ]

      makeFlags =
        flags Make.Flags
          |-- onOff "debug" "Turn on the time-travelling debugger. It allows you to rewind and replay events. The events can be imported/exported into a file, which makes for very precise bug reports!"
          |-- onOff "optimize" "Turn on optimizations to make code smaller and faster. For example, the compiler renames record fields to be as short as possible and unboxes values to reduce allocation."
          |-- flag "output" Make.output "Specify the name of the resulting JS file. For example --output=assets/gren.js to generate the JS at assets/gren.js. You can also use --output=/dev/stdout to output the JS to the terminal, or --output=/dev/null to generate no output at all!"
          |-- flag "report" Make.reportType "You can say --report=json to get error messages as JSON. This is only really useful if you are an editor plugin. Humans should avoid it!"
          |-- flag "docs" Make.docsFile "Generate a JSON file of documentation for a package."
   in Terminal.Command "make" Uncommon details example (zeroOrMore grenFile) makeFlags Make.run

-- INSTALL

install :: Terminal.Command
install =
  let details =
        "The `install` command fetches packages from <https://package.gren-lang.org> for\
        \ use in your project:"

      example =
        stack
          [ reflow
              "For example, if you want to get packages for HTTP and JSON, you would say:",
            P.indent 4 $
              P.green $
                P.vcat $
                  [ "gren install gren/http",
                    "gren install gren/json"
                  ],
            reflow
              "Notice that you must say the AUTHOR name and PROJECT name! After running those\
              \ commands, you could say `import Http` or `import Json.Decode` in your code.",
            reflow
              "What if two projects use different versions of the same package? No problem!\
              \ Each project is independent, so there cannot be conflicts like that!"
          ]

      installArgs =
        oneOf
          [ require0 Install.NoArgs,
            require1 Install.Install package
          ]
   in Terminal.Command "install" Uncommon details example installArgs noFlags Install.run

-- PUBLISH

publish :: Terminal.Command
publish =
  let details =
        "The `publish` command publishes your package on <https://package.gren-lang.org>\
        \ so that anyone in the Gren community can use it."

      example =
        stack
          [ reflow
              "Think hard if you are ready to publish NEW packages though!",
            reflow
              "Part of what makes Gren great is the packages ecosystem. The fact that\
              \ there is usually one option (usually very well done) makes it way\
              \ easier to pick packages and become productive. So having a million\
              \ packages would be a failure in Gren. We do not need twenty of\
              \ everything, all coded in a single weekend.",
            reflow
              "So as community members gain wisdom through experience, we want\
              \ them to share that through thoughtful API design and excellent\
              \ documentation. It is more about sharing ideas and insights than\
              \ just sharing code! The first step may be asking for advice from\
              \ people you respect, or in community forums. The second step may\
              \ be using it at work to see if it is as nice as you think. Maybe\
              \ it ends up as an experiment on GitHub only. Point is, try to be\
              \ respectful of the community and package ecosystem!",
            reflow
              "Check out <https://package.gren-lang.org/help/design-guidelines> for guidance on how to create great packages!"
          ]
   in Terminal.Command "publish" Uncommon details example noArgs noFlags Publish.run

-- BUMP

bump :: Terminal.Command
bump =
  let details =
        "The `bump` command figures out the next version number based on API changes:"

      example =
        reflow
          "Say you just published version 1.0.0, but then decided to remove a function.\
          \ I will compare the published API to what you have locally, figure out that\
          \ it is a MAJOR change, and bump your version number to 2.0.0. I do this with\
          \ all packages, so there cannot be MAJOR changes hiding in PATCH releases in Gren!"
   in Terminal.Command "bump" Uncommon details example noArgs noFlags Bump.run

-- DIFF

diff :: Terminal.Command
diff =
  let details =
        "The `diff` command detects API changes:"

      example =
        stack
          [ reflow
              "For example, to see what changed in the HTML package between\
              \ versions 1.0.0 and 2.0.0, you can say:",
            P.indent 4 $ P.green $ "gren diff gren/html 1.0.0 2.0.0",
            reflow
              "Sometimes a MAJOR change is not actually very big, so\
              \ this can help you plan your upgrade timelines."
          ]

      diffArgs =
        oneOf
          [ require0 Diff.CodeVsLatest,
            require1 Diff.CodeVsExactly version,
            require2 Diff.LocalInquiry version version,
            require3 Diff.GlobalInquiry package version version
          ]
   in Terminal.Command "diff" Uncommon details example diffArgs noFlags Diff.run

-- FORMAT
{-
format :: Terminal.Command
format =
  let details =
        "The `format` command rewrites .gren files to use Gren's preferred style:"

      example =
        reflow "If no files or directories are given, all .gren files in all source and test directories will be formatted."

      formatFlags =
        flags Format.Flags
          |-- onOff "yes" "Assume yes for all interactive prompts."
          |-- onOff "stdin" "Format stdin and write it to stdout."
   in Terminal.Command "format" Uncommon details example (zeroOrMore grenFileOrDirectory) formatFlags Format.run
   -}

-- HELPERS

stack :: [P.Doc] -> P.Doc
stack docs =
  P.vcat $ List.intersperse "" docs

reflow :: String -> P.Doc
reflow string =
  P.fillSep $ map P.text $ words string
