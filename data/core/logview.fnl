(local core (require :core))

(local style (require :core.style))

(local View (require :core.view))

(local Log-view (View:extend))

(fn Log-view.new [self]
  (Log-view.super.new self)
  (set self.last_item (. core.log_items (length core.log_items)))
  (set self.scrollable true)
  (set self.yoffset 0))

(fn Log-view.get_name [self]
  :Log)

(fn Log-view.update [self]
  (let [item (. core.log_items (length core.log_items))]
    (when (not= self.last_item item)
      (set self.last_item item)
      (set self.scroll.to.y 0)
      (set self.yoffset (- (+ (style.font:get_height) style.padding.y))))
    (self:move_towards :yoffset 0)
    (Log-view.super.update self)))

(fn draw-text-multiline [font text x y color]
  (let [th (font:get_height)]
    (var (resx resy) (values x y))
    (each [line (text:gmatch "[^\n]+")]
      (set resy y)
      (set resx (renderer.draw_text style.font line x y color))
      (set-forcibly! y (+ y th)))
    (values resx resy)))

(fn Log-view.draw [self]
  (self:draw_background style.background)
  (local (ox oy) (self:get_content_offset))
  (local th (style.font:get_height))
  (var y (+ (+ oy style.padding.y) self.yoffset))
  (for [i (length core.log_items) 1 (- 1)]
    (var x (+ ox style.padding.x))
    (local item (. core.log_items i))
    (local time (os.date nil item.time))
    (set x (renderer.draw_text style.font time x y style.dim))
    (set x (+ x style.padding.x))
    (local subx x)
    (set-forcibly! (x y)
                   (draw-text-multiline style.font item.text x y style.text))
    (renderer.draw_text style.font (.. " at " item.at) x y style.dim)
    (set y (+ y th))
    (when item.info
      (set-forcibly! (subx y)
                     (draw-text-multiline style.font item.info subx y style.dim))
      (set y (+ y th)))
    (set y (+ y style.padding.y))))

Log-view

