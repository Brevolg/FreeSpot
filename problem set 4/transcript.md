# New chat

**User:** Anonymous  
**Created:** 9/18/2026 11:29:37  
**Updated:** 9/18/2026 11:30:55  
**Exported:** 9/18/2026 11:31:32  
**Link:** [https://chatgpt.com/?temporary-chat=true](https://chatgpt.com/?temporary-chat=true)  

## Prompt:
9/18/2026, 11:30:49 AM

(define (extremes xs) 
      (for/fold ([lo (first xs)] 
                      [hi (first xs)]) 
                     ([x (rest xs)]) 
         (values (min lo x) (max hi x)))) 
(extremes '(4 9 2)) ; 2 ; 9  

Rewrite extremes in Racket with a single foldl and no for forms

## Response:
9/18/2026, 11:30:51 AM

You can use a single `foldl` over the whole list, carrying the current low and high as a pair:

```racket
(define (extremes xs)
  (foldl (lambda (x acc)
           (cons (min x (car acc))
                 (max x (cdr acc))))
         (cons (first xs) (first xs))
         (rest xs)))
```

However, that returns a **pair** like `(cons 2 9)`, rather than two values. If you want `extremes` to return the same two values as your original version:

```racket
(define (extremes xs)
  (let ([result
         (foldl (lambda (x acc)
                  (cons (min x (car acc))
                        (max x (cdr acc))))
                (cons (first xs) (first xs))
                (rest xs))])
    (values (car result) (cdr result))))
```

Then:

```racket
(call-with-values (lambda () (extremes '(4 9 2)))
  list)
;; '(2 9)
```

This uses **one `foldl` and no `for` forms**.



---
Powered by [ChatGPT Exporter](https://www.chatgptexporter.com)