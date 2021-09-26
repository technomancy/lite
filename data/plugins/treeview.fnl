(local core (require :core))

(local common (require :core.common))

(local command (require :core.command))

(local config (require :core.config))

(local keymap (require :core.keymap))

(local style (require :core.style))

(local View (require :core.view))

(set config.treeview_size (* 200 SCALE))

(fn get-depth [filename]
  (var n 0)
  (each [sep (filename:gmatch "[\\/]")]
    (set n (+ n 1)))
  n)

(local Tree-view (View:extend))

(fn Tree-view.new [self]
  (Tree-view.super.new self)
  (set self.scrollable true)
  (set self.visible true)
  (set self.init_size true)
  (set self.cache {}))

(fn Tree-view.get_cached [self item]
  (var t (. self.cache item.filename))
  (when (not t)
    (set t {})
    (set t.filename item.filename)
    (set t.abs_filename (system.absolute_path item.filename))
    (set t.name (t.filename:match "[^\\/]+$"))
    (set t.depth (get-depth t.filename))
    (set t.type item.type)
    (tset self.cache t.filename t))
  t)

(fn Tree-view.get_name [self]
  :Project)

(fn Tree-view.get_item_height [self]
  (+ (style.font:get_height) style.padding.y))

(fn Tree-view.check_cache [self]
  (when (not= core.project_files self.last_project_files)
    (each [_ v (pairs self.cache)]
      (set v.skip nil))
    (set self.last_project_files core.project_files)))

(fn Tree-view.each_item [self]
  (coroutine.wrap (fn []
                    (do
                      (self:check_cache)
                      (local (ox oy) (self:get_content_offset))
                      (var y (+ oy style.padding.y))
                      (local w self.size.x)
                      (local h (self:get_item_height))
                      (var i 1)
                      (while (<= i (length core.project_files))
                        (local item (. core.project_files i))
                        (local cached (self:get_cached item))
                        (coroutine.yield cached ox y w h)
                        (set y (+ y h))
                        (set i (+ i 1))
                        (when (not cached.expanded)
                          (if cached.skip (set i cached.skip)
                              (let [depth cached.depth]
                                (while (<= i (length core.project_files))
                                  (local filename
                                         (. (. core.project_files i) :filename))
                                  (when (<= (get-depth filename) depth)
                                    (lua :break))
                                  (set i (+ i 1)))
                                (set cached.skip i)))))))))

(fn Tree-view.on_mouse_moved [self px py]
  (set self.hovered_item nil)
  (each [item x y w h (self:each_item)]
    (when (and (and (and (> px x) (> py y)) (<= px (+ x w))) (<= py (+ y h)))
      (set self.hovered_item item)
      (lua :break))))

(fn Tree-view.on_mouse_pressed [self button x y]
  (if (not self.hovered_item) nil (= self.hovered_item.type :dir)
      (set self.hovered_item.expanded (not self.hovered_item.expanded))
      (core.try (fn []
                  (core.root_view:open_doc (core.open_doc self.hovered_item.filename))))))

(fn Tree-view.update [self]
  (let [dest (or (and self.visible config.treeview_size) 0)]
    (if self.init_size (do
                         (set self.size.x dest)
                         (set self.init_size false))
        (self:move_towards self.size :x dest))
    (Tree-view.super.update self)))

(fn Tree-view.draw [self]
  (self:draw_background style.background2)
  (local icon-width (style.icon_font:get_width :D))
  (local spacing (* (style.font:get_width " ") 2))
  (local ___doc-__ core.active_view.doc)
  (local active-filename
         (and ___doc-__ (system.absolute_path (or ___doc-__.filename ""))))
  (each [item x y w h (self:each_item)]
    (var color style.text)
    (when (= item.abs_filename active-filename)
      (set color style.accent))
    (when (= item self.hovered_item)
      (renderer.draw_rect x y w h style.line_highlight)
      (set color style.accent))
    (set-forcibly! x (+ (+ x (* item.depth style.padding.x)) style.padding.x))
    (if (= item.type :dir)
        (let [icon1 (or (and item.expanded "-") "+")
              icon2 (or (and item.expanded :D) :d)]
          (common.draw_text style.icon_font color icon1 nil x y 0 h)
          (set-forcibly! x (+ x style.padding.x))
          (common.draw_text style.icon_font color icon2 nil x y 0 h)
          (set-forcibly! x (+ x icon-width)))
        (do
          (set-forcibly! x (+ x style.padding.x))
          (common.draw_text style.icon_font color :f nil x y 0 h)
          (set-forcibly! x (+ x icon-width))))
    (set-forcibly! x (+ x spacing))
    (set-forcibly! x (common.draw_text style.font color item.name nil x y 0 h))))

(local view (Tree-view))

(local node (core.root_view:get_active_node))

(node:split :left view true)

(command.add nil
             {"treeview:toggle" (fn []
                                  (set view.visible (not view.visible)))})

(keymap.add {"ctrl+\\" "treeview:toggle"})

