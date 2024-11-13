#| fibonacci |#
(defun fibonacci-1 (n)
  (cond ((< n 0) nil)
        ((= n 0) 1)
        ((= n 1) 1)
        (t (+ (fibonacci-1 (- n 1)) (fibonacci-1 (- n 2))))))

(defun fibonacci-2 (n &optional (i 2) (fn-1 1) (fn-2 1))
  (cond ((< n 0) nil)
        ((= n 0) 1)
        ((= n 1) 1)
        ((= n i) (+ fn-1 fn-2))
        (t (fibonacci-2 n (1+ i) (+ fn-1 fn-2) fn-1))))

(defun fibonacci-3 (n &optional (cont #'+))
  (cond ((< n 0) nil)
        ((= n 0) 1)
        ((= n 1) 1)
        ((= n 2) (funcall cont 1 1))
        (t (fibonacci-3 (1- n) (lambda (fn-1 fn-2)
                                 (funcall cont (+ fn-1 fn-2) fn-1))))))

