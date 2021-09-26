(local core (require :core))

(local common (require :core.common))

(local command (require :core.command))

(local config (require :core.config))

(local style (require :core.style))

(local Doc-view (require :core.docview))

(local Log-view (require :core.logview))

(local View (require :core.view))

(local Status-view (View:extend))

(set Status-view.separator "      ")

(set Status-view.separator2 "   |   ")

(fn Status-view.new [self]
  (Status-view.super.new self)
  (set self.message_timeout 0)
  (set self.message {}))

(fn Status-view.on_mouse_pressed [self]
  (core.set_active_view core.last_active_view)
  (when (and (< (system.get_time) self.message_timeout)
             (not (core.active_view:is Log-view)))
    (command.perform "core:open-log")))

(fn Status-view.show_message [self icon icon-color text]
  (set self.message {1 icon-color
                     2 style.icon_font
                     3 icon
                     4 style.dim
                     5 style.font
                     6 Status-view.separator2
                     7 style.text
                     8 text})
  (set self.message_timeout (+ (system.get_time) config.message_timeout)))

(fn Status-view.update [self]
  (set self.size.y (+ (style.font:get_height) (* style.padding.y 2)))
  (if (< (system.get_time) self.message_timeout)
      (set self.scroll.to.y self.size.y) (set self.scroll.to.y 0))
  (Status-view.super.update self))

(fn draw-items [self items x y draw-fn]
  (var font style.font)
  (var color style.text)
  (each [_ item (ipairs items)]
    (if (= (type item) :userdata) (set font item) (= (type item) :table)
        (set color item)
        (set-forcibly! x (draw-fn font color item nil x y 0 self.size.y))))
  x)

(fn text-width [font _ text _ x]
  (+ x (font:get_width text)))

(fn Status-view.draw_items [self items right-align yoffset]
  (var (x y) (self:get_content_offset))
  (set y (+ y (or yoffset 0)))
  (if right-align
      (let [w (draw-items self items 0 0 text-width)]
        (set x (- (- (+ x self.size.x) w) style.padding.x))
        (draw-items self items x y common.draw_text))
      (do
        (set x (+ x style.padding.x))
        (draw-items self items x y common.draw_text))))

(fn Status-view.get_items [self]
  (when (= (getmetatable core.active_view) Doc-view)
    (local dv core.active_view)
    (local (line col) (dv.doc:get_selection))
    (local dirty (dv.doc:is_dirty))
    (let [___antifnl_rtn_1___ {1 (or (and dirty style.accent) style.text)
                               2 style.icon_font
                               3 :f
                               4 style.dim
                               5 style.font
                               6 self.separator2
                               7 style.text
                               8 (or (and dv.doc.filename style.text) style.dim)
                               9 (dv.doc:get_name)
                               10 style.text
                               11 self.separator
                               12 "line: "
                               13 line
                               14 self.separator
                               15 (or (and (> col config.line_limit)
                                           style.accent)
                                      style.text)
                               16 "col: "
                               17 col
                               18 style.text
                               19 self.separator
                               20 (string.format "%d%%"
                                                 (* (/ line
                                                       (length dv.doc.lines))
                                                    100))}
          ___antifnl_rtn_2___ {1 style.icon_font
                               2 :g
                               3 style.font
                               4 style.dim
                               5 self.separator2
                               6 style.text
                               7 (length dv.doc.lines)
                               8 " lines"
                               9 self.separator
                               10 (or (and dv.doc.crlf :CRLF) :LF)}]
      (lua "return ___antifnl_rtn_1___, ___antifnl_rtn_2___")))
  (values {} {1 style.icon_font
              2 :g
              3 style.font
              4 style.dim
              5 self.separator2
              6 (length core.docs)
              7 style.text
              8 " / "
              9 (length core.project_files)
              10 " files"}))

(fn Status-view.draw [self]
  (self:draw_background style.background2)
  (when self.message
    (self:draw_items self.message false self.size.y))
  (local (left right) (self:get_items))
  (self:draw_items left)
  (self:draw_items right true))

Status-view

