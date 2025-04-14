(defpackage #:random-untils
  (:use #:common-lisp)
  (:nicknames #:rand)
  (:export #:random-int
	   #:random-char
           #:random-string
           #:random-datetime))

(in-package random-untils)

(declaim (inline rlst-limit
		 rlst-add
		 rlst-remove
		 copy-nrange
		 modify-nrange
		 random-num-from-range
		 int-atom->pair
		 random-int
		 random-item))

;;;;number ranges
(defstruct (num-ranges (:conc-name      nranges-)
		       (:constructor    make-nranges)
                       (:copier         copy-nranges)
		       (:predicate      nranges-p)
		       (:print-function print-nranges))
  rlst
  limit)

(defun print-nranges (nranges stream depth)
  (format stream "#<num-ranges>~%->limit: ~A~%->ranges: ~A~%"
	  (nranges-limit nranges)
	  (nranges-rlst  nranges)))

(defun rlst-limit (rlst)
  (apply #'+ (mapcar #'(lambda (pair)
			 (- (second pair) (first pair)))
		     rlst)))

(defun rlst-add (rlst start end)
  (if (null rlst)
      (if (null start)
	  nil
	  (list (list start end)))
      (let* ((pair    (car    rlst))
	     (next    (cdr    rlst))
	     (pfirst  (first  pair))
	     (psecond (second pair)))
	(cond ((null start)
	       (append (list pair)
		       (rlst-add next nil nil)))
	      ((< end pfirst)
	       (append (list (list start end))
		       (list pair)
		       (rlst-add next nil nil)))
	      ((and (< start pfirst) (<= end psecond))
	       (append (list (list start psecond))
		       (rlst-add next nil nil)))
	      ((and (< start pfirst) (> end psecond))
	       (rlst-add next start end))
	      ((and (< start psecond) (<= end psecond))
	       (append (list pair)
		       (rlst-add next nil nil)))
	      ((and (<= start psecond) (> end psecond))
	       (rlst-add next pfirst end))
	      (t (append (list pair)
			 (rlst-add next start end)))))))

(defun rlst-remove (rlst start end)
  (cond ((null start) rlst)
	((null rlst) nil)
	(t (let* ((pair    (car    rlst))
		  (next    (cdr    rlst))
		  (pfirst  (first  pair))
		  (psecond (second pair)))
	     (cond ((<= end pfirst)
		    (append (list pair)
			    (rlst-remove next start end)))
		   ((and (<= start pfirst) (< end psecond))
		    (append (list (list end psecond))
			    (rlst-remove next start end)))
		   ((and (<= start pfirst) (>= end psecond))
		    (rlst-remove next start end))
		   ((and (< start psecond) (< end psecond))
		    (append (list (list pfirst start))
			    (list (list end psecond))
			    (rlst-remove next start end)))
		   ((and (< start psecond) (>= end psecond))
		    (append (list (list pfirst start))
			    (rlst-remove next start end)))
		   (t (append (list pair)
			      (rlst-remove next start end))))))))
  
(defun modify-nranges (nranges &key range-pairs pass-pairs (key #'identity))
  (let ((rlst (when nranges
		(nranges-rlst nranges))))
    (labels ((map-rlst (rlst-do pairs)
	       (mapc #'(lambda (pair)
			 (setf rlst (let ((new-pair (funcall key pair)))
				      (funcall rlst-do
					       rlst
					       (first  new-pair)
					       (second new-pair)))))
		     pairs)))
      (when range-pairs
	(map-rlst #'rlst-add range-pairs))
      (when pass-pairs
	(map-rlst #'rlst-remove pass-pairs))
      (if (or range-pairs pass-pairs)
	  (make-nranges :rlst  rlst
			:limit (rlst-limit rlst))
	  nranges))))

;;;;random number
(defun random-multiple-ranges (nranges)
  (let* ((limit (nranges-limit nranges))
	 (rlst  (nranges-rlst  nranges))
	 (r     (random limit)))
    (labels ((rc (rlst r)
	       (if (null rlst)
		   nil
		   (let* ((pair      (car    rlst))
			  (start     (first  pair))
			  (end       (second pair))
			  (sub-limit (- end start)))
		     (if (< r sub-limit)
			 (+ start r)
			 (rc (cdr rlst) (- r sub-limit)))))))
      (rc rlst r))))

(defun int-atom->pair (elt)
  (if (atom elt)
      (list elt (1+ elt))
      elt))

(defun make-int-ranges (&rest pairs)
  (modify-nranges nil :range-pairs pairs
		      :key #'int-atom->pair))
  
(defun random-single-range (start end)
  (+ start (random (- end start))))

;;;;random item
(defun random-item (&rest items)
  (do ((i (random (length items)) (1- i))
       (x items (cdr x)))
      ((= i 0) (car x))))

;;;;random char
(defconstant +char-list+
  '((alpl alphabetic-lowercase ((97 123)))
    (alpu alphabetic-uppercase ((65 91)))
    (num  number               ((48 58)))
    (sym  Punctuation&symbols  ((33 48) (58 65) (91 97) (123 127)))
    (spc  space                (32))))

(defun get-char-list-ranges (lst)
  (apply #'append
	 (if lst
	     (mapcar #'(lambda (x)
			 (third (assoc x +char-list+)))
		     lst)
	     (mapcar #'third +char-list+))))
    
(defun make-char-ranges (&rest lst)
  (let ((char-ranges (get-char-list-ranges lst)))
    (apply #'make-int-ranges char-ranges)))

(defconstant +char-ranges-all+ (make-char-ranges))

(defun random-char (&optional (cranges +char-ranges-all+))
  (code-char (random-multiple-ranges cranges)))

;;;;random string
(defun random-string (len &key
			    minlen
			    (cranges +char-ranges-all+)
			    escape
			    quote
			    double-quote)
  (let ((len2 (if (null minlen)
                  len
                  (random-single-range minlen (1+ len)))))
    (let (str-lst)
      (dotimes (i len2)
        (setf str-lst
	      (let ((rchar (random-char cranges)))
		(cons (cond ((and escape (char= escape rchar))
			     (make-string 2 :initial-element rchar))
			    ((and quote (char= quote rchar))
			     (if (or double-quote (null escape))
				 (make-string 2 :initial-element rchar)
				 (coerce (list escape rchar) 'string)))
			    (t (string rchar)))
		      str-lst))))
      (apply #'concatenate (cons 'string str-lst)))))

;;;;random datetime
(defun binary-search (obj vec test &key
				  (key   #'identity)
				  (start 0)
				  (end   nil))
  (when obj
    (let* ((len (length vec))
	   (end2 (if end
		     (if (< end len)
			 end
			 len)
		     len)))
      (when (< start end2)
	(labels ((searcher (start end)
		   (if (= start end)
		       nil
		       (let* ((mid  (+ start (floor (- end start) 2)))
			      (elt  (svref vec mid))
			      (elt2 (funcall key elt))
			      (lt   (funcall test obj elt2))
			      (gt   (funcall test elt2 obj)))
			 (cond ((not (or lt gt)) elt)
			       (lt (searcher start mid))
			       (gt (searcher (1+ mid) end)))))))
	  (searcher start end2))))))

(defun concat-symbol (&rest syms)
  (intern (apply #'concatenate
		 (cons 'string
		       (mapcar #'(lambda (sym)
				   (if (symbolp sym)
				       (symbol-name sym)
				       (string-upcase sym)))
			       syms)))))

(defmacro def-in-elts-p (name test &rest elts)
  (let ((elts2 (apply #'vector
		      (sort (copy-list elts)
			    test)))
	(fun-name (concat-symbol name "-p")))
    `(defun ,fun-name (elt)
       (binary-search elt ,elts2 #',test))))

(defmacro def-or/and-p (mode name &rest predicates)
  (let ((fun-name (concat-symbol name "-p")))
    `(defun ,fun-name (elt)
       (,mode ,@(mapcar #'(lambda (x) (list x 'elt))
		     predicates)))))

(def-in-elts-p whitespace-char          char< '(#\tab #\newline #\Vt #\page #\return #\space))
(def-in-elts-p date-separator-Char      char< '(#\- #\/ #\.))
(def-in-elts-p date-time-separator-Char char< '(#\T #\t))
(def-in-elts-p time-separator-Char      char< '(#\:))
(def-in-elts-p timezone-symbol-char     char< '(#\+ #\-))     

(def-or/and-p and constituent graphic-char-p (lambda (char) (not (char= char #\space))))

(defun datetime-tokens (str)
  (let ((len (length str))
	(last (1- (length str)))
	(tokens nil)
	(start 0)
	(tag 'whitespace))
    (dotimes (end len)
      (let ((char (char str end)))
	(cond ((eql type 'whitespace) (cond ((whitespace-char-p char) (setf start (1+ end)))
					    ((digit-char-p char) (setf start end
								       tag 'number))
					    ((timezone-symbol-char-p char) (setf start end
										 tag 'timezone))
					    (t (setf start end
						     tag 'string))))
	      ((eql type 'number) (cond ((= end last) 
								       

					 ))))
	(when (and (= end last)
		   (not (eql tag 'whitespace)))
	  (setf tokens (cons (list start len tag) tokens)))))
    (res))
	    
	    
					    
				
		     (when (null current-token-type)
		       (error "Parse DateTime String ~S Error, Character ~S is illegal." str char))
		     (cond ((null token-type) (rec token-start (1+ token-end) current-token-type))
			   (merge-token-type (rec token-start (1+ token-end) merge-token-type))
			   (t (cons (list (subseq str token-start
					              token-end)
					  token-type)
				    (rec token-end (1+ token-end) current-token-type))))))))
      (rec 0 0 nil))))



  
(defun decode-time-iso8601 (str)
  (let ((tokens (datetime-tokens str))
	(year       nil)
	(month      nil)
	(day        nil)
	(date-split nil)
	(hour       nil)
	(minute     nil)
	(second     nil)
	(tz         nil))
