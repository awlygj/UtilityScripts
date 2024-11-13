(defpackage #:random-untils
  (:use #:common-lisp)
  (:nicknames #:rd)
  (:export #:random-int
           #:random-int-pass
           #:random-int-range))

(in-package random-untils)

;;;;random int
(defun random-int (start end)
  (+ start (random (- end start))))

(defun iprange (pair)
  (if (atom pair)
    1
    (- (second pair) (first pair))))

(defun ipfirst (pair)
  (if (atom pair)
    pair
    (first pair)))

(defun ipsecond (pair)
  (if (atom pair)
    (1+ pair)
    (second pair)))

(defun random-int-pass (start end pass-lst)
  (let* ((pass-range-sum (apply #'+ (mapcar #'iprange pass-lst)))
         (r (random-int start (- end pass-range-sum))))
    (labels ((rc (lst r)
                 (if (null lst)
                   r
                   (let ((pair (car lst)))
                     (if (< r (ipfirst pair))
                       r
                       (rc (cdr lst) (+ r (iprange pair))))))))
      (rc pass-lst r))))

(defun random-int-range (lst)
  (let* ((limit (apply #'+ (mapcar #'iprange lst)))
         (r (random limit)))
    (labels ((rc (lst r)
                 (if (null lst)
                   r
                   (let* ((pair (car lst))
                          (start (ipfirst pair))
                          (end (ipsecond pair))
                          (nr (+ start r)))
                     (if (< nr end)
                       nr
                       (rc (cdr lst) (- nr end)))))))
      (rc lst r))))

;;;;random item
(defun random-item (&rest items)
  (do ((i (random (length items)) (1- i))
       (x items (cdr x)))
      ((= i 0) (car x))))

;;;;random char
(defun random-char (&optional (mode 'ALL))
  (case mode 
    ('ALL      (code-char (random-int 32 127)))
    ;;all display character exclude #\" #\' #\\
    ('ALL-EX0  (code-char (random-int-pass 32 127 '(34 39 92))))
    ;;all display character exclude #\space #\" #\' #\
    ('ALL-EX1  (code-char (random-int-pass 32 127 '(32 34 39 92))))
    ;;Alphabet
    ('ALPHABET (code-char (random-int-range '((65 91) (97 123)))))
    ('ALP-LOW  (code-char (random-int 97 123)))
    ('ALP-UP   (code-char (random-int 65 91)))
    ;;Number
    ('NUMBER   (code-char (random-int 48 58)))
    ;;Alphabet+Number
    ('ALP+NUM  (code-char (random-int-range '((48 58) (65 91) (97 123)))))
    ;;Punctuation marks
    ('PM       (code-char (random-int-range '((32 48) (58 65) (91 97) (123 127)))))
    ('PM-EX0   (code-char (rand

(defun random-string (len &optional (minlen 0))
  (let ((flen (if (= minlen 0)
                len
                (random-int minlen (1+ len)))))
    (let ((str (make-string flen)))
      (dotimes (i flen)
        (setf (char str i) (random-char)))
      str)))

|#


