#lang racket
;;; Topic 2. Problem set --- Racket. Answer file.
;;;
;;; Name:   Mariia Chegodaeva
;;; Group:  B24-SD-02
;;; Email:  ma.chegodaeva@innopolis.university
;;;
;;; (The name above is Valentin Turchin, who designed Refal and invented
;;; supercompilation. Please replace it with your own.)
;;;
;;; How to use this file.
;;;
;;;   1. Enter your name, group and university email above.
;;;   2. Answer every problem of the sheet in this file. Code is written as
;;;      code. A trace, a proof or an explanation is written in a comment,
;;;      under the marker for its part. A trace is written one step per line,
;;;      as in the lecture:
;;;
;;;        ;; (my-sum '(1 2))
;;;        ;; = (+ 1 (my-sum '(2)))
;;;        ;; = (+ 1 (+ 2 (my-sum '())))
;;;        ;; = (+ 1 (+ 2 0))
;;;        ;; = 3
;;;
;;;   3. Every problem carries an AI use declaration. It consists of two
;;;      lines. Keep the line that is true and delete the other. A missing
;;;      declaration is treated as a missing answer.
;;;   4. Rename the file after yourself, as problem-set-2-<Surname>.rkt, and
;;;      make sure that it runs. Open it in DrRacket and press Run, or run
;;;
;;;        racket problem-set-2-<Surname>.rkt
;;;
;;;      in a terminal. The examples from the sheet appear in this file as
;;;      plain expressions, each with its expected value in a comment. Thus
;;;      running the file prints your values next to the expected ones. A file
;;;      that does not run can only be marked from what can be read, and that
;;;      is less.
;;;   5. Submit this file. If you used an assistant for problem 2.5, submit
;;;      transcript.md as well. It must contain the whole exchange, verbatim
;;;      and unedited.

;;; ===========================================================================
;;; Problem 2.1 (Explicit recursion)                                     No AI
;;; ===========================================================================

;; AI use declaration. Keep one line and delete the other.
;; I have not used AI tools when solving this problem.

;; (a)
(define (balances txs)
  (define (helper txs current)
    (cond
      [(empty? txs) empty]
      [else
       (let ([next (+ current (first txs))])
         (cons next
               (helper (rest txs) next)))]))
  (helper txs 0))


(balances '(300 -120 50)) ; '(300 180 230)
(balances '())            ; '()

;; Tail recursive or not, and why:
;; Not tail recursive: after the recursive call returns,
;; cons still has to construct the resulting list.
;; This directly builds the balances in the correct order

;; (b)
(define (interleave xs ys)
  (cond
  [(or (empty? xs) (empty? ys)) empty]
  [else
   (cons (first xs)
         (cons (first ys)
               (interleave (rest xs) (rest ys))))])
  )

(interleave '(a b c) '(1 2 3)) ; '(a 1 b 2 c 3)
(interleave '(a b) '(1 2 3))   ; '(a 1 b 2)

;; Tail recursive or not, and why:
;; Not tail recursive: after the recursive call returns,
;; cons still has to construct the resulting list.
;; This directly constructs the result in the required order

;; (c)
(define (low-high readings)
  (define (helper xs low high)
    (cond
      [(empty? xs) (cons low high)]
      [else
       (helper (rest xs)
               (min low (first xs))
               (max high (first xs)))]))
  (helper (rest readings)
          (first readings)
          (first readings)))

(low-high '(7 2 9 4)) ; '(2 . 9)
(low-high '(5))       ; '(5 . 5)

;; Tail recursive or not, and why:
;; Tail recursive: the recursive call to helper is the last operation.
;; Nothing remains to be done after it returns

;;; ===========================================================================
;;; Problem 2.2 (Tail calls)                                             No AI
;;; ===========================================================================

;; AI use declaration. Keep one line and delete the other.
;; I have not used AI tools when solving this problem.

(define (count-drops readings)
  (cond
    [(empty? readings) 0]
    [(empty? (rest readings)) 0]
    [(< (second readings) (first readings))
     (+ 1 (count-drops (rest readings)))]
    [else (count-drops (rest readings))]))

;; (a)
;; The recursive call in
;; (+ 1 (count-drops (rest readings)))
;; isn't a tail call because after the recursive call returns,
;; 1 still has to be added to its result
;;
;; The recursive call in
;; (count-drops (rest readings))
;; is a tail call, because it is the last operation:
;; nothing remains to be done after it returns

;; (b)
;; (count-drops '(5 3 4 1))
;; = (+ 1 (count-drops '(3 4 1)))
;; = (+ 1 (count-drops '(4 1)))
;; = (+ 1 (+ 1 (count-drops '(1))))   
;; = (+ 1 (+ 1 0))
;; = (+ 1 1)
;; = 2

;; (c)
(define (count-drops2 readings)
  (define (helper readings count)
    (cond
      [(empty? readings) count]
      [(empty? (rest readings)) count]
      [(< (second readings) (first readings))
       (helper (rest readings) (+ count 1))]
      [else
       (helper (rest readings) count)]))
  (helper readings 0))

(count-drops '(5 3 4 1))  ; 2
(count-drops2 '(5 3 4 1)) ; 2

;; (count-drops2 '(5 3 4 1))
;; = (helper '(5 3 4 1) 0)
;; = (helper '(3 4 1) 1)
;; = (helper '(4 1) 1)
;; = (helper '(1) 2)
;; = 2

;;; ===========================================================================
;;; Problem 2.3 (A proof for every list)                                 No AI
;;; ===========================================================================

;; AI use declaration. Keep one line and delete the other.
;; I have not used AI tools when solving this problem.

(define (my-length lst)
  (cond [(empty? lst) 0]
        [else (+ 1 (my-length (rest lst)))]))

(define (my-append xs ys)
  (cond [(empty? xs) ys]
        [else (cons (first xs) (my-append (rest xs) ys))]))

;; (a)
(my-length (my-append '(a b) '(c)))     ; 3
(+ (my-length '(a b)) (my-length '(c))) ; 3

;; (my-length (my-append '(a b) '(c)))
;; = (my-length (cons 'a (my-append '(b) '(c))))
;; = (my-length (cons 'a
;;                    (cons 'b (my-append '() '(c)))))
;; = (my-length (cons 'a (cons 'b '(c))))
;; = (my-length '(a b c))
;; = (+ 1 (my-length '(b c)))
;; = (+ 1 (+ 1 (my-length '(c))))
;; = (+ 1 (+ 1 (+ 1 (my-length '()))))
;; = (+ 1 (+ 1 (+ 1 0)))
;; = 3
;;
;; (+ (my-length '(a b)) (my-length '(c)))
;; = (+ (+ 1 (my-length '(b)))
;;      (+ 1 (my-length '())))
;; = (+ (+ 1 (+ 1 (my-length '())))
;;      (+ 1 0))
;; = (+ (+ 1 (+ 1 0)) 1)
;; = (+ 2 1)
;; = 3

;; (b)
;; Case xs = empty.
;;   (my-length (my-append empty ys))
;;   = (my-length ys)
;;   = (+ 0 (my-length ys))
;;   = (+ (my-length empty) (my-length ys))
;;
;; Case xs = (cons z zs). Assume the claim for zs, that is,
;;   (my-length (my-append zs ys)) = (+ (my-length zs) (my-length ys)).
;;
;;   (my-length (my-append (cons z zs) ys))
;;   = (my-length (cons z (my-append zs ys)))
;;   = (+ 1 (my-length (my-append zs ys)))
;;   = (+ 1 (+ (my-length zs) (my-length ys)))
;;   = (+ (+ 1 (my-length zs)) (my-length ys))
;;   = (+ (my-length (cons z zs)) (my-length ys))

;; (c)
;; The assumption is used in the third equality of the second case,
;; and it is allowed because zs is the rest of (cons z zs), so zs is a shorter list

;;; ===========================================================================
;;; Problem 2.4 (A counterexample)                                       No AI
;;; ===========================================================================

;; AI use declaration. Keep one line and delete the other.
;; I have not used AI tools when solving this problem.

(define (my-sum lst)
  (cond [(empty? lst) 0]
        [else (+ (first lst) (my-sum (rest lst)))]))

(define (discount x)
  (cond [(>= x 100) (* x 9/10)] [else x]))

(define (checkout cart)
  (discount (my-sum cart)))

(define (checkout2 cart)
  (cond [(empty? cart) 0]
        [else (+ (discount (first cart)) (checkout2 (rest cart)))]))

;; (a)
;; (checkout (list p))
;; = (discount (my-sum (list p)))
;; = (discount (+ p (my-sum '())))
;; = (discount (+ p 0))
;; = (discount p)
;;
;; (checkout2 (list p))
;; = (+ (discount p) (checkout2 '()))
;; = (+ (discount p) 0)
;; = (discount p)

;; (b) Enter your cart in the two lines below, so that the file shows the
;;     disagreement when it runs.
(checkout '(60 60))  ; replace '() with your cart
(checkout2 '(60 60)) ; and here as well

;; (checkout '(60 60))
;; = (discount (my-sum '(60 60)))
;; = (discount (+ 60 (my-sum '(60))))
;; = (discount (+ 60 (+ 60 (my-sum '()))))
;; = (discount (+ 60 (+ 60 0)))
;; = (discount 120)
;; = (* 120 9/10)
;; = 108
;;
;; (checkout2 '(60 60))
;; = (+ (discount 60) (checkout2 '(60)))
;; = (+ 60 (+ (discount 60) (checkout2 '())))
;; = (+ 60 (+ 60 0))
;; = 120
;;
;; (c)
;; If discount is (lambda (x) (* x 9/10)), the two functions agree
;; because multiplication distributes over addition:
;; (* (+ a b) 9/10) = (+ (* a 9/10) (* b 9/10)).
;; This is the distributive property of multiplication over addition


;;; ===========================================================================
;;; Problem 2.5 (An accumulator, audited)           (a) AI allowed, then No AI
;;; ===========================================================================

;; AI use declaration. Keep one line and delete the other. Here the second
;; line is usually the true one.
;; I have used AI (Chatgpt free) in part (a) of this problem, in accordance with the course rules and the problem statement.

(define (to-fahrenheit temps)
  (cond [(empty? temps) '()]
        [else (cons (+ 32 (* 9/5 (first temps)))
                    (to-fahrenheit (rest temps)))]))

(to-fahrenheit '(0 100 -40)) ; '(32 212 -40)

;; (a) The assistant's version, renamed so that both can live in this file.
;;     The exchange itself goes into transcript.md.
(define (to-fahrenheit/ai temps)
  (define (helper temps acc)
    (cond
      [(empty? temps) (reverse acc)]
      [else
       (helper (rest temps)
               (cons (+ 32 (* 9/5 (first temps))) acc))]))
  (helper temps '()))

(to-fahrenheit/ai '(0 100 -40)) ; compare with the line above

;; (b)
;; (to-fahrenheit/ai '(0 100 -40))
;; = (helper '(0 100 -40) '())
;; = (helper '(100 -40) '(32))
;; = (helper '(-40) '(212 32))
;; = (helper '() '(-40 212 32))
;; = (reverse '(-40 212 32))
;; = '(32 212 -40)
;;
;; Agrees or not, and why:
;; It agrees with the original.
;; cons adds each converted value to the front of acc,
;; so acc is built in reverse order.
;; reverse restores the original order at the end.

;; (c)
(define (to-fahrenheit/acc temps)
  (define (helper temps acc)
    (cond
      [(empty? temps) (reverse acc)]
      [else
       (helper (rest temps)
               (cons (+ 32 (* 9/5 (first temps))) acc))]))
  (helper temps '()))

(to-fahrenheit/acc '(0 100 -40)) ; '(32 212 -40)

;; Its cost on a list of n readings:
;; Theta(n) time because helper processes each element once,
;; and reverse makes one additional linear pass over the list
