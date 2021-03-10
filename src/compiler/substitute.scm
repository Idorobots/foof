;; Binding aware variable substitution.

(load "compiler/ast.scm")
(load "compiler/utils.scm")

(define (filter-subs subs vars)
  (filter (lambda (s)
            (not (member (car s) vars)))
          subs))

;; FIXME Rewrite in terms of ast/walk.
(define (substitute subs expr)
  (cond ((empty? subs) expr)
        ((simple? expr) expr)
        ((symbol? expr) (let ((a (assoc expr subs)))
                          (if a
                              (cdr a)
                              expr)))
        ((lambda? expr) (let ((vars (lambda-args expr)))
                          (make-lambda vars
                                       (substitute (filter-subs subs vars)
                                                   (lambda-body expr)))))
        ((let? expr) (let* ((bindings (let-bindings expr))
                            (subbed-bindings (map (lambda (b)
                                                    (list (car b)
                                                          (substitute subs (cadr b))))
                                                  bindings)))
                       (make-let subbed-bindings
                                 (substitute (filter-subs subs (bindings-vars bindings))
                                             (let-body expr)))))
        ((or (letrec? expr)
             (fix? expr)) (let* ((bindings (let-bindings expr))
                                 (unbound-subs (filter-subs subs (bindings-vars bindings)))
                                 (subbed-bindings (map (lambda (b)
                                                         (list (car b)
                                                               (substitute unbound-subs (cadr b))))
                                                       bindings)))
                            (make-letrec subbed-bindings
                                         (substitute unbound-subs (let-body expr)))))
        ((value-define? expr) (make-val-define (define-name expr)
                                               (substitute subs (define-value expr))))
        ((define? expr) (make-define (define-name expr)
                                     (define-args expr)
                                     (substitute subs (define-body expr))))
        ((set!? expr) (make-set! (set!-var expr)
                                 (substitute subs (set!-val expr))))
        ((do? expr) (make-do (map (lambda (s)
                                    (substitute subs s))
                                  (do-statements expr))))
        ((if? expr) (make-if (substitute subs (if-predicate expr))
                             (substitute subs (if-then expr))
                             (substitute subs (if-else expr))))
        ((application? expr) (make-app (substitute subs (app-op expr))
                                       (map (lambda (a)
                                              (substitute subs a))
                                            (app-args expr))))
        ((module? expr) (make-module (module-name expr)
                                     (module-deps expr)
                                     (map (lambda (s)
                                            (substitute subs s))
                                          (module-body expr))))
        ((structure? expr) (make-structure (map (lambda (s)
                                                  (substitute subs s))
                                                (structure-defs expr))))
        (else expr)))
