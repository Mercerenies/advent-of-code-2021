
(ns advent-of-code-2021)

;; A grid consists of a 2-dimensional (y-major) array and a single
;; character indicating the value at infinity.
(defrecord Grid [infinity array])

(defn read-file [filename]
  (with-open [r (clojure.java.io/reader filename)]
    (let [algorithm (.readLine r)
          image (do (.readLine r) ; Ignore blank line
                    (vec (map vec (line-seq r))))]
      (list algorithm (->Grid \. image)))))

(defn char->num [ch]
  (if (= ch \#) 1 0))

(defn num->char [b]
  (if (> b 0) \# \.))

(defn grid-height [grid]
  (count (.array grid)))

(defn grid-width [grid]
  (if (= (grid-height grid) 0)
    0
    (count (nth (.array grid) 0))))

(defn grid-in-bounds [grid y x]
  (and (>= y 0) (>= x 0) (< y (grid-height grid)) (< x (grid-width grid))))

(defn grid-get [grid y x]
  (if (grid-in-bounds grid y x)
    (-> grid .array (nth y) (nth x))
    (.infinity grid)))

(defn grid-get-neighborhood [grid y x]
  (let [positions (for [dy (range -1 2) dx (range -1 2)] [(+ y dy) (+ x dx)])]
    (map (fn [[y x]] (char->num (grid-get grid y x))) positions)))

(defn grid-get-bit-value [grid y x]
  (->>
   (grid-get-neighborhood grid y x)
   (reduce (fn [a b] (+ (* 2 a) b)))))

(defn grid-enhance [grid algorithm]
  (let [new-grid (vec (for [y (range -1 (+ (grid-height grid) 1))]
                        (vec (for [x (range -1 (+ (grid-width grid) 1))]
                               (nth algorithm (grid-get-bit-value grid y x))))))
        new-infinity (nth algorithm (if (= (.infinity grid) \#) 511 0))]
    (->Grid new-infinity new-grid)))

(defn grid->list [grid]
  (flatten (.array grid)))

(defn grid-count [grid ch]
  (if (= (.infinity grid) ch)
    ##Inf
    (->>
     grid
     grid->list
     (filter (fn [v] (= v ch)))
     count)))

(let [[algorithm image] (read-file "input.txt")]
  (let [twice-enhanced (grid-enhance (grid-enhance image algorithm) algorithm)]
    (println (grid-count twice-enhanced \#))))
