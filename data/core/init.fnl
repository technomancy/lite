(require :core.strict)

(local common (require :core.common))

(local config (require :core.config))

(local style (require :core.style))

(var command nil)

(var keymap nil)

(var Root-view nil)

(var Status-view nil)

(var Command-view nil)

(var Doc nil)

(local core {})

(fn project-scan-thread []
  (fn diff-files [a b]
    (when (not= (length a) (length b))
      (lua "return true"))
    (each [i v (ipairs a)]
      (when (or (not= (. (. b i) :filename) v.filename)
                (not= (. (. b i) :modified) v.modified))
        (lua "return true"))))

  (fn compare-file [a b]
    (< a.filename b.filename))

  (fn get-files [path t]
    (coroutine.yield)
    (set-forcibly! t (or t {}))
    (local size-limit (* config.file_size_limit 1000000))
    (local all (or (system.list_dir path) {}))
    (local (dirs files) (values {} {}))
    (each [_ file (ipairs all)]
      (when (not (common.match_pattern file config.ignore_files))
        (local file (.. (or (and (not= path ".") (.. path PATHSEP)) "") file))
        (local info (system.get_file_info file))
        (when (and info (< info.size size-limit))
          (set info.filename file)
          (table.insert (or (and (= info.type :dir) dirs) files) info))))
    (table.sort dirs compare-file)
    (each [_ f (ipairs dirs)]
      (table.insert t f)
      (get-files f.filename t))
    (table.sort files compare-file)
    (each [_ f (ipairs files)]
      (table.insert t f))
    t)

  (while true
    (local t (get-files "."))
    (when (diff-files core.project_files t)
      (set core.project_files t)
      (set core.redraw true))
    (coroutine.yield config.project_scan_rate)))

(fn core.init []
  (set command (require :core.command))
  (set keymap (require :core.keymap))
  (set Root-view (require :core.rootview))
  (set Status-view (require :core.statusview))
  (set Command-view (require :core.commandview))
  (set Doc (require :core.doc))
  (var project-dir EXEDIR)
  (local files {})
  (for [i 2 (length ARGS) 1]
    (local info (or (system.get_file_info (. ARGS i)) {}))
    (if (= info.type :file)
        (table.insert files (system.absolute_path (. ARGS i)))
        (= info.type :dir) (set project-dir (. ARGS i))))
  (system.chdir project-dir)
  (set core.frame_start 0)
  (set core.clip_rect_stack {1 {1 0 2 0 3 0 4 0}})
  (set core.log_items {})
  (set core.docs {})
  (set core.threads (setmetatable {} {:__mode :k}))
  (set core.project_files {})
  (set core.redraw true)
  (set core.root_view (Root-view))
  (set core.command_view (Command-view))
  (set core.status_view (Status-view))
  (core.root_view.root_node:split :down core.command_view true)
  (core.root_view.root_node.b:split :down core.status_view true)
  (core.add_thread project-scan-thread)
  (command.add_defaults)
  (local got-plugin-error (not (core.load_plugins)))
  (local got-user-error (not (core.try require :user)))
  (local got-project-error (not (core.load_project_module)))
  (each [_ filename (ipairs files)]
    (core.root_view:open_doc (core.open_doc filename)))
  (when (or (or got-plugin-error got-user-error) got-project-error)
    (command.perform "core:open-log")))

(local temp-uid (% (* (system.get_time) 1000) 4294967295))

(local temp-file-prefix (string.format ".lite_temp_%08x" temp-uid))

(var temp-file-counter 0)

(fn delete-temp-files []
  (each [_ filename (ipairs (system.list_dir EXEDIR))]
    (when (= (filename:find temp-file-prefix 1 true) 1)
      (os.remove (.. EXEDIR PATHSEP filename)))))

(fn core.temp_filename [ext]
  (set temp-file-counter (+ temp-file-counter 1))
  (.. EXEDIR PATHSEP temp-file-prefix (string.format "%06x" temp-file-counter)
      (or ext "")))

(fn core.quit [force]
  (when force
    (delete-temp-files)
    (os.exit))
  (var dirty-count 0)
  (var dirty-name nil)
  (each [_ ___doc-__ (ipairs core.docs)]
    (when (___doc-__:is_dirty)
      (set dirty-count (+ dirty-count 1))
      (set dirty-name (___doc-__:get_name))))
  (when (> dirty-count 0)
    (var text nil)
    (if (= dirty-count 1)
        (set text (string.format "\"%s\" has unsaved changes. Quit anyway?"
                                 dirty-name))
        (set text (string.format "%d docs have unsaved changes. Quit anyway?"
                                 dirty-count)))
    (local confirm (system.show_confirm_dialog "Unsaved Changes" text))
    (when (not confirm)
      (lua "return ")))
  (core.quit true))

(fn core.load_plugins []
  (var no-errors true)
  (local files (system.list_dir (.. EXEDIR :/data/plugins)))
  (each [_ filename (ipairs files)]
    (local modname (.. :plugins. (filename:gsub :.lua$ "")))
    (local ok (core.try require modname))
    (if ok (core.log_quiet "Loaded plugin %q" modname) (set no-errors false)))
  no-errors)

(fn core.load_project_module []
  (let [filename :.lite_project.lua]
    (when (system.get_file_info filename)
      (let [___antifnl_rtn_1___ (core.try (fn []
                                            (let [(___fn-__ err) (loadfile filename)]
                                              (when (not ___fn-__)
                                                (error (.. "Error when loading project module:
\t" err)))
                                              (___fn-__)
                                              (core.log_quiet "Loaded project module"))))]
        (lua "return ___antifnl_rtn_1___")))
    true))

(fn core.reload_module [name]
  (let [old (. package.loaded name)]
    (tset package.loaded name nil)
    (local new (require name))
    (when (= (type old) :table)
      (each [k v (pairs new)]
        (tset old k v))
      (tset package.loaded name old))))

(fn core.set_active_view [view]
  (assert view "Tried to set active view to nil")
  (when (not= view core.active_view)
    (set core.last_active_view core.active_view)
    (set core.active_view view)))

(fn core.add_thread [f weak-ref]
  (let [key (or weak-ref (+ (length core.threads) 1))]
    (fn ___fn-__ []
      (core.try f))

    (tset core.threads key {:wake 0 :cr (coroutine.create ___fn-__)})))

(fn core.push_clip_rect [x y w h]
  (let [(x2 y2 w2 h2) (table.unpack (. core.clip_rect_stack
                                       (length core.clip_rect_stack)))
        (r b r2 b2) (values (+ x w) (+ y h) (+ x2 w2) (+ y2 h2))]
    (set-forcibly! (x y) (values (math.max x x2) (math.max y y2)))
    (set-forcibly! (b r) (values (math.min b b2) (math.min r r2)))
    (set-forcibly! (w h) (values (- r x) (- b y)))
    (table.insert core.clip_rect_stack {1 x 2 y 3 w 4 h})
    (renderer.set_clip_rect x y w h)))

(fn core.pop_clip_rect []
  (table.remove core.clip_rect_stack)
  (local (x y w h)
         (table.unpack (. core.clip_rect_stack (length core.clip_rect_stack))))
  (renderer.set_clip_rect x y w h))

(fn core.open_doc [filename]
  (when filename
    (local abs-filename (system.absolute_path filename))
    (each [_ ___doc-__ (ipairs core.docs)]
      (when (and ___doc-__.filename
                 (= abs-filename (system.absolute_path ___doc-__.filename)))
        (lua "return ___doc-__"))))
  (local ___doc-__ (Doc filename))
  (table.insert core.docs ___doc-__)
  (core.log_quiet (or (and filename "Opened doc \"%s\"") "Opened new doc")
                  filename)
  ___doc-__)

(fn core.get_views_referencing_doc [___doc-__]
  (let [res {}
        views (core.root_view.root_node:get_children)]
    (each [_ view (ipairs views)]
      (when (= view.doc ___doc-__)
        (table.insert res view)))
    res))

(fn log [icon icon-color fmt ...]
  (let [text (string.format fmt ...)]
    (when icon
      (core.status_view:show_message icon icon-color text))
    (local info (debug.getinfo 2 :Sl))
    (local at (string.format "%s:%d" info.short_src info.currentline))
    (local item {:time (os.time) : text : at})
    (table.insert core.log_items item)
    (when (> (length core.log_items) config.max_log_items)
      (table.remove core.log_items 1))
    item))

(fn core.log [...]
  (log :i style.text ...))

(fn core.log_quiet [...]
  (log nil nil ...))

(fn core.error [...]
  (log "!" style.accent ...))

(fn core.try [___fn-__ ...]
  (var err nil)
  (local (ok res) (xpcall ___fn-__
                          (fn [msg]
                            (let [item (core.error "%s" msg)]
                              (set item.info
                                   (: (debug.traceback nil 2) :gsub "\t" ""))
                              (set err msg))) ...))
  (when ok
    (lua "return true, res"))
  (values false err))

(fn core.on_event [type ...]
  (var did-keymap false)
  (if (= type :textinput) (core.root_view:on_text_input ...)
      (= type :keypressed) (set did-keymap (keymap.on_key_pressed ...))
      (= type :keyreleased) (keymap.on_key_released ...) (= type :mousemoved)
      (core.root_view:on_mouse_moved ...) (= type :mousepressed)
      (core.root_view:on_mouse_pressed ...) (= type :mousereleased)
      (core.root_view:on_mouse_released ...) (= type :mousewheel)
      (core.root_view:on_mouse_wheel ...) (= type :filedropped)
      (let [(filename mx my) ...
            info (system.get_file_info filename)]
        (if (and info (= info.type :dir))
            (system.exec (string.format "%q %q" EXEFILE filename))
            (let [(ok ___doc-__) (core.try core.open_doc filename)]
              (when ok
                (local node
                       (core.root_view.root_node:get_child_overlapping_point mx
                                                                             my))
                (node:set_active_view node.active_view)
                (core.root_view:open_doc ___doc-__))))) (= type :quit)
      (core.quit))
  did-keymap)

(fn core.step []
  (var did-keymap false)
  (var mouse-moved false)
  (local mouse {:dy 0 :y 0 :x 0 :dx 0})
  (each [type* a b c d system.poll_event]
    (if (= type* :mousemoved)
        (do
          (set mouse-moved true)
          (set-forcibly! (mouse.x mouse.y) (values a b))
          (set-forcibly! (mouse.dx mouse.dy)
                         (values (+ mouse.dx c) (+ mouse.dy d))))
        (and (= type* :textinput) did-keymap) (set did-keymap false)
        (let [(_ res) (core.try core.on_event type* a b c d)]
          (set did-keymap (or res did-keymap))))
    (set core.redraw true))
  (when mouse-moved
    (core.try core.on_event :mousemoved mouse.x mouse.y mouse.dx mouse.dy))
  (local (width height) (renderer.get_size))
  (set-forcibly! (core.root_view.size.x core.root_view.size.y)
                 (values width height))
  (core.root_view:update)
  (when (not core.redraw)
    (lua "return false"))
  (set core.redraw false)
  (for [i (length core.docs) 1 (- 1)]
    (local ___doc-__ (. core.docs i))
    (when (= (length (core.get_views_referencing_doc ___doc-__)) 0)
      (table.remove core.docs i)
      (core.log_quiet "Closed doc \"%s\"" (___doc-__:get_name))))
  (local name (core.active_view:get_name))
  (local title (or (and (not= name "---") (.. name " - lite")) :lite))
  (when (not= title core.window_title)
    (system.set_window_title title)
    (set core.window_title title))
  (renderer.begin_frame)
  (tset core.clip_rect_stack 1 {1 0 2 0 3 width 4 height})
  (renderer.set_clip_rect (table.unpack (. core.clip_rect_stack 1)))
  (core.root_view:draw)
  (renderer.end_frame)
  true)

(local run-threads
       (coroutine.wrap (fn []
                         (while true
                           (local max-time (- (/ 1 config.fps) 0.004))
                           (var ran-any-threads false)
                           (each [k thread (pairs core.threads)]
                             (when (< thread.wake (system.get_time))
                               (local (_ wait)
                                      (assert (coroutine.resume thread.cr)))
                               (if (= (coroutine.status thread.cr) :dead)
                                   (if (= (type k) :number)
                                       (table.remove core.threads k)
                                       (tset core.threads k nil))
                                   wait
                                   (set thread.wake (+ (system.get_time) wait)))
                               (set ran-any-threads true))
                             (when (> (- (system.get_time) core.frame_start)
                                      max-time)
                               (coroutine.yield)))
                           (when (not ran-any-threads)
                             (coroutine.yield))))))

(fn core.run []
  (while true
    (set core.frame_start (system.get_time))
    (local did-redraw (core.step))
    (run-threads)
    (when (and (not did-redraw) (not (system.window_has_focus)))
      (system.wait_event 0.25))
    (local elapsed (- (system.get_time) core.frame_start))
    (system.sleep (math.max 0 (- (/ 1 config.fps) elapsed)))))

(fn core.on_error [err]
  (let [fp (io.open (.. EXEDIR :/error.txt) :wb)]
    (fp:write (.. "Error: " (tostring err) "\n"))
    (fp:write (debug.traceback nil 4))
    (fp:close)
    (each [_ ___doc-__ (ipairs core.docs)]
      (when (and (___doc-__:is_dirty) ___doc-__.filename)
        (___doc-__:save (.. ___doc-__.filename "~"))))))

core

