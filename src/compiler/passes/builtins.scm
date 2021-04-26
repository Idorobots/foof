;; Builtins inliner

(load-once "compiler/utils/utils.scm")
(load-once "compiler/substitute.scm")

(load-once "compiler/env.scm")
(load-once "compiler/pass.scm")
(load-once "compiler/ast.scm")

(define inline-builtins
  (pass (schema "inline-builtins"
                'globals a-list?
                'ast (ast-subset? '(const symbol
                                    if do let letrec binding lambda app primop-app)))
        (lambda (env)
          (env-update env 'ast (partial inline-app-ops (env-get env 'globals))))))

(define (inline-app-ops builtins expr)
  (substitute (lambda (subs expr kont)
                (kont (ast-case expr
                       ((app (symbol ,op) . ,args)
                        (let ((b (assoc (ast-symbol-value op) subs)))
                          (if b
                              ((cdr b) expr)
                              expr)))
                       (else
                        expr))))
              (map (lambda (b)
                     (cons b
                           (lambda (expr)
                             (let ((args (ast-app-args expr)))
                               (replace expr
                                      ;; NOTE The op no longer needs to be stored in free vars.
                                      (free-vars
                                       (set-sum (map get-free-vars args))
                                       (make-primop-app-node b args)))))))
                   (set-intersection
                    builtins
                    (apply set
                           '(car cadr cdr cddr list cons append concat
                             equal? nil? not
                             * + - / = < zero?
                             ref deref assign!
                             self send spawn
                             assert! signal! retract! select notify-whenever
                             display newline debug
                             ;; NOTE These ones use the continuations, so they cannot be inlined.
                             ;; call/current-continuation call/reset call/shift call/handler raise recv
                             ;; FIXME These ones are overriden by the tests, so for the time being they can't be inlined.
                             ;; sleep random
                             ))))
              expr))
