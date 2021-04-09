;; The compiler

(load "compiler/env.scm")
(load "compiler/ast.scm")

;; The frontend
(load "compiler/parser.scm")
(load "compiler/macro-expander.scm")
(load "compiler/elaboration.scm")
(load "compiler/body.scm")
(load "compiler/qq.scm")
(load "compiler/validate.scm")
(load "compiler/errors.scm")

;; The backend
(load "compiler/bindings.scm")
(load "compiler/freevars.scm")
(load "compiler/builtins.scm")
(load "compiler/letrec.scm")
(load "compiler/cpc.scm")
(load "compiler/closures.scm")
(load "compiler/rename.scm")

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
               letrec-expand
               inline-builtins
               continuation-passing-convert
               annotate-free-vars
               closure-convert
               symbol-rename
               generate-target-code)))

(define (generate-target-code env)
  ;; FIXME Actually implement a proper code-gen.
  (ast->plain (env-get env 'ast)))
