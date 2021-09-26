(local core (require :core))

(local command (require :core.command))

(local config (require :core.config))

(local search (require :core.doc.search))

(local Doc-view (require :core.docview))

(local max-previous-finds 50)

(fn ___doc-__ []
  core.active_view.doc)

(var previous-finds nil)

(var last-doc nil)

(local (last-fn last-text) nil)

(fn push-previous-find [___doc-__ sel]
  (when (not= last-doc ___doc-__)
    (set last-doc ___doc-__)
    (set previous-finds {}))
  (when (>= (length previous-finds) max-previous-finds)
    (table.remove previous-finds 1))
  (table.insert previous-finds (or sel {1 (___doc-__:get_selection)})))

(fn find [label search-fn]
  (let [dv core.active_view
        sel {1 (dv.doc:get_selection)}
        text (dv.doc:get_text (table.unpack sel))]
    (var found false)
    (core.command_view:set_text text true)
    (core.command_view:enter label
                             (fn [text]
                               (if found
                                   (do
                                     (set-forcibly! (last-fn last-text)
                                                    (values search-fn text))
                                     (set previous-finds {})
                                     (push-previous-find dv.doc sel))
                                   (do
                                     (core.error "Couldn't find %q" text)
                                     (dv.doc:set_selection (table.unpack sel))
                                     (dv:scroll_to_make_visible (. sel 1)
                                                                (. sel 2)))))
                             (fn [text]
                               (let [(ok line1 col1 line2 col2) (pcall search-fn
                                                                       dv.doc
                                                                       (. sel 1)
                                                                       (. sel 2)
                                                                       text)]
                                 (if (and (and ok line1) (not= text ""))
                                     (do
                                       (dv.doc:set_selection line2 col2 line1
                                                             col1)
                                       (dv:scroll_to_line line2 true)
                                       (set found true))
                                     (do
                                       (dv.doc:set_selection (table.unpack sel))
                                       (set found false)))))
                             (fn [explicit]
                               (when explicit
                                 (dv.doc:set_selection (table.unpack sel))
                                 (dv:scroll_to_make_visible (. sel 1) (. sel 2)))))))

(fn replace [kind default ___fn-__]
  (core.command_view:set_text default true)
  (core.command_view:enter (.. "Find To Replace " kind)
                           (fn [old]
                             (do
                               (core.command_view:set_text old true)
                               (local s
                                      (string.format "Replace %s %q With" kind
                                                     old))
                               (core.command_view:enter s
                                                        (fn [new]
                                                          (let [n (: (___doc-__)
                                                                     :replace
                                                                     (fn [text]
                                                                       (___fn-__ text
                                                                                 old
                                                                                 new)))]
                                                            (core.log "Replaced %d instance(s) of %s %q with %q"
                                                                      n kind old
                                                                      new))))))))

(fn has-selection []
  (and (core.active_view:is Doc-view) (core.active_view.doc:has_selection)))

(command.add has-selection
             {"find-replace:select-next" (fn []
                                           (local (l1 c1 l2 c2)
                                                  (: (___doc-__) :get_selection
                                                     true))
                                           (local text
                                                  (: (___doc-__) :get_text l1
                                                     c1 l2 c2))
                                           (local (l1 c1 l2 c2)
                                                  (search.find (___doc-__) l2
                                                               c2 text
                                                               {:wrap true}))
                                           (when l2
                                             (: (___doc-__) :set_selection l2
                                                c2 l1 c1)))})

(command.add :core.docview
             {"find-replace:find-pattern" (fn []
                                            (find "Find Text Pattern"
                                                  (fn [___doc-__ line col text]
                                                    (local opt
                                                           {:wrap true
                                                            :pattern true
                                                            :no_case true})
                                                    (search.find ___doc-__ line
                                                                 col text opt))))
              "find-replace:replace-symbol" (fn []
                                              (var first "")
                                              (when (: (___doc-__)
                                                       :has_selection)
                                                (local text
                                                       (: (___doc-__) :get_text
                                                          (: (___doc-__)
                                                             :get_selection)))
                                                (set first
                                                     (or (text:match config.symbol_pattern)
                                                         "")))
                                              (replace :Symbol first
                                                       (fn [text old new]
                                                         (var n 0)
                                                         (local res
                                                                (text:gsub config.symbol_pattern
                                                                           (fn [sym]
                                                                             (when (= old
                                                                                      sym)
                                                                               (set n
                                                                                    (+ n
                                                                                       1))
                                                                               new))))
                                                         (values res n))))
              "find-replace:replace-pattern" (fn []
                                               (replace :Pattern ""
                                                        (fn [text old new]
                                                          (text:gsub old new))))
              "find-replace:replace" (fn []
                                       (replace :Text ""
                                                (fn [text old new]
                                                  (text:gsub (old:gsub "%W"
                                                                       "%%%1")
                                                             (new:gsub "%%"
                                                                       "%%%%")
                                                             nil))))
              "find-replace:repeat-find" (fn []
                                           (if (not last-fn)
                                               (core.error "No find to continue from")
                                               (do
                                                 (local (line col)
                                                        (: (___doc-__)
                                                           :get_selection))
                                                 (local (line1 col1 line2 col2)
                                                        (last-fn (___doc-__)
                                                                 line col
                                                                 last-text))
                                                 (when line1
                                                   (push-previous-find (___doc-__))
                                                   (: (___doc-__)
                                                      :set_selection line2 col2
                                                      line1 col1)
                                                   (core.active_view:scroll_to_line line2
                                                                                    true)))))
              "find-replace:find" (fn []
                                    (find "Find Text"
                                          (fn [___doc-__ line col text]
                                            (local opt
                                                   {:wrap true :no_case true})
                                            (search.find ___doc-__ line col
                                                         text opt))))
              "find-replace:previous-find" (fn []
                                             (local sel
                                                    (table.remove previous-finds))
                                             (when (or (not sel)
                                                       (not= (___doc-__)
                                                             last-doc))
                                               (core.error "No previous finds")
                                               (lua "return "))
                                             (: (___doc-__) :set_selection
                                                (table.unpack sel))
                                             (core.active_view:scroll_to_line (. sel
                                                                                 3)
                                                                              true))})

