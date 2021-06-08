#lang racket

;; A task debug monitor.

(require "processes.rkt")
(require "scheduler.rkt")

(provide task-info)

(define (paddify thing padding)
  (let ((s (format "~a" thing)))
    (string-append (make-string (max (- padding (string-length s)) 1)
                                #\ )
                   s)))

(define (display-line . args)
  (display ";;")
  (map (lambda (a)
         (display (paddify a 15)))
       (take args 3))
  (map (lambda (a)
         (display (paddify a 20)))
       (drop args 3))
  (newline))

(define (task-info)
  (display-line "PID" "priority" "state" "VTime" "RTime")
  (map (lambda (task)
         (display-line (uproc-pid task)
                       (uproc-priority task)
                       (uproc-state task)
                       (uproc-vtime task)
                       (uproc-rtime task)))
       (running-tasks))
  '())