;; Constant propagation tests.

(require "../testing.rkt")
(require "../../src/compiler/ast.rkt")
(require "../../src/compiler/passes/const-propagation.rkt")

(describe
 "constant-propagation"
 (it "should subtitute usages of bound consts"
     (check ((var gen-valid-symbol)
             (sym (gen-symbol-node var))
             (const gen-const-node)
             (node (gen-if-node gen-valid-symbol-node
                                sym
                                gen-valid-symbol-node)))
            (assert (constant-propagation (make-subs (list (cons var const)))
                                          sym)
                    const)
            (assert-ast (constant-propagation (make-subs (list (cons var const)))
                                              node)
                        (if converted-cond
                            converted-then
                            converted-else)
                        (assert converted-cond (ast-if-condition node))
                        (assert converted-then const)
                        (assert converted-else (ast-if-else node)))))

 (it "should preserve lambda-bound variables"
     (check ((var gen-valid-symbol)
             (const gen-const-node)
             (arg1 (gen-symbol-node var))
             (node1 (gen-with-fv-bv (gen-lambda-node (list arg1) arg1)
                                    (set var)
                                    (set var)))
             (other-var gen-valid-symbol)
             (arg2 (gen-symbol-node other-var))
             (node2 (gen-with-fv-bv (gen-lambda-node (list arg2) arg1)
                                    (set var)
                                    (set other-var))))
            (assert (constant-propagation (make-subs (list (cons var const)))
                                          node1)
                    node1)
            (assert-ast (constant-propagation (make-subs (list (cons var const)))
                                              node2)
                        (lambda _ converted-body)
                        (assert converted-body const))))

 (it "should handle let bound consts"
     (check ((var1 gen-valid-symbol)
             (sym1 (gen-symbol-node var1))
             (const gen-const-node)
             (b1 (gen-binding-node sym1 gen-valid-symbol-node))
             (node (gen-with-fv-bv (gen-let-node (list b1) sym1)
                                   (set var1)
                                   (set var1))))
            (assert-ast (constant-propagation (make-subs '()) node)
                        (let (converted-binding)
                          converted-body)
                        (assert converted-binding b1)
                        (assert converted-body sym1)))
     (check ((var1 gen-valid-symbol)
             (sym1 (gen-symbol-node var1))
             (const gen-const-node)
             (b1 (gen-binding-node sym1 const))
             (var2 gen-valid-symbol)
             (sym2 (gen-symbol-node var2))
             (b2 (gen-binding-node sym2 sym1))
             (node (gen-with-fv-bv (gen-let-node (list b1 b2) sym1)
                                   (set var1)
                                   (set var2 var1))))
            (assert-ast (constant-propagation (make-subs '()) node)
                        (let ((binding converted-sym2 converted-sym1))
                          converted-body)
                        (assert converted-sym2 sym2)
                        (assert converted-sym1 sym1)
                        (assert converted-body const))))

 (it "should handle letrec bound consts"
     (check ((var1 gen-valid-symbol)
             (sym1 (gen-symbol-node var1))
             (const gen-const-node)
             (b1 (gen-binding-node sym1 gen-valid-symbol-node))
             (node (gen-with-fv-bv (gen-letrec-node (list b1) sym1)
                                   (set var1)
                                   (set var1))))
            (assert-ast (constant-propagation (make-subs '()) node)
                        (letrec (converted-binding)
                          converted-body)
                        (assert converted-binding b1)
                        (assert converted-body sym1)))
     (check ((var1 gen-valid-symbol)
             (sym1 (gen-symbol-node var1))
             (const gen-const-node)
             (b1 (gen-binding-node sym1 const))
             (var2 gen-valid-symbol)
             (sym2 (gen-symbol-node var2))
             (b2 (gen-binding-node sym2 sym1))
             (node (gen-with-fv-bv (gen-letrec-node (list b1 b2) sym1)
                                   (set var1)
                                   (set var2 var1))))
            (assert-ast (constant-propagation (make-subs '()) node)
                        (letrec ((binding converted-sym2 converted-sym1))
                          converted-body)
                        (assert converted-sym2 sym2)
                        (assert converted-sym1 const)
                        (assert converted-body const)))))
