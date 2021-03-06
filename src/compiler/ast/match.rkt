#lang racket

;; AST pattern matching

(require "nodes.rkt")
(require "eqv.rkt")
(require "../errors.rkt")

(provide match-ast)

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
   (syntax-case stx (ast-quote ast-quasiquote ast-unquote ast-unquote-splicing ast-body ast-error ast-location
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
     ((ast-location pattern)
      #`(ast-node '<location> _ _ _ _ _ #,(match-ast-pattern #'pattern)))
     ((ast-error pattern)
      #`(ast-node '<error> _ _ _ _ _ #,(match-ast-pattern #'pattern)))
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
