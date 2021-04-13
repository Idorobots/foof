;; The compiler

(load "compiler/env.scm")
(load "compiler/ast.scm")

;; The frontend
(load "compiler/passes/parser.scm")
(load "compiler/passes/macro-expander.scm")
(load "compiler/passes/elaboration.scm")
(load "compiler/passes/body.scm")
(load "compiler/passes/qq.scm")
(load "compiler/passes/validate.scm")
(load "compiler/passes/errors.scm")

;; The backend
(load "compiler/passes/bindings.scm")
(load "compiler/passes/freevars.scm")
(load "compiler/passes/builtins.scm")
(load "compiler/passes/letrec-bindings.scm")
(load "compiler/passes/letrec-fix.scm")
(load "compiler/passes/cpc.scm")
(load "compiler/passes/closures.scm")
(load "compiler/passes/rename.scm")

(define (compile env)
  (foldl (lambda (phase expr)
           (phase expr))
         (env-set env
                  'errors '()
                  'macros (make-builtin-macros)
                  'globals (make-global-definitions-list))
         (list parse
               macro-expand
               elaborate
               body-expand
               quasiquote-expand
               annotate-free-vars
               annotate-bindings
               validate
               report-errors
               reorder-letrec-bindings
               fix-letrec
               inline-builtins
               continuation-passing-convert
               annotate-free-vars
               closure-convert
               symbol-rename
               generate-target-code)))

(define (generate-target-code env)
  ;; FIXME Actually implement a proper code-gen.
  (ast->plain (env-get env 'ast)))
