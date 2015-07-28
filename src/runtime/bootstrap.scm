;; The bootstrap code.

(load "runtime/rt.scm")

;; Built-in values:
(define __nil nil)

;; Built-in functions:
(define (cpsfy f)
  (lambda args
    (&yield-cont (last args)
                 (apply f
                        (take args
                              (- (length args) 1))))))

(define __car (cpsfy car))
(define __cadr (cpsfy car))
(define __cdr (cpsfy cdr))
(define __cddr (cpsfy cddr))

(define __cons (cpsfy cons))
(define __list (cpsfy list))

(define __MULT (cpsfy *))
(define __PLUS (cpsfy +))
(define ___ (cpsfy -))

(define __EQUAL (cpsfy =))
(define __LESS (cpsfy <))

;; Actor model:
(define (__sleep time cont)
  (inc-uproc-rtime! (current-task)
                    time)
  (&yield-cont cont time))

(define (__self cont)
  (&yield-cont cont (uproc-pid (current-task))))

(define (__node cont)
  ;; TODO
  (&yield-cont cont nil))

(define (__send pid msg cont)
  (let ((t (find-task pid)))
    ;; FIXME Throw exception when pid isn't found.
    (uproc-enqueue-msg! t msg)
    (when (equal? (uproc-state t) 'waiting-4-msg)
      (set-uproc-rtime! t (current-milliseconds))
      (enqueue-task! t))
    (&yield-cont cont pid)))

(define (__recv cont)
  (let ((p (current-task)))
    (if (uproc-msg-queue-empty? p)
        (do (set-uproc-state! p 'waiting-4-msg)
            (&yield-cont (lambda (_)
                           ;; NOTE Retry receive.
                           (__recv cont))
                         nil))
        (&yield-cont cont (uproc-dequeue-msg! p)))))

(define (__spawn fun cont)
  (let ((kont (lambda (v)
                (set-uproc-state! (current-task)
                                  'halted)
                v)))
    (&yield-cont cont (spawn-task! (&yield-cont (lambda (_)
                                                  (fun kont))
                                                nil)
                                   (lambda (e _)
                                     (display ";; Task finished due to unhandled error: ")
                                     (display e)
                                     (newline)
                                     (kont e))))))

;; Misc:
(define __task_info (cpsfy task-info))
(define __display (cpsfy display))
(define __newline (cpsfy newline))

;; Module system bootstrap:
(define __make_structure (cpsfy make-structure))
