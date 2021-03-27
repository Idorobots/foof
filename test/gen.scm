;; Generators

(define (sample gen rand)
  (if (procedure? gen)
      (gen rand)
      gen))

(define (gen-integer min max)
  (lambda (rand)
    (rand min max)))

(define (gen-real min max)
  (lambda (rand)
    (+ min (* (rand) (- max min)))))

(define (gen-number rand)
  ((gen-one-of (gen-integer -1000 1000)
               (gen-real -12345.6 12345.6))
   rand))

(define (gen-string letters gen-max-length)
  (lambda (rand)
    (let ((len (string-length letters))
          (size (sample gen-max-length rand)))
      (list->string
       (map (lambda (_)
              (string-ref letters (rand 0 len)))
            (iota 1 size 1))))))

(define (gen-text gen-max-length)
  (gen-string "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ()[]{}?-!@#$%^&*~` " gen-max-length))

(define (gen-symbol gen-max-length)
  (compose string->symbol
           (gen-string "abcdefghijklmnopqrstuvwxyz-?" gen-max-length)))

(define (gen-list gen-max-size gen-contents)
  (lambda (rand)
    (let ((size (sample gen-max-size rand)))
      (map (lambda (_)
             (sample gen-contents rand))
           (iota 1 size 1)))))

(define (gen-location rand)
  (let ((start (rand 0 1000)))
    (location start (+ start (rand 0 1000)))))

(define (gen-number-node gen-value)
  (lambda (rand)
    (at (gen-location rand)
        (make-number-node
         (sample gen-value rand)))))

(define (gen-symbol-node gen-symbol)
  (lambda (rand)
    (at (gen-location rand)
        (make-symbol-node
         (sample gen-symbol rand)))))

(define gen-valid-symbol-node
  (gen-symbol-node (gen-symbol (gen-integer 3 10))))

(define (gen-string-node gen-contents)
  (lambda (rand)
    (at (gen-location rand)
        (make-string-node
         (sample gen-contents rand)))))

(define (gen-list-node gen-max-size)
  (lambda (rand)
    (at (gen-location rand)
        (make-list-node
         ((gen-list gen-max-size
                   ;; NOTE To avoid generating huge objects.
                    gen-simple-node)
          rand)))))

(define (gen-one-of . alternatives)
  (lambda (rand)
    (sample (list-ref alternatives (rand 0 (length alternatives)))
            rand)))

(define (gen-simple-node rand)
  ((gen-one-of (gen-number-node gen-number)
               (gen-symbol-node (gen-symbol (gen-integer 1 10)))
               (gen-string-node (gen-text (gen-integer 0 10)))
               (gen-quote-node gen-simple-node))
   rand))

(define (gen-quote-node gen-contents)
  (lambda (rand)
    (at (gen-location rand)
        (make-quote-node
         (gen-contents rand)))))

(define (gen-arg-list gen-max-length)
  (gen-list gen-max-length gen-valid-symbol-node))

(define (gen-lambda-node gen-formals gen-body)
  (lambda (rand)
    (at (gen-location rand)
        (make-lambda-node (sample gen-formals rand)
                          (sample gen-body rand)))))

(define (gen-app-node gen-op . gen-args)
  (lambda (rand)
    (at (gen-location rand)
        (make-app-node (sample gen-op rand)
                       (map (flip sample rand) gen-args)))))

(define (gen-binding gen-name gen-value)
  (lambda (rand)
    (make-binding (sample gen-name rand)
                  (sample gen-value rand))))

(define gen-valid-binding
  (gen-binding gen-valid-symbol-node gen-simple-node))

(define (gen-binding-list gen-max-length)
  (gen-list gen-max-length gen-valid-binding))

(define (gen-let-node gen-bindings gen-body)
  (lambda (rand)
    (at (gen-location rand)
        (make-let-node (sample gen-bindings rand)
                       (sample gen-body rand)))))

(define (gen-letrec-node gen-bindings gen-body)
  (lambda (rand)
    (at (gen-location rand)
        (make-letrec-node (sample gen-bindings rand)
                          (sample gen-body rand)))))

(define (gen-ast-node rand)
  ((gen-one-of gen-simple-node
               (gen-list-node (gen-integer 0 5))
               (gen-quote-node gen-simple-node)
               (gen-lambda-node (gen-arg-list (gen-integer 0 3))
                                gen-simple-node)
               (gen-let-node (gen-binding-list (gen-integer 1 5))
                             gen-simple-node)
               (gen-letrec-node (gen-binding-list (gen-integer 1 5))
                                gen-simple-node)
               (apply gen-app-node
                      gen-simple-node
                      (sample (gen-list (gen-integer 0 3)
                                        gen-simple-node)
                              rand)))
   rand))