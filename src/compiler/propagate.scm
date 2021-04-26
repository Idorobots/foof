;; Generic binding propagation

(load "compiler/utils/utils.scm")

(load "compiler/ast.scm")
(load "compiler/substitute.scm") ;; FIXME For filter-subs.

(load "compiler/passes/freevars.scm") ;; FIXME Just for compute-*-fv

(define (propagate partition-by make-sub replace-with subs expr)
  (define (loop subs expr)
    (replace-with subs
                  expr
                  (lambda (expr)
                    (ast-case expr
                     ((const _)
                      expr)
                     ((lambda _ _)
                      (ast-update expr
                                  'body
                                  (partial loop
                                           (filter-subs subs
                                                        (get-bound-vars expr)))))
                     ((let ,bindings ,body)
                      (let* ((bs (partition-bindings partition-by bindings))
                             (updated-subs (append (map make-sub (car bs))
                                                   (filter-subs subs (get-bound-vars expr))))
                             (updated-bindings (map (partial loop subs)
                                                    (cdr bs))))
                        (reconstruct-let-node expr
                                              updated-bindings
                                              (loop updated-subs body))))
                     ((letrec ,bindings ,body)
                      (let* ((bs (select-first (partition-bindings partition-by bindings)
                                               bindings));; NOTE Can't use all propagatable bindings as they might interfere.
                             (updated-subs (append (map make-sub (car bs))
                                                   (filter-subs subs (get-bound-vars expr))))
                             (updated-bindings (map (partial loop updated-subs)
                                                    (cdr bs))))
                        (reconstruct-letrec-node expr
                                                 updated-bindings
                                                 (loop updated-subs body))))
                     ((fix ,bindings ,body)
                      (let* ((bs (select-first (partition-bindings partition-by bindings)
                                               bindings)) ;; NOTE Can't use all propagatable bindings as they might interfere.
                             (updated-subs (append (map make-sub (car bs))
                                                   (filter-subs subs (get-bound-vars expr))))
                             (updated-bindings (map (partial loop updated-subs)
                                                    (cdr bs))))
                        (reconstruct-fix-node expr
                                              updated-bindings
                                              (loop updated-subs body))))
                     ((binding _ _)
                      (ast-update expr 'val (partial loop subs)))
                     (else
                      (walk-ast (partial loop subs) expr))))))
  (loop subs expr))

(define (partition-bindings pred bindings)
  (foldr (lambda (b acc)
           (if (pred b)
               (cons (cons b (car acc))
                     (cdr acc))
               (cons (car acc)
                     (cons b (cdr acc)))))
         (cons '() '())
         bindings))

(define (select-first partitioned original)
  (let ((left (car partitioned)))
    (if (empty? left)
        partitioned
        (let ((selected (car left)))
          (cons (list selected)
                (filter (lambda (b)
                          (not (equal? b selected)))
                        original))))))

(define (reconstruct-let-node parent bindings body)
  (if (empty? bindings)
      body
      (compute-let-fv
       (at (get-location parent)
           (make-let-node bindings
                          body)))))

(define (reconstruct-letrec-node parent bindings body)
  (if (empty? bindings)
      body
      (compute-letrec-fv
       (at (get-location parent)
           (make-letrec-node bindings
                             body)))))

(define (reconstruct-fix-node parent bindings body)
  (if (empty? bindings)
      body
      (compute-fix-fv
       (at (get-location parent)
           (make-fix-node bindings
                          body)))))