(local core (require :core))

(local command (require :core.command))

(local translate (require :core.doc.translate))

(fn gmatch-to-array [text ptn]
  (let [res {}]
    (each [x (text:gmatch ptn)]
      (table.insert res x))
    res))

(fn tabularize-lines [lines delim]
  (let [rows {}
        cols {}
        ptn (.. "[^" (: (delim:sub 1 1) :gsub "%W" "%%%1") "]+")]
    (each [i line (ipairs lines)]
      (tset rows i (gmatch-to-array line ptn))
      (each [j col (ipairs (. rows i))]
        (tset cols j (math.max (length col) (or (. cols j) 0)))))
    (each [_ row (ipairs rows)]
      (for [i 1 (- (length row) 1) 1]
        (tset row i
              (.. (. row i) (string.rep " " (- (. cols i) (length (. row i))))))))
    (each [i line (ipairs lines)]
      (tset lines i (table.concat (. rows i) delim)))))

(command.add :core.docview
             {"tabularize:tabularize" (fn []
                                        (core.command_view:enter "Tabularize On Delimiter"
                                                                 (fn [delim]
                                                                   (when (= delim
                                                                            "")
                                                                     (set-forcibly! delim
                                                                                    " "))
                                                                   (local ___doc-__
                                                                          core.active_view.doc)
                                                                   (local (line1 col1
                                                                                 line2
                                                                                 col2
                                                                                 swap)
                                                                          (___doc-__:get_selection true))
                                                                   (set-forcibly! (line1 col1)
                                                                                  (___doc-__:position_offset line1
                                                                                                             col1
                                                                                                             translate.start_of_line))
                                                                   (set-forcibly! (line2 col2)
                                                                                  (___doc-__:position_offset line2
                                                                                                             col2
                                                                                                             translate.end_of_line))
                                                                   (___doc-__:set_selection line1
                                                                                            col1
                                                                                            line2
                                                                                            col2
                                                                                            swap)
                                                                   (___doc-__:replace (fn [text]
                                                                                        (local lines
                                                                                               (gmatch-to-array text
                                                                                                                "[^
]*
?"))
                                                                                        (tabularize-lines lines
                                                                                                          delim)
                                                                                        (table.concat lines))))))})

