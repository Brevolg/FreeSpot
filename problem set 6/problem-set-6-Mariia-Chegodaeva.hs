{-# OPTIONS_GHC -Wall #-}
-- Topic 6. Problem set --- Haskell. Answer file.
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
--      code. A trace or an explanation is written in a comment, under the
--      marker for its part. A trace is written one step per line, as in the
--      lecture:
--
--        -- totalWeight [250, 1200]
--        -- = 250 + totalWeight [1200]
--        -- = 250 + (1200 + totalWeight [])
--        -- = 250 + (1200 + 0)
--        -- = 1450
--
--   3. Every problem carries an AI use declaration. For a No AI problem,
--      leave the declaration in place. Problem 6.5 gives two choices: keep
--      the line that is true and delete the other. A missing declaration is
--      treated as a missing answer.
--   4. Rename the file after yourself, as problem-set-6-<Surname>.hs, and
--      make sure that it loads. Use GHC 9.10.3, the version GHCup
--      recommends. In a terminal, in the directory of the file, run
--
--        ghci problem-set-6-<Surname>.hs
--
--      and check that it loads without errors. The examples from the sheet
--      appear in this file as comments in the form GHCi shows them: the
--      expression after the prompt, and the expected value below it. Type
--      each at the prompt and compare. Running
--
--        runghc problem-set-6-<Surname>.hs
--
--      prints the values of all the examples in order, but stops at the
--      first part that is still undefined. A file that does not load can
--      only be marked from what can be read, and that is less. The stubs
--      below are chosen so that the file loads before you have written
--      anything; replace them.
--   5. Two rules from the lecture apply throughout. No partial functions:
--      every function has an equation for every shape of its input, and no
--      answer calls head, tail or !!; the -Wall at the top warns you about
--      the first two. The file loads: a part you have not finished stays
--      undefined.
--   6. Submit this file. If you used an assistant for problem 6.5(a), submit
--      transcript.md as well. It must contain the whole exchange, verbatim
--      and unedited.

module Main where

-- Given, for the whole sheet.
rides :: [Int]
rides = [12, 45, 8, 61, 30]

data Station = Station String Int          -- name, docks

stations :: [Station]
stations = [Station "Park" 12, Station "Campus" 20, Station "Market" 8]

docks :: Station -> Int
docks (Station _ d) = d

-- ===========================================================================
-- Problem 6.1 (Rides, by hand)                                        No AI
-- ===========================================================================

-- I have not used AI tools when solving this problem.

-- (a)
overtime :: Int -> [Int] -> Int
overtime _ [] = 0
overtime limit (x:xs)
  | x > limit = (x - limit) + overtime limit xs
  | otherwise = overtime limit xs

-- ghci> overtime 30 [12, 45, 8, 61, 30]
-- 46
-- ghci> overtime 60 [12, 45]
-- 0

-- (b)
longRides :: Int -> [Int] -> [Int]
longRides _ [] = []
longRides limit (x:xs)
  | x > limit = x : longRides limit xs
  | otherwise = longRides limit xs

-- ghci> longRides 30 [12, 45, 8, 61, 30]
-- [45,61]
-- ghci> longRides 100 [12, 45, 8, 61, 30]
-- []

-- (c)
splitAtLimit :: Int -> [Int] -> ([Int], [Int])
splitAtLimit _ [] = ([], [])
splitAtLimit limit (x:xs)
  | x <= limit = (x : short, long)
  | otherwise = (short, x : long)
  where
    (short, long) = splitAtLimit limit xs

-- ghci> splitAtLimit 30 [12, 45, 8, 61, 30]
-- ([12,8,30],[45,61])
-- ghci> splitAtLimit 30 []
-- ([],[])

-- (d) The trace of overtime 30 [45, 8], one step per line:
-- overtime 30 [45, 8]
-- = (45 - 30) + overtime 30 [8]
-- = 15 + overtime 30 [8]
-- = 15 + overtime 30 []
-- = 15 + 0
-- = 15

-- ===========================================================================
-- Problem 6.2 (Three ways to choose)                                  No AI
-- ===========================================================================

-- I have not used AI tools when solving this problem.

-- Given.
cost :: Bool -> Int -> Int
cost night minutes
  | minutes <= 15 = 0
  | minutes <= 30 = 50 * factor
  | otherwise     = (50 + 3 * (minutes - 30)) * factor
  where
    factor = if night then 2 else 1

-- ghci> cost False 10
-- 0
-- ghci> cost False 40
-- 80
-- ghci> cost True 40
-- 160

-- (a) The same function, as a case on the pair (night, minutes).
cost2 :: Bool -> Int -> Int
cost2 night minutes =
  case (night, minutes) of
    (False, m)
      | m <= 15 -> 0
      | m <= 30 -> 50
      | otherwise -> 50 + 3 * (m - 30)
    (True, m)
      | m <= 15 -> 0
      | m <= 30 -> 50 * 2
      | otherwise -> (50 + 3 * (m - 30)) * 2


-- (b) The same function, with if-then-else only.
cost3 :: Bool -> Int -> Int
cost3 night minutes = 
  if minutes <= 15 then 0
  else if minutes <= 30 then 50 * factor
  else (50 + 3 * (minutes - 30)) * factor 
  where 
    factor = if night then 2 else 1

-- What the where still saves:
-- It defines the night multiplier once, avoiding duplication in the two paid branches

-- (c) The flaw, and what a better type would say:
-- Boolean blindness: Bool doesn't explain what True and False mean;
-- a domain-specific type with Day and Night alternatives would make 
-- the ride's time category explicit

-- ===========================================================================
-- Problem 6.3 (Types by hand)                                         No AI
-- ===========================================================================

-- I have not used AI tools when solving this problem.

-- (a) The four definitions, given without signatures. Add a signature above
--     each; -Wall warns about the missing ones until you do. Then say, in a
--     comment under each, how the type of the body decides it.

busy :: Bool
busy = length rides > 3
-- length rides :: Int; comparing it with 3 using (>) gives Bool

perDock :: Fractional a => Station -> a
perDock s = fromIntegral (docks s) / 2
-- docks requires s :: Station and returns Int; fromIntegral converts
-- that Int to a number type a, and (/) requires Fractional a

labels :: [String]
labels = [n ++ "!" | Station n _ <- stations]
-- n :: String, so n ++ "!" :: String; the comprehension gives [String]

total :: Int
total = sum rides + length rides
-- rides :: [Int], so sum rides :: Int; length rides :: Int too,
-- and adding two Int values gives Int

-- (b) Which of the two is refused, and the "what" part of GHC's message.
--     They stay in this comment: one of them would stop the file loading.
--
--       sum rides / 2 is refused:
--       "No instance for (Fractional Int) arising from a use of '/'".
--       sum rides :: Int fixes the operands of (/) to Int
--       but Int has no Fractional instance
-- 
--       length rides + 1 is accepted and has type Int:
--       length rides :: Int, so 1 is also used as an Int
--

-- ===========================================================================
-- Problem 6.4 (Minutes are not rubles)                                No AI
-- ===========================================================================

-- I have not used AI tools when solving this problem.

-- Given. The mistake is in refund: a fare goes in where a duration was
-- meant. Part (a) is answered by changing these lines in place.
newtype Minutes = Minutes Int
newtype Rubles  = Rubles Int

fare :: Minutes -> Rubles
fare (Minutes m)
  | m <= 30   =  Rubles 50
  | otherwise = Rubles (50 + 3 * (m - 30))

refund :: Minutes -> Minutes -> Rubles
refund planned ridden =
  case (fare planned, fare ridden) of
    (Rubles p, Rubles r) -> Rubles (p - r)

-- Error Code
-- refund planned ridden =
--   case (fare planned, fare (fare ridden)) of
--    (Rubles p, Rubles r) -> Rubles (p - r)

-- ghci> refund 60 20
-- 30, and 90 was meant.
-- Once Minutes and Rubles are newtypes, the example reads
-- ghci> refund (Minutes 60) (Minutes 20)
-- and GHCi cannot show a Rubles until next week; check the number inside
-- with a pattern, or compare with fare (Minutes 60) and fare (Minutes 20).

-- (a) GHC's message for the mistaken line, pasted here before the fix:
-- problem-set-6-Mariia-Chegodaeva.hs:233:29: error: [GHC-83865]
--   • Couldn't match expected type ‘Minutes’ with actual type ‘Rubles’
--   • In the first argument of ‘fare’, namely ‘(fare ridden)’
--     In the expression: fare (fare ridden)
--     In the expression: (fare planned, fare (fare ridden))
--     |
-- 233 |   case (fare planned, fare (fare ridden)) of
--     |                             ^^^^^^^^^^^



-- ghci> case refund (Minutes 60) (Minutes 20) of Rubles n -> n
-- 90

-- (b)
data Ride = Ride String Minutes

toPair :: Ride -> (String, Int)
toPair (Ride station (Minutes m)) = (station, m)

fromPair :: (String, Int) -> Ride
fromPair (station, m) = Ride station (Minutes m)

-- ghci> toPair (fromPair ("Park", 25))
-- ("Park",25)

-- fromPair (toPair r) is r for every ride, because:
-- for r = Ride station (Minutes m), toPair extracts (station, m),
-- and fromPair rebuilds Ride station (Minutes m)

-- toPair (fromPair p) is p for every pair, because:
-- for p = (station, m), fromPair builds Ride station (Minutes m),
-- and toPair extracts the original (station, m)

-- ===========================================================================
-- Problem 6.5 (The busiest station, audited)    (a) AI allowed, then No AI
-- ===========================================================================

-- AI use declaration. Keep one line and delete the other. Here the second
-- line is usually the true one.
-- I have used AI (ChatGPT Free, GPT-5.6) in part (a) of this problem, in accordance with
-- the course rules and the problem statement.

-- Given.
counts :: [(String, Int)]
counts = [("Park", 14), ("Campus", 27), ("Market", 9)]

-- (a) The assistant's function, or your own if you used no assistant,
--     renamed so that both can live in this file. If it needs an import,
--     the import goes at the top of the file, under `module Main where`.
--     If you used an assistant, the exchange itself goes into
--     transcript.md. If the recorded function does not load, keep it in a
--     comment, note the error in (b), and leave the stub.
busiestAi :: [(String, Int)] -> String
busiestAi = fst . foldl1 (\(name1, count1) (name2, count2) ->
    if count1 >= count2
        then (name1, count1)
        else (name2, count2))

-- (b) The functions in the recorded answer that the lecture did not
--     introduce, and the partial ones:
--      foldl1 and (.) were not introduced in lecture;
--     Lambda syntax (\...) was not introduced either;
--     fst was introduced and is total on pairs;
--     foldl1 is partial on []; therefore busiestAi is also partial.
--     The comparison lambda and (>=) are total on these input types

busiest :: [(String, Int)] -> String
busiest [] = ""
busiest ((name, count):rest) = go (name, count) rest
  where
    go (bestName, _) [] = bestName
    go (bestName, bestCount) ((nextName, nextCount):xs)
      | nextCount > bestCount = go (nextName, nextCount) xs
      | otherwise = go (bestName, bestCount) xs


-- ghci> busiest counts
-- "Campus"
-- ghci> busiest [("Park", 14)]
-- "Park"

-- (c) What each version does on the empty list, and which of the two ways
--     a type could say more fits busiest, and why:
--     ghci> busiestAi counts
--     "Campus"
--     ghci> busiestAi [("Park", 14)]
--     "Park"
--     ghci> busiestAi []
--     *** Exception: Prelude.foldl1: empty list
--     ghci> busiest []
--     ""
--     busiest returns an empty string as a placeholder, not a station name.
--     An optional result (Maybe String) fits busiest because [] is a valid
--     input list, but there is no station name to return for an empty list;
--     returning "" would only be a placeholder

-- ===========================================================================
-- Running the file prints the examples in order. It stops at the first
-- part that is still undefined; that is expected until you are done.
-- ===========================================================================

main :: IO ()
main = do
  print (overtime 30 [12, 45, 8, 61, 30])     -- 46
  print (overtime 60 [12, 45])                -- 0
  print (longRides 30 [12, 45, 8, 61, 30])    -- [45,61]
  print (longRides 100 [12, 45, 8, 61, 30])   -- []
  print (splitAtLimit 30 [12, 45, 8, 61, 30]) -- ([12,8,30],[45,61])
  print (splitAtLimit 30 [])                  -- ([],[])
  print (cost False 10, cost False 40, cost True 40)     -- (0,80,160)
  print (cost2 False 10, cost2 False 40, cost2 True 40)  -- the same
  print (cost3 False 10, cost3 False 40, cost3 True 40)  -- the same
  print (busy, labels, total)                 -- (True,["Park!","Campus!","Market!"],161)
  print (toPair (fromPair ("Park", 25)))      -- ("Park",25)
  print (busiest counts)                      -- "Campus"
  print (busiest [("Park", 14)])              -- "Park"
  print (busiestAi counts)                    -- compare with the line above
