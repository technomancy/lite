(local tokenizer {})

(fn push-token [t type text]
  (let [prev-type (. t (- (length t) 1))
        prev-text (. t (length t))]
    (if (and prev-type (or (= prev-type type) (prev-text:find "^%s*$")))
        (do
          (tset t (- (length t) 1) type)
          (tset t (length t) (.. prev-text text)))
        (do
          (table.insert t type)
          (table.insert t text)))))

(fn is-escaped [text idx esc]
  (let [byte (esc:byte)]
    (var count 0)
    (for [i (- idx 1) 1 (- 1)]
      (when (not= (text:byte i) byte)
        (lua :break))
      (set count (+ count 1)))
    (= (% count 2) 1)))

(fn find-non-escaped [text pattern offset esc]
  (while true
    (local (s e) (text:find pattern offset))
    (when (not s)
      (lua :break))
    (if (and esc (is-escaped text s esc)) (set-forcibly! offset (+ e 1))
        (lua "return s, e"))))

(fn tokenizer.tokenize [syntax text state]
  (let [res {}]
    (var i 1)
    (when (= (length syntax.patterns) 0)
      (let [___antifnl_rtn_1___ {1 :normal 2 text}]
        (lua "return ___antifnl_rtn_1___")))
    (while (<= i (length text))
      (when state
        (local p (. syntax.patterns state))
        (local (s e) (find-non-escaped text (. p.pattern 2) i (. p.pattern 3)))
        (if s (do
                (push-token res p.type (text:sub i e))
                (set-forcibly! state nil)
                (set i (+ e 1)))
            (do
              (push-token res p.type (text:sub i))
              (lua :break))))
      (var matched false)
      (each [n p (ipairs syntax.patterns)]
        (local pattern (or (and (= (type p.pattern) :table) (. p.pattern 1))
                           p.pattern))
        (local (s e) (text:find (.. "^" pattern) i))
        (when s
          (local t (text:sub s e))
          (push-token res (or (. syntax.symbols t) p.type) t)
          (when (= (type p.pattern) :table)
            (set-forcibly! state n))
          (set i (+ e 1))
          (set matched true)
          (lua :break)))
      (when (not matched)
        (push-token res :normal (text:sub i i))
        (set i (+ i 1))))
    (values res state)))

(fn iter [t i]
  (set-forcibly! i (+ i 2))
  (local (type* text) (values (. t i) (. t (+ i 1))))
  (when type*
    (values i type* text)))

(fn tokenizer.each_token [t]
  (values iter t (- 1)))

tokenizer

