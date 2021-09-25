(local command (require :core.command))
(local keymap (require :core.keymap))

(local fennel (require :plugins.fennel))
(table.insert (or package.loaders package.searchers) fennel.searcher)
(local rep (require :data.user.rep))

;; mostly emacs bindings
(keymap.add {:ctrl+pageup :root:switch-to-previous-tab
             :ctrl+pagedown :root:switch-to-next-tab

             :alt+x :core:find-command

             :ctrl+p [:command-select-previous :doc:move-to-previous-line]
             :ctrl+n [:command-select-next :doc:move-to-next-line]
             :ctrl+f :doc:move-to-next-char
             :ctrl+b :doc:move-to-previous-char
             :alt+f :doc:move-to-next-word-end
             :alt+b :doc:move-to-previous-word-start
             "alt+shift+," :doc:move-to-start-of-doc
             "alt+shift+." :doc:move-to-end-of-doc

             "ctrl+;" :user:rep
             :ctrl+/ :doc:undo
             :alt+w :doc:copy
             :ctrl+y :doc:paste
             "alt+;" :doc:toggle-line-comments
             })

(command.add nil {:user:reinit #(fennel.dofile "data/user/init.fnl")
                  :user:rep #(rep.rep)})

(require :user.colors.summer)
