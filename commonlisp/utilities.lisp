#|
(defpackage "ANSI-CL-UTILITIES"
  (:use "COMMON-LISP")
  (:nicknames "ACLUTIL")
  (:export "SINGLE?" "APPEND1" "MAP-INT" "FILTER" "MOST"
           #:pair #:analyze-body "LIST>" "LIST<" "LIST="
           "LIST/=" "RANDOM-DPCHAR" "RANDOM-DPSTRING" "COMPOSE" "DISJOIN"
           "CONJOIN" "CURRY" "RCURRY" "ALWAYS" "NIL!"
           "WHILE" "NTIMES" "FOR" "IN" "RANDOM-CHOICE"
           "AVG" "WITH-GENSYMS" "AIF" #:setf2))

(in-package ANSI-CL-UTILITIES)
|#

;Function Utilities
(defun single? (lst)
  (and (consp lst) (null (cdr lst))))

(defun append1 (lst obj)
  (append lst (list obj)))

(defun map-int (fn n)
  (let ((acc nil))
    (dotimes (i n)
      (push (funcall fn i) acc))
    (nreverse acc)))

(defun filter (fn lst)
  (let ((acc nil))
    (dolist (x lst)
      (let ((val (funcall fn x)))
        (if val (push val acc))))
    (nreverse acc)))

(defun most (fn lst)
  (if (null lst)
      (values nil nil)
      (let* ((wins (car lst))
             (max (funcall fn wins)))
        (dolist (obj (cdr lst))
          (let ((score (funcall fn obj)))
            (when (> score max)
              (setf wins obj
                    max  score))))
        (values wins max))))

(defun pair (lst)
  (if (null lst)
      nil
      (cons (cons (car lst) (cadr lst))
            (pair (cddr lst)))))

(defun analyze-body (body &optional dec doc)
  (let ((expr (car body)))
    (cond ((and (consp expr) (eq (car expr) 'declare))
           (analyze-body (cdr body) (cons expr dec) doc))
          ((and (stringp expr) (not doc) (cdr body))
           (if dec
               (values dec expr (cdr body))
               (analyze-body (cdr body) dec expr)))
          (t (values dec doc body)))))

(defun list< (lst1 lst2)
        (multiple-value-bind (type< type-car)
                (typecase (car lst1)
                        (number    (values #'< #'car))
                        (string    (values #'string< #'car))
                        (character (values #'char< #'car))
                        (symbol    (values #'string< 
                                        #'(lambda (x) (symbol-name (car x))))))
             (do ((obj1 lst1 (cdr obj1))
                  (obj2 lst2 (cdr obj2)))
                 ((and (null obj1) (null obj2)))
                 (cond ((and (null obj1) obj2) (return t))
                       ((and (null obj2) obj1) (return nil))
                       ((funcall type< (funcall type-car obj1)
                                       (funcall type-car obj2))
                                (return t))
                       ((funcall type< (funcall type-car obj2)
                                       (funcall type-car obj1))
                                (return nil))))))

(defun list> (lst1 lst2)
        (list< lst2 lst1))

(defun list= (lst1 lst2)
        (multiple-value-bind (type/= type-car)
                (typecase (car lst1)
                        (number    (values #'/= #'car))
                        (string    (values #'string/= #'car))
                        (character (values #'char/= #'car))
                        (symbol    (values #'string/=
                                        #'(lambda (x) (symbol-name (car x))))))
             (do ((obj1 lst1 (cdr obj1))
                  (obj2 lst2 (cdr obj2)))
                 ((and (null obj1) (null obj2)) t)
                 (cond ((not (and obj1 obj2)) (return nil))
                       ((funcall type/= (funcall type-car obj1)
                                        (funcall type-car obj2))
                                (return nil))))))

(defun list/= (lst1 lst2)
        (not (list= lst1 lst2)))

(defun random-dpchar ()
        (code-char (+ 33 (random 94))))

(defun random-dpstring (len)
        (let ((str (make-string len)))
             (dotimes (i len str)
                (setf (char str i) (random-dpchar)))))

;Function Builders
;Dylan
(defun compose (&rest fns)
  (destructuring-bind (fn1 . rest) (reverse fns)
    #'(lambda (&rest args)
        (reduce #'(lambda (v f) (funcall f v))
                rest
                :initial-value (apply fn1 args)))))

(defun disjoin (fn &rest fns)
  (if (null fns)
      fn
      (let ((disj (apply #'disjoin fns)))
        #'(lambda (&rest args)
            (or (apply fn args) (apply disj args))))))

(defun conjoin (fn &rest fns)
  (if (null fns)
      fn
      (let ((conj (apply #'conjoin fns)))
        #'(lambda (&rest args)
            (and (apply fn args) (apply conj args))))))

(defun curry (fn &rest args)
  #'(lambda (&rest args2)
      (apply fn (append args args2))))

(defun rcurry (fn &rest args)
  #'(lambda (&rest args2)
      (apply fn (append args2 args))))

(defun always (x) #'(lambda (&rest args) (declare (ignore args)) x))

;Macro Utilities
(defmacro nil! (x)
  `(setf ,x nil))

(defmacro while (test &rest body)
  `(do ()
       ((not ,test))
     ,@body))

(defmacro ntimes (n &rest body)
  (let ((g (gensym))
        (h (gensym)))
    `(let ((,h ,n))
       (do ((,g 0 (+ ,g 1)))
           ((>= ,g ,h))
         ,@body))))

(defmacro for (var start stop &body body)
  (let ((gstop (gensym)))
    `(do ((,var ,start (1+ ,var))
          (,gstop ,stop))
         ((> ,var ,gstop))
       ,@body)))

(defmacro in (obj &rest choices)
  (let ((insym (gensym)))
    `(let ((,insym ,obj))
       (or ,@(mapcar #'(lambda (c) `(eql ,insym ,c))
                     choices)))))

(defmacro random-choice (&rest exprs)
  `(case (random ,(length exprs))
     ,@(let ((key -1))
         (mapcar #'(lambda (expr)
                     `(,(incf key) ,expr))
                 exprs))))

(defmacro avg (&rest args)
  `(/ (+ ,@args) ,(length args)))

(defmacro with-gensyms (syms &body body)
  `(let ,(mapcar #'(lambda (s)
                     `(,s (gensym)))
                 syms)
     ,@body))

(defmacro aif (test then &optional else)
  `(let ((it ,test))
     (if it ,then ,else)))

(defmacro setf2 (place val &rest args)
  (multiple-value-bind (vars forms var set)
                       (get-setf-expansion place)
    `(progn
       (let* (,@(mapcar #'list vars forms)
              (,(car var) ,val))
         ,set)
       ,@(if args `((setf2 ,@args)) nil))))

#| Temp Lisp File
 | 
   quote
   list
   cons
   append
   adjoin
   nconc
   car
   cdr
   nth
   nthcdr
   cxr...caddr
   first...second...third...tenth
   last
   tailp
   listp
   atom
   consp
   
   symbolp
   symbol-name
   symbol-value
   symbol-plist
   symbol-function
   boundp
   fboundp
   get
   defpackage...:use :nicknames :export
   in-package
   use-package
   intern...common-lisp-user common-lisp
   unintern
   gensym
   export
   import
   *package*
   package-name
   find-package
   symbol-package
   make-package...:use
   package::External_symbol...'not_exported'
   package:Internal_symbol...'exported'
   
   t
   nil
   null
   not
   if
   and
   or
   when
   unless
   cond...t
   case...t otherwise
   eq
   eql
   equal
   equalp
   complement
   identity
   constantly
   
   do
   do*
   dolist
   dotimes
   progn
   prog1
   block
   tagbody
   return-from
   return
   go
   catch
   throw
   error
   unwind-protect
   ecase
   check-type
   assert
   ignore-errors

   lambda
   function
   apply
   funcall
   map
   map-into
   mapc
   mapcar
   mapcan
   maplist
   reduce...:initial-value :from-end
   values
   multiple-value-bind
   multiple-value-call
   multiple-value-list
   
   defun...&rest &optional &key
   defsetf
   documentation
   labels
   compiled-function-p
   compile
   compile-file
   load
   require
   eval
   eval-when
   coerce
   disassemble
   
   defmacro
   define-modify-macro
   macroexpand-1
   macro-function
   
   defparameter
   defconstant
   defvar
   let
   let*
   setf
   rplaca
   rplacd
   destructuring-bind
   declare
   special
   
   defstruct...:conc-name :print-function :include :type
   defclass...:accessor :writer :reader :initform :initarg :default-initargs
              :allocation :class :instance :documentation :type
   defmethod...:before :after :around
   defgeneric...:method-combination + and append list max min nconc or progn standard
   slot-value
   make-instance
   next-method-p
   call-next-method
   fmakunbound
   compute-applicable-methods
   find-method
   
   format
   princ
   prin1
   print
   pprint
   terpri
   fresh-line
   finish-output
   force-output
   clear-output
   read
   read-line
   read-char
   read-from-string
   read-macro
   peek-char
   clear-input
   listen
   *standard-input*
   *standard-output*
   *error-output*
   make-pathname...host device directory name type version
   open...:direction :input :output :io :if-exists :supersede :element-type 'unsigned-byte
   close
   with-open-file
   file-length
   file-position
   set-macro-character
   get-macro-character
   make-dispatch-macro-character
   set-dispatch-macro-character
   read-delimited-list
   
   copy-list
   copy-tree
   copy-seq
   elt
   substitute
   substitute-if
   subst
   subst-if
   nsubst
   nsubst-if
   sublis
   nsublis
   member...:key :test :from-end :start :end
   member-if
   position
   position-if
   find
   find-if
   remove
   remove-if
   remove-duplicates
   delete
   delete-if
   delete-duplicates
   union
   intersection
   set-difference
   nunion
   nintersection
   nset-difference
   length
   subseq
   reverse
   nreverse
   sort
   every
   some
   push
   pushnew
   pop
   assoc
   assoc-if
   rotatef
   merge
   
   make-array...:initial-element :element-type :fill-pointer
   aref
   svref
   vector
   vector-push
   vector-pop
   fill-pointer
   *print-array*
   
   char-code
   code-char
   char<
   char<=
   char=
   char>=
   char>
   char/=
   char
   make-string
   string-equal
   string=
   string-downcase
   string-upcase
   string-capitalize
   concatenate
   graphic-char-p
   alpha-char-p
   digit-char-p
   string-lessp
   string-greaterp
   
   make-hash-table...:size :test
   hash-table-count
   gethash
   remhash
   maphash
   
   numberp
   zerop
   plusp
   minusp
   oddp
   evenp
   integerp
   floatp
   complexp
   ratiop
   float
   truncate
   floor
   ceiling
   round
   mod
   rem
   signum
   abs
   numerator
   denominator
   realpart
   imgpart
   random
   = < <= >= > /=
   max
   min
   + - * /
   1+
   1-
   incf
   decf
   expt
   log
   exp
   sqrt
   pi
   sin
   cos
   tan
   asin 
   acos
   atan
   sinh
   cosh
   tanh
   asinh
   acosh
   atanh
   parse-integer
   *print-base*
   most-positive-fixnum
   most-negative-fixnum
   m-s-f...most least-positive negative-short-float single-float double-float long-float(s f d l)
   
   typep
   typecase
   type-of
   satisfies
   deftype
   
   *print-circle*
   cdr-circular...#1=( . #1#)
   car-circular...#1=(#1#)
   
   decode-universal-time
   encode-universal-time
   get-decoded-time
   get-internal-real-time
   get-internal-run-time
   get-universal-time
   internal-time-units-per-second
   
   the
   declare...ignore dynamic-extent
   declaim...optimize speed compilation-speed safety space debug 0~3
             inline notinline type
   proclaim
   time
   trace
   untrace
   step
   break
   *trace-output*
   
   loop for from to
        do ()
   loop for then ()
        while/until ()
        do ()
   loop for from to
        and from to
        do ()
   loop for in '()
        collect ()
   loop for from to
        collect ()
   loop for in '()
        if ()
                collect into
        else collect into
        finally (return ())
   loop for from to
        sum
   loop with =
        with =
        for in '()
        for =
        when () (do ())
        finally (return ())
   loop for downfrom
        until ()
        sum into
        finally (return ())
   loop with prev =
        for from
        until ()
        do ()
        sum () into
        finally (return ())
   loop for = then
        for from to
        sum into
        finally (return ())
   
        ;Dylan
        compose
        disjoin
        conjoin
        curry
        rcurry
        always
        
        ;Utilities
        single?
        append1
        map-int
        filter
        most
        
        ;Macro Utilities
        for
        in
        random-choice
        avg
        with-gensyms
        aif
   
 | 
 |#
