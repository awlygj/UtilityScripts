(ql:quickload "cl-mysql")

(let ((mydb (cl-mysql:connect :host "localhost"
                              :user "root" 
                              :password "1234" 
                              :database "test"))
      (sql_templete_1 "insert into test1 (id, col1, col2) values (~A, '~A', adddate(now(), interval ~A day));")
      (sql_templete_2 "insert into test2 (id, fk, col1, col2, col3) values(~A, ~A, '~A', adddate(now(), interval ~A day), ~A);"))
  (cl-mysql:query "start transaction;" :database mydb)
  (do ((i 1 (1+ i))
       (j 1))
    ((> i 1000000))
    (cl-mysql:query (format nil sql_templete_1 i (random-string 128 64) (random-int -365 365)) :database mydb)
    (dotimes (k (random-int 1 10)) 
      (cl-mysql:query (format nil sql_templete_2 j i (random-string 128 64) (random-int -365 365) (random 100000.0)) :database mydb)
      (incf j))
    (multiple-value-bind (f r) (floor i 1000)
      (when (= r 0)
        (cl-mysql:query "commit;" :database mydb)
        (cl-mysql:query "start transaction;" :database mydb)
        (print i))))
  (cl-mysql:query "commit;" :database mydb)
  (cl-mysql:disconnect mydb))

