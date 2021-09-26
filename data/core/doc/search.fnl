(local search {})

(local default-opt {})

(fn pattern-lower [str]
  (when (= (str:sub 1 1) "%")
    (lua "return str"))
  (str:lower))

(fn init-args [___doc-__ line col text opt]
  (set-forcibly! opt (or opt default-opt))
  (set-forcibly! (line col) (___doc-__:sanitize_position line col))
  (when opt.no_case
    (if opt.pattern (set-forcibly! text (text:gsub "%%?." pattern-lower))
        (set-forcibly! text (text:lower))))
  (values ___doc-__ line col text opt))

(fn search.find [___doc-__ line col text opt]
  (set-forcibly! (___doc-__ line col text opt)
                 (init-args ___doc-__ line col text opt))
  (for [line line (length ___doc-__.lines) 1]
    (var line-text (. ___doc-__.lines line))
    (when opt.no_case
      (set line-text (line-text:lower)))
    (local (s e) (line-text:find text col (not opt.pattern)))
    (when s
      (let [___antifnl_rtn_1___ line
            ___antifnl_rtn_2___ s
            ___antifnl_rtn_3___ line
            ___antifnl_rtn_4___ (+ e 1)]
        (lua "return ___antifnl_rtn_1___, ___antifnl_rtn_2___, ___antifnl_rtn_3___, ___antifnl_rtn_4___")))
    (set-forcibly! col 1))
  (when opt.wrap
    (set-forcibly! opt {:pattern opt.pattern :no_case opt.no_case})
    (search.find ___doc-__ 1 1 text opt)))

search

