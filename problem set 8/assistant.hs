
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
