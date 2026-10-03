#lang racket
;;; Topic 3. Problem set --- Racket. Answer file.
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
;;;        ;; (foldl + 0 '(1 2))
;;;        ;; = (foldl + 1 '(2))
;;;        ;; = (foldl + 3 '())
;;;        ;; = 3
;;;
;;;   3. Every problem carries an AI use declaration. It consists of two
;;;      lines. Keep the line that is true and delete the other. A missing
;;;      declaration is treated as a missing answer.
;;;   4. Rename the file after yourself, as problem-set-3-<Surname>.rkt, and
;;;      make sure that it runs. Open it in DrRacket and press Run, or run
;;;
;;;        racket problem-set-3-<Surname>.rkt
;;;
;;;      in a terminal. The examples from the sheet appear in this file as
;;;      plain expressions, each with its expected value in a comment. Thus
;;;      running the file prints your values next to the expected ones. A file
;;;      that does not run can only be marked from what can be read, and that
;;;      is less.
;;;   5. Submit this file. If you used an assistant for problem 3.5, submit
;;;      transcript.md as well. It must contain the whole exchange, verbatim
;;;      and unedited.

;;; ===========================================================================
;;; Problem 3.1 (Standard higher-order functions)                        No AI
;;; ===========================================================================

;; AI use declaration. Keep one line and delete the other.
;; I have not used AI tools when solving this problem.

;; Given. (equal? a b) compares any two values, where = compares numbers only.
(equal? 'a 'a) ; #t
(equal? 'a 'b) ; #f

;; (a)
(define (late-fees loans)
  (map (lambda (loan)
         (list (first loan)
               (* 5 (second loan))))
       (filter (lambda (loan)
                 (> (second loan) 0))
               loans)))

(late-fees '(("Ann" 0) ("Bo" 3) ("Cy" 12))) ; '(("Bo" 15) ("Cy" 60))
(late-fees '(("Ann" 0)))                    ; '()

;; (b)
(define (affordable? prices budget)
  (and
   (andmap (lambda (price)
             (> price 0))
           prices)
   (<= (foldl + 0  prices)
       budget)))

(affordable? '(120 350) 500) ; #t
(affordable? '(120 -5) 500)  ; #f
(affordable? '(300 350) 500) ; #f

;; (c)
(define (run-lengths xs)
  (reverse
   (foldl
    (lambda (x runs)
      (cond
        [(empty? runs)
         (list (list x 1))]
        [(equal? x (first (first runs)))
         (cons
          (list x (+ 1 (second (first runs))))
          (rest runs))]
        [else
         (cons (list x 1) runs)]))
    '()
    xs)))

(run-lengths '(a a b c c c)) ; '((a 2) (b 1) (c 3))
(run-lengths '(a b a))       ; '((a 1) (b 1) (a 1))
(run-lengths '())            ; '()

;;; ===========================================================================
;;; Problem 3.2 (Higher-order functions of your own)                     No AI
;;; ===========================================================================

;; AI use declaration. Keep one line and delete the other.
;; I have not used AI tools when solving this problem.

;; (a)
(define (forecast rule years balance)
  (cond
    [(zero? years) balance]
    [else
     (forecast rule
               (- years 1)
               (rule balance))]))

(forecast (lambda (b) (* b 11/10)) 3 1000) ; 1331
(forecast (lambda (b) (- b 100)) 2 1000)   ; 800
(forecast (lambda (b) (* b 2)) 0 7)        ; 7

;; (b)
(define (combine f xs ys)
  (cond
    [(or (empty? xs) (empty? ys)) '()]
    [else
     (cons (f (first xs) (first ys))
           (combine f (rest xs) (rest ys)))]))
     

(combine * '(2 3) '(350 120))                        ; '(700 360)
(combine string-append '("Ann" "Bo") '("a" "b" "c")) ; '("Anna" "Bob")

;; (c)
;; Given.
(define (same-length? a b) (= (string-length a) (string-length b)))

(define (group same? xs)
  (cond
  [(empty? xs) '()]
  [(empty? (rest xs))
   (list (list (first xs)))]
  [else
   (let ([grouped-rest (group same? (rest xs))])
     (if (same? (first xs)
                (first (rest xs)))
         (cons (cons (first xs)
                     (first grouped-rest))
               (rest grouped-rest))
         (cons (list (first xs))
               grouped-rest)))]))

(group = '(1 1 2 3 3 3))                          ; '((1 1) (2) (3 3 3))
(group same-length? '("tea" "cat" "milk" "rice")) ; '(("tea" "cat") ("milk" "rice"))
(group = '())                                     ; '()

;;; ===========================================================================
;;; Problem 3.3 (A proof for every list)                                 No AI
;;; ===========================================================================

;; AI use declaration. Keep one line and delete the other.
;; I have not used AI tools when solving this problem.

(define (my-map f lst)
  (cond [(empty? lst) empty]
        [else (cons (f (first lst)) (my-map f (rest lst)))]))

(define (inc x) (+ x 1))
(define (dbl x) (* 2 x))

;; (a)
(my-map dbl (my-map inc '(1 2)))           ; '(4 6)
(my-map (lambda (x) (dbl (inc x))) '(1 2)) ; '(4 6)

;; (my-map dbl (my-map inc '(1 2)))
;; = (my-map dbl (cons (inc 1) (my-map inc '(2))))
;; = (my-map dbl (cons 2 (my-map inc '(2))))
;; = (my-map dbl (cons 2 (cons (inc 2) (my-map inc empty))))
;; = (my-map dbl (cons 2 (cons 3 empty)))
;; = (cons (dbl 2) (my-map dbl '(3)))
;; = (cons 4 (cons (dbl 3) (my-map dbl empty)))
;; = (cons 4 (cons 6 empty))
;; = '(4 6)
;;
;; (my-map (lambda (x) (dbl (inc x))) '(1 2))
;; = (cons ((lambda (x) (dbl (inc x))) 1)
;;         (my-map (lambda (x) (dbl (inc x))) '(2)))
;; = (cons (dbl (inc 1))
;;         (cons ((lambda (x) (dbl (inc x))) 2)
;;               (my-map (lambda (x) (dbl (inc x))) empty)))
;; = (cons (dbl 2)
;;         (cons (dbl (inc 2)) empty))
;; = (cons 4 (cons (dbl 3) empty))
;; = (cons 4 (cons 6 empty))
;; = '(4 6)

;; (b) Write h for (lambda (x) (f (g x))) if you like; say so.
;; Let h = (lambda (x) (f (g x))).
;; Case lst = empty.
;;   (my-map f (my-map g empty))
;;   = (my-map f empty)
;;   = empty
;;   = (my-map h empty)
;;
;; Case lst = (cons z zs). Assume the claim for zs, that is,
;;   (my-map f (my-map g zs)) = (my-map (lambda (x) (f (g x))) zs).
;;   (my-map f (my-map g (cons z zs)))
;;   = (my-map f (cons (g z) (my-map g zs)))
;;   = (cons (f (g z)) (my-map f (my-map g zs)))
;;   = (cons (f (g z)) (my-map h zs))            ; induction hypothesis
;;   = (cons (h z) (my-map h zs))
;;   = (my-map h (cons z zs))
;;
;; The lambda application used above is:
;;   (h z)
;;   = ((lambda (x) (f (g x))) z)
;;   = (f (g z)).
;;
;; Therefore the claim holds for every list lst

;; (c)
;; The right-hand side does less work because it traverses the list once,
;; while the left-hand side traverses it twice and creates an intermediate list

;;; ===========================================================================
;;; Problem 3.4 (A pipeline, read and rearranged)                        No AI
;;; ===========================================================================

;; AI use declaration. Keep one line and delete the other.
;; I have not used AI tools when solving this problem.

(define orders '(("tea" 2 350) ("soap" 1 120) ("rice" 3 90)))

(define (revenue orders)
  (foldl + 0
         (map (lambda (o) (* (second o) (third o)))
              (filter (lambda (o) (>= (second o) 2)) orders))))

(revenue orders) ; 970

;; (a) What revenue computes:
;; It computes the total price of all orders containing at least two items
;;
;; (filter (lambda (o) (>= (second o) 2)) orders)
;; = '(("tea" 2 350) ("rice" 3 90))
;;
;; (map (lambda (o) (* (second o) (third o)))
;;      '(("tea" 2 350) ("rice" 3 90)))
;; = '(700 270)
;;
;; (foldl + 0 '(700 270))
;; = 970

;; (b)
(define (revenue/discount orders)
  (foldl + 0
         (map (lambda (price) (* price 9/10))
              (map (lambda (o) (* (second o) (third o)))
                   (filter (lambda (o) (>= (second o) 2))
                           orders)))))

(revenue/discount orders) ; 873

;; Why the discount stage has to come after the filter:
;; only orders containing at least two items should receive the discount

;; (c)
(define (revenue2 orders)
  (foldl (lambda (o total)
           (if (>= (second o) 2)
               (+ total (* (second o) (third o)))
               total))
         0
         orders))

(revenue2 orders) ; 970

;; What revenue2 saves:
;; it avoids creating intermediate lists

;; What revenue makes easier to read:
;; it clearly separates filtering, calculating prices, and summing them

;;; ===========================================================================
;;; Problem 3.5 (A fold, audited)                   (a) AI allowed, then No AI
;;; ===========================================================================

;; AI use declaration. Keep one line and delete the other. Here the second
;; line is usually the true one.
;; I have used AI (ChatGPT free) in part (a) of this problem, in accordance with the course rules and the problem statement.

(define (first-passing n pass? applicants)
  (cond [(= n 0) '()]
        [(empty? applicants) '()]
        [(pass? (first applicants))
         (cons (first applicants)
               (first-passing (- n 1) pass? (rest applicants)))]
        [else (first-passing n pass? (rest applicants))]))

(first-passing 2 even? '(2 4 5 6 8)) ; '(2 4)
(first-passing 3 even? '(1 2 3 4))   ; '(2 4)

;; (a) The assistant's version, renamed so that both can live in this file.
;;     The exchange itself goes into transcript.md.
(define (first-passing/ai n pass? applicants)
  (reverse
   (car
    (foldl
     (lambda (app acc)
       (if (and (> (cdr acc) 0) (pass? app))
           (cons (cons app (car acc)) (sub1 (cdr acc)))
           acc))
     (cons '() n)
     applicants))))

(first-passing/ai 2 even? '(2 4 5 6 8)) ; '(2 4)

;; (b)
;; I think it would be convenient to denote
;; the lambda function passed to `foldl` with the letter F
;;
;; Two equations for `foldl`:
;; (foldl F acc '()) = acc
;; (foldl F acc (cons x xs)) = (foldl F (F x acc) xs)
;;
;; (first-passing/ai 2 even? '(2 4 5 6 8))
;; = (reverse (car (foldl F '(() . 2) '(2 4 5 6 8))))
;; = (reverse (car (foldl F (F 2 '(() . 2)) '(4 5 6 8))))
;; = (reverse (car (foldl F '((2) . 1) '(4 5 6 8))))
;; = (reverse (car (foldl F (F 4 '((2) . 1)) '(5 6 8))))
;; = (reverse (car (foldl F '((4 2) . 0) '(5 6 8))))
;; = (reverse (car (foldl F (F 5 '((4 2) . 0)) '(6 8))))
;; = (reverse (car (foldl F '((4 2) . 0) '(6 8))))
;; = (reverse (car (foldl F (F 6 '((4 2) . 0)) '(8))))
;; = (reverse (car (foldl F '((4 2) . 0) '(8))))
;; = (reverse (car (foldl F (F 8 '((4 2) . 0)) '())))
;; = (reverse (car (foldl F '((4 2) . 0) '())))
;; = (reverse (car '((4 2) . 0)))
;; = (reverse '(4 2))
;; = '(2 4)
;;
;; Calls of even? in the assistant's version: 2
;; Calls of even? in the original: 2

;; (c)
;; No, the rewritten version isn't an optimization. After finding a sufficient
;; number of matching elements, foldl still traverses the remainder
;; of the list, even though it stops calling pass?. The original version
;; stops as soon as n reaches zero,
;; whereas `foldl` can't do that, so I would keep the original version
