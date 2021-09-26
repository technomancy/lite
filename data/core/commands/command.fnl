(local core (require :core))

(local command (require :core.command))

(local Command-view (require :core.commandview))

(fn has-commandview []
  (core.active_view:is Command-view))

(command.add has-commandview
             {"command:select-next" (fn []
                                      (core.active_view:move_suggestion_idx (- 1)))
              "command:escape" (fn []
                                 (core.active_view:exit))
              "command:submit" (fn []
                                 (core.active_view:submit))
              "command:select-previous" (fn []
                                          (core.active_view:move_suggestion_idx 1))
              "command:complete" (fn []
                                   (core.active_view:complete))})

