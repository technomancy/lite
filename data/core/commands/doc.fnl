(local core (require :core))

(local command (require :core.command))

(local common (require :core.common))

(local config (require :core.config))

(local translate (require :core.doc.translate))

(local Doc-view (require :core.docview))

(fn dv []
  core.active_view)

(fn ___doc-__ []
  core.active_view.doc)

(fn get-indent-string []
  (when (= config.tab_type :hard)
    (lua "return \"\\t\""))
  (string.rep " " config.indent_size))

(fn insert-at-start-of-selected-lines [text skip-empty]
  (let [(line1 col1 line2 col2 swap) (: (___doc-__) :get_selection true)]
    (for [line line1 line2 1]
      (local line-text (. (. (___doc-__) :lines) line))
      (when (or (not skip-empty) (line-text:find "%S"))
        (: (___doc-__) :insert line 1 text)))
    (: (___doc-__) :set_selection line1 (+ col1 (length text)) line2
       (+ col2 (length text)) swap)))

(fn remove-from-start-of-selected-lines [text skip-empty]
  (let [(line1 col1 line2 col2 swap) (: (___doc-__) :get_selection true)]
    (for [line line1 line2 1]
      (local line-text (. (. (___doc-__) :lines) line))
      (when (and (= (line-text:sub 1 (length text)) text)
                 (or (not skip-empty) (line-text:find "%S")))
        (: (___doc-__) :remove line 1 line (+ (length text) 1))))
    (: (___doc-__) :set_selection line1 (- col1 (length text)) line2
       (- col2 (length text)) swap)))

(fn append-line-if-last-line [line]
  (when (>= line (length (. (___doc-__) :lines)))
    (: (___doc-__) :insert line math.huge "\n")))

(fn save [filename]
  (: (___doc-__) :save filename)
  (core.log "Saved \"%s\"" (. (___doc-__) :filename)))

(local commands {"doc:select-word" (fn []
                                     (local (line1 col1)
                                            (: (___doc-__) :get_selection true))
                                     (local (line1 col1)
                                            (translate.start_of_word (___doc-__)
                                                                     line1 col1))
                                     (local (line2 col2)
                                            (translate.end_of_word (___doc-__)
                                                                   line1 col1))
                                     (: (___doc-__) :set_selection line2 col2
                                        line1 col1))
                 "doc:redo" (fn []
                              (: (___doc-__) :redo))
                 "doc:move-lines-up" (fn []
                                       (local (line1 col1 line2 col2 swap)
                                              (: (___doc-__) :get_selection
                                                 true))
                                       (append-line-if-last-line line2)
                                       (when (> line1 1)
                                         (local text
                                                (. (. (___doc-__) :lines)
                                                   (- line1 1)))
                                         (: (___doc-__) :insert (+ line2 1) 1
                                            text)
                                         (: (___doc-__) :remove (- line1 1) 1
                                            line1 1)
                                         (: (___doc-__) :set_selection
                                            (- line1 1) col1 (- line2 1) col2
                                            swap)))
                 "doc:toggle-line-ending" (fn []
                                            (tset (___doc-__) :crlf
                                                  (not (. (___doc-__) :crlf))))
                 "doc:newline-below" (fn []
                                       (local line
                                              (: (___doc-__) :get_selection))
                                       (local indent
                                              (: (. (. (___doc-__) :lines) line)
                                                 :match "^[\t ]*"))
                                       (: (___doc-__) :insert line math.huge
                                          (.. "\n" indent))
                                       (: (___doc-__) :set_selection (+ line 1)
                                          math.huge))
                 "doc:rename" (fn []
                                (local old-filename (. (___doc-__) :filename))
                                (when (not old-filename)
                                  (core.error "Cannot rename unsaved doc")
                                  (lua "return "))
                                (core.command_view:set_text old-filename)
                                (core.command_view:enter :Rename
                                                         (fn [filename]
                                                           (: (___doc-__) :save
                                                              filename)
                                                           (core.log "Renamed \"%s\" to \"%s\""
                                                                     old-filename
                                                                     filename)
                                                           (when (not= filename
                                                                       old-filename)
                                                             (os.remove old-filename)))
                                                         common.path_suggest))
                 "doc:cut" (fn []
                             (when (: (___doc-__) :has_selection)
                               (local text
                                      (: (___doc-__) :get_text
                                         (: (___doc-__) :get_selection)))
                               (system.set_clipboard text)
                               (: (___doc-__) :delete_to 0)))
                 "doc:save" (fn []
                              (if (. (___doc-__) :filename) (save)
                                  (command.perform "doc:save-as")))
                 "doc:go-to-line" (fn []
                                    (local dv (dv))
                                    (var items nil)

                                    (fn init-items []
                                      (when items
                                        (lua "return "))
                                      (set items {})
                                      (local mt
                                             {:__tostring (fn [x]
                                                            x.text)})
                                      (each [i line (ipairs dv.doc.lines)]
                                        (local item
                                               {:info (.. "line: " i)
                                                :line i
                                                :text (line:sub 1 (- 2))})
                                        (table.insert items
                                                      (setmetatable item mt))))

                                    (core.command_view:enter "Go To Line"
                                                             (fn [text item]
                                                               (local line
                                                                      (or (and item
                                                                               item.line)
                                                                          (tonumber text)))
                                                               (when (not line)
                                                                 (core.error "Invalid line number or unmatched string")
                                                                 (lua "return "))
                                                               (dv.doc:set_selection line
                                                                                     1)
                                                               (dv:scroll_to_line line
                                                                                  true))
                                                             (fn [text]
                                                               (when (not (text:find "^%d*$"))
                                                                 (init-items)
                                                                 (common.fuzzy_match items
                                                                                     text)))))
                 "doc:duplicate-lines" (fn []
                                         (local (line1 col1 line2 col2 swap)
                                                (: (___doc-__) :get_selection
                                                   true))
                                         (append-line-if-last-line line2)
                                         (local text
                                                (: (___doc-__) :get_text line1
                                                   1 (+ line2 1) 1))
                                         (: (___doc-__) :insert (+ line2 1) 1
                                            text)
                                         (local n (+ (- line2 line1) 1))
                                         (: (___doc-__) :set_selection
                                            (+ line1 n) col1 (+ line2 n) col2
                                            swap))
                 "doc:select-all" (fn []
                                    (: (___doc-__) :set_selection 1 1 math.huge
                                       math.huge))
                 "doc:backspace" (fn []
                                   (local (line col)
                                          (: (___doc-__) :get_selection))
                                   (when (not (: (___doc-__) :has_selection))
                                     (local text
                                            (: (___doc-__) :get_text line 1
                                               line col))
                                     (when (and (>= (length text)
                                                    config.indent_size)
                                                (text:find "^ *$"))
                                       (: (___doc-__) :delete_to 0
                                          (- config.indent_size))
                                       (lua "return ")))
                                   (: (___doc-__) :delete_to
                                      translate.previous_char))
                 "doc:save-as" (fn []
                                 (when (. (___doc-__) :filename)
                                   (core.command_view:set_text (. (___doc-__)
                                                                  :filename)))
                                 (core.command_view:enter "Save As"
                                                          (fn [filename]
                                                            (save filename))
                                                          common.path_suggest))
                 "doc:lower-case" (fn []
                                    (: (___doc-__) :replace string.lower))
                 "doc:upper-case" (fn []
                                    (: (___doc-__) :replace string.upper))
                 "doc:toggle-line-comments" (fn []
                                              (local comment*
                                                     (. (. (___doc-__) :syntax)
                                                        :comment))
                                              (when (not comment*)
                                                (lua "return "))
                                              (local comment-text
                                                     (.. comment* " "))
                                              (local (line1 _ line2)
                                                     (: (___doc-__)
                                                        :get_selection true))
                                              (var uncomment true)
                                              (for [line line1 line2 1]
                                                (local text
                                                       (. (. (___doc-__) :lines)
                                                          line))
                                                (when (and (text:find "%S")
                                                           (not= (text:find comment-text
                                                                            1
                                                                            true)
                                                                 1))
                                                  (set uncomment false)))
                                              (if uncomment
                                                  (remove-from-start-of-selected-lines comment-text
                                                                                       true)
                                                  (insert-at-start-of-selected-lines comment-text
                                                                                     true)))
                 "doc:select-none" (fn []
                                     (local (line col)
                                            (: (___doc-__) :get_selection))
                                     (: (___doc-__) :set_selection line col))
                 "doc:indent" (fn []
                                (local text (get-indent-string))
                                (if (: (___doc-__) :has_selection)
                                    (insert-at-start-of-selected-lines text)
                                    (: (___doc-__) :text_input text)))
                 "doc:move-lines-down" (fn []
                                         (local (line1 col1 line2 col2 swap)
                                                (: (___doc-__) :get_selection
                                                   true))
                                         (append-line-if-last-line (+ line2 1))
                                         (when (< line2
                                                  (length (. (___doc-__) :lines)))
                                           (local text
                                                  (. (. (___doc-__) :lines)
                                                     (+ line2 1)))
                                           (: (___doc-__) :remove (+ line2 1) 1
                                              (+ line2 2) 1)
                                           (: (___doc-__) :insert line1 1 text)
                                           (: (___doc-__) :set_selection
                                              (+ line1 1) col1 (+ line2 1) col2
                                              swap)))
                 "doc:newline" (fn []
                                 (local (line col)
                                        (: (___doc-__) :get_selection))
                                 (var indent
                                      (: (. (. (___doc-__) :lines) line) :match
                                         "^[\t ]*"))
                                 (when (<= col (length indent))
                                   (set indent
                                        (indent:sub (- (+ (length indent) 2)
                                                       col))))
                                 (: (___doc-__) :text_input (.. "\n" indent)))
                 "doc:undo" (fn []
                              (: (___doc-__) :undo))
                 "doc:delete-lines" (fn []
                                      (local (line1 col1 line2)
                                             (: (___doc-__) :get_selection true))
                                      (append-line-if-last-line line2)
                                      (: (___doc-__) :remove line1 1
                                         (+ line2 1) 1)
                                      (: (___doc-__) :set_selection line1 col1))
                 "doc:newline-above" (fn []
                                       (local line
                                              (: (___doc-__) :get_selection))
                                       (local indent
                                              (: (. (. (___doc-__) :lines) line)
                                                 :match "^[\t ]*"))
                                       (: (___doc-__) :insert line 1
                                          (.. indent "\n"))
                                       (: (___doc-__) :set_selection line
                                          math.huge))
                 "doc:select-lines" (fn []
                                      (local (line1 _ line2 _ swap)
                                             (: (___doc-__) :get_selection true))
                                      (append-line-if-last-line line2)
                                      (: (___doc-__) :set_selection line1 1
                                         (+ line2 1) 1 swap))
                 "doc:paste" (fn []
                               (: (___doc-__) :text_input
                                  (: (system.get_clipboard) :gsub "\r" "")))
                 "doc:unindent" (fn []
                                  (local text (get-indent-string))
                                  (remove-from-start-of-selected-lines text))
                 "doc:delete" (fn []
                                (local (line col)
                                       (: (___doc-__) :get_selection))
                                (when (and (not (: (___doc-__) :has_selection))
                                           (: (. (. (___doc-__) :lines) line)
                                              :find "^%s*$" col))
                                  (: (___doc-__) :remove line col line
                                     math.huge))
                                (: (___doc-__) :delete_to translate.next_char))
                 "doc:join-lines" (fn []
                                    (var (line1 _ line2)
                                         (: (___doc-__) :get_selection true))
                                    (when (= line1 line2)
                                      (set line2 (+ line2 1)))
                                    (var text
                                         (: (___doc-__) :get_text line1 1 line2
                                            math.huge))
                                    (set text
                                         (text:gsub "(.-)\n[\t ]*"
                                                    (fn [x]
                                                      (or (and (x:find "^%s*$")
                                                               x)
                                                          (.. x " ")))))
                                    (: (___doc-__) :insert line1 1 text)
                                    (: (___doc-__) :remove line1
                                       (+ (length text) 1) line2 math.huge)
                                    (when (: (___doc-__) :has_selection)
                                      (: (___doc-__) :set_selection line1
                                         math.huge)))
                 "doc:copy" (fn []
                              (when (: (___doc-__) :has_selection)
                                (local text
                                       (: (___doc-__) :get_text
                                          (: (___doc-__) :get_selection)))
                                (system.set_clipboard text)))})

(local translations
       {:next-char translate.next_char
        :start-of-line translate.start_of_line
        :next-word-end translate.next_word_end
        :previous-page Doc-view.translate.previous_page
        :start-of-doc translate.start_of_doc
        :start-of-word translate.start_of_word
        :next-line Doc-view.translate.next_line
        :previous-block-start translate.previous_block_start
        :end-of-doc translate.end_of_doc
        :previous-line Doc-view.translate.previous_line
        :end-of-word translate.end_of_word
        :end-of-line translate.end_of_line
        :previous-char translate.previous_char
        :next-block-end translate.next_block_end
        :previous-word-start translate.previous_word_start
        :next-page Doc-view.translate.next_page})

(each [name ___fn-__ (pairs translations)]
  (tset commands (.. "doc:move-to-" name)
        (fn []
          (: (___doc-__) :move_to ___fn-__ (dv))))
  (tset commands (.. "doc:select-to-" name)
        (fn []
          (: (___doc-__) :select_to ___fn-__ (dv))))
  (tset commands (.. "doc:delete-to-" name)
        (fn []
          (: (___doc-__) :delete_to ___fn-__ (dv)))))

(tset commands "doc:move-to-previous-char"
      (fn []
        (if (: (___doc-__) :has_selection)
            (let [(line col) (: (___doc-__) :get_selection true)]
              (: (___doc-__) :set_selection line col))
            (: (___doc-__) :move_to translate.previous_char))))

(tset commands "doc:move-to-next-char"
      (fn []
        (if (: (___doc-__) :has_selection)
            (let [(_ _ line col) (: (___doc-__) :get_selection true)]
              (: (___doc-__) :set_selection line col))
            (: (___doc-__) :move_to translate.next_char))))

(command.add :core.docview commands)

