(local core (require :core))

(local common (require :core.common))

(local style (require :core.style))

(local Doc (require :core.doc))

(local Doc-view (require :core.docview))

(local View (require :core.view))

(local Single-line-doc (Doc:extend))

(fn Single-line-doc.insert [self line col text]
  (Single-line-doc.super.insert self line col (text:gsub "\n" "")))

(local Command-view (Doc-view:extend))

(local max-suggestions 10)

(fn noop [])

(local default-state {:suggest noop :cancel noop :submit noop})

(fn Command-view.new [self]
  (Command-view.super.new self (Single-line-doc))
  (set self.suggestion_idx 1)
  (set self.suggestions {})
  (set self.suggestions_height 0)
  (set self.last_change_id 0)
  (set self.gutter_width 0)
  (set self.gutter_text_brightness 0)
  (set self.selection_offset 0)
  (set self.state default-state)
  (set self.font :font)
  (set self.size.y 0)
  (set self.label ""))

(fn Command-view.get_name [self]
  (View.get_name self))

(fn Command-view.get_line_screen_position [self]
  (let [x (Command-view.super.get_line_screen_position self 1)
        (_ y) (self:get_content_offset)
        lh (self:get_line_height)]
    (values x (+ y (/ (- self.size.y lh) 2)))))

(fn Command-view.get_scrollable_size [self]
  0)

(fn Command-view.scroll_to_make_visible [self])

(fn Command-view.get_text [self]
  (self.doc:get_text 1 1 1 math.huge))

(fn Command-view.set_text [self text select]
  (self.doc:remove 1 1 math.huge math.huge)
  (self.doc:text_input text)
  (when select
    (self.doc:set_selection math.huge math.huge 1 1)))

(fn Command-view.move_suggestion_idx [self dir]
  (let [n (+ self.suggestion_idx dir)]
    (set self.suggestion_idx (common.clamp n 1 (length self.suggestions)))
    (self:complete)
    (set self.last_change_id (self.doc:get_change_id))))

(fn Command-view.complete [self]
  (when (> (length self.suggestions) 0)
    (self:set_text (. (. self.suggestions self.suggestion_idx) :text))))

(fn Command-view.submit [self]
  (let [suggestion (. self.suggestions self.suggestion_idx)
        text (self:get_text)
        submit self.state.submit]
    (self:exit true)
    (submit text suggestion)))

(fn Command-view.enter [self text submit suggest cancel]
  (when (not= self.state default-state)
    (lua "return "))
  (set self.state {:suggest (or suggest noop)
                   :cancel (or cancel noop)
                   :submit (or submit noop)})
  (core.set_active_view self)
  (self:update_suggestions)
  (set self.gutter_text_brightness 100)
  (set self.label (.. text ": ")))

(fn Command-view.exit [self submitted inexplicit]
  (when (= core.active_view self)
    (core.set_active_view core.last_active_view))
  (local cancel self.state.cancel)
  (set self.state default-state)
  (self.doc:reset)
  (set self.suggestions {})
  (when (not submitted)
    (cancel (not inexplicit))))

(fn Command-view.get_gutter_width [self]
  self.gutter_width)

(fn Command-view.get_suggestion_line_height [self]
  (+ (: (self:get_font) :get_height) style.padding.y))

(fn Command-view.update_suggestions [self]
  (let [t (or (self.state.suggest (self:get_text)) {})
        res {}]
    (each [i item (ipairs t)]
      (when (= i max-suggestions)
        (lua :break))
      (when (= (type item) :string)
        (set-forcibly! item {:text item}))
      (tset res i item))
    (set self.suggestions res)
    (set self.suggestion_idx 1)))

(fn Command-view.update [self]
  (Command-view.super.update self)
  (when (and (not= core.active_view self) (not= self.state default-state))
    (self:exit false true))
  (when (not= self.last_change_id (self.doc:get_change_id))
    (self:update_suggestions)
    (set self.last_change_id (self.doc:get_change_id)))
  (self:move_towards :gutter_text_brightness 0 0.1)
  (local dest (+ (: (self:get_font) :get_width self.label) style.padding.x))
  (if (<= self.size.y 0) (set self.gutter_width dest)
      (self:move_towards :gutter_width dest))
  (local lh (self:get_suggestion_line_height))
  (local dest (* (length self.suggestions) lh))
  (self:move_towards :suggestions_height dest)
  (local dest (* self.suggestion_idx (self:get_suggestion_line_height)))
  (self:move_towards :selection_offset dest)
  (var dest 0)
  (when (= self core.active_view)
    (set dest (+ (style.font:get_height) (* style.padding.y 2))))
  (self:move_towards self.size :y dest))

(fn Command-view.draw_line_highlight [self])

(fn Command-view.draw_line_gutter [self idx x y]
  (let [yoffset (self:get_line_text_y_offset)
        pos self.position
        color (common.lerp style.text style.accent
                           (/ self.gutter_text_brightness 100))]
    (core.push_clip_rect pos.x pos.y (self:get_gutter_width) self.size.y)
    (set-forcibly! x (+ x style.padding.x))
    (renderer.draw_text (self:get_font) self.label x (+ y yoffset) color)
    (core.pop_clip_rect)))

(fn draw-suggestions-box [self]
  (let [lh (self:get_suggestion_line_height)
        dh style.divider_size
        (x _) (self:get_line_screen_position)
        h (math.ceil self.suggestions_height)
        (rx ry rw rh) (values self.position.x (- (- self.position.y h) dh)
                              self.size.x h)]
    (when (> (length self.suggestions) 0)
      (renderer.draw_rect rx ry rw rh style.background3)
      (renderer.draw_rect rx (- ry dh) rw dh style.divider)
      (local y (- (- self.position.y self.selection_offset) dh))
      (renderer.draw_rect rx y rw lh style.line_highlight))
    (core.push_clip_rect rx ry rw rh)
    (each [i item (ipairs self.suggestions)]
      (local color (or (and (= i self.suggestion_idx) style.accent) style.text))
      (local y (- (- self.position.y (* i lh)) dh))
      (common.draw_text (self:get_font) color item.text nil x y 0 lh)
      (when item.info
        (local w (- (- self.size.x x) style.padding.x))
        (common.draw_text (self:get_font) style.dim item.info :right x y w lh)))
    (core.pop_clip_rect)))

(fn Command-view.draw [self]
  (Command-view.super.draw self)
  (core.root_view:defer_draw draw-suggestions-box self))

Command-view

