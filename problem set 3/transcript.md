# Rewrite first passing Racket

**User:** Anonymous  
**Created:** 9/11/2026 8:54:41  
**Updated:** 9/11/2026 8:54:58  
**Exported:** 9/11/2026 8:55:05  
**Link:** [https://chatgpt.com/?temporary-chat=true](https://chatgpt.com/?temporary-chat=true)   

## Prompt:
9/11/2026, 8:54:49 AM

Rewrite first-passing in Racket with foldl and no explicit recursion, to make it shorter:
(define (first-passing n pass? applicants)
  (cond [(= n 0) '()]
    [(empty? applicants) '()]
    [(pass? (first applicants))
      (cons (first applicants)
        (first-passing (- n 1) pass? (rest applicants)))]
    [else (first-passing n pass? (rest applicants))]))

(first-passing 2 even? '(2 4 5 6 8)) ; '(2 4)
(first-passing 3 even? '(1 2 3 4)) ; '(2 4)

## Response:
9/11/2026, 8:54:52 AM

Yes. With `foldl`, you can carry the number of people still needed and the selected applicants as the accumulator:

```racket
(define (first-passing n pass? applicants)
  (reverse
   (car
    (foldl
     (lambda (app acc)
       (if (and (> (cdr acc) 0) (pass? app))
           (cons (cons app (car acc)) (sub1 (cdr acc)))
           acc))
     (cons '() n)
     applicants))))
```

For example:

```racket
(first-passing 2 even? '(2 4 5 6 8))
; => '(2 4)

(first-passing 3 even? '(1 2 3 4))
; => '(2 4)
```

The accumulator is:

```racket
(cons selected-left n-left)
```

and each passing applicant is added until `n` reaches zero.

**One caveat:** unlike your original recursive version, `foldl` still processes the entire list after finding enough applicants. If the exercise specifically requires the function to **stop as soon as it has enough**, explicit recursion (or another short-circuiting higher-order function) is preferable.



---
Powered by [ChatGPT Exporter](https://www.chatgptexporter.com)