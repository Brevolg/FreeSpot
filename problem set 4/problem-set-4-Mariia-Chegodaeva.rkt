#lang racket
;;; Topic 4. Problem set --- Racket. Answer file.
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
;;;      code. A trace or an explanation is written in a comment, under the
;;;      marker for its part. A trace is written one step per line, as in
;;;      the lecture:
;;;
;;;        ;; (foldl cons empty '(1 2))
;;;        ;; = (foldl cons '(1) '(2))
;;;        ;; = (foldl cons '(2 1) '())
;;;        ;; = '(2 1)
;;;
;;;   3. Every problem carries an AI use declaration. For a No AI problem,
;;;      leave the declaration in place. Problem 4.5 gives two choices: keep
;;;      the line that is true and delete the other. A missing declaration is
;;;      treated as a missing answer.
;;;   4. Rename the file after yourself, as problem-set-4-<Surname>.rkt, and
;;;      make sure that it runs. Open it in DrRacket and press Run, or run
;;;
;;;        racket problem-set-4-<Surname>.rkt
;;;
;;;      in a terminal. The examples from the sheet appear in this file as
;;;      plain expressions, each followed by its expected value in a comment.
;;;      Running the file prints your values in the same order; compare them
;;;      with the comments. A file that does not run can only be marked from
;;;      what can be read, and that is less. The stubs below are chosen so that
;;;      the file runs before you have written anything; replace them.
;;;   5. Submit this file. If you used an assistant for problem 4.5(a), submit
;;;      transcript.md as well. It must contain the whole exchange, verbatim
;;;      and unedited.

(require racket/generator)

;;; ===========================================================================
;;; Problem 4.1 (Loops without recursion)                                No AI
;;; ===========================================================================


;; I have not used AI tools when solving this problem.

;; (a)
(define (warm-days limit temps)
  (for/list ([temp temps]
             [day (in-naturals 1)]
             #:when (> temp limit))
    (list day temp)))

(warm-days 20 '(18 23 21 17 25)) ; '((2 23) (3 21) (5 25))
(warm-days 30 '(18 23))          ; '()

;; (b)
(define (pairs-with-sum n xs)
  (for*/list ([x xs]
              [y xs]
              #:when(and (< x y)
                         (= (+ x y) n)))
    (list x y)))

(pairs-with-sum 10 '(3 7 5 2 8))    ; '((3 7) (2 8))
(pairs-with-sum 9 '(4 5 1 8 6 3))   ; '((4 5) (1 8) (3 6))
(pairs-with-sum 6 '(1 2 3))         ; '()

;; (c)
(define (longest-track tracks)
  (for/fold ([longest (first tracks)])
            ([track (rest tracks)])
    (if (> (second track) (second longest))
        track
        longest)))

(longest-track '(("a" 200) ("b" 320) ("c" 250))) ; '("b" 320)
(longest-track '(("x" 100) ("y" 100)))           ; '("x" 100)

;;; ===========================================================================
;;; Problem 4.2 (On demand)                                              No AI
;;; ===========================================================================

;; I have not used AI tools when solving this problem.

;; Assume that h is positive, k is greater than one, and the target below is
;; finite.

;; (a) The stub is the empty stream, so that the examples run.
(define (heights h k)
  (stream-cons h
               (heights (* h k) k)))

(for/list ([h (heights 50 6/5)] [i 4]) h) ; '(50 60 72 432/5)
(stream-first (stream-rest (heights 1 2)))  ; 2
;; Uncomment the line above once heights is written: on the stub it is an error.

;; (b) The stub is a generator that yields nothing, so that the calls run.
(define (make-next-height h k)
  (generator ()
     (for ([height (heights h k)])
       (yield height))))

(define next-height (make-next-height 50 6/5))
(next-height) ; 50
(next-height) ; 60
(next-height) ; 72

;; (c)
(define (years-until target s)
  (cond [(> (stream-first s) target) 0]
        [else
         (+ 1
            (years-until target (stream-rest s)))]))

(years-until 100 (heights 50 6/5)) ; 4
(years-until 40 (heights 50 6/5))  ; 0
(years-until 1000 (heights 1 2))   ; 10

;; Why the stream remains reusable after years-until reads it, while a
;; generator does not:
;; A stream remains reusable because it is immutable and stream-rest returns
;; another stream, whereas a generator has mutable state and each call consumes
;; the next value

;;; ===========================================================================
;;; Problem 4.3 (A datatype of your own)                                 No AI
;;; ===========================================================================

;; I have not used AI tools when solving this problem.

;; Given.
(struct flight (from to minutes))

(define flights
  (list (flight "KZN" "SVO" 95)
        (flight "SVO" "LED" 80)
        (flight "LED" "KZN" 130)
        (flight "SVO" "KZN" 95)))

;; Given. The three airports of a connection: where the first flight departs,
;; where the two meet, and where the second arrives.
(define (route c)
  (list (flight-from (first c)) (flight-to (first c)) (flight-to (second c))))

;; (a)
(define (airborne fs)
  (for/sum ([f fs])
    (flight-minutes f)))

(airborne flights) ; 400
(airborne '())     ; 0

;; (b) The stub returns the flight unchanged, so that the example runs.
(define (delayed f delay)
  (flight (flight-from f)
          (flight-to f)
          (+ (flight-minutes f) delay)))

(flight-minutes (delayed (first flights) 20)) ; 115
(flight-minutes (first flights))              ; 95

;; (c) The order of the five compatible pairs is not assessed. The stub is
;; the empty list, so that the examples run.
(define (connections fs)
  (for*/list ([f1 fs]
              [f2 fs]
              #:when (string=? (flight-to f1)
                               (flight-from f2)))
    (list f1 f2)))

(length (connections flights))     ; 5
(map route (connections flights))
; '(("KZN" "SVO" "LED") ("KZN" "SVO" "KZN") ("SVO" "LED" "KZN")
;   ("LED" "KZN" "SVO") ("SVO" "KZN" "SVO"))

;;; ===========================================================================
;;; Problem 4.4 (Two ways to say it)                                     No AI
;;; ===========================================================================

;; I have not used AI tools when solving this problem.

;; Given.
(define fares '(120 350 90 400))

(define (discounted fares)
  (for/list ([f fares] #:when (>= f 100))
    (* f 9/10)))

(define (dearest fares)
  (foldl (lambda (f m) (max f m)) 0 fares))

(discounted fares) ; '(108 315 360)
(dearest fares)    ; 400

;; (a)
(define (discounted2 fares)
  (map (lambda (f) (* f 9/10))
       (filter (lambda (f) (>= f 100))
               fares)))

(define (dearest2 fares)
  (for/fold ([m 0])
            ([f fares])
    (max f m)))

(discounted2 fares) ; '(108 315 360)
(dearest2 fares)    ; 400

;; (b)
;; discounted or discounted2, and why:
;; The discounted version reads better because for/list with #:when
;; combines filtering and transformation into a single loop

;; dearest or dearest2, and why:
;; The dearest2 version reads better because for/fold
;; explicitly indicates the accumulator, its initial value,
;; and the method of updating it

;; (c)
;; How many lists discounted builds:
;; one: the returned list, with no intermediate list

;; Could the computation in discounted be transferred to a stream, and why?
;; I think so because every result depends solely on the current fare,
;; so results can be obtained gradually, without reaching the end of the input

;; Could the computation in dearest be transferred to a stream, and why?
;; No, because the maximum may occur anywhere in the input, so the whole input
;; must be read before the final result is known
;;(The definitions above are eager and require finite input.)

;;; ===========================================================================
;;; Problem 4.5 (A fold with two accumulators, audited)   (a) AI allowed, then No AI
;;; ===========================================================================

;; AI use declaration. Keep one line and delete the other. Here the second
;; line is usually the true one.
;; I have used AI (ChatGPT free) in part (a) of this problem, in accordance with
;; the course rules and the problem statement.

(define (extremes xs)
  (for/fold ([lo (first xs)]
             [hi (first xs)])
            ([x (rest xs)])
    (values (min lo x) (max hi x))))

(extremes '(4 9 2)) ; 2
                    ; 9

;; (a) The assistant's version, or your own version if you used no assistant,
;;     renamed so that both can live in this file. If you used an assistant,
;;     the exchange itself goes into transcript.md. The stub returns two
;;     values, so that the example runs. If the recorded version stops with an
;;     error, keep its definition verbatim and comment out only the example
;;     call after recording the error in (b), so that the rest of the file runs.
(define (extremes/ai xs)
  (let ([result
         (foldl (lambda (x acc)
                  (cons (min x (car acc))
                        (max x (cdr acc))))
                (cons (first xs) (first xs))
                (rest xs))])
    (values (car result) (cdr result))))

(extremes/ai '(4 9 2)) ; 2
                       ; 9 

;; (b)
;; Let step be the lambda from extremes/ai.
;;
;; The two equations of foldl are:
;; (foldl step acc '()) = acc
;; (foldl step acc (cons x xs))
;; = (foldl step (step x acc) xs)
;;
;; (extremes/ai '(4 9 2))
;; starts the fold with (cons 4 4) over '(9 2):
;;
;; (foldl step (cons 4 4) '(9 2))
;; = (foldl step (step 9 (cons 4 4)) '(2))
;; = (foldl step (cons 4 9) '(2))
;; = (foldl step (step 2 (cons 4 9)) '())
;; = (foldl step (cons 2 9) '())
;; = (cons 2 9)
;;
;; Therefore:
;; (values (car (cons 2 9)) (cdr (cons 2 9)))
;; = (values 2 9)
;;
;; How the two accumulators travel through the fold:
;; foldl has one accumulator, so the lowest and highest values are packed
;; into its car and cdr: (4 . 4) -> (4 . 9) -> (2 . 9)

;; (c)
;; The rewrite isn't an improvement because for/fold directly shows two
;; named accumulators, their initial values, and their parallel updates.
;; The foldl version hides them inside a pair and then unpacks that pair,
;; so I would keep the for/fold version
