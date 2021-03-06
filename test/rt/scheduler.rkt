#lang racket

;; Process scheduling tests.

(require "../testing.rkt")
(require "../../src/main.rkt")
(require "../../src/runtime/rt.rkt")
(require "../../src/compiler/utils/utils.rkt")

(describe
 "scheduler"
 (it "Can step a process:"
     (assert (not (executable? (make-uproc 100 '() '() 0 'waiting))))
     (assert (executable? (make-uproc 100 (&yield-cont (&make-closure (&make-env) id) '()) '() 0 'waiting)))
     (assert (uproc? (execute-step! (make-uproc 100 (&yield-cont (&make-closure (&make-env) id) '()) '() 0 'waiting)))))

 (it "Can modify task list:"
     (let ((t (make-uproc 100 '() '() 0 'waiting)))
       (assert (begin (reset-tasks! (list t))
                      (next-task))
               t))
     (let* ((t1 (make-uproc 100 '() '() 1 'waiting))
            (t2 (make-uproc 100 '() '() 2 'waiting)))
       (assert (begin (reset-tasks! (list t1 t2))
                      (next-task))
               t1)
       (assert (begin (reset-tasks! (list t1 t2))
                      (dequeue-next-task!)
                      (next-task))
               t2)))

 (it "Can as easily resume stuff."
     (assert (resume
              (resume
               (resume
                (&apply __MULT 3 2 (&make-closure
                                    (&make-env)
                                    (lambda (_ mult)
                                      (&apply __PLUS 3 3 (&make-closure
                                                          (&make-env mult)
                                                          (lambda (e plus)
                                                            (&apply __EQUAL (&env-ref e 0) plus (&make-closure
                                                                                                 (&make-env)
                                                                                                 (lambda (_ v) v))))))))))))))

 (it "Can run compiled code."
     (assert (run '23) 23)
     (assert (run '(= (* 3 2) (+ 3 3)))))

 (it "Runing stuff changes state."
     (let ((p (make-uproc 100 '() '() 0 'waiting)))
       (reset-tasks! (list p))
       (assert (uproc-state p) 'waiting)
       (dequeue-next-task!)
       (assert (uproc-state p) 'running))))
