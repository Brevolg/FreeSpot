#lang racket
;;; Topic 2. Problem set --- Racket. Answer file.
;;;
;;; Name:   Valentin Turchin
;;; Group:  B24-SD-0x
;;; Email:  v.turchin@innopolis.university
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
;; I have used AI (<model>) in <which part> of this problem, in accordance with the course rules and the problem statement.

;; (a)
(define (balances txs)
  'todo)

(balances '(300 -120 50)) ; '(300 180 230)
(balances '())            ; '()

;; Tail recursive or not, and why:

;; (b)
(define (interleave xs ys)
  'todo)

(interleave '(a b c) '(1 2 3)) ; '(a 1 b 2 c 3)
(interleave '(a b) '(1 2 3))   ; '(a 1 b 2)

;; Tail recursive or not, and why:

;; (c)
(define (low-high readings)
  'todo)

(low-high '(7 2 9 4)) ; '(2 . 9)
(low-high '(5))       ; '(5 . 5)

;; Tail recursive or not, and why:

;;; ===========================================================================
;;; Problem 2.2 (Tail calls)                                             No AI
;;; ===========================================================================

;; AI use declaration. Keep one line and delete the other.
;; I have not used AI tools when solving this problem.
;; I have used AI (<model>) in <which part> of this problem, in accordance with the course rules and the problem statement.

(define (count-drops readings)
  (cond
    [(empty? readings) 0]
    [(empty? (rest readings)) 0]
    [(< (second readings) (first readings))
     (+ 1 (count-drops (rest readings)))]
    [else (count-drops (rest readings))]))

;; (a)
;;

;; (b)
;; (count-drops '(5 3 4 1))
;; = ...

;; (c)
(define (count-drops2 readings)
  'todo)

(count-drops '(5 3 4 1))  ; 2
(count-drops2 '(5 3 4 1)) ; 2

;; (count-drops2 '(5 3 4 1))
;; = ...

;;; ===========================================================================
;;; Problem 2.3 (A proof for every list)                                 No AI
;;; ===========================================================================

;; AI use declaration. Keep one line and delete the other.
;; I have not used AI tools when solving this problem.
;; I have used AI (<model>) in <which part> of this problem, in accordance with the course rules and the problem statement.

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
;; = ...
;;
;; (+ (my-length '(a b)) (my-length '(c)))
;; = ...

;; (b)
;; Case xs = empty.
;;   ...
;;
;; Case xs = (cons z zs). Assume the claim for zs, that is,
;;   (my-length (my-append zs ys)) = (+ (my-length zs) (my-length ys)).
;;   (my-length (my-append (cons z zs) ys))
;;   = ...

;; (c)
;;

;;; ===========================================================================
;;; Problem 2.4 (A counterexample)                                       No AI
;;; ===========================================================================

;; AI use declaration. Keep one line and delete the other.
;; I have not used AI tools when solving this problem.
;; I have used AI (<model>) in <which part> of this problem, in accordance with the course rules and the problem statement.

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
;; = ...
;;
;; (checkout2 (list p))
;; = ...

;; (b) Enter your cart in the two lines below, so that the file shows the
;;     disagreement when it runs.
(checkout '())  ; replace '() with your cart
(checkout2 '()) ; and here as well

;; (checkout ...)
;; = ...
;;
;; (checkout2 ...)
;; = ...

;; (c)
;;

;;; ===========================================================================
;;; Problem 2.5 (An accumulator, audited)           (a) AI allowed, then No AI
;;; ===========================================================================

;; AI use declaration. Keep one line and delete the other. Here the second
;; line is usually the true one.
;; I have not used AI tools when solving this problem.
;; I have used AI (<model>) in part (a) of this problem, in accordance with the course rules and the problem statement.

(define (to-fahrenheit temps)
  (cond [(empty? temps) '()]
        [else (cons (+ 32 (* 9/5 (first temps)))
                    (to-fahrenheit (rest temps)))]))

(to-fahrenheit '(0 100 -40)) ; '(32 212 -40)

;; (a) The assistant's version, renamed so that both can live in this file.
;;     The exchange itself goes into transcript.md.
(define (to-fahrenheit/ai temps)
  'todo)

(to-fahrenheit/ai '(0 100 -40)) ; compare with the line above

;; (b)
;; (to-fahrenheit/ai '(0 100 -40))
;; = ...
;;
;; Agrees or not, and why:

;; (c)
(define (to-fahrenheit/acc temps)
  'todo)

(to-fahrenheit/acc '(0 100 -40)) ; '(32 212 -40)

;; Its cost on a list of n readings:
