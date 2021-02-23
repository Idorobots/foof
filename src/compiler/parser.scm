;; A very simple parser.

(load "compiler/utils.scm")
(load "compiler/peggen.scm")

;; FIXME Re-generates the parser on each boot of the compiler. Probably super slow.
(generate-parser
 '(Expression
   (/ List Atom String Quote))
 '(Quote
   (/ PlainQuote Quasiquote UnquoteSplicing Unquote))
 '(PlainQuote
   (Spacing "'" Expression)
   (lambda (input result)
     (let* ((matching (match-match result))
            (start (car matching))
            (end (match-end result)))
       (matches (list 'quote (caddr matching))
                start
                end))))
 '(Quasiquote
   (Spacing "`" Expression)
   (lambda (input result)
     (let* ((matching (match-match result))
            (start (car matching))
            (end (match-end result)))
       (matches (list 'quasiquote (caddr matching))
                start
                end))))
 '(Unquote
   (Spacing "," Expression)
   (lambda (input result)
     (let* ((matching (match-match result))
            (start (car matching))
            (end (match-end result)))
       (matches (list 'unquote (caddr matching))
                start
                end))))
 '(UnquoteSplicing
   (Spacing ",@" Expression)
   (lambda (input result)
     (let* ((matching (match-match result))
            (start (car matching))
            (end (match-end result)))
       (matches (list 'unquote-splicing (caddr matching))
                start
                end))))
 '(String
   (Spacing (& "\"") "\"[^\"]*\"")
   (lambda (input result)
     (let* ((matching (match-match result))
            (start (car matching))
            (end (match-end result))
            (content (caddr matching)))
       (matches (substring content 1 (- (string-length content) 1))
                start
                end))))
 '(List
   (Spacing "(" (* Expression) Spacing ")")
   (lambda (input result)
     (let* ((matching (match-match result))
            (start (car matching))
            (end (match-end result)))
       (matches (caddr matching)
                start
                end))))
 '(Atom
   (/ Symbol Number))
 '(Number
   (Spacing "[+\\-]?[0-9]+(\\.[0-9]*)?")
   (lambda (input result)
     (let* ((matching (match-match result))
            (spacing-start (match-start result))
            (start (car matching))
            (end (match-end result)))
       (matches (string->number (cadr matching))
                start
                end))))
 '(Symbol
   (Spacing (! Number) "[^\\(\\)\"'`,@; \t\v\r\n]+")
   (lambda (input result)
     (let* ((matching (match-match result))
            (start (car matching))
            (end (match-end result)))
       (matches (string->symbol (caddr matching))
                start
                end))))
 '(Spacing
   (: (* (/ "[ \t\v\r\n]+" Comment)))
   (lambda (input result)
     (let ((start (match-start result))
           (end (match-end result)))
       ;; NOTE So that we can skip the spacing later.
       (matches end start end))))
 '(Comment
   (: ";[^\n]*\n")))

(define (parse input)
  (let ((result (Expression input)))
    (if (matches? result)
        (match-match result)
        (error (format "Could not parse input: ~a" input)))))
