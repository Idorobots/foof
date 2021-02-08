;; Top level for tests.

(load "../test/utils.scm")
(load "../test/compiler/utils.scm")
(load "../test/compiler/parser.scm")
(load "../test/compiler/ast.scm")
(load "../test/compiler/syntax.scm")
(load "../test/compiler/macros.scm")
(load "../test/compiler/letrec.scm")
(load "../test/compiler/anormal.scm")
(load "../test/compiler/cpc.scm")
(load "../test/compiler/closures.scm")
(load "../test/compiler/rename.scm")
(load "../test/rt/queue.scm")
(load "../test/rt/scheduler.scm")
(load "../test/rt/recurse.scm") ;; FIXME Broken let after closure conversion.
(load "../test/rt/continuations.scm") ;; FIXME Broken let after closure conversion.
(load "../test/rt/exception.scm")
(load "../test/rt/actor.scm")
(load "../test/rt/modules.scm")
