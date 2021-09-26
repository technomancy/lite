(local core (require :core))

(local common (require :core.common))

(local keymap (require :core.keymap))

(local command (require :core.command))

(local style (require :core.style))

(local View (require :core.view))

(local Results-view (View:extend))

(fn Results-view.new [self text ___fn-__]
  (Results-view.super.new self)
  (set self.scrollable true)
  (set self.brightness 0)
  (self:begin_search text ___fn-__))

(fn Results-view.get_name [self]
  "Search Results")

(fn find-all-matches-in-file [t filename ___fn-__]
  (let [fp (io.open filename)]
    (when (not fp)
      (lua "return t"))
    (var n 1)
    (each [line (fp:lines)]
      (local s (___fn-__ line))
      (when s
        (table.insert t {:file filename :col s :line n :text line})
        (set core.redraw true))
      (when (= (% n 100) 0)
        (coroutine.yield))
      (set n (+ n 1))
      (set core.redraw true))
    (fp:close)))

(fn Results-view.begin_search [self text ___fn-__]
  (set self.search_args {1 text 2 ___fn-__})
  (set self.results {})
  (set self.last_file_idx 1)
  (set self.query text)
  (set self.searching true)
  (set self.selected_idx 0)
  (core.add_thread (fn []
                     (each [i file (ipairs core.project_files)]
                       (when (= file.type :file)
                         (find-all-matches-in-file self.results file.filename
                                                   ___fn-__))
                       (set self.last_file_idx i))
                     (set self.searching false)
                     (set self.brightness 100)
                     (set core.redraw true)) self.results)
  (set self.scroll.to.y 0))

(fn Results-view.refresh [self]
  (self:begin_search (table.unpack self.search_args)))

(fn Results-view.on_mouse_moved [self mx my ...]
  (Results-view.super.on_mouse_moved self mx my ...)
  (set self.selected_idx 0)
  (each [i item x y w h (self:each_visible_result)]
    (when (and (and (and (>= mx x) (>= my y)) (< mx (+ x w))) (< my (+ y h)))
      (set self.selected_idx i)
      (lua :break))))

(fn Results-view.on_mouse_pressed [self ...]
  (let [caught (Results-view.super.on_mouse_pressed self ...)]
    (when (not caught)
      (self:open_selected_result))))

(fn Results-view.open_selected_result [self]
  (let [res (. self.results self.selected_idx)]
    (when (not res)
      (lua "return "))
    (core.try (fn []
                (let [dv (core.root_view:open_doc (core.open_doc res.file))]
                  (core.root_view.root_node:update_layout)
                  (dv.doc:set_selection res.line res.col)
                  (dv:scroll_to_line res.line false true))))))

(fn Results-view.update [self]
  (self:move_towards :brightness 0 0.1)
  (Results-view.super.update self))

(fn Results-view.get_results_yoffset [self]
  (+ (style.font:get_height) (* style.padding.y 3)))

(fn Results-view.get_line_height [self]
  (+ style.padding.y (style.font:get_height)))

(fn Results-view.get_scrollable_size [self]
  (+ (self:get_results_yoffset)
     (* (length self.results) (self:get_line_height))))

(fn Results-view.get_visible_results_range [self]
  (let [lh (self:get_line_height)
        oy (self:get_results_yoffset)
        min (math.max 1 (math.floor (/ (- self.scroll.y oy) lh)))]
    (values min (+ (+ min (math.floor (/ self.size.y lh))) 1))))

(fn Results-view.each_visible_result [self]
  (coroutine.wrap (fn []
                    (let [lh (self:get_line_height)]
                      (var (x y) (self:get_content_offset))
                      (local (min max) (self:get_visible_results_range))
                      (set y (+ (+ y (self:get_results_yoffset))
                                (* lh (- min 1))))
                      (for [i min max 1]
                        (local item (. self.results i))
                        (when (not item)
                          (lua :break))
                        (coroutine.yield i item x y self.size.x lh)
                        (set y (+ y lh)))))))

(fn Results-view.scroll_to_make_selected_visible [self]
  (let [h (self:get_line_height)
        y (+ (self:get_results_yoffset) (* h (- self.selected_idx 1)))]
    (set self.scroll.to.y (math.min self.scroll.to.y y))
    (set self.scroll.to.y (math.max self.scroll.to.y (- (+ y h) self.size.y)))))

(fn Results-view.draw [self]
  (self:draw_background style.background)
  (local (ox oy) (self:get_content_offset))
  (local (x y) (values (+ ox style.padding.x) (+ oy style.padding.y)))
  (local per (/ self.last_file_idx (length core.project_files)))
  (var text nil)
  (if self.searching
      (set text (string.format "Searching %d%% (%d of %d files, %d matches) for %q..."
                               (* per 100) self.last_file_idx
                               (length core.project_files) (length self.results)
                               self.query))
      (set text (string.format "Found %d matches for %q" (length self.results)
                               self.query)))
  (local color (common.lerp style.text style.accent (/ self.brightness 100)))
  (renderer.draw_text style.font text x y color)
  (local yoffset (self:get_results_yoffset))
  (local x (+ ox style.padding.x))
  (local w (- self.size.x (* style.padding.x 2)))
  (local h style.divider_size)
  (local color (common.lerp style.dim style.text (/ self.brightness 100)))
  (renderer.draw_rect x (- (+ oy yoffset) style.padding.y) w h color)
  (when self.searching
    (renderer.draw_rect x (- (+ oy yoffset) style.padding.y) (* w per) h
                        style.text))
  (local (y1 y2) (values self.position.y (+ self.position.y self.size.y)))
  (each [i item x y w h (self:each_visible_result)]
    (var color style.text)
    (when (= i self.selected_idx)
      (set color style.accent)
      (renderer.draw_rect x y w h style.line_highlight))
    (set-forcibly! x (+ x style.padding.x))
    (local text (string.format "%s at line %d (col %d): " item.file item.line
                               item.col))
    (set-forcibly! x (common.draw_text style.font style.dim text :left x y w h))
    (set-forcibly! x (common.draw_text style.code_font color item.text :left x
                                       y w h)))
  (self:draw_scrollbar))

(fn begin-search [text ___fn-__]
  (when (= text "")
    (core.error "Expected non-empty string")
    (lua "return "))
  (local rv (Results-view text ___fn-__))
  (: (core.root_view:get_active_node) :add_view rv))

(command.add nil
             {"project-search:find" (fn []
                                      (core.command_view:enter "Find Text In Project"
                                                               (fn [text]
                                                                 (set-forcibly! text
                                                                                (text:lower))
                                                                 (begin-search text
                                                                               (fn [line-text]
                                                                                 (: (line-text:lower)
                                                                                    :find
                                                                                    text
                                                                                    nil
                                                                                    true))))))
              "project-search:find-pattern" (fn []
                                              (core.command_view:enter "Find Pattern In Project"
                                                                       (fn [text]
                                                                         (begin-search text
                                                                                       (fn [line-text]
                                                                                         (line-text:find text))))))
              "project-search:fuzzy-find" (fn []
                                            (core.command_view:enter "Fuzzy Find Text In Project"
                                                                     (fn [text]
                                                                       (begin-search text
                                                                                     (fn [line-text]
                                                                                       (and (common.fuzzy_match line-text
                                                                                                                text)
                                                                                            1))))))})

(command.add Results-view
             {"project-search:refresh" (fn []
                                         (core.active_view:refresh))
              "project-search:select-previous" (fn []
                                                 (local view core.active_view)
                                                 (set view.selected_idx
                                                      (math.max (- view.selected_idx
                                                                   1)
                                                                1))
                                                 (view:scroll_to_make_selected_visible))
              "project-search:select-next" (fn []
                                             (local view core.active_view)
                                             (set view.selected_idx
                                                  (math.min (+ view.selected_idx
                                                               1)
                                                            (length view.results)))
                                             (view:scroll_to_make_selected_visible))
              "project-search:open-selected" (fn []
                                               (core.active_view:open_selected_result))})

(keymap.add {:ctrl+shift+f "project-search:find"
             :down "project-search:select-next"
             :f5 "project-search:refresh"
             :up "project-search:select-previous"
             :return "project-search:open-selected"})

