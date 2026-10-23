# Write Haskell Link Shortener

**User:** Anonymous  
**Created:** 10/17/2026 13:36:54  
**Updated:** 10/17/2026 13:37:16  
**Exported:** 10/17/2026 13:37:44  
 

## Prompt:
17.10.2026, 13:37:04

Write a Haskell console program for a link shortener. It reads one request per line from standard
input. PUT /alias https://... makes a short link, and the alias must be new. GET /alias redi-
rects to the address and counts a click. A link expires 30 days after it is made. Print one response
line per request, with its HTTP status code. Stop at an empty line.

## Response:
17.10.2026, 13:37:06

Here’s a complete Haskell console program that processes one request per line, stores aliases in memory, counts clicks, and expires links 30 days after creation.

### `Main.hs`

```haskell

module Main where

import Control.Monad (unless)
import Data.List (isPrefixOf)
import qualified Data.Map.Strict as Map
import Data.Time
    ( UTCTime, addUTCTime, getCurrentTime, diffUTCTime )
import Text.Read (readMaybe)

data Link = Link
    { address  :: String
    , created  :: UTCTime
    , clicks   :: Int
    } deriving (Show)

type Store = Map.Map String Link

expirySeconds :: NominalDiffTime
expirySeconds = 30 * 24 * 60 * 60

handleRequest :: UTCTime -> String -> Store -> (String, Store)
handleRequest now request store =
    case words request of
        ["PUT", path, url]
            | not ("/" `isPrefixOf` path) ->
                ("400 Bad Request", store)
            | not (validUrl url) ->
                ("400 Bad Request", store)
            | otherwise ->
                let alias = drop 1 path
                in if null alias
                   then ("400 Bad Request", store)
                   else case Map.lookup alias store of
                       Just link
                           | not (expired now link) ->
                               ("409 Conflict", store)
                       _ ->
                           let link = Link url now 0
                           in ("201 Created", Map.insert alias link store)

        ["GET", path]
            | not ("/" `isPrefixOf` path) ->
                ("400 Bad Request", store)
            | otherwise ->
                let alias = drop 1 path
                in case Map.lookup alias store of
                    Nothing -> ("404 Not Found", store)
                    Just link
                        | expired now link ->
                            ("410 Gone", store)
                        | otherwise ->
                            let updated = link
                                    { clicks = clicks link + 1 }
                            in ("302 Found: " ++ address link,
                                Map.insert alias updated store)

        _ -> ("400 Bad Request", store)

validUrl :: String -> Bool
validUrl url =
    "https://" `isPrefixOf` url && length url > 8

expired :: UTCTime -> Link -> Bool
expired now link =
    diffUTCTime now (created link) >= expirySeconds

main :: IO ()
main = loop Map.empty
  where
    loop :: Store -> IO ()
    loop store = do
        line <- getLine
        unless (null line) $ do
            now <- getCurrentTime
            let (response, newStore) =
                    handleRequest now line store
            putStrLn response
            loop newStore
```

### How it works

- `PUT /alias https://example.com` - creates a new short link and returns `201 Created`\.
- `PUT` with an existing, unexpired alias - returns `409 Conflict`\.
- `GET /alias` - returns `302 Found` with the destination and increments the click counter.
- `GET` for an unknown alias - returns `404 Not Found`\.
- `GET` for an expired link - returns `410 Gone`\.
- Invalid requests - return `400 Bad Request`\.
- Links expire after 30 days, measured from creation.
- An empty input line terminates the program.

### Example

Input\:

```text
PUT /docs https://example.com/docs
GET /docs
PUT /docs https://example.org
GET /missing
```

Possible output\:

```text
201 Created
302 Found: https://example.com/docs
409 Conflict
404 Not Found
```

### Run it

Save the program as `Main.hs`, then run\:

```bash
ghc Main.hs -o shortener
./shortener
```

**Note\:** This is a console simulation, not a real HTTP server. It models HTTP status codes in its output, keeps links in memory, and uses the system clock. Data is lost when the program exits. The click counter is maintained internally but is not displayed.



---
Powered by [ChatGPT Exporter](https://www.chatgptexporter.com)