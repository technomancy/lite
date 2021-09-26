(local command (require :core.command))

(local keymap {})

(set keymap.modkeys {})

(set keymap.map {})

(set keymap.reverse_map {})

(local modkey-map {"right shift" :shift
                   "left ctrl" :ctrl
                   "left shift" :shift
                   "right ctrl" :ctrl
                   "left alt" :alt
                   "right alt" :altgr})

(local modkeys {1 :ctrl 2 :alt 3 :altgr 4 :shift})

(fn key-to-stroke [k]
  (var stroke "")
  (each [_ mk (ipairs modkeys)]
    (when (. keymap.modkeys mk)
      (set stroke (.. stroke mk "+"))))
  (.. stroke k))

(fn keymap.add [map overwrite]
  (each [stroke commands (pairs map)]
    (when (= (type commands) :string)
      (set-forcibly! commands {1 commands}))
    (if overwrite (tset keymap.map stroke commands)
        (do
          (tset keymap.map stroke (or (. keymap.map stroke) {}))
          (for [i (length commands) 1 (- 1)]
            (table.insert (. keymap.map stroke) 1 (. commands i)))))
    (each [_ cmd (ipairs commands)]
      (tset keymap.reverse_map cmd stroke))))

(fn keymap.get_binding [cmd]
  (. keymap.reverse_map cmd))

(fn keymap.on_key_pressed [k]
  (let [mk (. modkey-map k)]
    (if mk (do
             (tset keymap.modkeys mk true)
             (when (= mk :altgr)
               (tset keymap.modkeys :ctrl false)))
        (let [stroke (key-to-stroke k)
              commands (. keymap.map stroke)]
          (when commands
            (each [_ cmd (ipairs commands)]
              (local performed (command.perform cmd))
              (when performed
                (lua :break)))
            (lua "return true"))))
    false))

(fn keymap.on_key_released [k]
  (let [mk (. modkey-map k)]
    (when mk
      (tset keymap.modkeys mk false))))

(keymap.add {:shift+backspace "doc:backspace"
             :alt+shift+j "root:split-left"
             :ctrl+return "doc:newline-below"
             :ctrl+f "find-replace:find"
             :ctrl+pageup "root:move-tab-left"
             :ctrl+backspace "doc:delete-to-previous-word-start"
             :ctrl+shift+left "doc:select-to-previous-word-start"
             :escape {1 "command:escape" 2 "doc:select-none"}
             :ctrl+shift+return "doc:newline-above"
             :alt+shift+l "root:split-right"
             :pageup "doc:move-to-previous-page"
             :ctrl+r "find-replace:replace"
             :ctrl+j "doc:join-lines"
             :alt+shift+i "root:split-up"
             :ctrl+pagedown "root:move-tab-right"
             :ctrl+shift+right "doc:select-to-next-word-end"
             :pagedown "doc:move-to-next-page"
             :alt+shift+k "root:split-down"
             :ctrl+shift+backspace "doc:delete-to-previous-word-start"
             :f3 "find-replace:repeat-find"
             :alt+1 "root:switch-to-tab-1"
             :ctrl+up "doc:move-lines-up"
             :end "doc:move-to-end-of-line"
             :delete "doc:delete"
             :shift+left "doc:select-to-previous-char"
             :ctrl+d {1 "find-replace:select-next" 2 "doc:select-word"}
             :shift+f3 "find-replace:previous-find"
             :shift+delete "doc:delete"
             :return {1 "command:submit" 2 "doc:newline"}
             :left "doc:move-to-previous-char"
             :right "doc:move-to-next-char"
             "ctrl+shift+]" "doc:select-to-next-block-end"
             :alt+l "root:switch-to-right"
             :ctrl+o "core:open-file"
             :ctrl+end "doc:move-to-end-of-doc"
             "ctrl+shift+[" "doc:select-to-previous-block-start"
             :ctrl+shift+d "doc:duplicate-lines"
             :ctrl+g "doc:go-to-line"
             :alt+i "root:switch-to-up"
             "ctrl+]" "doc:move-to-next-block-end"
             :ctrl+shift+end "doc:select-to-end-of-doc"
             :tab {1 "command:complete" 2 "doc:indent"}
             :ctrl+left "doc:move-to-previous-word-start"
             :shift+home "doc:select-to-start-of-line"
             :alt+2 "root:switch-to-tab-2"
             :alt+k "root:switch-to-down"
             :shift+pageup "doc:select-to-previous-page"
             :ctrl+shift+p "core:find-command"
             :ctrl+/ "doc:toggle-line-comments"
             :shift+down "doc:select-to-next-line"
             :alt+3 "root:switch-to-tab-3"
             :shift+tab "doc:unindent"
             :ctrl+delete "doc:delete-to-next-word-end"
             :alt+9 "root:switch-to-tab-9"
             :ctrl+w "root:close"
             :ctrl+shift+k "doc:delete-lines"
             :home "doc:move-to-start-of-line"
             :alt+4 "root:switch-to-tab-4"
             :shift+pagedown "doc:select-to-next-page"
             :ctrl+home "doc:move-to-start-of-doc"
             "ctrl+[" "doc:move-to-previous-block-start"
             :ctrl+right "doc:move-to-next-word-end"
             :alt+return "core:toggle-fullscreen"
             :shift+end "doc:select-to-end-of-line"
             :alt+5 "root:switch-to-tab-5"
             :ctrl+p "core:find-file"
             :ctrl+tab "root:switch-to-next-tab"
             :down {1 "command:select-next" 2 "doc:move-to-next-line"}
             :up {1 "command:select-previous" 2 "doc:move-to-previous-line"}
             :shift+right "doc:select-to-next-char"
             :backspace "doc:backspace"
             :alt+6 "root:switch-to-tab-6"
             :ctrl+z "doc:undo"
             :ctrl+a "doc:select-all"
             :ctrl+shift+s "doc:save-as"
             :alt+8 "root:switch-to-tab-8"
             :ctrl+shift+delete "doc:delete-to-next-word-end"
             :ctrl+x "doc:cut"
             :alt+7 "root:switch-to-tab-7"
             :ctrl+shift+tab "root:switch-to-previous-tab"
             :ctrl+v "doc:paste"
             :ctrl+y "doc:redo"
             :ctrl+shift+home "doc:select-to-start-of-doc"
             :alt+j "root:switch-to-left"
             :shift+up "doc:select-to-previous-line"
             :ctrl+c "doc:copy"
             :ctrl+s "doc:save"
             :ctrl+n "core:new-doc"
             "keypad enter" {1 "command:submit" 2 "doc:newline"}
             :ctrl+l "doc:select-lines"
             :ctrl+down "doc:move-lines-down"})

keymap

