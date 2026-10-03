# Tail Recursive Racket Rewrite

**User:** Anonymous  
**Created:** 9/7/2026 10:08:12  
**Updated:** 9/7/2026 10:08:17  
**Exported:** 9/7/2026 10:08:57  
**Link:** [https://chatgpt.com/?temporary-chat=true](https://chatgpt.com/?temporary-chat=true)  

## Prompt:
9/7/2026, 10:08:09 AM

Rewrite to-fahrenheit in Racket with a tail-recursive helper function and an accumulator param eter:

(define (to-fahrenheit temps)
             (cond [(empty? temps) '()]
                       [else (cons (+ 32 (* 9/5 (first temps))) 
                                         (to-fahrenheit (rest temps)))])) 

(to-fahrenheit '(0 100-40)) ; '(32 212-40)

## Response:
9/7/2026, 10:08:12 AM

You can make the recursion tail-recursive by carrying the converted values in an accumulator. Since an accumulator built with `cons` will be reversed, use `reverse` at the end:

```racket
(define (to-fahrenheit temps)
  (define (helper temps acc)
    (cond
      [(empty? temps) (reverse acc)]
      [else
       (helper (rest temps)
               (cons (+ 32 (* 9/5 (first temps))) acc))]))
  (helper temps '()))

(to-fahrenheit '(0 100 -40))
; '(32 212 -40)
```

### Why this is tail-recursive
The recursive call to `helper` is the **last operation** performed:

```racket
(helper (rest temps)
        (cons (+ 32 (* 9/5 (first temps))) acc))
```

The `acc` parameter stores the results accumulated so far. We reverse it once at the end because each new result is added to the front.

