(local core (require :core))

(local config (require :core.config))

(local Doc (require :core.doc))

(local times (setmetatable {} {:__mode :k}))

(fn update-time [___doc-__]
  (let [info (system.get_file_info ___doc-__.filename)]
    (tset times ___doc-__ info.modified)))

(fn reload-doc [___doc-__]
  (let [fp (io.open ___doc-__.filename :r)
        text (fp:read :*a)]
    (fp:close)
    (local sel {1 (___doc-__:get_selection)})
    (___doc-__:remove 1 1 math.huge math.huge)
    (___doc-__:insert 1 1 (: (text:gsub "\r" "") :gsub "\n$" ""))
    (___doc-__:set_selection (table.unpack sel))
    (update-time ___doc-__)
    (___doc-__:clean)
    (core.log_quiet "Auto-reloaded doc \"%s\"" ___doc-__.filename)))

(core.add_thread (fn []
                   (while true
                     (each [_ ___doc-__ (ipairs core.docs)]
                       (local info
                              (system.get_file_info (or ___doc-__.filename "")))
                       (when (and info (not= (. times ___doc-__) info.modified))
                         (reload-doc ___doc-__))
                       (coroutine.yield))
                     (coroutine.yield config.project_scan_rate))))

(local load Doc.load)

(local save Doc.save)

(set Doc.load (fn [self ...]
                (let [res (load self ...)]
                  (update-time self)
                  res)))

(set Doc.save (fn [self ...]
                (let [res (save self ...)]
                  (update-time self)
                  res)))

