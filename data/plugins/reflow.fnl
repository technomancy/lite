(local core (require :core))

(local config (require :core.config))

(local command (require :core.command))

(local keymap (require :core.keymap))

(fn wordwrap-text [text limit]
  (let [t {}]
    (var n 0)
    (each [word (text:gmatch "%S+")]
      (if (> (+ n (length word)) limit) (do
                                          (table.insert t "\n")
                                          (set n 0))
          (> (length t) 0) (table.insert t " "))
      (table.insert t word)
      (set n (+ (+ n (length word)) 1)))
    (table.concat t)))

(command.add :core.docview
             {"reflow:reflow" (fn []
                                (local ___doc-__ core.active_view.doc)
                                (___doc-__:replace (fn [text]
                                                     (local prefix-set
                                                            "[^%w\n%[%](){}`'\"]*")
                                                     (local prefix1
                                                            (text:match (.. "^\n*"
                                                                            prefix-set)))
                                                     (var prefix2
                                                          (text:match (.. "\n("
                                                                          prefix-set
                                                                          ")")
                                                                      (+ (length prefix1)
                                                                         1)))
                                                     (local trailing
                                                            (text:match "%s*$"))
                                                     (when (or (not prefix2)
                                                               (= prefix2 ""))
                                                       (set prefix2 prefix1))
                                                     (set-forcibly! text
                                                                    (: (text:sub (+ (length prefix1)
                                                                                    1)
                                                                                 (- (- (length trailing))
                                                                                    1))
                                                                       :gsub
                                                                       (.. "\n"
                                                                           prefix-set)
                                                                       "\n"))
                                                     (local line-limit
                                                            (- config.line_limit
                                                               (length prefix1)))
                                                     (local blocks {})
                                                     (set-forcibly! text
                                                                    (text:gsub "

"
                                                                               "\000"))
                                                     (each [block (text:gmatch "%Z+")]
                                                       (table.insert blocks
                                                                     (wordwrap-text block
                                                                                    line-limit)))
                                                     (set-forcibly! text (table.concat blocks
                                                                                       "

"))
                                                     (set-forcibly! text
                                                                    (.. prefix1
                                                                        (text:gsub "
"
                                                                                   (.. "
"
                                                                                       prefix2))
                                                                        trailing))
                                                     text)))})

(keymap.add {:ctrl+shift+q "reflow:reflow"})

