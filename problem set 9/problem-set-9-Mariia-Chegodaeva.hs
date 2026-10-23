{-# LANGUAGE BangPatterns #-}
{-# OPTIONS_GHC -Wall #-}
-- Programming Paradigms, Fall 2026. Topic 9.
-- Original course exercises following Nikolai Kudasov's lectures 7--9.
-- The reusable-list progression follows his 2024/2025 problem sets.
-- The scrolling world adapts his iu-haskell Lab 5 (Summer 2025).
-- Overlay adapts the sorted-pair merge from his 2025 problem set 9.
-- Progressive search is an original exercise from general programming knowledge.
-- Expr and replace extend the lecture's expression syntax.
-- Its two passes illustrate Kiselyov's producer/consumer organisation:
-- Simple generators in OCaml (August 2023),
-- https://okmij.org/ftp/continuations/PPYield/index.html#gen-OCaml
module Main where

import Prelude hiding (splitAt)
import System.Environment (getArgs)

-- 9.1. Lazy chunks.
-- AI use declaration: I have not used AI tools when solving this problem.
splitAt :: Int -> [a] -> ([a], [a])
splitAt n xs
  | n <= 0 = ([], xs)
splitAt _ [] = ([], [])
splitAt n (x:xs) = (x : prefix, rest)
  where
    (prefix, rest) = splitAt (n - 1) xs

chunksOf :: Int -> [a] -> [[a]]
chunksOf n _ 
  | n <= 0 = []
chunksOf _ [] = []
chunksOf n xs = chunk : chunksOf n rest
  where
    (chunk, rest) = splitAt n xs

-- Why the two splitAt probes demand different parts of the input:
-- take 1 needs only the first constructor of the prefix, so
-- take 1 (fst (splitAt 3 (1 : undefined))) returns [1].
-- length needs the whole prefix structure. To find its end,
-- it must inspect the undefined tail, so evaluation fails

-- 9.2. Progressive search.
-- AI use declaration: I have not used AI tools when solving this problem.
bestSoFar :: [(a, Int)] -> [(a, Int)]
bestSoFar [] = []
bestSoFar (first:rest) = first : go first rest
  where
    go _ [] = []
    go best (candidate@(_, score):xs)
      | score > snd best = candidate : go candidate xs
      | otherwise =  best : go best xs

search :: Int -> Int -> [(a, Int)] -> Maybe (a, Int)
search budget target candidates
  | budget <= 0 = Nothing 
  | otherwise = go budget Nothing (bestSoFar candidates)
  where 
    go _ result [] = result 
    go remaining _ (best@(_, score):rest)
      | score >= target || remaining == 1 =Just best
      | otherwise = go (remaining - 1) (Just best) rest 

-- How stopping limits scoring, and why unchanged results matter:
-- For map (\page -> (page, score page)) pages, search evaluates scores
-- only until it reaches the target, uses up the budget, or runs out of
-- candidates. It doesn't inspect page values directly. bestSoFar must include unchanged results:
-- each output then corresponds to one candidate. If unchanged results were skipped, the budget would
-- count improvements instead of candidates, so search could score more
-- than budget candidates (or never stop on an infinite stream)

-- 9.3. A scrolling world.
-- AI use declaration: I have not used AI tools when solving this problem.
newtype Distance = Distance Integer deriving (Eq, Show)
newtype Position = Position Integer deriving (Eq, Show)

positions :: [(Distance, a)] -> [(Position, a)]
positions = go 0
  where 
    go _ [] = []
    go n ((Distance gap, label) : rest) =
      let next = n + gap
      in (Position next, label) : go next rest

shift :: Distance -> [(Position, a)] -> [(Position, a)]
shift (Distance distance) = 
  map (\(Position p, label) ->  (Position (p - distance), label))

visible :: Distance -> [(Position, a)] -> [(Position, a)]
visible (Distance width) = go
  where
    go [] = []
    go (item@(Position p, _) : rest)
      | p < 0 = go rest
      | p <= width = item : go rest
      | otherwise = []

-- Why the viewport terminates, and why a filter would not:
-- `visible` stops at the first position beyond the viewport: all later
-- positions are larger. Filtering an infinite world would keep searching
-- forever for possible later matches, so it couldn't finish the frame

frames :: Distance -> Distance -> [(Position, a)] -> [[(Position, a)]]
frames width step world =
  map (visible width) (iterate (shift step) world)

overlay :: [(Position, a)] -> [(Position, a)] -> [(Position, a)]
overlay [] back = back
overlay front [] = front
overlay front@((Position p, a) : fs) back@((Position q, b) : bs)
  | p < q = (Position p, a) : overlay fs back
  | p > q = (Position q, b) : overlay front bs
  | otherwise = (Position p, a) : overlay fs bs

-- 9.4. Given: expressions and substitution.
-- AI use declaration: I have not used AI tools when solving this problem.
data Expr
  = Lit Integer           -- Integer literal
  | Var String            -- Variable name
  | Add Expr Expr         -- Sum of two expressions
  | IfZero Expr Expr Expr -- Condition, zero branch, nonzero branch
  deriving (Eq, Show)

replace :: String -> Expr -> Expr -> Expr
replace _ _ (Lit n) = Lit n
replace x replacement (Var y)
  | x == y = replacement
  | otherwise = Var y
replace x replacement (Add a b) =
  Add (replace x replacement a) (replace x replacement b)
replace x replacement (IfZero c yes no) =
  IfZero (replace x replacement c)
         (replace x replacement yes) (replace x replacement no)

prune :: Expr -> Expr
prune (Lit n) = Lit n
prune (Var x) = Var x
prune (Add a b) = Add (prune a) (prune b)
prune (IfZero c yes no) =
  case prune c of
    Lit 0 -> prune yes
    Lit _ -> prune no
    c' -> IfZero c' (prune yes) (prune no)

-- Why neither replace nor prune demands the discarded branch:
-- replace constructs the branches lazily, without evaluating them.
-- prune first examines the condition and then prunes only the selected
-- branch. Thus the following returns Add (Lit 2) (Lit 3) without
-- evaluating undefined:
-- prune (replace "flag" (Lit 0)
--   (IfZero (Var "flag") (Add (Lit 2) (Lit 3)) undefined))

-- Nested-condition and nonliteral-condition tests:
-- prune (IfZero (IfZero (Lit 1) (Lit 5) (Lit 0))
--               (Add (Lit 2) (Lit 3))
--               (Lit 9))
-- == Add (Lit 2) (Lit 3)
--
-- prune (IfZero (Var "flag")
--               (IfZero (Lit 0) (Lit 2) (Lit 3))
--               (IfZero (Lit 4) (Lit 5) (Lit 6)))
-- == IfZero (Var "flag") (Lit 2) (Lit 6)

-- Why the rules preserve values under a total assignment to variables:
-- Lit and Var keep their values. Add keeps the same operation on
-- value-preserving subexpressions. For IfZero, pruning the condition
-- preserves its value; if it becomes a literal, prune selects the
-- same branch as evaluation. Otherwise it retains the conditional
-- and prunes both branches

-- Comparing substitution before pruning with pruning before substitution:
-- The resulting trees need not be equal. Let:
--   x = "x"
--   r = Lit 0
--   e = IfZero (Var "x") (Lit 1) (Lit 2)
-- Then:
--   prune (replace x r e) == Lit 1
--   replace x r (prune e) == IfZero (Lit 0) (Lit 1) (Lit 2)

-- Whether a second pruning pass changes the result, and why:
-- No, for finite, fully defined expressions:
--   prune (prune e) == prune e
-- Every returned subexpression has already been pruned. A retained
-- IfZero has a pruned condition that isn't a literal, so another
-- pass can't remove it

-- 9.5. AI allowed in (a) only. Keep the true declaration and delete the other.
-- I have used AI (ChatGPT, Free, 22 October 2026, web interface) in part (a),
-- in accordance with the course rules and the problem statement.
-- Preserve the proposal in assistant.hs and any AI exchange in transcript.md.
-- Do not paste the proposal over the original given below.
nameStats :: [String] -> (Int, Int)
nameStats xs = (length xs, foldr (\s m -> max (length s) m) 0 xs)

-- Recorded tests of both versions, including an additional case and its purpose:
-- Input                    nameStats       nameStatsStrict
-- []                       (0,0)           (0,0)
-- ["a","long","xy"]          (3,4)           (3,4)
-- ["",""]                    (2,0)           (2,0)
-- ["same","size"]           (2,4)           (2,4)
-- The extra test checks equal-length longest names: the maximum
-- should remain 4, and both names must still be counted.
-- GHCi checks:
-- map nameStats [[],["a","long","xy"],["",""],["same","size"]]
-- map nameStatsStrict [[],["a","long","xy"],["",""],["same","size"]]

-- Partial-input demand and whether it violates the prompt in (a):
-- fst (nameStats [undefined]) returns 1 because length only 
-- examines the outer list structure. fst (nameStatsStrict [undefined]) fails
-- because the strict version also evaluates the length of the undefined string.
-- This doesn't violate the prompt, which only requires equal results on finite 
-- lists of fully defined strings

-- When additions and max calls are evaluated, and whether delayed work can accumulate:
-- Both updated values are forced during each foldl' iteration
-- by the bang patterns. Therefore, delayed arithmetic can't accumulate

-- If AI was used: one strictness claim, with evidence for agreeing or disagreeing:
-- The assistant states: "foldl' traverses the list from left to right
-- and forces each accumulator to weak head normal form (WHNF) before continuing."
-- I agree, but WHNF alone doesn't evaluate both fields of a tuple.
-- The bang patterns on newCount and newLongest force both Int values
-- at every iteration, preventing unevaluated arithmetic from accumulating
nameStatsStrict :: [String] -> (Int, Int)
nameStatsStrict = foldl' step (0, 0)
  where
    step (count, longest) s =
      let !newCount = count + 1
          !newLongest = max longest (length s)
      in (newCount, newLongest)


-- Why equality on total inputs does not promise equal demand on partial inputs:
-- Both versions return the same results on fully defined inputs,
-- but they differ in evaluation strategy. The original function computes 
-- the count independently from the longest length, so fst may avoid 
-- evaluating string values. The strict version evaluates both numeric fields at each step.
-- Therefore, equal results on total inputs don't imply equal behavior on partially defined inputs

-- Examples from the sheet; run after completing the corresponding functions.
examples :: IO ()
examples = do
  print (splitAt 3 "abcdef")
  -- ("abc","def")
  print (chunksOf 3 "abcdefgh")
  -- ["abc","def","gh"]
  print (take 2 (chunksOf 3 [1..] :: [[Integer]]))
  -- [[1,2,3],[4,5,6]]
  print (bestSoFar [("guide",40),("faq",20),("api",80),("index",80)])
  -- [("guide",40),("guide",40),("api",80),("api",80)]
  print (search 2 70 [("guide",40),("faq",20),("api",80)])
  -- Just ("guide",40)
  print (search 10 70 [("guide",40),("api",80),undefined])
  -- Just ("api",80)
  print (positions [(Distance 3,'a'),(Distance 5,'b'),(Distance 2,'c')])
  -- [(Position 3,'a'),(Position 8,'b'),(Position 10,'c')]
  let world = positions [(Distance 3,n) | n <- [1..] :: [Integer]]
  print (visible (Distance 5) (shift (Distance 4) world))
  -- [(Position 2,2),(Position 5,3)]
  print (take 3 (map (map snd) (frames (Distance 5) (Distance 4) world)))
  -- [[1],[2,3],[3,4]]
  let front = [(Position 3,'a'),(Position 8,'b')]
      back = [(Position 5,'c'),(Position 8,'d')]
  print (overlay front back)
  -- [(Position 3,'a'),(Position 5,'c'),(Position 8,'b')]
  print (prune (IfZero (Lit 0) (Add (Lit 2) (Lit 3)) (Var "x")))
  -- Add (Lit 2) (Lit 3)
  print (prune (Add (IfZero (Lit 1) (Lit 8) (Lit 9)) (Var "x")))
  -- Add (Lit 9) (Var "x")
  print (prune (replace "flag" (Lit 0)
    (IfZero (Var "flag") (Add (Lit 2) (Lit 3)) undefined)))
  -- Add (Lit 2) (Lit 3)

main :: IO ()
main = do
  args <- getArgs
  case args of
    [] -> putStrLn "Load this file in GHCi. After completing it, run examples."
    ["examples"] -> examples
    _ -> putStrLn "usage: runghc <answer-file>.hs [examples]"
