;; The bootstrap code.

(load "compiler/utils.scm")
(load "runtime/rt.scm")
(load "rete/rete.scm")

;; Built-in values:
(define __nil nil)

;; Built-in functions:
(define (cpsfy f)
  (lambda args
    (&yield-cont (last args)
                 (apply f
                        (take args
                              (- (length args) 1))))))

(define (closurize f)
  (&make-closure '()
                 (lambda (env . args)
                   (apply f args))))

(define bootstrap (compose closurize cpsfy))

;; Basic

(define __car (bootstrap car))
(define __cadr (bootstrap car))
(define __cdr (bootstrap cdr))
(define __cddr (bootstrap cddr))

(define __list (bootstrap list))
(define __cons (bootstrap cons))
(define __append (bootstrap append))
(define __concat (bootstrap append))

(define __equalQUEST (bootstrap equal?))
(define __nilQUEST (bootstrap null?))

(define __MULT (bootstrap *))
(define __PLUS (bootstrap +))
(define ___ (bootstrap -))
(define __DIV (bootstrap /))

(define __EQUAL (bootstrap =))
(define __LESS (bootstrap <))

(define __ref (bootstrap ref))
(define __deref (bootstrap deref))
(define __assignBANG (bootstrap assign!))

;; Continuations:
(define __callDIVcurrent_continuation (closurize
                                       (lambda (f cont)
                                         (&apply f (closurize
                                                    (lambda (v _)
                                                      (&apply cont v)))
                                                 cont))))

(define __callDIVreset (closurize
                        (lambda (f cont)
                          (&push-delimited-continuation! cont)
                          (&apply f
                                  (closurize
                                   (lambda (v)
                                     (&apply (&pop-delimited-continuation!)
                                             v)))))))

(define __callDIVshift (closurize
                        (lambda (f cont)
                          (&apply f
                                  (closurize
                                     (lambda (v ct2)
                                       (&push-delimited-continuation! ct2)
                                       (&apply cont v)))
                                  (closurize
                                   (lambda (v)
                                     (&apply (&pop-delimited-continuation!)
                                             v)))))))

;; Exceptions:
(define __callDIVhandler (closurize
                          (lambda (handler f cont)
                            (let* ((curr-handler (&error-handler))
                                   (new-handler (closurize
                                                 (lambda (error restart)
                                                   (&set-error-handler! curr-handler)
                                                   (&apply handler error restart cont)))))
                              (&set-error-handler! new-handler)
                              (&apply f
                                      (closurize
                                       (lambda (v)
                                         (&set-error-handler! curr-handler)
                                         (&apply cont v))))))))

(define __raise_error (closurize
                       (lambda (e cont)
                         (let ((curr-handler (&error-handler)))
                           (&apply curr-handler
                                   e
                                   (closurize
                                    (lambda (v _)
                                      (&set-error-handler! curr-handler)
                                      (&apply cont v))))))))

;; Actor model:
(define __sleep (bootstrap wait))
(define __self (bootstrap self))
(define __send (bootstrap send))

(define __recv (bootstrap
                (lambda ()
                  (let ((r (recv)))
                    (if (car r)
                        (cdr r)
                        nil)))))

(define __spawn (bootstrap spawn))

(define __task_info (bootstrap task-info))
(define __monitor (bootstrap (lambda (timeout)
                               (task-info)
                               (&apply __sleep timeout (bootstrap (lambda _
                                                                    (&apply __monitor timeout id)))))))

;; RBS bootstrap:
(define __assertBANG (bootstrap assert!))
(define __signalBANG (bootstrap signal!))
(define __retractBANG (bootstrap retract!))
(define __select (bootstrap select))

(define __notify_whenever (bootstrap
                           (lambda (who pattern)
                             (whenever pattern
                                       ;; NOTE We can't use FOOF functions, since they yield execution.
                                       (lambda (b)
                                         (send who b))))))

;; Misc:
(define __display (bootstrap display))
(define __newline (bootstrap newline))
(define __random (bootstrap random))
(define __debug (bootstrap (lambda args
                             (pretty-print args)
                             (newline))))
