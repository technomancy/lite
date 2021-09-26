(local core (require :core))

(local command (require :core.command))

(local keymap (require :core.keymap))

(local handled-events {:textinput true :keyreleased true :keypressed true})

(var state :stopped)

(var event-buffer {})

(var modkeys {})

(local on-event core.on_event)

(set core.on_event (fn [type ...]
                     (let [res (on-event type ...)]
                       (when (and (= state :recording) (. handled-events type))
                         (table.insert event-buffer {1 type 2 ...}))
                       res)))

(fn clone [t]
  (let [res {}]
    (each [k v (pairs t)]
      (tset res k v))
    res))

(fn predicate []
  (not= state :playing))

(command.add predicate
             {"macro:toggle-record" (fn []
                                      (if (= state :stopped)
                                          (do
                                            (set state :recording)
                                            (set event-buffer {})
                                            (set modkeys (clone keymap.modkeys))
                                            (core.log "Recording macro..."))
                                          (do
                                            (set state :stopped)
                                            (core.log "Stopped recording macro (%d events)"
                                                      (length event-buffer)))))
              "macro:play" (fn []
                             (set state :playing)
                             (core.log "Playing macro... (%d events)"
                                       (length event-buffer))
                             (local mk keymap.modkeys)
                             (set keymap.modkeys (clone modkeys))
                             (each [_ ev (ipairs event-buffer)]
                               (on-event (table.unpack ev))
                               (core.root_view:update))
                             (set keymap.modkeys mk)
                             (set state :stopped))})

(keymap.add {"ctrl+shift+;" "macro:toggle-record" "ctrl+;" "macro:play"})

