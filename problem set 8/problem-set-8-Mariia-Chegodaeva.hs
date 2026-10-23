{-# OPTIONS_GHC -Wall #-}
-- Topic 8. Problem set --- Haskell. Answer file.
--
-- Name:   Mariia Chegodaeva
-- Group:  B24-SD-02
-- Email:  ma.chegodaeva@innopolis.university
--
-- (The name above is Valentin Turchin, who designed Refal and invented
-- supercompilation. Please replace it with your own.)
--
-- How to use this file.
--
--   1. Enter your name, group and university email above.
--   2. Answer every problem of the sheet in this file. Code is written as
--      code. A type, a prediction or an explanation is written in a comment,
--      under the marker for its part.
--   3. Every problem carries an AI use declaration. For a No AI problem,
--      leave the declaration in place. Problem 8.5 gives two choices: keep
--      the line that is true and delete the other. A missing declaration is
--      treated as a missing answer.
--   4. Rename the file after yourself, as problem-set-8-<Surname>.hs, and
--      make sure that it loads. Use GHC 9.10.3, the version GHCup
--      recommends. In a terminal, in the directory of the file, run
--
--        ghci problem-set-8-<Surname>.hs
--
--      and check that it loads without errors. The examples from the sheet
--      appear in this file as comments in the form GHCi shows them: the
--      expression after the prompt, and the expected value below it.
--   5. The file is also a program, and its first argument picks what it
--      does. Nothing reads the keyboard unless the mode says so.
--
--        runghc problem-set-8-<Surname>.hs
--          prints the examples of the sheet and then your checks (8.3).
--          It stops at the first part that is still undefined.
--        runghc problem-set-8-<Surname>.hs files
--          writes the sample files log-1.txt, requests-1.txt,
--          requests-2.txt and links.txt into the current directory.
--        runghc problem-set-8-<Surname>.hs follow
--          runs the program of 8.1(c) with today's date.
--        runghc problem-set-8-<Surname>.hs follow-bind
--          runs the same program with your followBind of 8.1(b).
--        runghc problem-set-8-<Surname>.hs console < requests-1.txt
--          8.4(b): the console, reading requests-1.txt instead of the
--          keyboard. In GHCi, :main console reads the keyboard.
--        runghc problem-set-8-<Surname>.hs replay log-1.txt out.txt
--          8.4(c): the replay of a log.
--
--      The bonus is a copy of this file with a server added, and its
--      section below says how to run it.
--
--      The stubs below are chosen so that the file loads, with no warnings
--      under -Wall, before you have written anything; replace them.
--   6. Two rules apply throughout. No partial functions: every function has
--      an equation for every shape of its input, and no answer calls head,
--      tail or !!. The file loads: a part you have not finished stays
--      undefined, or in a comment.
--   7. Submit this file. For problem 8.5, submit assistant.hs as well, and
--      if you used an assistant, transcript.md with the whole exchange,
--      verbatim and unedited. For the bonus, submit server.hs as well.

module Main where

import Data.Time
import System.Environment (getArgs)
import Text.Read (readMaybe)

-- ===========================================================================
-- Given, for the whole sheet
-- ===========================================================================

-- From Data.Time, imported above. Four of its functions are all this sheet
-- needs:
--
--   getCurrentTime :: IO UTCTime                    reads the clock
--   utctDay        :: UTCTime -> Day                the date of a moment, in UTC
--   fromGregorian  :: Integer -> Int -> Int -> Day  fromGregorian 2026 10 14
--   addDays        :: Integer -> Day -> Day         addDays 30 d
--
-- ghci> addDays 30 (fromGregorian 2026 10 1)
-- 2026-10-31

data Method = GET | PUT
  deriving (Show, Read, Eq)

data LinkRequest
  = Create String String  -- PUT /alias url
  | Follow String         -- GET /alias
  deriving (Show, Eq)

data Response
  = Created            -- 201
  | Redirect String    -- 302, to this url
  | BadRequest String  -- 400, with a reason
  | NotFound           -- 404
  | Conflict           -- 409, the alias is taken
  | Gone               -- 410, the link expired
  deriving (Show, Eq)

data Link = Link
  { alias   :: String
  , target  :: String
  , created :: Day
  , clicks  :: Int
  }
  deriving (Show, Read, Eq)

-- A link works for 30 days: made on 1 Oct, it redirects up to 30 Oct.
alive :: Day -> Link -> Bool
alive today l = today < addDays 30 (created l)

findLink :: String -> [Link] -> Maybe Link
findLink _ [] = Nothing
findLink a (l : ls)
  | alias l == a = Just l
  | otherwise    = findLink a ls

-- One more click on the link with this alias.
countClick :: String -> [Link] -> [Link]
countClick a ls = map (\l -> if alias l == a then l { clicks = clicks l + 1 } else l) ls

statusLine :: Response -> String
statusLine Created          = "201 Created"
statusLine (Redirect url)   = "302 Found: " ++ url
statusLine (BadRequest why) = "400 Bad Request: " ++ why
statusLine NotFound         = "404 Not Found"
statusLine Conflict         = "409 Conflict"
statusLine Gone             = "410 Gone"

describeLink :: Link -> String
describeLink l =
  alias l ++ " -> " ++ target l ++ ", made " ++ show (created l)
    ++ ", clicks: " ++ show (clicks l)

-- Dates in October and November 2026, to keep the examples short.
oct, nov :: Int -> Day
oct d = fromGregorian 2026 10 d
nov d = fromGregorian 2026 11 d

-- ===========================================================================
-- Problem 8.1                                                         No AI
-- ===========================================================================

-- I have not used AI tools when solving this problem.

-- Given: the first version of the service.
follow :: String -> [Link] -> IO [Link]
follow a ls = do
  now <- getCurrentTime
  let today    = utctDay now
      notFound = putStrLn "404 Not Found"
  case findLink a ls of
    Nothing -> do
      notFound
      pure ls
    Just l ->
      if alive today l
        then do
          putStrLn ("302 Found: " ++ target l)
          pure (countClick a ls)
        else do
          putStrLn "410 Gone"
          pure ls

-- Given: two links, made on 14 Oct and on 2 Sep.
someLinks :: [Link]
someLinks =
  [ Link "ghcup" "https://www.haskell.org/ghcup/" (oct 14) 0
  , Link "lyah" "https://learnyouahaskell.github.io/input-and-output.html"
      (fromGregorian 2026 9 2) 5
  ]

-- (a) The type of each, and whether it is an action or a plain value:
--   now               :: UTCTime                   -- plain value
--   today             :: Day                       -- plain value
--   notFound          :: IO ()                     -- action
--   findLink a ls     :: Maybe Link                -- plain value
--   alive today l     :: Bool                      -- plain value
--   pure ls           :: IO [Link]                 -- action
--   follow "ghcup"    :: [Link] -> IO [Link]       -- plain function value
--   the else block    :: IO [Link]                 -- action

-- (b) The same block with >>=, >> and lambdas, and no do.
followBind :: String -> [Link] -> IO [Link]
followBind a ls =
  getCurrentTime >>= \now ->
    let today = utctDay now
        notFound = putStrLn "404 Not Found"
    in case findLink a ls of
      Nothing ->
        notFound >> pure ls
      Just l ->
        if alive today l
          then putStrLn ("302 Found: " ++ target l)
            >> pure (countClick a ls)
          else putStrLn "410 Gone"
            >> pure ls  

-- Given: the program of 8.1(c), and the same with your followBind.
followMain :: IO ()
followMain = do
  ls1 <- follow "ghcup" someLinks
  ls2 <- follow "ghcpu" ls1
  ls3 <- follow "lyah" ls2
  ls4 <- follow "ghcup" ls3
  print (map clicks ls4)

followBindMain :: IO ()
followBindMain = do
  ls1 <- followBind "ghcup" someLinks
  ls2 <- followBind "ghcpu" ls1
  ls3 <- followBind "lyah" ls2
  ls4 <- followBind "ghcup" ls3
  print (map clicks ls4)

-- (c) What followMain prints on 19 Oct:
--     302 Found: https://www.haskell.org/ghcup/
--     404 Not Found
--     410 Gone
--     302 Found: https://www.haskell.org/ghcup/
--     [2,5]

--    What followMain prints on 14 Nov:
--    410 Gone
--    404 Not Found
--    410 Gone
--    410 Gone
--    [0,5]

-- How many times getCurrentTime and notFound run:
-- On either date, getCurrentTime runs four times and notFound runs once.
-- Each call to follow runs getCurrentTime before the case. Only the one
-- missing alias runs notFound; the let that names it runs no action 

-- Why this file gives no expected output for followMain:
-- follow reads the actual clock, so the output depends on the UTC date 
-- when the program is run

-- (d) Accepted or refused, and if accepted, what (c) prints on 19 Oct:
-- 1. Refused. With now = getCurrentTime, now has type IO UTCTime but utctDay requires a UTCTime
-- 2. Refused. The Nothing branch requires IO [Link]; ls has type [Link]
-- 3. Accepted. With notFound executed immediately before the case, it prints
--    for every call, including successful and expired lookup. On 19 Oct:
--    404 Not Found
--    302 Found: https://www.haskell.org/ghcup/
--    404 Not Found
--    404 Not Found
--    410 Gone
--    404 Not Found
--    302 Found: https://www.haskell.org/ghcup/
--    [2,5]

-- ===========================================================================
-- Problem 8.2                                                         No AI
-- ===========================================================================

-- I have not used AI tools when solving this problem.

-- Given. The alias in a path such as "/ghcup", and an https address.
aliasOf :: String -> Maybe String
aliasOf ('/' : a)
  | a /= "" = Just a
aliasOf _   = Nothing

secure :: String -> Maybe String
secure url
  | take 8 url == "https://" && length url > 8 = Just url
  | otherwise                                  = Nothing

-- Given: the staircase.
parseLinkRequest :: String -> Maybe LinkRequest
parseLinkRequest line =
  case words line of
    (m : p : more) ->
      case readMaybe m of
        Nothing -> Nothing
        Just meth ->
          case aliasOf p of
            Nothing -> Nothing
            Just a ->
              case (meth, more) of
                (GET, [])    -> Just (Follow a)
                (PUT, [url]) ->
                  case secure url of
                    Nothing -> Nothing
                    Just u  -> Just (Create a u)
                _ -> Nothing
    _ -> Nothing

-- ghci> parseLinkRequest "GET /ghcup"
-- Just (Follow "ghcup")
-- ghci> parseLinkRequest "PUT /ghcup http://www.haskell.org/ghcup/"
-- Nothing

-- (a) With do in Maybe, and no case on a Maybe.
parseLinkRequestDo :: String -> Maybe LinkRequest
parseLinkRequestDo line =
  case words line of
    (m : p : more) -> do
      meth <- readMaybe m
      a <- aliasOf p
      case (meth, more) of
        (GET, []) -> Just (Follow a)
        (PUT, [url]) -> do
          u <- secure url
          Just (Create a u)
        _ -> Nothing
    _ -> Nothing

-- ghci> parseLinkRequestDo "PUT /ghcup https://www.haskell.org/ghcup/"
-- Just (Create "ghcup" "https://www.haskell.org/ghcup/")

-- (b) The same, saying what is wrong. Your wording may differ from the
--     examples, as long as it names the part and what is wrong with it.
readLinkRequest :: String -> Either String LinkRequest
readLinkRequest line = 
  case words line of
    [] -> Left "missing method"
    (m : rest) -> do
      meth <- maybe (Left ("no such method: " ++ m )) Right
                    (readMaybe m :: Maybe Method)
      
      case rest of
        [] -> Left "missing alias path"
        (p : more) -> do
          a <- maybe (Left ("not an alias path: " ++ p)) Right (aliasOf p)
          case (meth, more) of
            (GET, []) -> Right (Follow a)
            (GET, _) -> Left "GET must not have an address"
            (PUT, [url]) ->
              maybe (Left ("not an https address: " ++ url))
                    (Right . Create a)
                    (secure url) 
            (PUT, _) -> Left "PUT needs exactly one address"

-- ghci> readLinkRequest "POST /ghcup"
-- Left "no such method: POST"
-- ghci> readLinkRequest "PUT /time hackage.haskell.org/package/time"
-- Left "not an https address: hackage.haskell.org/package/time"

-- (c) A log, by explicit recursion.
readLog :: [String] -> Either String [(Day, String)]
readLog = go 1
  where
    go :: Int -> [String] -> Either String [(Day, String)]
    go _ [] = Right []
    go n (line : rest) =
      let (dateText, afterDate) = break (== ' ') line
          request = drop 1 afterDate
      in case readMaybe dateText of
          Nothing -> Left ("line " ++ show n ++ ": no date: " ++ dateText)
          Just day -> do
            entries <- go (n + 1) rest
            Right ((day, request) : entries)

-- ghci> readLog ["2026-10-14 GET /ghcup", "2026-10-15 POST /x"]
-- Right [(2026-10-14,"GET /ghcup"),(2026-10-15,"POST /x")]
-- ghci> readLog ["2026-10-14 GET /ghcup", "2026-11-31 GET /ghcup"]
-- Left "line 2: no date: 2026-11-31"

-- Why a bad date refuses the whole log, while a bad request does not:
-- A bad date prevents readLog from producing a (Day, String) entry,
-- so it returns Left for the whole log. A bad request is kept as a String 
-- without being checked, so it doesn't prevent the log from being read

-- ===========================================================================
-- Problem 8.3                                                         No AI
-- ===========================================================================

-- I have not used AI tools when solving this problem.

-- Given: a link made on 1 Oct, for the examples and the checks.
ghcupUrl :: String
ghcupUrl = "https://www.haskell.org/ghcup/"

ghcupLink :: Link
ghcupLink = Link "ghcup" ghcupUrl (oct 1) 0

-- (a) The core.
handle :: Day -> LinkRequest -> [Link] -> (Response, [Link])
handle today  (Follow a) ls = 
  case findLink a ls of 
    Nothing -> (NotFound, ls)
    Just l
      | alive today l -> (Redirect (target l), countClick a ls)
      | otherwise -> (Gone, ls) 
handle today(Create a url) ls = 
  case findLink a ls of
    Just _ -> (Conflict, ls)
    Nothing -> (Created, Link a url today 0 : ls)

respond :: Day -> String -> [Link] -> (Response, [Link])
respond today line ls =
  case readLinkRequest line of
    Left why -> (BadRequest why, ls)
    Right req -> handle today req ls

-- ghci> handle (oct 31) (Follow "ghcup") [ghcupLink]
-- (Gone,[Link {alias = "ghcup", target = "https://www.haskell.org/ghcup/", created = 2026-10-01, clicks = 0}])
-- ghci> respond (oct 5) "GET ghcup" [ghcupLink] == (BadRequest "not a path: ghcup", [ghcupLink])
-- True                        (with your own wording of the reason)

-- (b) By explicit recursion.
replay :: (r -> s -> (a, s)) -> [r] -> s -> ([a], s)
replay _ [] state = ([], state)
replay step (request : requests) state =
  let (answer, nextState) = step request state
      (answers, finalState) =replay step requests nextState
  in (answer : answers, finalState)

-- ghci> replay (\x n -> (x * n, n + 1)) [10, 10, 10] 1
-- ([10,20,30],4)

-- Given.
entry :: (Day, String) -> [Link] -> (Response, [Link])
entry (d, line) ls = respond d line ls

-- What replay entry is, with its type, and why replay can neither read
-- input nor print:
-- replay entry :: [(Day, String)] -> [Link] -> ([Response], [Link])
-- It runs each dated request in order, returning the responses and final links.
-- Its type contains no IO, so ordinary Haskell code can't read or print here

-- (c) Given: a check is a name and whether it holds, and the default run
--     of this file prints the names of the checks that fail.
type Check = (String, Bool)

failures :: [Check] -> [String]
failures [] = []
failures ((name, ok) : cs)
  | ok        = failures cs
  | otherwise = name : failures cs

-- Add at least six checks after the first.
checks :: [Check]
checks =
  [ ( "an unknown alias is not found"
    , handle (oct 5) (Follow "ghcpu") [ghcupLink] == (NotFound, [ghcupLink]) )
  , ( "create adds a link dated today with zero clicks"
    , handle (oct 5) (Create "notes" "https://example.org") []
        == (Created, [Link "notes" "https://example.org" (oct 5) 0]) )
  , ( "following on the last live day redirects and counts a click"
    , handle (oct 30) (Follow "ghcup") [ghcupLink]
        == (Redirect ghcupUrl, [ghcupLink { clicks = 1 }]) )
  , ( "following on the first expired day is gone without a click"
    , handle (oct 31) (Follow "ghcup") [ghcupLink]
        == (Gone, [ghcupLink]) )
  , ( "an existing alias conflicts"
    , handle (oct 5) (Create "ghcup" "https://example.org") [ghcupLink]
        == (Conflict, [ghcupLink]) )
  , ( "a malformed path is a bad request"
    , respond (oct 5) "GET ghcup" [ghcupLink]
        == (BadRequest "not an alias path: ghcup", [ghcupLink]) )
  , ( "a parsed GET redirects and counts a click"
    , respond (oct 5) "GET /ghcup" [ghcupLink]
        == (Redirect ghcupUrl, [ghcupLink { clicks = 1 }]) )
  , ( "replay passes the updated links to each next request"
    , replay entry
        [ (oct 5, "PUT /notes https://example.org")
        , (oct 6, "GET /notes")
        , (oct 7, "GET /notes")
        ] []
        == ( [Created, Redirect "https://example.org", Redirect "https://example.org"]
           , [Link "notes" "https://example.org" (oct 5) 2] ) )
  , ( "replay on no requests preserves the starting links"
    , replay entry [] [ghcupLink] == ([], [ghcupLink]) )
  ]

-- Which of your checks could not be written for follow of 8.1, and why:
-- The Create and malformed-request checks can't be written for follow:
-- it accepts only an alias, reads the real clock, and prints its response.
-- Its returned [Link] can still be checked for updated click counts, but
-- exact-date and response checks need control of the date and printed output;
-- a session through replay needs a pure state transition

-- ===========================================================================
-- Problem 8.4                                                         No AI
-- ===========================================================================

-- I have not used AI tools when solving this problem.

-- (a) The loop, from its type.
serveFrom :: IO (Maybe r) -> (r -> s -> (String, s)) -> s -> IO s
serveFrom next step state = do
  input <- next
  case input of
    Nothing -> pure state
    Just request -> do 
      let (line, newState) = step request state
      putStrLn line
      serveFrom next step newState

-- What the type lets serveFrom know about requests and links:
-- The type reveals nothing about the structure of requests or links:
-- r and s can be any types. serveFrom only passes them to step and
-- carries the returned state into the next iteration

-- (b) The console.
fromKeyboard :: IO (Maybe (Day, String))
fromKeyboard = do
  line <- getLine
  if null line
    then pure Nothing
    else do
      today <- utctDay <$> getCurrentTime
      pure (Just (today, line))

console :: IO ()
console = do
  links <- serveFrom fromKeyboard step []
  mapM_ (putStrLn . describeLink) links
  where
    step (day, line) links =
      let (response, newLinks) = respond day line links
      in (statusLine response, newLinks)

-- (c) The replay.
replayFile :: FilePath -> FilePath -> IO ()
replayFile input output = do
  contents <- readFile input
  case readLog (lines contents) of
    Left reason -> putStrLn reason 
    Right requests -> do
      let (responses, links) = replay entry requests []
      writeFile output (unlines (map statusLine responses))
      putStrLn ("replayed " ++ show (length requests) ++ " requests")
      mapM_ (putStrLn . describeLink) links
    
-- (d) After runghc ... files, then the console on requests-1.txt and the
--     replay of log-1.txt:
-- 1. Responses differ on lines 14 and 16. When the console runs 
--    on 17 October 2026, both links are still alive, so it returns 302 Found 
--    for both requests. The replay uses the dates recorded in log-1.txt.
--    By those dates, both links have expired, so it returns 410 Gone
-- 2. Without the final empty line, the console prints all 16 responses,
--    then getLine reaches EOF and raises an error. It never reaches the final link descriptions
-- 3. readLog reports line 14: no date: 2026-11-31. The replay produces no new output file 
--    because it rejects the log before processing requests. The service can't answer a request with an invalid Day;
--    on the original valid date, 13 November, that GET /ghcup would receive 410 Gone

-- ===========================================================================
-- Problem 8.5                                   (a) AI allowed, then No AI
-- ===========================================================================

-- I have used AI (ChatGPT free) in part (a) of this problem, in accordance with
-- the course rules and the problem statement.

-- (a) The program goes into assistant.hs, verbatim, beside this file. If
--     you used an assistant, the exchange goes into transcript.md.

-- (b) Before running it. For each line of requests-2.txt, whether the
--     program reads it and what it prints:
--   1. PUT /ghcup https://www.haskell.org/ghcup/
--      Read; 201 Created
--   2. GET /ghcup
--      Read; 302 Found: https://www.haskell.org/ghcup/
--   3. GET /ghcup/
--      Read; 404 Not Found
--   4. GET /ghcpu
--      Read; 404 Not Found
--   5. PUT /ghcup https://ghcup.haskell.org/
--      Read; 409 Conflict
--   6. GET /ghcup 
--      Read; 302 Found: https://www.haskell.org/ghcup/
--   7. PUT /lyah http://learnyouahaskell.com/
--      Read; 400 Bad Request
--   8. put /lyah https://learnyouahaskell.github.io/
--      Read; 400 Bad Request
--   9. GET /lyah
--      Read; 404 Not Found
--  10. GET /ghcup now
--      Read; 400 Bad Request
--  11. (an empty line)
--      Read; nothing printed; the program stops
--  12. GET /ghcup
--      Not read; nothing printed
--
-- Where and how often it reads the clock:
-- getCurrentTime is inside the body of unless (null line), after getLine.
-- It runs once for each nonempty line, so ten times for lines 1-10.
-- It doesn't run for the empty line or line 12

-- Its actions that this input runs more than once, or never:
-- getLine runs 11 times, getCurrentTime and putStrLn run 10 times each,
-- and loop calls itself 10 times. The body of unless never runs for the
-- empty line. No action reads line 12. The 410 Gone branch is never used

-- (c) After running both programs. The lines where your prediction and the
--     run differ, and the lines where the two programs differ, each with
--     whether the request to the assistant decided it:

-- Neither program compiled initially. In assistant.hs, NominalDiffTime was missing 
-- from the Data.Time import. My console initially had a typo: utcDay instead of utctDay,
-- which I corrected in the submitted file. The assistant's compilation error was not caused by my prompt

-- I fixed the compilation errors in temporary copies and ran both programs.
-- After that, all my predictions for the assistant matched its actual output.
-- Both programs returned the same status codes on lines 1-10, but their full responses 
-- differed on lines 7, 8, and 10. My console includes an error reason after 400 Bad Request,
-- while the assistant's program doesn't. The prompt required HTTP status codes 
-- but didn't specify whether error reasons should be included

-- One more difference is that my console prints the final ghcup link after the empty line.
-- In this run it was created on 2026-10-17 and had two clicks. The assistant
-- doesn't print a final link summary, but the prompt didn't request one.
-- Other differences don't occur in requests-2.txt: my service expires links
-- by calendar day, while the assistant measures 30 times 24 hours from the
-- creation moment. It also lets an expired alias be created again, whereas
-- my handler treats an alias already in the store as a conflict

-- Which of your checks from 8.3(c) run on its program as it stands, and the
-- function, with its type, that its code would need for all of them:
-- None of my checks run unchanged on assistant.hs. First, the assistant's program doesn't compile because
-- NominalDiffTime isn't imported. After fixing the import, I could adapt checks 1-5 and 7
-- to use the assistant's pure function: handleRequest :: UTCTime -> String -> Store -> (String, Store)
-- These would test unknown aliases, creation, expiry, conflicts, and successful GET requests.
-- Date-boundary checks would require UTCTime values instead of Day values.
-- Check 6 could verify the 400 status code, but not the exact error reason, 
-- which the assistant's program doesn't provide

-- The two session checks would also need a function like:
-- `replay :: (r -> s -> (a, s)) -> [r] -> s -> ([a], s)`
-- However, adding just this function wouldn't make all 
-- nine original checks work without changes. 
-- They also depend on the course's `Day`, `Response`, 
-- `LinkRequest`, and `[Link]` types, as well as the `handle` 
-- and `respond` functions

-- What is not idiomatic Haskell, with a line of reason each:
-- - The assistant has two unused imports, addUTCTime and readMaybe;
--   they make the intended dependencies less clear.
-- - Its handler returns a String instead of a Response value, so callers
--   can't inspect the status without examining formatted output.
-- - handleRequest parses the line and applies the request in one function.
--   A parser returning Either String LinkRequest would separate invalid
--   input from the state transition, as in the lecture's approach.
-- Direct use of getLine and putStrLn is idiomatic for this small console
-- program. The missing NominalDiffTime import is a compile error, not a
-- matter of style; both points are discussed above

-- ===========================================================================
-- Bonus, +0.5 points, extra: the service over HTTP                      No AI
-- ===========================================================================

-- I have not used AI tools when solving this problem.

-- The server needs a web library, and this file must load without one. So
-- the server goes into a copy of this file, server.hs, which you submit
-- beside it. In server.hs:
--
--   1. Put these four lines at the very top, above the OPTIONS_GHC line.
--      They tell cabal which packages the file needs, and that the server
--      runs threads.
--
--        {- cabal:
--        build-depends: base, time, scotty, text, bytestring
--        ghc-options: -threaded
--        -}
--
--   2. Import the library qualified, since names such as get, put and text
--      would clash with yours. S.text and S.setHeader take a lazy Text, and
--      S.body gives a lazy ByteString:
--
--        import qualified Data.ByteString.Lazy.Char8 as B
--        import qualified Data.Text.Lazy as T
--        import qualified Web.Scotty as S
--
--   3. Write serve :: FilePath -> IO (), and add the mode
--      ["serve", store] -> serve store to main. serve answers on port 8080.
--      For each request, it reads the links from the file store, answers
--      with respond and today's date, and writes the links back.
--      Links and click counts must survive a restart with the same file.
--
-- Write links.txt with the files mode, then run the server with cabal,
-- which comes with GHC through GHCup:
--
--   cabal update                              once, for the package list
--   cabal run server.hs -- serve links.txt
--
-- The first run downloads and builds Scotty and the libraries it needs,
-- which takes several minutes. Then, in a second terminal,
--
--   curl -i -X PUT -d https://www.haskell.org/ghcup/ http://localhost:8080/up
--   curl -i http://localhost:8080/up
--
-- or open http://localhost:8080/up in a browser. Ctrl-C stops the server.
-- Scotty's documentation, with examples, is at
-- https://hackage.haskell.org/package/scotty.

-- Given: the status code of a response.
statusCode :: Response -> Int
statusCode Created        = 201
statusCode (Redirect _)   = 302
statusCode (BadRequest _) = 400
statusCode NotFound       = 404
statusCode Conflict       = 409
statusCode Gone           = 410

-- ===========================================================================
-- Given: the sample files, written by the files mode
-- ===========================================================================

-- For 8.4: a recorded log of five weeks.
log1 :: [String]
log1 =
  [ "2026-10-14 PUT /ghcup https://www.haskell.org/ghcup/"
  , "2026-10-14 GET /ghcup"
  , "2026-10-14 PUT /lyah https://learnyouahaskell.github.io/input-and-output.html"
  , "2026-10-15 GET /lyah"
  , "2026-10-15 GET /ghcpu"
  , "2026-10-15 PUT /ghcup https://ghcup.haskell.org/"
  , "2026-10-16 POST /time https://hackage.haskell.org/package/time"
  , "2026-10-16 PUT /time hackage.haskell.org/package/time"
  , "2026-10-16 PUT /time https://hackage.haskell.org/package/time"
  , "2026-10-19 GET /ghcup"
  , "2026-10-19 GET time"
  , "2026-11-10 GET /time"
  , "2026-11-12 GET /ghcup"
  , "2026-11-13 GET /ghcup"
  , "2026-11-13 PUT /ghcup https://www.haskell.org/ghcup/"
  , "2026-11-14 GET /lyah"
  ]

-- The same requests as typed at the console: no dates, and an empty line
-- at the end.
requests1 :: [String]
requests1 = map dropDate log1 ++ [""]
  where
    dropDate l = unwords (drop 1 (words l))

-- For 8.5.
requests2 :: [String]
requests2 =
  [ "PUT /ghcup https://www.haskell.org/ghcup/"
  , "GET /ghcup"
  , "GET /ghcup/"
  , "GET /ghcpu"
  , "PUT /ghcup https://ghcup.haskell.org/"
  , "GET /ghcup"
  , "PUT /lyah http://learnyouahaskell.com/"
  , "put /lyah https://learnyouahaskell.github.io/"
  , "GET /lyah"
  , "GET /ghcup now"
  , ""
  , "GET /ghcup"
  ]

writeSamples :: IO ()
writeSamples = do
  writeFile "log-1.txt" (unlines log1)
  writeFile "requests-1.txt" (unlines requests1)
  writeFile "requests-2.txt" (unlines requests2)
  writeFile "links.txt" (show someLinks)
  putStrLn "written: log-1.txt, requests-1.txt, requests-2.txt, links.txt"

-- ===========================================================================
-- The examples of the sheet, then your checks. Nothing here reads input.
-- Add lines as you like; the expected values are in the comments.
-- ===========================================================================

examples :: IO ()
examples = do
  let good = ["GET /ghcup", "PUT /ghcup https://www.haskell.org/ghcup/"]
      bad  = [ "POST /ghcup", "get /ghcup", "GET ghcup", "GET /", "GET /ghcup now"
             , "PUT /ghcup", "PUT /ghcup http://www.haskell.org/", "PUT /x https://"
             , "", "GET" ]
  putStrLn "-- 8.2"
  print (map parseLinkRequestDo good)
  -- [Just (Follow "ghcup"),Just (Create "ghcup" "https://www.haskell.org/ghcup/")]
  print (map parseLinkRequestDo (good ++ bad) == map parseLinkRequest (good ++ bad))
  -- True
  print (readLinkRequest "POST /ghcup")
  -- Left "no such method: POST"
  print (readLinkRequest "PUT /time hackage.haskell.org/package/time")
  -- Left "not an https address: hackage.haskell.org/package/time"
  print (readLog ["2026-10-14 GET /ghcup", "2026-11-31 GET /ghcup"])
  -- Left "line 2: no date: 2026-11-31"
  putStrLn "-- 8.3"
  print (handle (oct 31) (Follow "ghcup") [ghcupLink])
  -- (Gone,[Link {alias = "ghcup", target = "https://www.haskell.org/ghcup/", created = 2026-10-01, clicks = 0}])
  print (fst (respond (oct 5) "GET ghcup" [ghcupLink]))
  -- BadRequest "not a path: ghcup"
  print (replay (\x n -> (x * n, n + 1)) [10, 10, 10 :: Int] 1)
  -- ([10,20,30],4)
  putStrLn (show (length checks) ++ " checks, failing: " ++ show (failures checks))
  -- 7 checks, failing: []      (or more checks, and none failing)

main :: IO ()
main = do
  args <- getArgs
  case args of
    []                   -> examples
    ["files"]            -> writeSamples
    ["follow"]           -> followMain
    ["follow-bind"]      -> followBindMain
    ["console"]          -> console
    ["replay", inp, out] -> replayFile inp out
    _ -> putStrLn "usage: runghc <file> [files | follow | follow-bind | console | replay LOG OUT]"
