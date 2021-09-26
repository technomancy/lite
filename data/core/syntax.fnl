(local common (require :core.common))

(local syntax {})

(set syntax.items {})

(local plain-text-syntax {:patterns {} :symbols {}})

(fn syntax.add [t]
  (table.insert syntax.items t))

(fn find [string field]
  (for [i (length syntax.items) 1 (- 1)]
    (local t (. syntax.items i))
    (when (common.match_pattern string (or (. t field) {}))
      (lua "return t"))))

(fn syntax.get [filename header]
  (or (or (find filename :files) (find header :headers)) plain-text-syntax))

syntax

