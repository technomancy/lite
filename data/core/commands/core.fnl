(local core (require :core))

(local common (require :core.common))

(local command (require :core.command))

(local keymap (require :core.keymap))

(local Log-view (require :core.logview))

(var fullscreen false)

(command.add nil
             {"core:reload-module" (fn []
                                     (core.command_view:enter "Reload Module"
                                                              (fn [text item]
                                                                (local text
                                                                       (or (and item
                                                                                item.text)
                                                                           text))
                                                                (core.reload_module text)
                                                                (core.log "Reloaded module %q"
                                                                          text))
                                                              (fn [text]
                                                                (local items {})
                                                                (each [name (pairs package.loaded)]
                                                                  (table.insert items
                                                                                name))
                                                                (common.fuzzy_match items
                                                                                    text))))
              "core:open-user-module" (fn []
                                        (core.root_view:open_doc (core.open_doc (.. EXEDIR
                                                                                    :/data/user/init.lua))))
              "core:open-log" (fn []
                                (local node (core.root_view:get_active_node))
                                (node:add_view (Log-view)))
              "core:find-file" (fn []
                                 (core.command_view:enter "Open File From Project"
                                                          (fn [text item]
                                                            (set-forcibly! text
                                                                           (or (and item
                                                                                    item.text)
                                                                               text))
                                                            (core.root_view:open_doc (core.open_doc text)))
                                                          (fn [text]
                                                            (local files {})
                                                            (each [_ item (pairs core.project_files)]
                                                              (when (= item.type
                                                                       :file)
                                                                (table.insert files
                                                                              item.filename)))
                                                            (common.fuzzy_match files
                                                                                text))))
              "core:force-quit" (fn []
                                  (core.quit true))
              "core:open-file" (fn []
                                 (core.command_view:enter "Open File"
                                                          (fn [text]
                                                            (core.root_view:open_doc (core.open_doc text)))
                                                          common.path_suggest))
              "core:open-project-module" (fn []
                                           (local filename :.lite_project.lua)
                                           (if (system.get_file_info filename)
                                               (core.root_view:open_doc (core.open_doc filename))
                                               (do
                                                 (local ___doc-__
                                                        (core.open_doc))
                                                 (core.root_view:open_doc ___doc-__)
                                                 (___doc-__:save filename))))
              "core:find-command" (fn []
                                    (local commands (command.get_all_valid))
                                    (core.command_view:enter "Do Command"
                                                             (fn [text item]
                                                               (when item
                                                                 (command.perform item.command)))
                                                             (fn [text]
                                                               (local res
                                                                      (common.fuzzy_match commands
                                                                                          text))
                                                               (each [i name (ipairs res)]
                                                                 (tset res i
                                                                       {:info (keymap.get_binding name)
                                                                        :text (command.prettify_name name)
                                                                        :command name}))
                                                               res)))
              "core:toggle-fullscreen" (fn []
                                         (set fullscreen (not fullscreen))
                                         (system.set_window_mode (or (and fullscreen
                                                                          :fullscreen)
                                                                     :normal)))
              "core:quit" (fn []
                            (core.quit))
              "core:new-doc" (fn []
                               (core.root_view:open_doc (core.open_doc)))})

