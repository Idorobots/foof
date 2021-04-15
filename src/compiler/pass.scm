;; Compiler pass definition

(load "compiler/errors.scm")
(load "compiler/ast.scm")

(define (pass schema transform)
  (cons schema transform))

(define (pass-schema pass)
  (car pass))

(define (pass-transform pass)
  (cdr pass))

(define (schema hint . properties)
  (lambda (env)
    (let ((errors (ref '())))
      (with-handlers ((schema-validation-error?
                       (lambda (e)
                         (assign! errors (cons (cadr e)
                                               (deref errors)))
                         ((caddr e) '()))))
        (hash-map (apply hasheq properties)
              (lambda (key schema)
                (if (hash-has-key? env key)
                    (schema (hash-ref env key))
                    (schema-validation-error (format "Missing required field `~a`" key) env)))))
      (unless (empty? (deref errors))
        (compiler-bug (format "Schema `~a` validation failed" hint)
                      (deref errors))))))

(define (non-empty-string? val)
  (unless (and (string? val)
               (> (string-length val) 0))
    (schema-validation-error "Not a non-empty string" val)))

(define (non-empty-list? val)
  (unless (and (list? val)
               (> (length val) 0))
    (schema-validation-error "Not a non-empty list" val)))

(define (a-list? val)
  (unless (list? val)
    (schema-validation-error "Not a list" val)))

(define (ast-subset? types)
  (lambda (expr)
    (let ((t (get-type expr)))
      (unless (member t types)
        (schema-validation-error (format "Unhandled AST node type `~a`" t) expr))
      ;; NOTE Contents of these are technically not part of the subset.
      (if (or (error-node? expr)
              (quote-node? expr))
          error
          (walk-ast (ast-subset? types)
                    expr)))))

(define (schema-validation-error? e)
  (tagged-list? 'schema-validation-error e))

(define (schema-validation-error hint value)
  (call/cc
   (lambda (cont)
     (raise (list 'schema-validation-error
                  (format "~a in: ~a" hint value)
                  cont)))))