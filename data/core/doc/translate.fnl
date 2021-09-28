(local common (require :core.common))

(local config (require :core.config))

(local translate {})

(fn is-non-word [char]
  (config.non_word_chars:find char nil true))

(fn translate.previous_char [___doc-__ line col]
  (while true
    (set-forcibly! (line col) (___doc-__:position_offset line col (- 1)))
    (when (not (common.is_utf8_cont (___doc-__:get_char line col)))
      (lua :break)))
  (values line col))

(fn translate.next_char [___doc-__ line col]
  (while true
    (set-forcibly! (line col) (___doc-__:position_offset line col 1))
    (when (not (common.is_utf8_cont (___doc-__:get_char line col)))
      (lua :break)))
  (values line col))

(fn translate.previous_word_start [___doc-__ line col]
  (let [prev nil]
    (while (or (> line 1) (> col 1))
      (local (l c) (___doc-__:position_offset line col (- 1)))
      (local char (___doc-__:get_char l c))
      (when (or (and prev (not= prev char)) (not (is-non-word char)))
        (lua :break))
      (set-forcibly! (prev line col) (values char l c)))
    (translate.start_of_word ___doc-__ line col)))

(fn translate.next_word_end [___doc-__ line col]
  (var prev nil)
  (local (end-line end-col) (translate.end_of_doc ___doc-__ line col))
  (while (or (< line end-line) (< col end-col))
    (local char (___doc-__:get_char line col))
    (when (or (and prev (not= prev char)) (not (is-non-word char)))
      (lua :break))
    (set-forcibly! (line col) (___doc-__:position_offset line col 1))
    (set prev char))
  (translate.end_of_word ___doc-__ line col))

(fn translate.start_of_word [___doc-__ line col]
  (while true
    (local (line2 col2) (___doc-__:position_offset line col (- 1)))
    (local char (___doc-__:get_char line2 col2))
    (when (or (is-non-word char) (and (= line line2) (= col col2)))
      (lua :break))
    (set-forcibly! (line col) (values line2 col2)))
  (values line col))

(fn translate.end_of_word [___doc-__ line col]
  (while true
    (local (line2 col2) (___doc-__:position_offset line col 1))
    (local char (___doc-__:get_char line col))
    (when (or (is-non-word char) (and (= line line2) (= col col2)))
      (lua :break))
    (set-forcibly! (line col) (values line2 col2)))
  (values line col))

(fn translate.previous_block_start [___doc-__ line col]
  (while true
    (set-forcibly! line (- line 1))
    (when (<= line 1)
      (lua "return 1, 1"))
    (when (and (: (. ___doc-__.lines (- line 1)) :find "^%s*$")
               (not (: (. ___doc-__.lines line) :find "^%s*$")))
      (lua :break)))
  (values line (: (. ___doc-__.lines line) :find "%S")))

(fn translate.next_block_end [___doc-__ line col]
  (while true
    (when (>= line (length ___doc-__.lines))
      (let [___antifnl_rtn_1___ (length ___doc-__.lines)
            ___antifnl_rtn_2___ 1]
        (lua "return ___antifnl_rtn_1___, ___antifnl_rtn_2___")))
    (when (and (: (. ___doc-__.lines (+ line 1)) :find "^%s*$")
               (not (: (. ___doc-__.lines line) :find "^%s*$")))
      (let [___antifnl_rtn_1___ (+ line 1)
            ___antifnl_rtn_2___ (length (. ___doc-__.lines (+ line 1)))]
        (lua "return ___antifnl_rtn_1___, ___antifnl_rtn_2___")))
    (set-forcibly! line (+ line 1))))

(fn translate.start_of_line [___doc-__ line col]
  (values line 1))

(fn translate.end_of_line [___doc-__ line col]
  (values line math.huge))

(fn translate.start_of_doc [___doc-__ line col]
  (values 1 1))

(fn translate.end_of_doc [___doc-__ line col]
  (values (length ___doc-__.lines)
          (length (. ___doc-__.lines (length ___doc-__.lines)))))

translate

