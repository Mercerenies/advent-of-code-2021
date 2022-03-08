
;; Approach: Our states variable is going to be a list of
;; non-overlapping cuboids which are currently "on". Every time we
;; need to turn a new cuboid on or off, we first go through the
;; existing list and bisect it at any position where there could be an
;; intersection with the new cuboid.
;;
;; All cuboids are represented by half-open intervals, to make the
;; calculations more consistent.

(defun read-cuboids (input-filename)
  (with-temp-buffer
    (insert-file-contents input-filename)
    (let ((result (list)))
      (while (not (eobp))
        (looking-at "\\(on\\|off\\) x=\\([0-9-]+\\)..\\([0-9-]+\\),y=\\([0-9-]+\\)..\\([0-9-]+\\),z=\\([0-9-]+\\)..\\([0-9-]+\\)")
        (push (list (equal (match-string 1) "on")
                    (string-to-number (match-string 2))
                    (1+ (string-to-number (match-string 3)))
                    (string-to-number (match-string 4))
                    (1+ (string-to-number (match-string 5)))
                    (string-to-number (match-string 6))
                    (1+ (string-to-number (match-string 7))))
              result)
        (forward-line))
      (nreverse result))))

(defun get-keys (hash)
  (let ((result nil))
    (maphash (lambda (k v) (setq result (cons k result))) hash)
    result))

(defun intervals-intersect (a-left b-left a-right b-right)
  (> (min b-left b-right) (max a-left a-right)))

(defun rectangles-intersect (rect-l rect-r)
  (destructuring-bind (lx0 lx1 ly0 ly1) rect-l
    (destructuring-bind (rx0 rx1 ry0 ry1) rect-r
      (and
       (intervals-intersect lx0 lx1 rx0 rx1)
       (intervals-intersect ly0 ly1 ry0 ry1)))))

(defun bisect-cuboid (cuboid rhs-cuboid)
  (destructuring-bind (lx0 lx1 ly0 ly1 lz0 lz1) cuboid
    (destructuring-bind (rx0 rx1 ry0 ry1 rz0 rz1) rhs-cuboid
      (cond
       ((and (< lx0 rx0 lx1) (rectangles-intersect (list ly0 ly1 lz0 lz1) (list ry0 ry1 rz0 rz1)))
        (bisect-list (list (list lx0 rx0 ly0 ly1 lz0 lz1) (list rx0 lx1 ly0 ly1 lz0 lz1)) rhs-cuboid))
       ((and (< lx0 rx1 lx1) (rectangles-intersect (list ly0 ly1 lz0 lz1) (list ry0 ry1 rz0 rz1)))
        (bisect-list (list (list lx0 rx1 ly0 ly1 lz0 lz1) (list rx1 lx1 ly0 ly1 lz0 lz1)) rhs-cuboid))
       ((and (< ly0 ry0 ly1) (rectangles-intersect (list lx0 lx1 lz0 lz1) (list rx0 rx1 rz0 rz1)))
        (bisect-list (list (list lx0 lx1 ly0 ry0 lz0 lz1) (list lx0 lx1 ry0 ly1 lz0 lz1)) rhs-cuboid))
       ((and (< ly0 ry1 ly1) (rectangles-intersect (list lx0 lx1 lz0 lz1) (list rx0 rx1 rz0 rz1)))
        (bisect-list (list (list lx0 lx1 ly0 ry1 lz0 lz1) (list lx0 lx1 ry1 ly1 lz0 lz1)) rhs-cuboid))
       ((and (< lz0 rz0 lz1) (rectangles-intersect (list lx0 lx1 ly0 ly1) (list rx0 rx1 ry0 ry1)))
        (bisect-list (list (list lx0 lx1 ly0 ly1 lz0 rz0) (list lx0 lx1 ly0 ly1 rz0 lz1)) rhs-cuboid))
       ((and (< lz0 rz1 lz1) (rectangles-intersect (list lx0 lx1 ly0 ly1) (list rx0 rx1 ry0 ry1)))
        (bisect-list (list (list lx0 lx1 ly0 ly1 lz0 rz1) (list lx0 lx1 ly0 ly1 rz1 lz1)) rhs-cuboid))
       (t (list cuboid))))))

(defun bisect-list (list rhs-cuboid)
  (cl-loop for lhs-cuboid in list
           append (bisect-cuboid lhs-cuboid rhs-cuboid)))

(defun bisect-states (states rhs-cuboid)
  (let ((changed nil))
    (cl-loop for lhs-cuboid in (get-keys states)
             do (progn
                  (remhash lhs-cuboid states)
                  (let ((bisection (bisect-cuboid lhs-cuboid rhs-cuboid)))
                    (when (/= (length bisection) 1)
                      (setq changed t))
                    (cl-loop for result in bisection
                             do (puthash result 1 states)))))
    changed))

(defun bisect-states-against-all (states rhs-states)
  (let ((changed nil))
    (maphash (lambda (k v)
               (when (bisect-states states k)
                 (setq changed t)))
             rhs-states)
    changed))

(defun union-in-place (hash rhs-hash)
  (maphash (lambda (k v) (puthash k 1 hash)) rhs-hash))

(defun set-difference-in-place (hash rhs-hash)
  (maphash (lambda (k v) (remhash k hash)) rhs-hash))

(defun run-command (states cuboid)
  (let ((instruction (car cuboid))
        (rhs-states (make-hash-table :test 'equal)))
    (puthash (cdr cuboid) 1 rhs-states)

    (let ((changed t))
      (while changed
        (setq changed nil)
        (let ((a (bisect-states-against-all states rhs-states))
              (b (bisect-states-against-all rhs-states states)))
          (setq changed (or a b)))))

    (if instruction
        (union-in-place states rhs-states)
      (set-difference-in-place states rhs-states))))

(defun clamp (x a b)
  (cond
   ((< x a) a)
   ((> x b) b)
   (t x)))

(defun truncated-cube (cuboid)
  (mapcar (lambda (n) (clamp n -50 51)) cuboid))

(defun volume-of-cube (cuboid)
  (destructuring-bind (x0 x1 y0 y1 z0 z1) cuboid
    (* (- x1 x0) (- y1 y0) (- z1 z0))))

(defun solve (commands)
  (let ((states (make-hash-table :test 'equal :size 4096)))
    (dolist (command commands)
      (run-command states command))
    (let ((sum 0))
      (maphash (lambda (k v)
                 (setq sum (+ sum (volume-of-cube (truncated-cube k)))))
               states)
      sum)))

(defun split-at-x (cuboid x)
  (destructuring-bind (instr x0 x1 y0 y1 z0 z1) cuboid
    (cond
     ((< x x0) (cons nil (list cuboid)))
     ((<= x x1) (cons (list (list instr x0 x y0 y1 z0 z1)) (list (list instr x x1 y0 y1 z0 z1))))
     (t (cons (list cuboid) nil)))))

(defun split-at-y (cuboid y)
  (destructuring-bind (instr x0 x1 y0 y1 z0 z1) cuboid
    (cond
     ((< y y0) (cons nil (list cuboid)))
     ((<= y y1) (cons (list (list instr x0 x1 y0 y z0 z1)) (list (list instr x0 x1 y y1 z0 z1))))
     (t (cons (list cuboid) nil)))))

(defun split-at-z (cuboid z)
  (destructuring-bind (instr x0 x1 y0 y1 z0 z1) cuboid
    (cond
     ((<= z z0) (cons nil (list cuboid)))
     ((< z z1) (cons (list (list instr x0 x1 y0 y1 z0 z)) (list (list instr x0 x1 y0 y1 z z1))))
     (t (cons (list cuboid) nil)))))

(defun split-planar (dataset splitter)
  (cl-flet ((merge (a b) (cons (nconc (car a) (car b)) (nconc (cdr a) (cdr b)))))
    (let ((results (cl-loop for cuboid in dataset
                            collect (funcall splitter cuboid))))
      (reduce #'merge results :initial-value (cons nil nil)))))

;; Split the dataset at the given coords.
(defun split-planar-all (dataset x y z)
  (cl-flet ((c-to-l (cell) (list (car cell) (cdr cell)))
            (spl-x (c) (split-at-x c x))
            (spl-y (c) (split-at-y c y))
            (spl-z (c) (split-at-z c z)))
    (cl-loop for x in (c-to-l (split-planar dataset #'spl-x))
             nconc (cl-loop for y in (c-to-l (split-planar x #'spl-y))
                            nconc (c-to-l (split-planar y #'spl-z))))))

;; If length is even, picks the lower of the two "middles". Not a true
;; median, but close enough for what we're doing.
(defun median (data)
  (let ((sorted (sort data #'<))
        (n (length data)))
    (nth (/ n 2) sorted)))

(defun split-planar-median (dataset)
  (let ((x-coords (mapcan (lambda (c) (list (nth 1 c) (nth 2 c))) dataset))
        (y-coords (mapcan (lambda (c) (list (nth 3 c) (nth 4 c))) dataset))
        (z-coords (mapcan (lambda (c) (list (nth 5 c) (nth 6 c))) dataset)))
    (split-planar-all dataset (median x-coords) (median y-coords) (median z-coords))))

;; If the dataset (after splitting) is bigger than n, then we've
;; already tried splitting it, so don't try again.
(defun split-and-run (n dataset)
  (let ((m (length dataset)))
    (if (< 8 m n) ; Experimentally, 8 seems to strike a good balance and get "fast"-ish results
        (cl-loop for new-dataset in (split-planar-median dataset)
                 sum (split-and-run (min m n) new-dataset))
      (solve dataset))))

(defun split-planar-median-some (dataset n)
  (let ((splits (list dataset)))
    (cl-loop for i from 1 to n
             do (setq splits (mapcan #'split-planar-median splits)))
    splits))

(defun run (input-filename)
  (let ((cuboids (read-cuboids input-filename)))
    (split-and-run 10000 cuboids)))

(let ((debug-on-error t))
  (message "%s" (run "input.txt")))
