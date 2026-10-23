{-# LANGUAGE BangPatterns #-}

import Data.List (foldl')

nameStats :: [String] -> (Int, Int)
nameStats = foldl' step (0, 0)
  where
    step (!count, !longest) s =
      let !count'   = count + 1
          !longest' = max longest (length s)
      in (count', longest')
