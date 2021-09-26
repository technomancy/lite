(local core (require :core))

(local common (require :core.common))

(local config (require :core.config))

(local command (require :core.command))

(local style (require :core.style))

(local keymap (require :core.keymap))

(local translate (require :core.doc.translate))

(local Root-view (require :core.rootview))

(local Doc-view (require :core.docview))

(set config.autocomplete_max_suggestions 6)

(local autocomplete {})

(set autocomplete.map {})

(local mt {:__tostring (fn [t]
                         t.text)})

(fn autocomplete.add [t]
  (let [items {}]
    (each [text info (pairs t.items)]
      (set-forcibly! info (and (= (type info) :string) info))
      (table.insert items (setmetatable {: text : info} mt)))
    (tset autocomplete.map t.name {: items :files (or t.files ".*")})))

(core.add_thread (fn []
                   (let [cache (setmetatable {} {:__mode :k})]
                     (fn get-symbols [___doc-__]
                       (var i 1)
                       (local s {})
                       (while (< i (length ___doc-__.lines))
                         (each [sym (: (. ___doc-__.lines i) :gmatch
                                       config.symbol_pattern)]
                           (tset s sym true))
                         (set i (+ i 1))
                         (when (= (% i 100) 0)
                           (coroutine.yield)))
                       s)

                     (fn cache-is-valid [___doc-__]
                       (let [c (. cache ___doc-__)]
                         (and c (= c.last_change_id (___doc-__:get_change_id)))))

                     (while true
                       (local symbols {})
                       (each [_ ___doc-__ (ipairs core.docs)]
                         (when (not (cache-is-valid ___doc-__))
                           (tset cache ___doc-__
                                 {:last_change_id (___doc-__:get_change_id)
                                  :symbols (get-symbols ___doc-__)}))
                         (each [sym (pairs (. (. cache ___doc-__) :symbols))]
                           (tset symbols sym true))
                         (coroutine.yield))
                       (autocomplete.add {:items symbols :name :open-docs})
                       (var valid true)
                       (while valid
                         (coroutine.yield 1)
                         (each [_ ___doc-__ (ipairs core.docs)]
                           (when (not (cache-is-valid ___doc-__))
                             (set valid false))))))))

(var ___partial-__ "")

(var suggestions-idx 1)

(var suggestions {})

(local (last-line last-col) nil)

(fn reset-suggestions []
  (set suggestions-idx 1)
  (set suggestions {}))

(fn update-suggestions []
  (let [___doc-__ core.active_view.doc
        filename (or (and ___doc-__ ___doc-__.filename) "")]
    (var items {})
    (each [_ v (pairs autocomplete.map)]
      (when (common.match_pattern filename v.files)
        (each [_ item (pairs v.items)]
          (table.insert items item))))
    (set items (common.fuzzy_match items ___partial-__))
    (var j 1)
    (for [i 1 config.autocomplete_max_suggestions 1]
      (tset suggestions i (. items j))
      (while (and (. items j) (= (. (. items i) :text) (. (. items j) :text)))
        (tset (. items i) :info
              (or (. (. items i) :info) (. (. items j) :info)))
        (set j (+ j 1))))))

(fn get-partial-symbol []
  (let [___doc-__ core.active_view.doc
        (line2 col2) (___doc-__:get_selection)
        (line1 col1) (___doc-__:position_offset line2 col2
                                                translate.start_of_word)]
    (___doc-__:get_text line1 col1 line2 col2)))

(fn get-active-view []
  (when (= (getmetatable core.active_view) Doc-view)
    core.active_view))

(fn get-suggestions-rect [av]
  (when (= (length suggestions) 0)
    (lua "return 0, 0, 0, 0"))
  (local (line col) (av.doc:get_selection))
  (var (x y) (av:get_line_screen_position line))
  (set x (+ x (av:get_col_x_offset line (- col (length ___partial-__)))))
  (set y (+ (+ y (av:get_line_height)) style.padding.y))
  (local font (av:get_font))
  (local th (font:get_height))
  (var max-width 0)
  (each [_ s (ipairs suggestions)]
    (var w (font:get_width s.text))
    (when s.info
      (set w (+ (+ w (style.font:get_width s.info)) style.padding.x)))
    (set max-width (math.max max-width w)))
  (values (- x style.padding.x) (- y style.padding.y)
          (+ max-width (* style.padding.x 2))
          (+ (* (length suggestions) (+ th style.padding.y)) style.padding.y)))

(fn draw-suggestions-box [av]
  (let [(rx ry rw rh) (get-suggestions-rect av)]
    (renderer.draw_rect rx ry rw rh style.background3)
    (local font (av:get_font))
    (local lh (+ (font:get_height) style.padding.y))
    (var y (+ ry (/ style.padding.y 2)))
    (each [i s (ipairs suggestions)]
      (var color (or (and (= i suggestions-idx) style.accent) style.text))
      (common.draw_text font color s.text :left (+ rx style.padding.x) y rw lh)
      (when s.info
        (set color (or (and (= i suggestions-idx) style.text) style.dim))
        (common.draw_text style.font color s.info :right rx y
                          (- rw style.padding.x) lh))
      (set y (+ y lh)))))

(local on-text-input Root-view.on_text_input)

(local update Root-view.update)

(local draw Root-view.draw)

(set Root-view.on_text_input
     (fn [...]
       (do
         (on-text-input ...)
         (local av (get-active-view))
         (when av
           (set ___partial-__ (get-partial-symbol))
           (if (>= (length ___partial-__) 3)
               (do
                 (update-suggestions)
                 (set-forcibly! (last-line last-col) (av.doc:get_selection)))
               (reset-suggestions))
           (local (_ y _ h) (get-suggestions-rect av))
           (local limit (+ av.position.y av.size.y))
           (when (> (+ y h) limit)
             (set av.scroll.to.y (- (+ (+ av.scroll.y y) h) limit)))))))

(set Root-view.update (fn [...]
                        (do
                          (update ...)
                          (local av (get-active-view))
                          (when av
                            (local (line col) (av.doc:get_selection))
                            (when (or (not= line last-line) (not= col last-col))
                              (reset-suggestions))))))

(set Root-view.draw
     (fn [...]
       (do
         (draw ...)
         (local av (get-active-view))
         (when av
           (core.root_view:defer_draw draw-suggestions-box av)))))

(fn predicate []
  (and (get-active-view) (> (length suggestions) 0)))

(command.add predicate
             {"autocomplete:cancel" (fn []
                                      (reset-suggestions))
              "autocomplete:previous" (fn []
                                        (set suggestions-idx
                                             (math.max (- suggestions-idx 1) 1)))
              "autocomplete:complete" (fn []
                                        (local ___doc-__ core.active_view.doc)
                                        (local (line col)
                                               (___doc-__:get_selection))
                                        (local text
                                               (. (. suggestions
                                                     suggestions-idx)
                                                  :text))
                                        (___doc-__:insert line col text)
                                        (___doc-__:remove line col line
                                                          (- col
                                                             (length ___partial-__)))
                                        (___doc-__:set_selection line
                                                                 (- (+ col
                                                                       (length text))
                                                                    (length ___partial-__)))
                                        (reset-suggestions))
              "autocomplete:next" (fn []
                                    (set suggestions-idx
                                         (math.min (+ suggestions-idx 1)
                                                   (length suggestions))))})

(keymap.add {:up "autocomplete:previous"
             :tab "autocomplete:complete"
             :escape "autocomplete:cancel"
             :down "autocomplete:next"})

autocomplete

