(local core (require :core))

(local config (require :core.config))

(local style (require :core.style))

(local common (require :core.common))

(local Object (require :core.object))

(local View (Object:extend))

(fn View.new [self]
  (set self.position {:x 0 :y 0})
  (set self.size {:x 0 :y 0})
  (set self.scroll {:x 0 :y 0 :to {:x 0 :y 0}})
  (set self.cursor :arrow)
  (set self.scrollable false))

(fn View.move_towards [self t k dest rate]
  (if (not= (type t) :table)
      (self:move_towards self t k dest rate)
      (let [val (. t k)]
        (if (< (math.abs (- val dest)) 0.5) (tset t k dest)
            (tset t k (common.lerp val dest (or rate 0.5))))
        (when (not= val dest)
          (set core.redraw true)))))

(fn View.try_close [self do-close]
  (do-close))

(fn View.get_name [self]
  "---")

(fn View.get_scrollable_size [self]
  math.huge)

(fn View.get_scrollbar_rect [self]
  (let [sz (self:get_scrollable_size)]
    (when (or (<= sz self.size.y) (= sz math.huge))
      (lua "return 0, 0, 0, 0"))
    (local h (math.max 20 (/ (* self.size.y self.size.y) sz)))
    (values (- (+ self.position.x self.size.x) style.scrollbar_size)
            (+ self.position.y
               (/ (* self.scroll.y (- self.size.y h)) (- sz self.size.y)))
            style.scrollbar_size h)))

(fn View.scrollbar_overlaps_point [self x y]
  (let [(sx sy sw sh) (self:get_scrollbar_rect)]
    (and (and (and (>= x (- sx (* sw 3))) (< x (+ sx sw))) (>= y sy))
         (< y (+ sy sh)))))

(fn View.on_mouse_pressed [self button x y clicks]
  (when (self:scrollbar_overlaps_point x y)
    (set self.dragging_scrollbar true)
    true))

(fn View.on_mouse_released [self button x y]
  (set self.dragging_scrollbar false))

(fn View.on_mouse_moved [self x y dx dy]
  (when self.dragging_scrollbar
    (local delta (* (/ (self:get_scrollable_size) self.size.y) dy))
    (set self.scroll.to.y (+ self.scroll.to.y delta)))
  (set self.hovered_scrollbar (self:scrollbar_overlaps_point x y)))

(fn View.on_text_input [self text])

(fn View.on_mouse_wheel [self y]
  (when self.scrollable
    (set self.scroll.to.y
         (+ self.scroll.to.y (* y (- config.mouse_wheel_scroll))))))

(fn View.get_content_bounds [self]
  (let [x self.scroll.x
        y self.scroll.y]
    (values x y (+ x self.size.x) (+ y self.size.y))))

(fn View.get_content_offset [self]
  (let [x (common.round (- self.position.x self.scroll.x))
        y (common.round (- self.position.y self.scroll.y))]
    (values x y)))

(fn View.clamp_scroll_position [self]
  (let [max (- (self:get_scrollable_size) self.size.y)]
    (set self.scroll.to.y (common.clamp self.scroll.to.y 0 max))))

(fn View.update [self]
  (self:clamp_scroll_position)
  (self:move_towards self.scroll :x self.scroll.to.x 0.3)
  (self:move_towards self.scroll :y self.scroll.to.y 0.3))

(fn View.draw_background [self color]
  (let [(x y) (values self.position.x self.position.y)
        (w h) (values self.size.x self.size.y)]
    (renderer.draw_rect x y (+ w (% x 1)) (+ h (% y 1)) color)))

(fn View.draw_scrollbar [self]
  (let [(x y w h) (self:get_scrollbar_rect)
        highlight (or self.hovered_scrollbar self.dragging_scrollbar)
        color (or (and highlight style.scrollbar2) style.scrollbar)]
    (renderer.draw_rect x y w h color)))

(fn View.draw [self])

View

