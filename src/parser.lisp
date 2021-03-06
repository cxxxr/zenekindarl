(in-package :cl-user)
(defpackage :zenekindarl.parser
  (:use :cl :zenekindarl.util :zenekindarl.token :zenekindarl.att :mpc)
  (:export :=template))
(in-package :zenekindarl.parser)

(defun =token-string () (=satisfies #'token-string-p))
(defun =token-variable () (=satisfies #'token-variable-p))
(defun =token-if () (=satisfies #'token-if-p))
(defun =token-else () (=satisfies #'token-else-p))
(defun =token-end () (=satisfies #'token-end-p))
(defun =token-loop () (=satisfies #'token-loop-p))
(defun =token-repeat () (=satisfies #'token-repeat-p))
(defun =token-include () (=satisfies #'token-include-p))
(defun =token-insert () (=satisfies #'token-insert-p))

(defun =template-string ()
  (=let* ((token-string (=token-string)))
    (=result (att-output (att-string (token-str token-string))))))

(defun =control-variable ()
  (=let* ((token-variable (=token-variable)))
    (=result (att-output (att-variable (token-value token-variable)
				       :anything
				       (token-auto-escape token-variable))))))

(defun =control-if ()
  (=let* ((token-if (=token-if))
          (then     (=template))
          (else     (=maybe (=and (=token-else) (=template))))
          (_        (=token-end)))
    (=result (att-if (if (symbolp (token-cond-clause token-if))
                         (att-variable (token-cond-clause token-if))
                         (att-eval (token-cond-clause token-if)))
                     then
                     (if else
                         else
                         (att-nil))))))

(defun =control-loop ()
  (=let* ((token-loop (=token-loop))
          (body       (=template))
          (_          (=token-end)))
    (=result (att-loop
              (if (symbolp (token-seq token-loop))
                  (att-variable (token-seq token-loop))
                  (att-constant (token-seq token-loop)))
              body
              (if (token-loop-sym token-loop)
                  (att-variable (token-loop-sym token-loop))
                  (att-gensym "loopvar"))))))

(defun =control-repeat ()
  (=let* ((token-repeat (=token-repeat))
          (body       (=template))
          (_          (=token-end)))
    (=result (att-repeat
              (if (symbolp (token-times token-repeat))
                  (att-variable (token-times token-repeat))
                  (att-constant (token-times token-repeat)))
              body
              (if (token-repeat-sym token-repeat)
                  (att-variable (token-repeat-sym token-repeat))
                  (att-gensym "repeatvar"))))))

(defun =control-include ()
  (=let* ((token-include (=token-include)))
    (=result (run (=template)
                  (token-include-template token-include)))))

(defun =control-insert ()
  (=let* ((token-insert (=token-insert)))
    (=result (att-output (att-string (token-insert-string token-insert))))))


(defun =template ()
  (=let* ((tmp (=one-or-more
                (=or
                 (=template-string)
                 (=control-variable)
                 (=control-if)
                 (=control-loop)
                 (=control-repeat)
                 (=control-include)
                 (=control-insert)))))
    (=result (apply #'att-progn tmp))))
