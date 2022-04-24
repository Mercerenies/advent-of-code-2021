#lang racket

;; We split the instruction list into blocks of code, where each block
;; begins with an "inp" instruction and goes up to (but excluding) the
;; next "inp" instruction. By hand analysis, we find that each block
;; of code does one of two things.
;;
;; 1. It multiplies z by a predefined constant N and then adds the
;; input, plus or minus some other predefined constant.
;;
;; 2. It conditionally divides z by the same predefined constant N, if
;; the input (plus or minus some value) is equal to a previous input.
;;
;; In order to make the number zero, we need to make sure all of the
;; conditional divisions are successful. So we identify which blocks
;; are "input" blocks and which are "output" blocks, then we pair them
;; off so that each "output" is folded into the nearest "input", then
;; we make sure the constraints for which inputs and which outputs are
;; paired match up.

;; An instruction consists of a symbol opcode and up to two arguments.
;; The left-hand argument is required and is always a symbol. The
;; right-hand argument can be either null, a number, or a symbol.
(struct instruction (opcode lhs rhs) #:transparent)

;; A summary of a section of the code. A "section" of the code
;; consists of the block beginning with an "inp" instruction and going
;; up to (but not including) the next "inp" instruction. A section is
;; summarized by its type (either the symbol 'input or 'output), an
;; amount to shift the input by, and an amount to shift the prior
;; output by.
;;
;; A section is an 'input section if it involves a "div ? 1"
;; instruction, i.e. there is no way to shift the value to a lower
;; digit count in this section. A section is an 'output section if it
;; involves a "div ? N" for some numerical constant N > 1 in it.
(struct section-summary (type input-shift output-shift) #:transparent)

;; A constraint consists of two input variable indices (input indices
;; start at 1 and go up to 14 inclusive) and a difference between
;; them. The first input must be equal to the second input plus that
;; amount.
(struct constraint (lhs-input rhs-input shift) #:transparent)

;; Convert to number if it's a valid numerical value, otherwise
;; convert to symbol.
(define (string->atom x)
  (or (string->number x) (string->symbol x)))

(define (line->instr line)
  (match (string-split line " ")
    [(list opcode lhs)
     (instruction (string->symbol opcode) (string->symbol lhs) null)]
    [(list opcode lhs rhs)
     (instruction (string->symbol opcode) (string->symbol lhs) (string->atom rhs))]))

(define (read-lines-from-file filename)
  (letrec ([read-next-line (lambda (file-handle acc)
                             (let ([line (read-line file-handle 'any)])
                               (if (eof-object? line)
                                   (reverse acc)
                                   (read-next-line file-handle (cons line acc)))))])
    (call-with-input-file filename (lambda (file-handle) (read-next-line file-handle null)))))

(define (read-instrs-from-file filename)
  (map line->instr (read-lines-from-file filename)))

;; In my particular case, the "modulo" we're doing all of this with
;; respect to is 26, but that may not be true in general. So let's
;; identify that dynamically from the input we're given.
(define (identify-mod-target instrs)
  (instruction-rhs (findf (lambda (x) (equal? (instruction-opcode x) 'mod)) instrs)))

;; Splits the list into sublists, before each element with the
;; predicate is true.
(define (split-before pred lst)
  (letrec ([rec (lambda (lst curr acc)
                  (cond
                    [(null? lst)
                     (reverse (cons (reverse curr) acc))]
                    [(pred (car lst))
                     (rec (cdr lst) (list (car lst)) (cons (reverse curr) acc))]
                    [else
                     (rec (cdr lst) (cons (car lst) curr) acc)]))])
    ;; If the first element of the argument matches the predicate,
    ;; then the first element in the result will be null, which is
    ;; probably not what the caller intended.
    (let ([result (rec lst null null)])
      (if (null? (car result))
          (cdr result)
          result))))

(define (split-at-inp instrs)
  (split-before (lambda (instr) (equal? (instruction-opcode instr) 'inp)) instrs))

(define (summarize-block instrs-block)
  (let* ([div-instr (findf (lambda (x) (and (equal? (instruction-opcode x) 'div)
                                            (number? (instruction-rhs x))))
                           instrs-block)]
         [add-instr (findf (lambda (x) (and (equal? (instruction-opcode x) 'add)
                                            (equal? (instruction-lhs x) 'x)
                                            (number? (instruction-rhs x))))
                           instrs-block)]
         [add-y-instr (cadr (memf (lambda (x) (equal? x (instruction 'add 'y 'w))) instrs-block))]
         [summary-type (if (= (instruction-rhs div-instr) 1)
                           'input
                           'output)])
    (section-summary summary-type (instruction-rhs add-y-instr) (instruction-rhs add-instr))))

;; Given a list of summaries, build up the constraints by "pairing
;; off" the input summaries with the corresponding output summaries
;; and keeping track of the constraints.
(define (build-constraints summaries)
  (letrec ([rec (lambda (input-stack remaining-stack index acc)
                  (cond
                    [(null? remaining-stack)
                     (reverse acc)]
                    [(equal? (section-summary-type (car remaining-stack)) 'input)
                     (let* ([new-input-entry (cons index (car remaining-stack))]
                            [input-stack (cons new-input-entry input-stack)]
                            [remaining-stack (cdr remaining-stack)])
                       (rec input-stack remaining-stack (+ 1 index) acc))]
                    [else
                     (let ([input-stack (cdr input-stack)]
                           [remaining-stack (cdr remaining-stack)]
                           [new-constraint (constraint index
                                                       (caar input-stack)
                                                       (+ (section-summary-input-shift (cdar input-stack))
                                                          (section-summary-output-shift (car remaining-stack))))])
                       (rec input-stack remaining-stack (+ 1 index) (cons new-constraint acc)))]))])
    (rec null summaries 1 null)))

;; Normalize the constraint so that its shift amount is nonnegative.
;; If its shift amount is negative, the two variables are swapped so
;; that the shift amount is positive.
(define (normalize-constraint c)
  (if (< (constraint-shift c) 0)
      (constraint (constraint-rhs-input c) (constraint-lhs-input c) (- (constraint-shift c)))
      c))

;; Assign the smallest value to the variable which can still feasibly
;; satisfy the constraints.
(define (assign-variable constraints index)
  ;; Assume it's 1 until proven otherwise.
  (let ([value 1])
    (for/list ([c constraints])
      (when (= (constraint-lhs-input c) index)
        (set! value (max value (+ 1 (constraint-shift c))))))
    value))

(let* ([instrs (read-instrs-from-file "input.txt")]
       [mod-target (identify-mod-target instrs)]
       [instr-parts (split-at-inp instrs)]
       [instr-summaries (map summarize-block instr-parts)]
       [constraints (build-constraints instr-summaries)]
       [constraints (map normalize-constraint constraints)])
  (for/list ([index (range 1 15)])
    (print (assign-variable constraints index)))
  (displayln ""))
