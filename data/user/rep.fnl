(local core (require :core))
(local fennel (require :plugins.fennel))

(local repl (doto (coroutine.create fennel.repl)
              (coroutine.resume {:readChunk coroutine.yield
                                 :onValues #(core.log (table.concat $...))

                                 :pp fennel.view
                                 :onError #(core.error (table.concat $...))
                                 :moduleName :pluigns.fennel})))
(fn rep []
  (core.command_view:enter :eval #(assert (coroutine.resume repl (.. $ "\n")))))

{: rep}
