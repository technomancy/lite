(local core (require :core))

(local common (require :core.common))

(local style (require :core.style))

(local keymap (require :core.keymap))

(local Object (require :core.object))

(local View (require :core.view))

(local Doc-view (require :core.docview))

(local Empty-view (View:extend))

(fn draw-text [x y color]
  (var th (style.big_font:get_height))
  (local dh (+ th (* style.padding.y 2)))
  (set-forcibly! x
                 (renderer.draw_text style.big_font :lite x
                                     (+ y (/ (- dh th) 2)) color))
  (set-forcibly! x (+ x style.padding.x))
  (renderer.draw_rect x y (math.ceil (* 1 SCALE)) dh color)
  (local lines {1 {:cmd "core:find-command" :fmt "%s to run a command"}
                2 {:cmd "core:find-file"
                   :fmt "%s to open a file from the project"}})
  (set th (style.font:get_height))
  (set-forcibly! y (+ y (/ (- (- dh (* th 2)) style.padding.y) 2)))
  (var w 0)
  (each [_ line (ipairs lines)]
    (local text (string.format line.fmt (keymap.get_binding line.cmd)))
    (set w (math.max w
                     (renderer.draw_text style.font text (+ x style.padding.x)
                                         y color)))
    (set-forcibly! y (+ (+ y th) style.padding.y)))
  (values w dh))

(fn Empty-view.draw [self]
  (self:draw_background style.background)
  (local (w h) (draw-text 0 0 {1 0 2 0 3 0 4 0}))
  (local x (+ self.position.x
              (math.max style.padding.x (/ (- self.size.x w) 2))))
  (local y (+ self.position.y (/ (- self.size.y h) 2)))
  (draw-text x y style.dim))

(local Node (Object:extend))

(fn Node.new [self type]
  (set self.type (or type :leaf))
  (set self.position {:y 0 :x 0})
  (set self.size {:y 0 :x 0})
  (set self.views {})
  (set self.divider 0.5)
  (when (= self.type :leaf)
    (self:add_view (Empty-view))))

(fn Node.propagate [self ___fn-__ ...]
  ((. self.a ___fn-__) self.a ...)
  ((. self.b ___fn-__) self.b ...))

(fn Node.on_mouse_moved [self x y ...]
  (set self.hovered_tab (self:get_tab_overlapping_point x y))
  (if (= self.type :leaf) (self.active_view:on_mouse_moved x y ...)
      (self:propagate :on_mouse_moved x y ...)))

(fn Node.on_mouse_released [self ...]
  (if (= self.type :leaf) (self.active_view:on_mouse_released ...)
      (self:propagate :on_mouse_released ...)))

(fn Node.consume [self node]
  (each [k _ (pairs self)]
    (tset self k nil))
  (each [k v (pairs node)]
    (tset self k v)))

(local type-map {:right :hsplit :left :hsplit :up :vsplit :down :vsplit})

(fn Node.split [self dir view locked]
  (assert (= self.type :leaf) "Tried to split non-leaf node")
  (local type (assert (. type-map dir) "Invalid direction"))
  (local last-active core.active_view)
  (local child (Node))
  (child:consume self)
  (self:consume (Node type))
  (set self.a child)
  (set self.b (Node))
  (when view
    (self.b:add_view view))
  (when locked
    (set self.b.locked locked)
    (core.set_active_view last-active))
  (when (or (= dir :up) (= dir :left))
    (set-forcibly! (self.a self.b) (values self.b self.a)))
  child)

(fn Node.close_active_view [self root]
  (fn do-close []
    (if (> (length self.views) 1)
        (let [idx (self:get_view_idx self.active_view)]
          (table.remove self.views idx)
          (self:set_active_view (or (. self.views idx)
                                    (. self.views (length self.views)))))
        (let [parent (self:get_parent_node root)
              is-a (= parent.a self)
              other (. parent (or (and is-a :b) :a))]
          (if (other:get_locked_size)
              (do
                (set self.views {})
                (self:add_view (Empty-view)))
              (do
                (parent:consume other)
                (var p parent)
                (while (not= p.type :leaf)
                  (set p (. p (or (and is-a :a) :b))))
                (p:set_active_view p.active_view)))))
    (set core.last_active_view nil))

  (self.active_view:try_close do-close))

(fn Node.add_view [self view]
  (assert (= self.type :leaf) "Tried to add view to non-leaf node")
  (assert (not self.locked) "Tried to add view to locked node")
  (when (and (. self.views 1) (: (. self.views 1) :is Empty-view))
    (table.remove self.views))
  (table.insert self.views view)
  (self:set_active_view view))

(fn Node.set_active_view [self view]
  (assert (= self.type :leaf) "Tried to set active view on non-leaf node")
  (set self.active_view view)
  (core.set_active_view view))

(fn Node.get_view_idx [self view]
  (each [i v (ipairs self.views)]
    (when (= v view)
      (lua "return i"))))

(fn Node.get_node_for_view [self view]
  (each [_ v (ipairs self.views)]
    (when (= v view)
      (lua "return self")))
  (when (not= self.type :leaf)
    (or (self.a:get_node_for_view view) (self.b:get_node_for_view view))))

(fn Node.get_parent_node [self root]
  (if (or (= root.a self) (= root.b self)) root
      (not= root.type :leaf) (or (self:get_parent_node root.a)
                                 (self:get_parent_node root.b))))

(fn Node.get_children [self t]
  (set-forcibly! t (or t {}))
  (each [_ view (ipairs self.views)]
    (table.insert t view))
  (when self.a
    (self.a:get_children t))
  (when self.b
    (self.b:get_children t))
  t)

(fn Node.get_divider_overlapping_point [self px py]
  (when (not= self.type :leaf)
    (local p 6)
    (local (x y w h) (self:get_divider_rect))
    (set-forcibly! (x y) (values (- x p) (- y p)))
    (set-forcibly! (w h) (values (+ w (* p 2)) (+ h (* p 2))))
    (when (and (and (and (> px x) (> py y)) (< px (+ x w))) (< py (+ y h)))
      (lua "return self"))
    (or (self.a:get_divider_overlapping_point px py)
        (self.b:get_divider_overlapping_point px py))))

(fn Node.get_tab_overlapping_point [self px py]
  (when (= (length self.views) 1)
    (lua "return nil"))
  (local (x y w h) (self:get_tab_rect 1))
  (when (and (and (and (>= px x) (>= py y))
                  (< px (+ x (* w (length self.views)))))
             (< py (+ y h)))
    (+ (math.floor (/ (- px x) w)) 1)))

(fn Node.get_child_overlapping_point [self x y]
  (var child nil)
  (if (= self.type :leaf) (lua "return self") (= self.type :hsplit)
      (set child (or (and (< x self.b.position.x) self.a) self.b))
      (= self.type :vsplit)
      (set child (or (and (< y self.b.position.y) self.a) self.b)))
  (child:get_child_overlapping_point x y))

(fn Node.get_tab_rect [self idx]
  (let [tw (math.min style.tab_width
                     (math.ceil (/ self.size.x (length self.views))))
        h (+ (style.font:get_height) (* style.padding.y 2))]
    (values (+ self.position.x (* (- idx 1) tw)) self.position.y tw h)))

(fn Node.get_divider_rect [self]
  (let [(x y) (values self.position.x self.position.y)]
    (if (= self.type :hsplit)
        (values (+ x self.a.size.x) y style.divider_size self.size.y)
        (= self.type :vsplit)
        (values x (+ y self.a.size.y) self.size.x style.divider_size))))

(fn Node.get_locked_size [self]
  (if (= self.type :leaf) (when self.locked
                            (local size self.active_view.size)
                            (values size.x size.y))
      (let [(x1 y1) (self.a:get_locked_size)
            (x2 y2) (self.b:get_locked_size)]
        (when (and x1 x2)
          (local dsx (or (and (or (< x1 1) (< x2 1)) 0) style.divider_size))
          (local dsy (or (and (or (< y1 1) (< y2 1)) 0) style.divider_size))
          (values (+ (+ x1 x2) dsx) (+ (+ y1 y2) dsy))))))

(fn copy-position-and-size [dst src]
  (set-forcibly! (dst.position.x dst.position.y)
                 (values src.position.x src.position.y))
  (set-forcibly! (dst.size.x dst.size.y) (values src.size.x src.size.y)))

(fn calc-split-sizes [self x y x1 x2]
  (var n nil)
  (local ds (or (and (or (and x1 (< x1 1)) (and x2 (< x2 1))) 0)
                style.divider_size))
  (if x1 (set n (+ x1 ds)) x2 (set n (- (. self.size x) x2))
      (set n (math.floor (* (. self.size x) self.divider))))
  (tset self.a.position x (. self.position x))
  (tset self.a.position y (. self.position y))
  (tset self.a.size x (- n ds))
  (tset self.a.size y (. self.size y))
  (tset self.b.position x (+ (. self.position x) n))
  (tset self.b.position y (. self.position y))
  (tset self.b.size x (- (. self.size x) n))
  (tset self.b.size y (. self.size y)))

(fn Node.update_layout [self]
  (if (= self.type :leaf)
      (let [av self.active_view]
        (if (> (length self.views) 1)
            (let [(_ _ _ th) (self:get_tab_rect 1)]
              (set-forcibly! (av.position.x av.position.y)
                             (values self.position.x (+ self.position.y th)))
              (set-forcibly! (av.size.x av.size.y)
                             (values self.size.x (- self.size.y th))))
            (copy-position-and-size av self)))
      (let [(x1 y1) (self.a:get_locked_size)
            (x2 y2) (self.b:get_locked_size)]
        (if (= self.type :hsplit) (calc-split-sizes self :x :y x1 x2)
            (= self.type :vsplit) (calc-split-sizes self :y :x y1 y2))
        (self.a:update_layout)
        (self.b:update_layout))))

(fn Node.update [self]
  (if (= self.type :leaf) (each [_ view (ipairs self.views)]
                            (view:update))
      (do
        (self.a:update)
        (self.b:update))))

(fn Node.draw_tabs [self]
  (let [(x y _ h) (self:get_tab_rect 1)
        ds style.divider_size]
    (core.push_clip_rect x y self.size.x h)
    (renderer.draw_rect x y self.size.x h style.background2)
    (renderer.draw_rect x (- (+ y h) ds) self.size.x ds style.divider)
    (each [i view (ipairs self.views)]
      (local (x y w h) (self:get_tab_rect i))
      (local text (view:get_name))
      (var color style.dim)
      (when (= view self.active_view)
        (set color style.text)
        (renderer.draw_rect x y w h style.background)
        (renderer.draw_rect (+ x w) y ds h style.divider)
        (renderer.draw_rect (- x ds) y ds h style.divider))
      (when (= i self.hovered_tab)
        (set color style.text))
      (core.push_clip_rect x y w h)
      (set-forcibly! (x w)
                     (values (+ x style.padding.x) (- w (* style.padding.x 2))))
      (local align (or (and (> (style.font:get_width text) w) :left) :center))
      (common.draw_text style.font color text align x y w h)
      (core.pop_clip_rect))
    (core.pop_clip_rect)))

(fn Node.draw [self]
  (if (= self.type :leaf) (do
                            (when (> (length self.views) 1)
                              (self:draw_tabs))
                            (local (pos size)
                                   (values self.active_view.position
                                           self.active_view.size))
                            (core.push_clip_rect pos.x pos.y
                                                 (+ size.x (% pos.x 1))
                                                 (+ size.y (% pos.y 1)))
                            (self.active_view:draw)
                            (core.pop_clip_rect))
      (let [(x y w h) (self:get_divider_rect)]
        (renderer.draw_rect x y w h style.divider)
        (self:propagate :draw))))

(local Root-view (View:extend))

(fn Root-view.new [self]
  (Root-view.super.new self)
  (set self.root_node (Node))
  (set self.deferred_draws {})
  (set self.mouse {:y 0 :x 0}))

(fn Root-view.defer_draw [self ___fn-__ ...]
  (table.insert self.deferred_draws 1 {2 ... :fn ___fn-__}))

(fn Root-view.get_active_node [self]
  (self.root_node:get_node_for_view core.active_view))

(fn Root-view.open_doc [self ___doc-__]
  (var node (self:get_active_node))
  (when (and node.locked core.last_active_view)
    (core.set_active_view core.last_active_view)
    (set node (self:get_active_node)))
  (assert (not node.locked) "Cannot open doc on locked node")
  (each [i view (ipairs node.views)]
    (when (= view.doc ___doc-__)
      (node:set_active_view (. node.views i))
      (lua "return view")))
  (local view (Doc-view ___doc-__))
  (node:add_view view)
  (self.root_node:update_layout)
  (view:scroll_to_line (view.doc:get_selection) true true)
  view)

(fn Root-view.on_mouse_pressed [self button x y clicks]
  (let [div (self.root_node:get_divider_overlapping_point x y)]
    (when div
      (set self.dragged_divider div)
      (lua "return "))
    (local node (self.root_node:get_child_overlapping_point x y))
    (local idx (node:get_tab_overlapping_point x y))
    (if idx (do
              (node:set_active_view (. node.views idx))
              (when (= button :middle)
                (node:close_active_view self.root_node)))
        (do
          (core.set_active_view node.active_view)
          (node.active_view:on_mouse_pressed button x y clicks)))))

(fn Root-view.on_mouse_released [self ...]
  (when self.dragged_divider
    (set self.dragged_divider nil))
  (self.root_node:on_mouse_released ...))

(fn Root-view.on_mouse_moved [self x y dx dy]
  (when self.dragged_divider
    (local node self.dragged_divider)
    (if (= node.type :hsplit)
        (set node.divider (+ node.divider (/ dx node.size.x)))
        (set node.divider (+ node.divider (/ dy node.size.y))))
    (set node.divider (common.clamp node.divider 0.01 0.99))
    (lua "return "))
  (set-forcibly! (self.mouse.x self.mouse.y) (values x y))
  (self.root_node:on_mouse_moved x y dx dy)
  (local node (self.root_node:get_child_overlapping_point x y))
  (local div (self.root_node:get_divider_overlapping_point x y))
  (if div (system.set_cursor (or (and (= div.type :hsplit) :sizeh) :sizev))
      (node:get_tab_overlapping_point x y) (system.set_cursor :arrow)
      (system.set_cursor node.active_view.cursor)))

(fn Root-view.on_mouse_wheel [self ...]
  (let [(x y) (values self.mouse.x self.mouse.y)
        node (self.root_node:get_child_overlapping_point x y)]
    (node.active_view:on_mouse_wheel ...)))

(fn Root-view.on_text_input [self ...]
  (core.active_view:on_text_input ...))

(fn Root-view.update [self]
  (copy-position-and-size self.root_node self)
  (self.root_node:update)
  (self.root_node:update_layout))

(fn Root-view.draw [self]
  (self.root_node:draw)
  (while (> (length self.deferred_draws) 0)
    (local t (table.remove self.deferred_draws))
    (t.fn (table.unpack t))))

Root-view

