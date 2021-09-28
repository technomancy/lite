(local common {})

(fn common.is_utf8_cont [char]
  (let [byte (char:byte)]
    (and (>= byte 128) (< byte 192))))

(fn common.utf8_chars [text]
  (text:gmatch "[\000-\127Â-ô][€-¿]*"))

(fn common.clamp [n lo hi]
  (math.max (math.min n hi) lo))

(fn common.round [n]
  (or (and (>= n 0) (math.floor (+ n 0.5))) (math.ceil (- n 0.5))))

(fn common.lerp [a b t]
  (when (not= (type a) :table)
    (let [___antifnl_rtn_1___ (+ a (* (- b a) t))]
      (lua "return ___antifnl_rtn_1___")))
  (local res {})
  (each [k v (pairs b)]
    (tset res k (common.lerp (. a k) v t)))
  res)

(fn common.color [str]
  (var (r g b a) (str:match "#(%x%x)(%x%x)(%x%x)"))
  (if r (do
          (set r (tonumber r 16))
          (set g (tonumber g 16))
          (set b (tonumber b 16))
          (set a 1)) (str:match "rgba?%s*%([%d%s%.,]+%)")
      (let [f (str:gmatch "[%d.]+")]
        (set r (or (f) 0))
        (set g (or (f) 0))
        (set b (or (f) 0))
        (set a (or (f) 1)))
      (error (string.format "bad color string '%s'" str)))
  (values r g b (* a 255)))

(fn compare-score [a b]
  (> a.score b.score))

(fn fuzzy-match-items [items needle]
  (let [res {}]
    (each [_ item (ipairs items)]
      (local score (system.fuzzy_match (tostring item) needle))
      (when score
        (table.insert res {: score :text item})))
    (table.sort res compare-score)
    (each [i item (ipairs res)]
      (tset res i item.text))
    res))

(fn common.fuzzy_match [haystack needle]
  (if (= (type haystack) :table)
      (fuzzy-match-items haystack needle)
      (system.fuzzy_match haystack needle)))

(fn common.path_suggest [text]
  (let [(path name) (text:match "^(.-)([^/\\]*)$")
        files (or (system.list_dir (or (and (= path "") ".") path)) {})
        res {}]
    (each [_ file (ipairs files)]
      (set-forcibly! file (.. path file))
      (local info (system.get_file_info file))
      (when info
        (when (= info.type :dir)
          (set-forcibly! file (.. file PATHSEP)))
        (when (= (: (file:lower) :find (text:lower) nil true) 1)
          (table.insert res file))))
    res))

(fn common.match_pattern [text pattern ...]
  (if (= (type pattern) :string)
      (text:find pattern ...)
      (do (each [_ p (ipairs pattern)]
            (local (s e) (common.match_pattern text p ...))
            (when s
              (lua "return s, e")))
          false)))

(fn common.draw_text [font color text align x y w h]
  (let [(tw th) (values (font:get_width text) (font:get_height text))]
    (if (= align :center) (set-forcibly! x (+ x (/ (- w tw) 2)))
        (= align :right) (set-forcibly! x (+ x (- w tw))))
    (set-forcibly! y (common.round (+ y (/ (- h th) 2))))
    (values (renderer.draw_text font text x y color) (+ y th))))

(fn common.bench [name ___fn-__ ...]
  (let [start (system.get_time)
        res (___fn-__ ...)
        t (- (system.get_time) start)
        ms (* t 1000)
        per (* (/ t (/ 1 60)) 100)]
    (print (string.format "*** %-16s : %8.3fms %6.2f%%" name ms per))
    res))

common

