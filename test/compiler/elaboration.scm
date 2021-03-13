;; Semantic elaboration.

(describe
 "elaboration"
 (it "elaborates valid ifs"
     (assert (elaborate-syntax-forms (at (location 5 23)
                                         (make-list-node
                                          (list (make-symbol-node 'if)
                                                (make-number-node 23)
                                                (make-number-node 5)
                                                (make-number-node 0)))))
             (at (location 5 23)
                 (make-if-node (make-number-node 23)
                               (make-number-node 5)
                               (make-number-node 0)))))

 (it "disallows bad if syntax"
     (assert (with-handlers ((compilation-error?
                              compilation-error-what))
               (elaborate-syntax-forms (at (location 5 23)
                                           (make-list-node
                                            (list (at (location 7 8)
                                                      (make-symbol-node 'if))
                                                  (at (location 9 10)
                                                      (make-symbol-node 'cond))
                                                  (at (location 11 12)
                                                      (make-symbol-node 'then)))))))
             "Bad `if` syntax, expected exactly three expressions - condition, then and else branches - to follow:")
     (assert (with-handlers ((compilation-error?
                              compilation-error-what))
               (elaborate-syntax-forms (at (location 5 23)
                                           (make-list-node
                                            (list (at (location 7 8)
                                                      (make-symbol-node 'if))
                                                  (at (location 9 10)
                                                      (make-symbol-node 'cond)))))))
             "Bad `if` syntax, expected exactly three expressions - condition, then and else branches - to follow:")
     (assert (with-handlers ((compilation-error?
                              compilation-error-what))
               (elaborate-syntax-forms (at (location 5 23)
                                           (make-list-node
                                            (list (at (location 7 8)
                                                      (make-symbol-node 'if)))))))
             "Bad `if` syntax, expected exactly three expressions - condition, then and else branches - to follow:")
     (assert (with-handlers ((compilation-error?
                              compilation-error-what))
               (elaborate-syntax-forms (at (location 5 23)
                                           (make-list-node
                                            (list (at (location 7 8)
                                                      (make-symbol-node 'if))
                                                  (at (location 9 10)
                                                      (make-symbol-node 'cond))
                                                  (at (location 11 12)
                                                      (make-symbol-node 'then))
                                                  (at (location 11 12)
                                                      (make-symbol-node 'else))
                                                  (at (location 11 12)
                                                      (make-symbol-node '???)))))))
             "Bad `if` syntax, expected exactly three expressions - condition, then and else branches - to follow:"))

 (it "elaborates valid dos"
     (assert (elaborate-syntax-forms (at (location 5 23)
                                         (make-list-node
                                          (list (make-symbol-node 'do)
                                                (make-number-node 23)
                                                (make-number-node 5)))))
             (at (location 5 23)
                 (make-do-node
                  (list (make-number-node 23)
                        (make-number-node 5))))))

 (it "disallows bad do syntax"
     (assert (with-handlers ((compilation-error?
                              compilation-error-what))
               (elaborate-syntax-forms (at (location 5 23)
                                           (make-list-node
                                            (list (at (location 7 13)
                                                      (make-symbol-node 'do)))))))
             "Bad `do` syntax, expected at least one expression to follow:"))

 (it "elaborates valid lambdas"
     (assert (elaborate-syntax-forms (at (location 5 23)
                                         (make-list-node
                                          (list (make-symbol-node 'lambda)
                                                (make-list-node
                                                 (list (make-symbol-node 'x)))
                                                (make-symbol-node 'x)))))
             (at (location 5 23)
                 (make-lambda-node
                  (list (make-symbol-node 'x))
                  (make-symbol-node 'x))))
     (assert (elaborate-syntax-forms (at (location 5 23)
                                         (make-list-node
                                          (list (make-symbol-node 'lambda)
                                                (make-list-node
                                                 (list (make-symbol-node 'x)))
                                                (at (location 7 13)
                                                    (make-symbol-node 'y))
                                                (at (location 14 15)
                                                    (make-symbol-node 'x))))))
             (at (location 5 23)
                 (make-lambda-node
                  (list (make-symbol-node 'x))
                  (at (location 7 15)
                      (generated
                       (make-do-node
                        (list (at (location 7 13)
                                  (make-symbol-node 'y))
                              (at (location 14 15)
                                  (make-symbol-node 'x))))))))))

 (it "disallows bad lambda syntax"
     (assert (with-handlers ((compilation-error?
                              compilation-error-what))
               (elaborate-syntax-forms (at (location 5 23)
                                           (make-list-node
                                            (list (at (location 7 13)
                                                      (make-symbol-node 'lambda)))))))
             "Bad `lambda` syntax, expected a formal arguments specification followed by a body:")
     (assert (with-handlers ((compilation-error?
                              compilation-error-what))
               (elaborate-syntax-forms (at (location 5 23)
                                           (make-list-node
                                            (list (at (location 7 13)
                                                      (make-symbol-node 'lambda))
                                                  (make-symbol-node 'x))))))
             "Bad `lambda` syntax, expected a formal arguments specification followed by a body:")
     (assert (with-handlers ((compilation-error?
                              compilation-error-what))
               (elaborate-syntax-forms (at (location 5 23)
                                           (make-list-node
                                            (list (make-symbol-node 'lambda)
                                                  (at (location 7 13)
                                                      (make-list-node
                                                       (list (make-symbol-node 'x)
                                                             (at (location 10 11)
                                                                 (make-number-node 23)))))
                                                  (make-symbol-node 'x))))))
             "Bad `lambda` formal arguments syntax, expected a symbol but got a number instead:"))

 (it "elaborates valid let"
     (assert (elaborate-syntax-forms (at (location 5 23)
                                         (make-list-node
                                          (list (make-symbol-node 'let)
                                                (make-list-node
                                                 (list (make-list-node
                                                        (list (make-symbol-node 'x)
                                                              (make-number-node 23)))))
                                                (make-symbol-node 'x)))))
             (at (location 5 23)
                 (make-let-node
                  (list (cons (make-symbol-node 'x)
                              (make-number-node 23)))
                  (make-symbol-node 'x))))
     (assert (elaborate-syntax-forms (at (location 5 23)
                                         (make-list-node
                                          (list (make-symbol-node 'let)
                                                (make-list-node
                                                 (list (make-list-node
                                                        (list (make-symbol-node 'x)
                                                              (make-number-node 23)))
                                                       (make-list-node
                                                        (list (make-symbol-node 'y)
                                                              (make-number-node 5)))))
                                                (make-symbol-node 'x)))))
             (at (location 5 23)
                 (make-let-node
                  (list (cons (make-symbol-node 'x)
                              (make-number-node 23))
                        (cons (make-symbol-node 'y)
                              (make-number-node 5)))
                  (make-symbol-node 'x))))
     (assert (elaborate-syntax-forms (at (location 5 23)
                                         (make-list-node
                                          (list (make-symbol-node 'let)
                                                (make-list-node
                                                 (list (make-list-node
                                                        (list (make-symbol-node 'x)
                                                              (make-number-node 23)))))
                                                (at (location 7 13)
                                                    (make-symbol-node 'y))
                                                (at (location 14 15)
                                                    (make-symbol-node 'x))))))
             (at (location 5 23)
                 (make-let-node
                  (list (cons (make-symbol-node 'x)
                              (make-number-node 23)))
                  (at (location 7 15)
                      (generated
                       (make-do-node
                        (list (at (location 7 13)
                                  (make-symbol-node 'y))
                              (at (location 14 15)
                                  (make-symbol-node 'x))))))))))

 (it "disallows bad let syntax"
     (assert (with-handlers ((compilation-error?
                              compilation-error-what))
               (elaborate-syntax-forms (at (location 5 23)
                                           (make-list-node
                                            (list (at (location 7 13)
                                                      (make-symbol-node 'let)))))))
             "Bad `let` syntax, expected a list of bindings followed by a body:")
     (assert (with-handlers ((compilation-error?
                              compilation-error-what))
               (elaborate-syntax-forms (at (location 5 23)
                                           (make-list-node
                                            (list (at (location 7 13)
                                                      (make-symbol-node 'let))
                                                  (make-symbol-node 'x))))))
             "Bad `let` syntax, expected a list of bindings followed by a body:")
     (assert (with-handlers ((compilation-error?
                              compilation-error-what))
               (elaborate-syntax-forms (at (location 5 23)
                                           (make-list-node
                                            (list (make-symbol-node 'let)
                                                  (at (location 7 13)
                                                      (make-list-node
                                                       (list (make-number-node 23))))
                                                  (make-symbol-node 'x))))))
             "Bad bindings format, expected a list of (identifier <value>) pairs:")
     (assert (with-handlers ((compilation-error?
                              compilation-error-what))
               (elaborate-syntax-forms (at (location 5 23)
                                           (make-list-node
                                            (list (make-symbol-node 'let)
                                                  (at (location 7 13)
                                                      (make-list-node
                                                       (list (make-list-node
                                                              (list (make-number-node 23)
                                                                    (make-number-node 23))))))
                                                  (make-symbol-node 'x))))))
             "Bad bindings format, expected a list of (identifier <value>) pairs:"))

 (it "elaborates valid letrec"
     (assert (elaborate-syntax-forms (at (location 5 23)
                                         (make-list-node
                                          (list (make-symbol-node 'letrec)
                                                (make-list-node
                                                 (list (make-list-node
                                                        (list (make-symbol-node 'x)
                                                              (make-number-node 23)))))
                                                (make-symbol-node 'x)))))
             (at (location 5 23)
                 (make-letrec-node
                  (list (cons (make-symbol-node 'x)
                              (make-number-node 23)))
                  (make-symbol-node 'x))))
     (assert (elaborate-syntax-forms (at (location 5 23)
                                         (make-list-node
                                          (list (make-symbol-node 'letrec)
                                                (make-list-node
                                                 (list (make-list-node
                                                        (list (make-symbol-node 'x)
                                                              (make-number-node 23)))
                                                       (make-list-node
                                                        (list (make-symbol-node 'y)
                                                              (make-number-node 5)))))
                                                (make-symbol-node 'x)))))
             (at (location 5 23)
                 (make-letrec-node
                  (list (cons (make-symbol-node 'x)
                              (make-number-node 23))
                        (cons (make-symbol-node 'y)
                              (make-number-node 5)))
                  (make-symbol-node 'x))))
     (assert (elaborate-syntax-forms (at (location 5 23)
                                         (make-list-node
                                          (list (make-symbol-node 'letrec)
                                                (make-list-node
                                                 (list (make-list-node
                                                        (list (make-symbol-node 'x)
                                                              (make-number-node 23)))))
                                                (at (location 7 13)
                                                    (make-symbol-node 'y))
                                                (at (location 14 15)
                                                    (make-symbol-node 'x))))))
             (at (location 5 23)
                 (make-letrec-node
                  (list (cons (make-symbol-node 'x)
                              (make-number-node 23)))
                  (at (location 7 15)
                      (generated
                       (make-do-node
                        (list (at (location 7 13)
                                  (make-symbol-node 'y))
                              (at (location 14 15)
                                  (make-symbol-node 'x))))))))))

 (it "disallows bad letrec syntax"
     (assert (with-handlers ((compilation-error?
                              compilation-error-what))
               (elaborate-syntax-forms (at (location 5 23)
                                           (make-list-node
                                            (list (at (location 7 13)
                                                      (make-symbol-node 'letrec)))))))
             "Bad `letrec` syntax, expected a list of bindings followed by a body:")
     (assert (with-handlers ((compilation-error?
                              compilation-error-what))
               (elaborate-syntax-forms (at (location 5 23)
                                           (make-list-node
                                            (list (at (location 7 13)
                                                      (make-symbol-node 'letrec))
                                                  (make-symbol-node 'x))))))
             "Bad `letrec` syntax, expected a list of bindings followed by a body:")
     (assert (with-handlers ((compilation-error?
                              compilation-error-what))
               (elaborate-syntax-forms (at (location 5 23)
                                           (make-list-node
                                            (list (make-symbol-node 'letrec)
                                                  (at (location 7 13)
                                                      (make-list-node
                                                       (list (make-number-node 23))))
                                                  (make-symbol-node 'x))))))
             "Bad bindings format, expected a list of (identifier <value>) pairs:")
     (assert (with-handlers ((compilation-error?
                              compilation-error-what))
               (elaborate-syntax-forms (at (location 5 23)
                                           (make-list-node
                                            (list (make-symbol-node 'letrec)
                                                  (at (location 7 13)
                                                      (make-list-node
                                                       (list (make-list-node
                                                              (list (make-number-node 23)
                                                                    (make-number-node 23))))))
                                                  (make-symbol-node 'x))))))
             "Bad bindings format, expected a list of (identifier <value>) pairs:"))

 (it "elaborates valid quotes"
     (assert (elaborate-syntax-forms (at (location 5 23)
                                         (make-list-node
                                          (list (make-symbol-node 'quote)
                                                (make-number-node 23)))))
             (at (location 5 23)
                 (make-quote-node
                  (make-number-node 23))))
     (assert (elaborate-syntax-forms (at (location 5 23)
                                         (make-list-node
                                          (list (make-symbol-node 'unquote)
                                                (make-number-node 23)))))
             (at (location 5 23)
                 (make-unquote-node
                  (make-number-node 23))))
     (assert (elaborate-syntax-forms (at (location 5 23)
                                         (make-list-node
                                          (list (make-symbol-node 'quasiquote)
                                                (make-number-node 23)))))
             (at (location 5 23)
                 (make-quasiquote-node
                  (make-number-node 23))))
     (assert (elaborate-syntax-forms (at (location 5 23)
                                         (make-list-node
                                          (list (make-symbol-node 'unquote-splicing)
                                                (make-number-node 23)))))
             (at (location 5 23)
                 (make-unquote-splicing-node
                  (make-number-node 23)))))

 (it "disallows bad quote syntax"
     (map (lambda (q)
            (assert (with-handlers ((compilation-error?
                                     compilation-error-what))
                      (elaborate-syntax-forms (at (location 5 23)
                                                  (make-list-node
                                                   (list (at (location 7 13)
                                                             (make-symbol-node q))
                                                         (make-number-node 23)
                                                         (make-number-node 5))))))
                    (format "Bad `~a` syntax, expected exactly one expression to follow:" q))
            (assert (with-handlers ((compilation-error?
                                     compilation-error-what))
                      (elaborate-syntax-forms (at (location 5 23)
                                                  (make-list-node
                                                   (list (at (location 7 13)
                                                             (make-symbol-node q)))))))
                    (format "Bad `~a` syntax, expected exactly one expression to follow:" q)))
          (list 'quote 'quasiquote 'unquote 'unquote-splicing)))

 (it "handles valid defines"
     (assert (elaborate-syntax-forms (at (location 5 23)
                                         (make-list-node
                                          (list (make-symbol-node 'define)
                                                (make-symbol-node 'foo)
                                                (make-number-node 23)))))
             (at (location 5 23)
                 (make-def-node
                  (make-symbol-node 'foo)
                  (make-number-node 23))))
     (assert (elaborate-syntax-forms (at (location 5 23)
                                         (make-list-node
                                          (list (make-symbol-node 'define)
                                                (at (location 7 13)
                                                    (make-list-node
                                                     (list (make-symbol-node 'foo))))
                                                (make-number-node 23)))))
             (at (location 5 23)
                 (make-def-node
                  (make-symbol-node 'foo)
                  (at (location 5 23)
                      (generated
                       (make-lambda-node
                        '()
                        (make-number-node 23)))))))
     (assert (elaborate-syntax-forms (at (location 5 23)
                                         (make-list-node
                                          (list (make-symbol-node 'define)
                                                (at (location 7 13)
                                                    (make-list-node
                                                     (list (make-symbol-node 'foo)
                                                           (make-symbol-node 'x))))
                                                (make-symbol-node 'x)))))
             (at (location 5 23)
                 (make-def-node
                  (make-symbol-node 'foo)
                  (at (location 5 23)
                      (generated
                       (make-lambda-node
                        (list (make-symbol-node 'x))
                        (make-symbol-node 'x))))))))

 (it "disallows invalid defines"
     (assert (with-handlers ((compilation-error?
                              compilation-error-what))
               (elaborate-syntax-forms (at (location 5 23)
                                           (make-list-node
                                            (list
                                             (at (location 7 13)
                                                 (make-symbol-node 'define)))))))
             "Bad `define` syntax, expected either an identifier and an expression or a function signature and a body to follow:")
     (assert (with-handlers ((compilation-error?
                              compilation-error-what))
               (elaborate-syntax-forms (at (location 5 23)
                                           (make-list-node
                                            (list (at (location 7 13)
                                                      (make-symbol-node 'define))
                                                  (make-symbol-node 'foo))))))
             "Bad `define` syntax, expected either an identifier and an expression or a function signature and a body to follow:")
     (assert (with-handlers ((compilation-error?
                              compilation-error-what))
               (elaborate-syntax-forms (at (location 5 23)
                                           (make-list-node
                                            (list (at (location 7 13)
                                                      (make-symbol-node 'define))
                                                  (at (location 9 10)
                                                      (make-number-node 23))
                                                  (make-symbol-node 'foo))))))
             "Bad `define` syntax, expected a symbol but got a number instead:")
     (assert (with-handlers ((compilation-error?
                              compilation-error-what))
               (elaborate-syntax-forms (at (location 5 23)
                                           (make-list-node
                                            (list (at (location 7 13)
                                                      (make-symbol-node 'define))
                                                  (make-list-node
                                                   (list (make-symbol-node 'foo)
                                                         (make-number-node 23))))))))
             "Bad `define` syntax, expected either an identifier and an expression or a function signature and a body to follow:")
     (assert (with-handlers ((compilation-error?
                              compilation-error-what))
               (elaborate-syntax-forms (at (location 5 23)
                                           (make-list-node
                                            (list (at (location 5 7)
                                                      (make-symbol-node 'define))
                                                  (at (location 7 13)
                                                      (make-list-node
                                                       (list (make-symbol-node 'foo)
                                                             (at (location 9 10)
                                                                 (make-number-node 23)))))
                                                  (make-number-node 23))))))
             "Bad `define` function signature syntax, expected a symbol but got a number instead:")
     (assert (with-handlers ((compilation-error?
                              compilation-error-what))
               (elaborate-syntax-forms (at (location 5 23)
                                           (make-list-node
                                            (list (at (location 5 7)
                                                      (make-symbol-node 'define))
                                                  (at (location 7 13)
                                                      (make-list-node
                                                       (list (at (location 9 10)
                                                                 (make-number-node 23))
                                                             (make-symbol-node 'foo))))
                                                  (make-number-node 23))))))
            "Bad `define` syntax, expected a symbol but got a number instead:")))
