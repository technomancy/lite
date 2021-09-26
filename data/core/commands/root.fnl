(local core (require :core))

(local style (require :core.style))

(local Doc-view (require :core.docview))

(local command (require :core.command))

(local common (require :core.common))

(local t {"root:switch-to-next-tab" (fn []
                                      (local node
                                             (core.root_view:get_active_node))
                                      (var idx
                                           (node:get_view_idx core.active_view))
                                      (set idx (+ idx 1))
                                      (when (> idx (length node.views))
                                        (set idx 1))
                                      (node:set_active_view (. node.views idx)))
          "root:switch-to-previous-tab" (fn []
                                          (local node
                                                 (core.root_view:get_active_node))
                                          (var idx
                                               (node:get_view_idx core.active_view))
                                          (set idx (- idx 1))
                                          (when (< idx 1)
                                            (set idx (length node.views)))
                                          (node:set_active_view (. node.views
                                                                   idx)))
          "root:close" (fn []
                         (local node (core.root_view:get_active_node))
                         (node:close_active_view core.root_view.root_node))
          "root:grow" (fn []
                        (local node (core.root_view:get_active_node))
                        (local parent
                               (node:get_parent_node core.root_view.root_node))
                        (local n (or (and (= parent.a node) 0.1) (- 0.1)))
                        (set parent.divider
                             (common.clamp (+ parent.divider n) 0.1 0.9)))
          "root:shrink" (fn []
                          (local node (core.root_view:get_active_node))
                          (local parent
                                 (node:get_parent_node core.root_view.root_node))
                          (local n (or (and (= parent.a node) (- 0.1)) 0.1))
                          (set parent.divider
                               (common.clamp (+ parent.divider n) 0.1 0.9)))
          "root:move-tab-right" (fn []
                                  (local node (core.root_view:get_active_node))
                                  (local idx
                                         (node:get_view_idx core.active_view))
                                  (when (< idx (length node.views))
                                    (table.remove node.views idx)
                                    (table.insert node.views (+ idx 1)
                                                  core.active_view)))
          "root:move-tab-left" (fn []
                                 (local node (core.root_view:get_active_node))
                                 (local idx
                                        (node:get_view_idx core.active_view))
                                 (when (> idx 1)
                                   (table.remove node.views idx)
                                   (table.insert node.views (- idx 1)
                                                 core.active_view)))})

(for [i 1 9 1]
  (tset t (.. "root:switch-to-tab-" i)
        (fn []
          (let [node (core.root_view:get_active_node)
                view (. node.views i)]
            (when view
              (node:set_active_view view))))))

(each [_ dir (ipairs {1 :left 2 :right 3 :up 4 :down})]
  (tset t (.. "root:split-" dir)
        (fn []
          (let [node (core.root_view:get_active_node)
                av node.active_view]
            (node:split dir)
            (when (av:is Doc-view)
              (core.root_view:open_doc av.doc)))))
  (tset t (.. "root:switch-to-" dir)
        (fn []
          (let [node (core.root_view:get_active_node)]
            (var (x y) nil)
            (if (or (= dir :left) (= dir :right))
                (do
                  (set y (+ node.position.y (/ node.size.y 2)))
                  (set x
                       (+ node.position.x
                          (or (and (= dir :left) (- 1))
                              (+ node.size.x style.divider_size)))))
                (do
                  (set x (+ node.position.x (/ node.size.x 2)))
                  (set y
                       (+ node.position.y
                          (or (and (= dir :up) (- 1))
                              (+ node.size.y style.divider_size))))))
            (local node
                   (core.root_view.root_node:get_child_overlapping_point x y))
            (when (not (node:get_locked_size))
              (core.set_active_view node.active_view))))))

(command.add (fn []
               (let [node (core.root_view:get_active_node)]
                 (not (node:get_locked_size)))) t)

