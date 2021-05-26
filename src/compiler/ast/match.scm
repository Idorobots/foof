;; AST pattern matching

(load-once "compiler/ast/nodes.scm")
(load-once "compiler/ast/eqv.scm")

(load-once "compiler/errors.scm")

;; FIXME I don't know how I feel about this thing...
(begin-for-syntax
 (define (match-ast-patterns stx)
   (syntax-case stx ()
     (()
      '())
     ((first rest ...)
      (cons (match-ast-pattern #'first)
            (match-ast-patterns #'(rest ...))))))

 (define (match-ast-pattern stx)
   (syntax-case stx (ast-quote ast-quasiquote ast-unquote ast-unquote-splicing ast-body
                     const number symbol string list do if lambda let letrec fix binding app primop-app def
                     quote)
     ((const pattern)
      #`(ast-node 'const _ _ _ _ _ #,(match-ast-pattern #'pattern)))
     ((number pattern)
      #`(ast-node 'number _ _ _ _ _ #,(match-ast-pattern #'pattern)))
     ((symbol pattern)
      #`(ast-node 'symbol _ _ _ _ _ #,(match-ast-pattern #'pattern)))
     ((string pattern)
      #`(ast-node 'string _ _ _ _ _ #,(match-ast-pattern #'pattern)))
     ((list patterns ...)
      #`(ast-node 'list _ _ _ _ _ #,(match-ast-pattern #'(patterns ...))))
     ((do patterns ...)
      #`(ast-node 'do _ _ _ _ _ #,(match-ast-pattern #'(patterns ...))))
     ((if condition then else)
      #`(ast-node 'if _ _ _ _ _ (ast-if-data #,(match-ast-pattern #'condition)
                                             #,(match-ast-pattern #'then)
                                             #,(match-ast-pattern #'else))))
     ((lambda formals body)
      #`(ast-node 'lambda _ _ _ _ _ (ast-lambda-data #,(match-ast-pattern #'formals)
                                                     #,(match-ast-pattern #'body))))
     ((let bindings body)
      #`(ast-node 'let _ _ _ _ _ (ast-let-data #,(match-ast-pattern #'bindings)
                                               #,(match-ast-pattern #'body))))
     ((letrec bindings body)
      #`(ast-node 'letrec _ _ _ _ _ (ast-letrec-data #,(match-ast-pattern #'bindings)
                                                     #,(match-ast-pattern #'body))))
     ((fix bindings body)
      #`(ast-node 'fix _ _ _ _ _ (ast-fix-data #,(match-ast-pattern #'bindings)
                                               #,(match-ast-pattern #'body))))
     ((binding var val)
      #`(ast-node 'binding _ _ _ _ _ (ast-binding-data #,(match-ast-pattern #'var)
                                                       #,(match-ast-pattern #'val)
                                                       _
                                                       _)))
     ((app op args ...)
      #`(ast-node 'app _ _ _ _ _ (ast-app-data #,(match-ast-pattern #'op)
                                               #,(match-ast-pattern #'(args ...)))))
     ((primop-app op args ...)
      #`(ast-node 'primop-app _ _ _ _ _ (ast-primop-app-data #,(match-ast-pattern #'op)
                                                             #,(match-ast-pattern #'(args ...)))))
     ((def name value)
      #`(ast-node 'def _ _ _ _ _ (ast-def-data #,(match-ast-pattern #'name)
                                               #,(match-ast-pattern #'value))))
     ;; FIXME This collides with all kinds of usages.
     ((ast-body patterns ...)
      #`(ast-node 'body _ _ _ _ _ #,(match-ast-pattern #'(patterns ...))))
     ((ast-quote pattern)
      #`(ast-node 'quote _ _ _ _ _ #,(match-ast-pattern #'pattern)))
     ((ast-quasiquote pattern)
      #`(ast-node 'quasiquote _ _ _ _ _ #,(match-ast-pattern #'pattern)))
     ((ast-unquote pattern)
      #`(ast-node 'unquote _ _ _ _ _ #,(match-ast-pattern #'pattern)))
     ((ast-unquote-splicing pattern)
      #`(ast-node 'unquote-splicing _ _ _ _ _ #,(match-ast-pattern #'pattern)))
     ;; These are just plain pattern.s
     ((quote pattern)
      #'(quote pattern))
     ((patterns ...)
      #`(list #,@(match-ast-patterns #'(patterns ...))))
     (pattern
      #'pattern)))

 (define (match-ast-clause stx)
   (syntax-case stx ()
     ((pattern body ...)
      (let ((p (match-ast-pattern #'pattern)))
        #`(#,p body ...)))))

 (define (match-ast-clauses stx)
   (syntax-case stx ()
     (()
      '())
     ((first rest ...)
      (cons (match-ast-clause #'first)
            (match-ast-clauses #'(rest ...)))))))

(define-syntax (match-ast stx)
  (syntax-case stx ()
    ((match-ast expr
                clause ...
                (else body ...))
     (let ((clauses (match-ast-clauses #'(clause ...))))
       #`(match expr
           #,@clauses
           (else body ...))))))

(define-syntax ast-case-extract-vars
  (syntax-rules (quote unquote get-var)
    ((ast-case-extract-vars bound body)
     body)
    ((ast-case-extract-vars bound body (unquote var) rest ...)
     (let ((var (get-var bound 'var)))
       (ast-case-extract-vars bound body rest ...)))
    ((ast-case-extract-vars bound body (quote symbol) rest ...)
     (ast-case-extract-vars bound body rest ...))
    ((ast-case-extract-vars bound body (parts ...) rest ...)
     (ast-case-extract-vars bound body parts ... rest ...))
    ((ast-case-extract-vars bound body unquote var rest ...)
     (let ((var (get-var bound 'var)))
       (ast-case-extract-vars bound body rest ...)))
    ((ast-case-extract-vars bound body symbol rest ...)
     (ast-case-extract-vars bound body rest ...))))

(define-syntax ast-case-match-rule
  (syntax-rules (ast-matches?)
    ((ast-case-match-rule expr (pattern body ...) rest)
     (let ((bound (ast-matches? expr 'pattern)))
       (if bound
           (ast-case-extract-vars bound
                                  (begin '() body ...)
                                  pattern)
           rest)))))

(define-syntax ast-case
  (syntax-rules (else)
    ((ast-case expr (else v ...))
     (begin v ...))
    ((ast-case expr rule rest ...)
     (let ((tmp expr))
       (ast-case-match-rule tmp
                            rule
                            (ast-case tmp rest ...))))))

(define (ast-matches? expr pattern)
  (cond ((equal? pattern '_)
         (empty-bindings))
        ((and (empty? pattern)
              (ast-list? expr)
              (empty? (ast-list-values expr)))
         (empty-bindings))
        ((pair? pattern)
         (cond ((equal? (car pattern) 'unquote)
                (bindings (cadr pattern) expr))
               ((equal? (car pattern) 'quote)
                (cond ((symbol? (cadr pattern))
                       (and (ast-symbol? expr)
                            (equal? (cadr pattern) (ast-symbol-value expr))
                            (empty-bindings)))
                      ((number? (cadr pattern))
                       (and (ast-number? expr)
                            (equal? (cadr pattern) (ast-number-value expr))
                            (empty-bindings)))
                      ((string? (cadr pattern))
                       (and (ast-string? expr)
                            (equal? (cadr pattern) (ast-string-value expr))
                            (empty-bindings)))
                      (else
                       #f)))
               (else
                (case (car pattern)
                  ((symbol number string)
                   (and (or (ast-symbol? expr)
                            (ast-number? expr)
                            (ast-string? expr))
                        (ast-matches? expr (cadr pattern))))
                  ((list) (and (ast-list? expr)
                               (ast-list-matches? (ast-list-values expr) (cdr pattern))))
                  ((do) (and (ast-do? expr)
                             (ast-list-matches? (ast-do-exprs expr) (cdr pattern))))
                  ((body) (and (ast-body? expr)
                               (ast-list-matches? (ast-body-exprs expr) (cdr pattern))))
                  ((if) (and (ast-if? expr)
                             (unify-bindings
                              (unify-bindings
                               (ast-matches? (ast-if-condition expr) (cadr pattern))
                               (ast-matches? (ast-if-then expr) (caddr pattern)))
                              (ast-matches? (ast-if-else expr) (cadddr pattern)))))
                  ((def) (and (ast-def? expr)
                              (unify-bindings (ast-matches? (ast-def-name expr) (cadr pattern))
                                              (ast-matches? (ast-def-value expr) (caddr pattern)))))
                  ((app) (and (ast-app? expr)
                              (unify-bindings (ast-matches? (ast-app-op expr) (cadr pattern))
                                              (ast-list-matches? (ast-app-args expr) (cddr pattern)))))
                  ((primop-app) (and (ast-primop-app? expr)
                                     ;; NOTE Spoofs a full symbol node for the op to make matching easier.
                                     (unify-bindings (ast-matches? (generated
                                                                    (make-ast-symbol (ast-node-location expr)
                                                                                     (ast-primop-app-op expr)))
                                                                   (cadr pattern))
                                                     (ast-list-matches? (ast-primop-app-args expr) (cddr pattern)))))
                  ((lambda) (and (ast-lambda? expr)
                                 (unify-bindings (ast-list-matches? (ast-lambda-formals expr) (cadr pattern))
                                                 (ast-matches? (ast-lambda-body expr) (caddr pattern)))))
                  ((binding) (and (ast-binding? expr)
                                  (unify-bindings (ast-matches? (ast-binding-var expr) (cadr pattern))
                                                  (ast-matches? (ast-binding-val expr) (caddr pattern)))))
                  ((let) (and (ast-let? expr)
                              (unify-bindings (ast-list-matches? (ast-let-bindings expr)
                                                                 (cadr pattern))
                                              (ast-matches? (ast-let-body expr)
                                                            (caddr pattern)))))
                  ((letrec) (and (ast-letrec? expr)
                                 (unify-bindings (ast-list-matches? (ast-letrec-bindings expr)
                                                                    (cadr pattern))
                                                 (ast-matches? (ast-letrec-body expr)
                                                               (caddr pattern)))))
                  ((fix) (and (ast-fix? expr)
                              (unify-bindings (ast-list-matches? (ast-fix-bindings expr)
                                                                 (cadr pattern))
                                              (ast-matches? (ast-fix-body expr)
                                                            (caddr pattern)))))
                  ;; NOTE These need to be named differently as they interfere with convenience syntax of the patterns and binding resolution.
                  ((a-quote a-quasiquote an-unquote an-unquote-splicing)
                   (and (or (ast-quote? expr)
                            (ast-quasiquote? expr)
                            (ast-unquote? expr)
                            (ast-unquote-splicing? expr))
                        (ast-matches? (ast-quoted-expr expr) (cadr pattern))))
                  ((const)
                   (and (ast-const? expr)
                        (ast-matches? (ast-const-value expr) (cadr pattern))))
                  ;; NOTE These are special nodes that we might still want to match for error handling etc.
                  ((<error>) (and (ast-error? expr)
                                  (ast-matches? (ast-error-expr expr)
                                                (cadr pattern))))
                  ((<location>) (ast-location? expr))
                  (else #f)))))
        (else
         #f)))

(define (ast-list-matches? exprs pattern)
  (cond ((equal? pattern '_)
         (empty-bindings))
        ((and (empty? exprs)
              (empty? pattern))
         (empty-bindings))
        ((and (pair? pattern)
              (equal? (car pattern) 'unquote))
         (bindings (cadr pattern) exprs))
        ((and (pair? exprs)
              (pair? pattern))
         (unify-bindings (ast-matches? (car exprs) (car pattern))
                         (ast-list-matches? (cdr exprs) (cdr pattern))))
        (else
         #f)))

;; NOTE This is actually faster than using hasheq.

(define (empty-bindings)
  '())

(define (make-bindings assocs)
  (sort assocs
        (lambda (a b)
          (symbol<? (car a)
                    (car b)))))

(define (bindings key value)
  (list (cons key value)))

(define (unify-bindings as bs)
  (if (or (false? as)
          (false? bs))
      #f
      (if (every? (lambda (kv)
                    (let ((b (assoc (car kv) bs)))
                      (or (not b)
                          (ast-eqv? (cdr kv)
                                    (cdr b)))))
                  as)
          (sort (append bs as)
                (lambda (a b)
                  (symbol<? (car a)
                            (car b))))
          #f)))

(define (get-var vars var)
  (let ((b (assoc var vars)))
    (if b
        (cdr b)
        (compiler-bug "pattern variable undefined" var))))
