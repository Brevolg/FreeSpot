# Improve Haskell Function

**User:** Anonymous  
**Created:** 10/22/2026 14:21:51  
**Updated:** 10/22/2026 14:22:12  
**Exported:** 10/22/2026 14:23:06  


## Prompt:
22.10.2026, 14:22:06

Improve this Haskell function so it traverses the input list once and avoids accu-
mulating unevaluated arithmetic. Keep its type and its results on finite lists of fully
defined strings. Explain your strictness choices

nameStats :: [String] -> (Int, Int)
nameStats xs =
(length xs, foldr (\s m -> max (length s) m) 0 xs)

## Response:
22.10.2026, 14:22:08

Use a strict left fold to compute both statistics in a single traversal, with a strict accumulator to avoid building up unevaluated arithmetic.

```haskell
import Data.List (foldl')

nameStats :: [String] -> (Int, Int)
nameStats = foldl' step (0, 0)
  where
    step (!count, !longest) s =
      let !count'   = count + 1
          !longest' = max longest (length s)
      in (count', longest')
```

This version requires the `BangPatterns` language extension\:

```haskell
{-# LANGUAGE BangPatterns #-}
```

### Explanation of strictness choices

- **`foldl'` instead of `foldr`\:** `foldl'` traverses the list from left to right and forces each accumulator to weak head normal form (WHNF) before continuing. This avoids accumulating a chain of unevaluated accumulator updates.
- **Strict accumulator fields (`!count`, `!longest`\)\:** The bang patterns force both `Int` values when the accumulator is matched, preventing either component from remaining unevaluated.
- **Strict updated values (`!count'`, `!longest'`\)\:** These ensure that the arithmetic and maximum calculation are evaluated at each step rather than deferred.
- **`length s`\:** Each string's length is computed once when processing that string. Since the strings are fully defined and finite, this terminates.

The function retains the original type and results for finite lists of fully defined strings. It traverses the outer list once, taking $O(n + L)$ time, where $n$ is the number of strings and $L$ is the total number of characters across them. The accumulator uses $O(1)$ additional space, excluding the input strings.
