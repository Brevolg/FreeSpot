{-# OPTIONS_GHC -Wall #-}
-- Topic 7. Problem set --- Haskell. Answer file.
--
-- Name:  Mariia Chegodaeva
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
--        -- foldl' (+) 0 [250, 1200]
--        -- = foldl' (+) 250 [1200]
--        -- = foldl' (+) 1450 []
--        -- = 1450
--
--   3. Every problem carries an AI use declaration. For a No AI problem,
--      leave the declaration in place. Problem 7.5 gives two choices: keep
--      the line that is true and delete the other. A missing declaration is
--      treated as a missing answer.
--   4. Rename the file after yourself, as problem-set-7-<Surname>.hs, and
--      make sure that it loads. Use GHC 9.10.3, the version GHCup
--      recommends. In a terminal, in the directory of the file, run
--
--        ghci problem-set-7-<Surname>.hs
--
--      and check that it loads without errors. The examples from the sheet
--      appear in this file as comments in the form GHCi shows them: the
--      expression after the prompt, and the expected value below it. Type
--      each at the prompt and compare. Running
--
--        runghc problem-set-7-<Surname>.hs
--
--      prints the values of the examples in order, but stops at the first
--      part that is still undefined. The stubs below are chosen so that the
--      file loads before you have written anything; replace them. Until you
--      do, -Wall warns about a few things on purpose: the definitions of
--      7.1 have no signatures, and NonEmpty is imported before 7.3 uses it.
--   5. Two rules apply throughout. No partial functions: every
--      function has an equation for every shape of its input, and no answer
--      calls head, tail or !!. The file loads: a part you have not finished
--      stays undefined, or in a comment.
--   6. Submit this file. If you used an assistant for problem 7.5(a), submit
--      transcript.md as well. It must contain the whole exchange, verbatim
--      and unedited.

module Main where

import Data.List.NonEmpty (NonEmpty (..))

-- ===========================================================================
-- Problem 7.1                                                         No AI
-- ===========================================================================

-- I have not used AI tools when solving this problem.

-- Given, without signatures. Leave them so.
countOf x xs = length (filter (== x) xs)
tag f xs     = zip xs (map f xs)
longest xs   = foldl' max 0 xs

-- (a) Accepted or refused, and why, for each signature in the order of the
--     sheet. They stay in this comment: some of them would stop the file
--     loading.
--
--   countOf :: (Int -> Int) -> [Int -> Int] -> Int
--   countOf :: Eq a => a -> [a] -> Integer
--   tag     :: (String -> Int) -> [String] -> [(Int, String)]
--   tag     :: (a -> a) -> [a] -> [(a, a)]
--   longest :: [Int] -> Int
--   longest :: [Bool] -> Bool
--
-- 1. Refused. countOf uses (==), which requires Eq for the element type. 
--    Functions of type Int -> Int don't have an Eq instance, so they can't be compared using (==)

-- 2. Refused. The Eq a constraint is correct, but length returns Int, not Integer.
--  The result type must be Int. Correct: countOf :: Eq a=> a -> [a] -> Int

-- 3. Refused. zip produces pairs in the order (original, transformed). 
--    Here the actual result is [(String, Int)], not [(Int, String)]

-- 4. Accepted. The function maps a -> a over [a] and  combines the original and transformed elements. 
--    Both elements of each pair have type a

-- 5. Accepted. Int supports both Ord (for max) and Num (for initial value 0)

-- 6. Refused. Bool has an Ord instance, so max works, but Bool has no Num instance. The initial value 0
--    requires Num, so this signature is invalid

-- (b) Given.
data Size = Small | Medium | Large

-- The number of functions of type (Size, Size) -> Size, and how you got it:
-- Size has 3 possible values. A pair (Size, Size) has 3 * 3 = 9 possible inputs.
-- For each input, the function can return one of 3 values. Therefore, there are 3^9 = 19683 total functions

-- Only those that GHC also accepts at (a, a) -> a. Add more stubs if you
-- need them, then explain why GHC refuses the others:
-- We can return either the first or the second component. GHC can't accept 
-- the other Size-specific functions at this polymorphic type 
-- because they would need to inspect or distinguish values of an arbitrary type a.
-- No constructors or equality operations are available for an arbitrary a
pick1 :: (a, a) -> a
pick1 (x, _)= x

pick2 :: (a, a) -> a
pick2 (_, y) = y

--

-- Every function of each type that always returns a value. Add more stubs
-- if there are more; if there is none, delete the stub and say why.
-- a -> b -> a
-- There is exactly one total function: return the first argument. 
-- The first argument is the only available value of type a
first1 :: a -> b -> a
first1 x _ = x

-- a -> Maybe a
-- There are exactly two total functions:
-- return Nothing or wrap the argument in Just

wrap1 :: a -> Maybe a
wrap1 _= Nothing

wrap2 :: a -> Maybe a
wrap2 x = Just x

-- Maybe a -> a
-- There is no total function of this type.
-- For Nothing, there is no value of type a available.
-- Returning undefined or using an incomplete pattern
-- match would violate the no-partial-functions rule

-- (a -> b) -> a -> b
-- There is exactly one total function:
-- apply the supplied function to the supplied argument.
-- This is the only way to obtain a value of arbitrary type b

apply1 :: (a -> b) -> a -> b
apply1 f x = f x

-- (c) Missing, redundant, unused or none, whether GHC accepts each as
--     written, and the corrected signature. Correct the signatures in place.
--     Two are in a comment, since as written they stop the file loading;
--     uncomment them once their signatures are right.

withProgramme :: Eq a => a -> [a] -> [a]
withProgramme p ms = filter (\m -> m == p) ms

busiest :: Ord a => a -> [a] -> a
busiest start xs = foldl' max start xs

scale :: Num a => a -> [a] -> [a]
scale k xs = map (* k) xs

labels :: Show a => [a] -> [String]
labels xs = map show xs

within :: Ord a => a -> a -> a -> Bool
within lo hi x = lo <= x && x <= hi

-- withProgramme:
-- Missing constraint: Eq a.
-- GHC refuses the original signature because (==)
-- requires equality comparison of values of type a.
-- Corrected: Eq a => a -> [a] -> [a]

-- busiest:
-- Redundant constraint: Eq a.
-- GHC accepts the original signature because Ord
-- already implies Eq. The separate Eq constraint
-- is unnecessary. max only requires Ord.
-- Corrected: Ord a => a -> [a] -> a

-- scale:
-- Missing constraint: Num a.
-- GHC refuses the original signature because (*)
-- requires its operands to be instances of Num.
-- Corrected: Num a => a -> [a] -> [a]

-- labels:
-- None. The signature is already correct.
-- GHC accepts it because show requires Show a
-- and returns a String for each element.
-- Corrected: Show a => [a] -> [String]

-- within:
-- Unused constraint: Num a.
-- GHC accepts the original signature, but only
-- ordering comparisons (<=) are used.
-- These require Ord a, not Num a.
-- Corrected: Ord a => a -> a -> a -> Bool

-- ===========================================================================
-- Problem 7.2                                                         No AI
-- ===========================================================================

-- I have not used AI tools when solving this problem.

-- Given.
power :: [Int]
power = [0, 300, 0, 0, 450, 500, 0, 200]

cycles :: [Int] -> Int
cycles ws = go 0 False ws
  where
    go n _       []       = n
    go n running (x : xs)
      | x > 0 && not running = go (n + 1) True xs
      | otherwise            = go n (x > 0) xs

-- ghci> cycles power
-- 3
-- ghci> cycles []
-- 0

-- (a) With a left fold and no explicit recursion.
cyclesFold :: [Int] -> Int
cyclesFold ws = fst (foldl' step (0, False) ws)
  where
    step (n, running) x
      | x > 0 && not running = (n + 1, True)
      | otherwise  = (n, x > 0)

-- ghci> cyclesFold power
-- 3
-- ghci> cyclesFold []
-- 0

-- (b) The trace of your version on [0, 300, 0], one line per element, and
--     which guard of go each line corresponds to:
-- foldl' ... [0, 300, 0]

-- foldl' step (0, False) [0, 300, 0] 
-- = foldl' step (0, False) [300, 0]   -- otherwise guard
-- = foldl' step (1, True) [0]         -- first guard
-- = foldl' step (1, False) []         -- otherwise guard
-- = (1, False)
--
-- fst (1, False) = 1

-- ===========================================================================
-- Problem 7.3                                                         No AI
-- ===========================================================================

-- I have not used AI tools when solving this problem.

-- Given.
data Machine = Machine
  { busy       :: Bool
  , steps      :: [String]   -- "wash 40", "rinse", "spin 1200"
  , current    :: Int        -- the index of the running step
  , outOfOrder :: Bool
  , faults     :: [String]   -- "no water", "door", "E17"
  }

-- (a) Three sample values that describe no real machine, and what is
--     wrong with each:
impossible1, impossible2, impossible3 :: Machine
impossible1 = Machine True [] 0 False []
impossible2 = Machine False ["rinse"] 0 True []
impossible3 = Machine True ["wash 40"] 5 False []

-- impossible1:
-- The machine is busy, but it has no steps to run
-- impossible2:
-- The machine is out of order, but it has no faults
-- impossible3:
-- The current step index is outside the program

-- (b) Your types go here, with State for a machine's state and Fault for a
--     fault. Then the slogan, and the two flaws of the old record:
-- New types
data Temperature = Cold | Warm | Hot
  deriving (Show, Eq)

data Step 
  = Wash Temperature
  | Rinse 
  | Spin Int
  deriving (Show, Eq)

data Fault
  = NoWater
  | DoorJammed
  | ErrorCode Int 
  deriving (Show, Eq)

data State
  = Free
  | Running (NonEmpty Step)
  | OutOfOrder (NonEmpty Fault)
  deriving (Show, Eq)

-- Slogan:
-- Make illegal states unrepresentable
-- Flaw 1: Boolean blindness.
-- Separate Bool flags do not express the alternatives
-- Free, Running and OutOfOrder as distinct constructors,
-- and allow contradictory combinations.

-- Flaw 2: Stringly typed.
-- Steps and faults are arbitrary strings, so misspelled
-- or meaningless descriptions are accepted.

-- (c) and (d): uncomment the signatures once your types exist.

advance :: State -> State
advance Free = Free
advance (OutOfOrder fs) = OutOfOrder fs
advance (Running (_ :| [])) = Free
advance (Running (_ :| (x : xs))) = Running (x :| xs)

faultReport :: NonEmpty Fault -> String
faultReport (f :| fs) =
  faultName f ++
  if null fs
    then ""
    else " (and " ++ show (length fs) ++ " more)"
  where
    faultName NoWater = "no water"
    faultName DoorJammed = "door jammed"
    faultName (ErrorCode n) = "error " ++ show n

-- ghci> faultReport (DoorJammed :| [])
-- "door jammed"
-- ghci> faultReport (DoorJammed :| [NoWater, ErrorCode 17])
-- "door jammed (and 2 more)"

-- ===========================================================================
-- Problem 7.4                                                         No AI
-- ===========================================================================

-- AI use declaration.
-- I have not used AI tools when solving this problem.

-- Given.
newtype Version = Version [Int]

-- (a) Replace the stub with your equation, or equations.
instance Eq Version where
  Version xs == Version ys = normalize xs == normalize ys
    where
      normalize = reverse . dropWhile (== 0) . reverse

-- ghci> Version [2, 1] == Version [2, 1, 0]
-- True
-- ghci> Version [2, 1] == Version [2, 1, 1]
-- False

-- (b) Why your == is symmetric:
-- Both versions are normalized by removing trailing zeros.
-- Since list equality is symmetric, comparing the normalized
-- lists gives the same result regardless of their order

-- (c) Why your == is transitive:
-- If x == y and y == z, their normalized lists are equal.
-- Since list equality is transitive, the normalized lists
-- of x and z are also equal, so x == z

-- ===========================================================================
-- Problem 7.5                                   (a) AI allowed, then No AI
-- ===========================================================================

-- AI use declaration. Keep one line and delete the other. Here the second
-- line is usually the true one.
-- I have used AI (ChatGPT free) in part (a) of this problem, in accordance with
-- the course rules and the problem statement.

-- Given: the description and the six examples of the API, as on the sheet.
--
-- Each reservation has an id and a customer. It is pending, with the
-- requested time; confirmed, with a machine and one or more consecutive time
-- slots; cancelled, either by the staff, who always give a reason, or by the
-- customer, who is refunded in full when cancelling at least two hours ahead
-- and not at all otherwise; or completed, with the machine and the length of
-- the cycle in minutes.
--
-- {"id": 7, "customer": "anna", "status": "pending",
--  "requested": "2026-10-14T18:00"}
-- {"id": 8, "customer": "boris", "status": "confirmed", "machine": "W2",
--  "slots": ["2026-10-14T19:00", "2026-10-14T19:30"]}
-- {"id": 9, "customer": "anna", "status": "cancelled",
--  "cancelledBy": "staff", "reason": "machine out of order"}
-- {"id": 10, "customer": "dmitry", "status": "completed",
--  "machine": "W1", "minutes": 52}
-- {"id": 11, "customer": "boris", "status": "cancelled",
--  "cancelledBy": "customer", "refunded": true}
-- {"id": 12, "customer": "elena", "status": "cancelled",
--  "cancelledBy": "customer", "refunded": false}

-- (a) The assistant's answer, or your own if you used no assistant. Add the
--     suffix Ai to every type, constructor, field and function name in it,
--     so that it can live in this file beside your own model: Reservation
--     becomes ReservationAi, machineLoad becomes machineLoadAi. If you used
--     an assistant, the exchange itself goes into transcript.md. If the
--     recorded answer does not load, keep it in a comment and note the
--     error in (b).

data ReservationAi = ReservationAi
  { reservationIdAi :: Int
  , customerAi      :: String
  , statusAi        :: StatusAi
  } deriving (Show)

data StatusAi
  = PendingAi String
  | ConfirmedAi String [String]
  | CancelledAi CancellationAi
  | CompletedAi String Int
  deriving (Show)

data CancellationAi
  = StaffAi String
  | CustomerAi Bool
  deriving (Show)

machineLoadAi :: String -> [ReservationAi] -> Int
machineLoadAi machine reservations =
  sum [minutes |
       ReservationAi _ _ (CompletedAi m minutes) <- reservations,
       m == machine]

staffReasonsAi :: [ReservationAi] -> [String]
staffReasonsAi reservations =
  [reason |
   ReservationAi _ _ (CancelledAi (StaffAi reason)) <- reservations]

-- The six examples as values of the assistant's types:
examplesAi :: [ReservationAi]
examplesAi =
  [ ReservationAi 7 "anna"
      (PendingAi "2026-10-14T18:00")

  , ReservationAi 8 "boris"
      (ConfirmedAi "W2"
        ["2026-10-14T19:00", "2026-10-14T19:30"])

  , ReservationAi 9 "anna"
      (CancelledAi (StaffAi "machine out of order"))

  , ReservationAi 10 "dmitry"
      (CompletedAi "W1" 52)

  , ReservationAi 11 "boris"
      (CancelledAi (CustomerAi True))

  , ReservationAi 12 "elena"
      (CancelledAi (CustomerAi False))
  ]

-- (b) Every impossible value its types allow, with an example value for
--     each, and what else is not idiomatic, with a line of reason each:
-- 1. ConfirmedAi "W2" []
-- A confirmed reservation must have at least one slot

-- 2. ConfirmedAi "W2"
--      ["2026-10-14T19:00", "2026-10-14T21:00"]
-- The slots are not consecutive

-- 3. CompletedAi "W1" (-5)
-- A completed cycle can't have a negative duration

-- 4. CompletedAi "W1" 0
-- A completed cycle can't have zero duration

-- 5. CancelledAi (StaffAi "")
-- Staff must provide a non-empty reason

-- 6. ReservationAi 7 ""
--      (PendingAi "2026-10-14T18:00")
-- A reservation can't have an empty customer name

-- 7. CompletedAi "" 52
-- A completed reservation must have a valid machine

-- 8. PendingAi "not a date"
-- A requested time must be a valid timestamp

-- 9. ConfirmedAi "W2"
--      ["invalid time"]
-- Confirmed slots must contain valid times

-- 10. ReservationAi (-1) "anna" (PendingAi "2026-10-14T18:00")
-- A reservation identifier can't be negative

-- 11. ConfirmedAi "W2" ["2026-10-14T19:30", "2026-10-14T19:00"]
-- The slots are in reverse chronological order

-- 12. ConfirmedAi "W2" ["2026-10-14T19:00", "2026-10-14T19:00"]
-- The same slot appears twice; the slots are not consecutive intervals

-- 13. ConfirmedAi "" ["2026-10-14T19:00"]
-- A confirmed reservation must name a machine

-- 14. ReservationAi 7 "anna" (PendingAi "")
-- A pending reservation must have a requested time

-- Other non-idiomatic choices:

-- 1. String is used for timestamps.
-- It does not distinguish timestamps from ordinary text

-- 2. String is used for machines and customers.
-- Different domain concepts have the same type

-- 3. [String] is used for confirmed slots.
-- It allows an empty list and non-consecutive slots

-- 4. Int is used for cycle duration.
-- It allows zero and negative values

-- 5. Boolean blindness.
-- CustomerAi True and CustomerAi False do not name
-- the meaning of the two alternatives explicitly

-- 6. Primitive obsession.
-- Reservation identifiers and cycle durations use Int.
-- These are different domain concepts but are represented
-- by the same primitive type. Dedicated types would
-- make accidental misuse harder

-- 7. The refund rule is not encoded in the AI model.
-- CustomerAi True/False records only the refund result,
-- without the cancellation timing. The two-hour rule
-- therefore can't be checked from the stored data.

-- (c) Your model, the two functions on it, and the six examples as its
--     values. Uncomment, and adapt the types to your model.

-- A positive number. The constructors can't represent zero or negatives
data Positive
  = One
  | Next Positive
  deriving (Show, Eq)

-- Construct a positive number for the sample data. This helper clamps
-- non-positive inputs to One; all six examples use positive inputs
positive :: Int -> Positive
positive n
  | n <= 1    = One
  | otherwise = Next (positive (n - 1))

positiveToInt :: Positive -> Int
positiveToInt One = 1
positiveToInt (Next n) = 1 + positiveToInt n

-- Non-empty text
data NonEmptyText = Text Char String
  deriving (Show, Eq)

toString :: NonEmptyText -> String
toString (Text c cs) = c : cs

-- A machine has a non-empty name.
newtype BookingMachine = BookingMachine NonEmptyText
  deriving (Show, Eq)

-- Any integer denotes a valid minute relative to 2026-10-14 00:00.
-- Negative values denote earlier dates; this is not an invalid timestamp
newtype Moment = Moment Integer
  deriving (Show, Eq)

-- Every integer denotes a valid half-hour slot on the timeline.
-- A start slot plus a positive slot count denotes consecutive slots
newtype Slot = Slot Integer
  deriving (Show, Eq)

-- Customer cancellation timing determines the refund
data CustomerTiming
  = AtLeastTwoHours
  | LessThanTwoHours
  deriving (Show, Eq)

data Cancellation
  = StaffCancelled NonEmptyText
  | CustomerCancelled CustomerTiming
  deriving (Show)

data Status
  = Pending Moment
  | Confirmed BookingMachine Slot Positive
  | Cancelled Cancellation
  | Completed BookingMachine Positive
  deriving (Show)

data Reservation =
  Reservation Positive NonEmptyText Status
  deriving (Show)

-- Total minutes of completed cycles on a given machine
machineLoad :: BookingMachine -> [Reservation] -> Int
machineLoad machine reservations =
  sum [positiveToInt minutes |
       Reservation _ _ (Completed m minutes) <- reservations,
       m == machine]

-- Reasons for all cancellations by staff
staffReasons :: [Reservation] -> [String]
staffReasons reservations =
  [toString reason |
   Reservation _ _ (Cancelled (StaffCancelled reason))
     <- reservations]

-- The six examples as values of my types.
-- Their timestamps are expressed on a whole-minute timeline, so arbitrary
-- malformed timestamp strings are not representable. Slot 38 means 19:00
-- on the reference date, and the following slot means 19:30.
-- The constructor NonEmptyText excludes empty text but can't validate
-- domain-specific naming rules without smart constructors

examples :: [Reservation]
examples =
  [ Reservation (positive 7) (Text 'a' "nna")
      (Pending (Moment 1080))

  , Reservation (positive 8) (Text 'b' "oris")
      (Confirmed
        (BookingMachine (Text 'W' "2"))
        (Slot 38)
        (positive 2))

  , Reservation (positive 9) (Text 'a' "nna")
      (Cancelled
        (StaffCancelled (Text 'm' "achine out of order")))

  , Reservation (positive 10) (Text 'd' "mitry")
      (Completed
        (BookingMachine (Text 'W' "1"))
        (positive 52))

  , Reservation (positive 11) (Text 'b' "oris")
      (Cancelled (CustomerCancelled AtLeastTwoHours))

  , Reservation (positive 12) (Text 'e' "lena")
      (Cancelled (CustomerCancelled LessThanTwoHours))
  ]

-- Refund rule.
isRefunded :: CustomerTiming -> Bool
isRefunded AtLeastTwoHours = True
isRefunded LessThanTwoHours = False

-- ghci> machineLoadAi "W1" examplesAi
-- 52

-- ghci> staffReasonsAi examplesAi
-- ["machine out of order"]

-- ghci> machineLoad (BookingMachine (Text 'W' "1")) examples
-- 52

-- ghci> staffReasons examples
-- ["machine out of order"]

-- One value from (b), written in the assistant's types, and what its
-- functions give on it:

badExampleAi :: ReservationAi
badExampleAi =
  ReservationAi 99 "anna" (CompletedAi "W1" (-5))

-- ghci> machineLoadAi "W1" [badExampleAi]
-- -5

-- ghci> staffReasonsAi [badExampleAi]
-- []

-- The model allows a negative cycle duration. machineLoadAi adds this negative duration to the total.
-- staffReasonsAi returns an empty list because the reservation is completed, not cancelled by staff

-- ===========================================================================
-- Running the file prints the examples in order. It stops at the first
-- part that is still undefined; that is expected until you are done.
-- Add lines for 7.3 and 7.5 once those parts compile.
-- ===========================================================================

main :: IO ()
main = do
  print (countOf "W1" ["W1", "W2", "W1"], longest [3, 9, 4 :: Int])  -- (2,9)
  print (tag even [1, 2 :: Int])                  -- [(1,False),(2,True)]
  print (busiest 0 [3, 9, 4 :: Int], labels [3, 9 :: Int])     -- (9,["3","9"])
  print (within 1 5 (3 :: Int))                   -- True
  print (cycles power, cycles [])                 -- (3,0)
  print (cyclesFold power, cyclesFold [])         -- (3,0)
  print (Version [2, 1] == Version [2, 1, 0])     -- True
  print (Version [2, 1] == Version [2, 1, 1])     -- False
  print (pick1 (1 :: Int, 2), first1 'x' True)
  print (advance (Running (Rinse :| [Spin 1200])))
  print (advance (Running (Rinse :| [])))
  print (faultReport (DoorJammed :| []))
  print (faultReport (DoorJammed :| [NoWater, ErrorCode 17]))
  print (machineLoadAi "W1" examplesAi)
  print (staffReasonsAi examplesAi)
  print (machineLoad (BookingMachine (Text 'W' "1")) examples)
  print (staffReasons examples)
  print (machineLoadAi "W1" [badExampleAi])
  print (staffReasonsAi [badExampleAi])
