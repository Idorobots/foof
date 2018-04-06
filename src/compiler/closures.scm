;; Closure conversion.
;; Assumes macro-expanded code.

(load "compiler/ast.scm")
(load "compiler/utils.scm")

(define (closure-convert expr globals)
  (let ((cc (flip closure-convert globals)))
    (cond ((lambda? expr) (cc-lambda (make-lambda (lambda-args expr)
                                                  (make-do (map cc (lambda-body expr))))
                                     globals))
          ((simple-expression? expr) expr)
          ((define? expr) (make-define-1 (define-name expr)
                                         (cc (define-value expr))))
          ((do? expr) (make-do (map cc (do-statements expr))))
          ((if? expr) (make-if (cc (if-predicate expr))
                               (cc (if-then expr))
                               (cc (if-else expr))))
          ((let? expr) (make-let (map (lambda (b)
                                        (list (car b)
                                              (cc (cadr b))))
                                      (let-bindings expr))
                                 (make-do (map cc (let-body expr)))))
          ((letrec? expr) (make-letrec (map (lambda (b)
                                              (list (car b)
                                                    (cc (cadr b))))
                                            (let-bindings expr))
                                       (make-do (map cc (let-body expr)))))
          ;; These shouldn't be here anymore.
          ((letcc? expr) (make-letcc (let-bindings expr)
                                     (make-do (map cc (let-body expr)))))
          ((reset? expr) (make-reset (cc (reset-expr expr))))
          ((shift? expr) (make-shift (shift-cont expr)
                                     (cc (shift-expr expr))))
          ((handle? expr) (make-handle (cc (handle-expr expr))
                                       (cc (handle-handler expr))))
          ((raise? expr) (make-raise (cc (raise-expr expr))))
          ;; --
          ((application? expr) (cc-application expr globals))
          ('else (error "Unexpected expression:" expr)))))

(define (make-global-environment)
  '(&apply
    &env-ref
    &make-env
    &make-closure
    &set-uproc-error-handler!
    &structure-ref
    &uproc-error-handler
    &yield-cont
    ;; FIXME let & set! is required by current, broken letrec implementation.
    set!
    let))

(define (cc-lambda expr globals)
  (let ((env (gensym 'env))
        (args (lambda-args expr))
        (body (lambda-body expr))
        (free (set-difference (free-vars expr)
                              globals)))
    (make-app '&make-closure
              (list (make-app '&make-env free)
                    (make-lambda (cons env args)
                                 (substitute (map (lambda (var)
                                                    (cons var
                                                          (make-app '&env-ref
                                                                    (list env
                                                                          (offset var free)))))
                                                  free)
                                             (make-do body)))))))

(define (cc-application expr globals)
  (let* ((cc (flip closure-convert globals))
         (op (app-op expr))
         (args (map cc (app-args expr))))
    (if (member op globals)
        (make-app op args)
        (make-app '&apply
                  (cons (cc (app-op expr))
                        args)))))

(define (free-vars expr)
  (cond ((symbol? expr) (set expr))
        ((number? expr) (set))
        ((string? expr) (set))
        ((vector? expr) (set))
        ((nil? expr) (set))
        ((char? expr) (set))
        ((quote? expr) (set))
        ((lambda? expr) (set-difference (free-vars (lambda-body expr))
                                        (apply set (lambda-args expr))))
        ((define? expr) (free-vars (define-value expr)))
        ((do? expr) (set-sum (map free-vars
                                  (do-statements expr))))
        ((if? expr) (set-sum (list (free-vars (if-predicate expr))
                                   (free-vars (if-then expr))
                                   (free-vars (if-else expr)))))
        ((let? expr) (set-difference (set-union (set-sum (map (compose free-vars cadr)
                                                                 (let-bindings expr)))
                                                   (free-vars (let-body expr)))
                                        (set-sum (map (compose free-vars car)
                                                      (let-bindings expr)))))
        ((letcc? expr) (set-difference (free-vars (let-body expr))
                                       (set (let-bindings expr))))
        ((letrec? expr) (set-difference (set-union (set-sum (map (compose free-vars cadr)
                                                                 (let-bindings expr)))
                                                   (free-vars (let-body expr)))
                                        (set-sum (map (compose free-vars car)
                                                      (let-bindings expr)))))
        ((reset? expr) (free-vars (reset-expr expr)))
        ((shift? expr) (set-difference (free-vars (shift-expr expr))
                                       (set (shift-cont expr))))
        ((handle? expr) (set-union (free-vars (handle-expr expr))
                                   (free-vars (handle-handler expr))))
        ((raise? expr) (free-vars (raise-expr expr)))
        ((application? expr) (set-union (free-vars (app-op expr))
                                        (foldl set-union
                                               (set)
                                               (map free-vars
                                                    (app-args expr)))))))

(define (substitute subs expr)
  (cond ((symbol? expr) (subs-symbol subs expr))
        ((number? expr) expr)
        ((string? expr) expr)
        ((vector? expr) expr)
        ((nil? expr) expr)
        ((char? expr) expr)
        ((quote? expr) expr)
        ('else (map (partial substitute subs) expr))))

(define (subs-symbol subs symbol)
  (let ((a (assoc symbol subs)))
    (if a
        (cdr a)
        symbol)))
