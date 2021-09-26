(local core (require :core))

(local common (require :core.common))

(local config (require :core.config))

(local style (require :core.style))

(local keymap (require :core.keymap))

(local translate (require :core.doc.translate))

(local View (require :core.view))

(local Doc-view (View:extend))

(fn move-to-line-offset [dv line col offset]
  (let [xo dv.last_x_offset]
    (when (or (not= xo.line line) (not= xo.col col))
      (set xo.offset (dv:get_col_x_offset line col)))
    (set xo.line (+ line offset))
    (set xo.col (dv:get_x_offset_col (+ line offset) xo.offset))
    (values xo.line xo.col)))

(set Doc-view.translate
     {:next_page (fn [___doc-__ line col dv]
                   (local (min max) (dv:get_visible_line_range))
                   (values (+ line (- max min)) 1))
      :previous_page (fn [___doc-__ line col dv]
                       (local (min max) (dv:get_visible_line_range))
                       (values (- line (- max min)) 1))
      :previous_line (fn [___doc-__ line col dv]
                       (when (= line 1)
                         (lua "return 1, 1"))
                       (move-to-line-offset dv line col (- 1)))
      :next_line (fn [___doc-__ line col dv]
                   (when (= line (length ___doc-__.lines))
                     (let [___antifnl_rtn_1___ (length ___doc-__.lines)
                           ___antifnl_rtn_2___ math.huge]
                       (lua "return ___antifnl_rtn_1___, ___antifnl_rtn_2___")))
                   (move-to-line-offset dv line col 1))})

(local blink-period 0.8)

(fn Doc-view.new [self ___doc-__]
  (Doc-view.super.new self)
  (set self.cursor :ibeam)
  (set self.scrollable true)
  (set self.doc (assert ___doc-__))
  (set self.font :code_font)
  (set self.last_x_offset {})
  (set self.blink_timer 0))

(fn Doc-view.try_close [self do-close]
  (if (and (self.doc:is_dirty) (= (length (core.get_views_referencing_doc self.doc))
                                  1))
      (core.command_view:enter "Unsaved Changes; Confirm Close"
                               (fn [_ item]
                                 (if (item.text:match "^[cC]") (do-close)
                                     (item.text:match "^[sS]") (do
                                                                 (self.doc:save)
                                                                 (do-close))))
                               (fn [text]
                                 (let [items {}]
                                   (when (not (text:find "^[^cC]"))
                                     (table.insert items "Close Without Saving"))
                                   (when (not (text:find "^[^sS]"))
                                     (table.insert items "Save And Close"))
                                   items))) (do-close)))

(fn Doc-view.get_name [self]
  (let [post (or (and (self.doc:is_dirty) "*") "")
        name (self.doc:get_name)]
    (.. (name:match "[^/%\\]*$") post)))

(fn Doc-view.get_scrollable_size [self]
  (+ (* (self:get_line_height) (- (length self.doc.lines) 1)) self.size.y))

(fn Doc-view.get_font [self]
  (. style self.font))

(fn Doc-view.get_line_height [self]
  (math.floor (* (: (self:get_font) :get_height) config.line_height)))

(fn Doc-view.get_gutter_width [self]
  (+ (: (self:get_font) :get_width (length self.doc.lines))
     (* style.padding.x 2)))

(fn Doc-view.get_line_screen_position [self idx]
  (let [(x y) (self:get_content_offset)
        lh (self:get_line_height)
        gw (self:get_gutter_width)]
    (values (+ x gw) (+ (+ y (* (- idx 1) lh)) style.padding.y))))

(fn Doc-view.get_line_text_y_offset [self]
  (let [lh (self:get_line_height)
        th (: (self:get_font) :get_height)]
    (/ (- lh th) 2)))

(fn Doc-view.get_visible_line_range [self]
  (let [(x y x2 y2) (self:get_content_bounds)
        lh (self:get_line_height)
        minline (math.max 1 (math.floor (/ y lh)))
        maxline (math.min (length self.doc.lines) (+ (math.floor (/ y2 lh)) 1))]
    (values minline maxline)))

(fn Doc-view.get_col_x_offset [self line col]
  (let [text (. self.doc.lines line)]
    (when (not text)
      (lua "return 0"))
    (: (self:get_font) :get_width (text:sub 1 (- col 1)))))

(fn Doc-view.get_x_offset_col [self line x]
  (let [text (. self.doc.lines line)]
    (var (xoffset last-i i) (values 0 1 1))
    (each [char (common.utf8_chars text)]
      (local w (: (self:get_font) :get_width char))
      (when (>= xoffset x)
        (let [___antifnl_rtn_1___ (or (and (> (- xoffset x) (/ w 2)) last-i) i)]
          (lua "return ___antifnl_rtn_1___")))
      (set xoffset (+ xoffset w))
      (set last-i i)
      (set i (+ i (length char))))
    (length text)))

(fn Doc-view.resolve_screen_position [self x y]
  (let [(ox oy) (self:get_line_screen_position 1)]
    (var line (+ (math.floor (/ (- y oy) (self:get_line_height))) 1))
    (set line (common.clamp line 1 (length self.doc.lines)))
    (local col (self:get_x_offset_col line (- x ox)))
    (values line col)))

(fn Doc-view.scroll_to_line [self line ignore-if-visible instant]
  (let [(min max) (self:get_visible_line_range)]
    (when (not (and (and ignore-if-visible (> line min)) (< line max)))
      (local lh (self:get_line_height))
      (set self.scroll.to.y
           (math.max 0 (- (* lh (- line 1)) (/ self.size.y 2))))
      (when instant
        (set self.scroll.y self.scroll.to.y)))))

(fn Doc-view.scroll_to_make_visible [self line col]
  (let [min (* (self:get_line_height) (- line 1))
        max (- (* (self:get_line_height) (+ line 2)) self.size.y)]
    (set self.scroll.to.y (math.min self.scroll.to.y min))
    (set self.scroll.to.y (math.max self.scroll.to.y max))
    (local gw (self:get_gutter_width))
    (local xoffset (self:get_col_x_offset line col))
    (local max (+ (+ (- xoffset self.size.x) gw) (/ self.size.x 5)))
    (set self.scroll.to.x (math.max 0 max))))

(fn mouse-selection [___doc-__ clicks line1 col1 line2 col2]
  (let [swap (or (< line2 line1) (and (= line2 line1) (<= col2 col1)))]
    (when swap
      (set-forcibly! (line1 col1 line2 col2) (values line2 col2 line1 col1)))
    (if (= clicks 2)
        (do
          (set-forcibly! (line1 col1)
                         (translate.start_of_word ___doc-__ line1 col1))
          (set-forcibly! (line2 col2)
                         (translate.end_of_word ___doc-__ line2 col2)))
        (= clicks 3)
        (do
          (when (and (= line2 (length ___doc-__.lines))
                     (not= (. ___doc-__.lines (length ___doc-__.lines)) "\n"))
            (___doc-__:insert math.huge math.huge "\n"))
          (set-forcibly! (line1 col1 line2 col2) (values line1 1 (+ line2 1) 1))))
    (when swap
      (lua "return line2, col2, line1, col1"))
    (values line1 col1 line2 col2)))

(fn Doc-view.on_mouse_pressed [self button x y clicks]
  (let [caught (Doc-view.super.on_mouse_pressed self button x y clicks)]
    (when caught
      (lua "return "))
    (if (. keymap.modkeys :shift)
        (when (= clicks 1)
          (local (line1 col1) (select 3 (self.doc:get_selection)))
          (local (line2 col2) (self:resolve_screen_position x y))
          (self.doc:set_selection line2 col2 line1 col1))
        (let [(line col) (self:resolve_screen_position x y)]
          (self.doc:set_selection (mouse-selection self.doc clicks line col
                                                   line col))
          (set self.mouse_selecting {1 line 2 col : clicks})))
    (set self.blink_timer 0)))

(fn Doc-view.on_mouse_moved [self x y ...]
  (Doc-view.super.on_mouse_moved self x y ...)
  (if (or (self:scrollbar_overlaps_point x y) self.dragging_scrollbar)
      (set self.cursor :arrow) (set self.cursor :ibeam))
  (when self.mouse_selecting
    (local (l1 c1) (self:resolve_screen_position x y))
    (local (l2 c2) (table.unpack self.mouse_selecting))
    (local clicks self.mouse_selecting.clicks)
    (self.doc:set_selection (mouse-selection self.doc clicks l1 c1 l2 c2))))

(fn Doc-view.on_mouse_released [self button]
  (Doc-view.super.on_mouse_released self button)
  (set self.mouse_selecting nil))

(fn Doc-view.on_text_input [self text]
  (self.doc:text_input text))

(fn Doc-view.update [self]
  (let [(line col) (self.doc:get_selection)]
    (when (and (or (not= line self.last_line) (not= col self.last_col))
               (> self.size.x 0))
      (when (= core.active_view self)
        (self:scroll_to_make_visible line col))
      (set self.blink_timer 0)
      (set-forcibly! (self.last_line self.last_col) (values line col)))
    (when (and (= self core.active_view) (not self.mouse_selecting))
      (local n (/ blink-period 2))
      (local prev self.blink_timer)
      (set self.blink_timer (% (+ self.blink_timer (/ 1 config.fps))
                               blink-period))
      (when (not= (> self.blink_timer n) (> prev n))
        (set core.redraw true)))
    (Doc-view.super.update self)))

(fn Doc-view.draw_line_highlight [self x y]
  (let [lh (self:get_line_height)]
    (renderer.draw_rect x y self.size.x lh style.line_highlight)))

(fn Doc-view.draw_line_text [self idx x y]
  (var (tx ty) (values x (+ y (self:get_line_text_y_offset))))
  (local font (self:get_font))
  (each [_ type text (self.doc.highlighter:each_token idx)]
    (local color (. style.syntax type))
    (set tx (renderer.draw_text font text tx ty color))))

(fn Doc-view.draw_line_body [self idx x y]
  (let [(line col) (self.doc:get_selection)]
    (var (line1 col1 line2 col2) (self.doc:get_selection true))
    (when (and (>= idx line1) (<= idx line2))
      (local text (. self.doc.lines idx))
      (when (not= line1 idx)
        (set col1 1))
      (when (not= line2 idx)
        (set col2 (+ (length text) 1)))
      (local x1 (+ x (self:get_col_x_offset idx col1)))
      (local x2 (+ x (self:get_col_x_offset idx col2)))
      (local lh (self:get_line_height))
      (renderer.draw_rect x1 y (- x2 x1) lh style.selection))
    (when (and (and (and config.highlight_current_line
                         (not (self.doc:has_selection)))
                    (= line idx)) (= core.active_view self))
      (self:draw_line_highlight (+ x self.scroll.x) y))
    (self:draw_line_text idx x y)
    (when (and (and (and (= line idx) (= core.active_view self))
                    (< self.blink_timer (/ blink-period 2)))
               (system.window_has_focus))
      (local lh (self:get_line_height))
      (local x1 (+ x (self:get_col_x_offset line col)))
      (renderer.draw_rect x1 y style.caret_width lh style.caret))))

(fn Doc-view.draw_line_gutter [self idx x y]
  (var color style.line_number)
  (local (line1 _ line2 _) (self.doc:get_selection true))
  (when (and (>= idx line1) (<= idx line2))
    (set color style.line_number2))
  (local yoffset (self:get_line_text_y_offset))
  (set-forcibly! x (+ x style.padding.x))
  (renderer.draw_text (self:get_font) idx x (+ y yoffset) color))

(fn Doc-view.draw [self]
  (self:draw_background style.background)
  (local font (self:get_font))
  (font:set_tab_width (* (font:get_width " ") config.indent_size))
  (local (minline maxline) (self:get_visible_line_range))
  (local lh (self:get_line_height))
  (var (_ y) (self:get_line_screen_position minline))
  (local x self.position.x)
  (for [i minline maxline 1]
    (self:draw_line_gutter i x y)
    (set y (+ y lh)))
  (var (x y) (self:get_line_screen_position minline))
  (local gw (self:get_gutter_width))
  (local pos self.position)
  (core.push_clip_rect (+ pos.x gw) pos.y self.size.x self.size.y)
  (for [i minline maxline 1]
    (self:draw_line_body i x y)
    (set y (+ y lh)))
  (core.pop_clip_rect)
  (self:draw_scrollbar))

Doc-view

