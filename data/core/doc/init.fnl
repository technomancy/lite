(local Object (require :core.object))

(local Highlighter (require :core.doc.highlighter))

(local syntax (require :core.syntax))

(local config (require :core.config))

(local common (require :core.common))

(local Doc (Object:extend))

(fn split-lines [text]
  (let [res {}]
    (each [line (: (.. text "\n") :gmatch "(.-)\n")]
      (table.insert res line))
    res))

(fn splice [t at remove insert]
  (set-forcibly! insert (or insert {}))
  (local offset (- (length insert) remove))
  (local old-len (length t))
  (if (< offset 0) (for [i (- at offset) (- old-len offset) 1]
                     (tset t (+ i offset) (. t i)))
      (> offset 0) (for [i old-len at (- 1)]
                    (tset t (+ i offset) (. t i))))
  (each [i item (ipairs insert)]
    (tset t (- (+ at i) 1) item)))

(fn Doc.new [self filename]
  (self:reset)
  (when filename
    (self:load filename)))

(fn Doc.reset [self]
  (set self.lines {1 "\n"})
  (set self.selection {:a {:line 1 :col 1} :b {:line 1 :col 1}})
  (set self.undo_stack {:idx 1})
  (set self.redo_stack {:idx 1})
  (set self.clean_change_id 1)
  (set self.highlighter (Highlighter self))
  (self:reset_syntax))

(fn Doc.reset_syntax [self]
  (let [header (self:get_text 1 1 (self:position_offset 1 1 128))
        syn (syntax.get (or self.filename "") header)]
    (when (not= self.syntax syn)
      (set self.syntax syn)
      (self.highlighter:reset))))

(fn Doc.load [self filename]
  (let [fp (assert (io.open filename :rb))]
    (self:reset)
    (set self.filename filename)
    (set self.lines {})
    (each [line (fp:lines)]
      (when (= (line:byte (- 1)) 13)
        (set-forcibly! line (line:sub 1 (- 2)))
        (set self.crlf true))
      (table.insert self.lines (.. line "\n")))
    (when (= (length self.lines) 0)
      (table.insert self.lines "\n"))
    (fp:close)
    (self:reset_syntax)))

(fn Doc.save [self filename]
  (set-forcibly! filename
                 (or filename
                     (assert self.filename "no filename set to default to")))
  (local fp (assert (io.open filename :wb)))
  (each [_ line (ipairs self.lines)]
    (when self.crlf
      (set-forcibly! line (line:gsub "\n" "\r\n")))
    (fp:write line))
  (fp:close)
  (set self.filename (or filename self.filename))
  (self:reset_syntax)
  (self:clean))

(fn Doc.get_name [self]
  (or self.filename :unsaved))

(fn Doc.is_dirty [self]
  (not= self.clean_change_id (self:get_change_id)))

(fn Doc.clean [self]
  (set self.clean_change_id (self:get_change_id)))

(fn Doc.get_change_id [self]
  self.undo_stack.idx)

(fn Doc.set_selection [self line1 col1 line2 col2 swap]
  (assert (= (not line2) (not col2)) "expected 2 or 4 arguments")
  (when swap
    (set-forcibly! (line1 col1 line2 col2) (values line2 col2 line1 col1)))
  (set-forcibly! (line1 col1) (self:sanitize_position line1 col1))
  (set-forcibly! (line2 col2)
                 (self:sanitize_position (or line2 line1) (or col2 col1)))
  (set-forcibly! (self.selection.a.line self.selection.a.col)
                 (values line1 col1))
  (set-forcibly! (self.selection.b.line self.selection.b.col)
                 (values line2 col2)))

(fn sort-positions [line1 col1 line2 col2]
  (when (or (> line1 line2) (and (= line1 line2) (> col1 col2)))
    (lua "return line2, col2, line1, col1, true"))
  (values line1 col1 line2 col2 false))

(fn Doc.get_selection [self sort]
  (let [(a b) (values self.selection.a self.selection.b)]
    (if sort
        (sort-positions a.line a.col b.line b.col)
        (values a.line a.col b.line b.col))))

(fn Doc.has_selection [self]
  (let [(a b) (values self.selection.a self.selection.b)]
    (not (and (= a.line b.line) (= a.col b.col)))))

(fn Doc.sanitize_selection [self]
  (self:set_selection (self:get_selection)))

(fn Doc.sanitize_position [self line col]
  (set-forcibly! line (common.clamp line 1 (length self.lines)))
  (set-forcibly! col (common.clamp col 1 (length (. self.lines line))))
  (values line col))

(fn position-offset-func [self line col ___fn-__ ...]
  (set-forcibly! (line col) (self:sanitize_position line col))
  (___fn-__ self line col ...))

(fn position-offset-byte [self line col offset]
  (set-forcibly! (line col) (self:sanitize_position line col))
  (set-forcibly! col (+ col offset))
  (while (and (> line 1) (< col 1))
    (set-forcibly! line (- line 1))
    (set-forcibly! col (+ col (length (. self.lines line)))))
  (while (and (< line (length self.lines)) (> col (length (. self.lines line))))
    (set-forcibly! col (- col (length (. self.lines line))))
    (set-forcibly! line (+ line 1)))
  (self:sanitize_position line col))

(fn position-offset-linecol [self line col lineoffset coloffset]
  (self:sanitize_position (+ line lineoffset) (+ col coloffset)))

(fn Doc.position_offset [self line col ...]
  (if (not= (type ...) :number) (position-offset-func self line col ...)
      (= (select "#" ...) 1) (position-offset-byte self line col ...)
      (= (select "#" ...) 2) (position-offset-linecol self line col ...)
      (error "bad number of arguments")))

(fn Doc.get_text [self line1 col1 line2 col2]
  (set-forcibly! (line1 col1) (self:sanitize_position line1 col1))
  (set-forcibly! (line2 col2) (self:sanitize_position line2 col2))
  (set-forcibly! (line1 col1 line2 col2) (sort-positions line1 col1 line2 col2))
  (if (= line1 line2)
      (: (. self.lines line1) :sub col1 (- col2 1))
      (let [lines {1 (: (. self.lines line1) :sub col1)}]
        (for [i (+ line1 1) (- line2 1) 1]
          (table.insert lines (. self.lines i)))
        (table.insert lines (: (. self.lines line2) :sub 1 (- col2 1)))
        (table.concat lines))))

(fn Doc.get_char [self line col]
  (set-forcibly! (line col) (self:sanitize_position line col))
  (: (. self.lines line) :sub col col))

(fn push-undo [undo-stack time type ...]
  (tset undo-stack undo-stack.idx {: type : time 3 ...})
  (tset undo-stack (- undo-stack.idx config.max_undos) nil)
  (set undo-stack.idx (+ undo-stack.idx 1)))

(fn pop-undo [self undo-stack redo-stack]
  (let [cmd (. undo-stack (- undo-stack.idx 1))]
    (when (not cmd)
      (lua "return "))
    (set undo-stack.idx (- undo-stack.idx 1))
    (if (= cmd.type :insert)
        (let [(line col text) (table.unpack cmd)]
          (self:raw_insert line col text redo-stack cmd.time))
        (= cmd.type :remove)
        (let [(line1 col1 line2 col2) (table.unpack cmd)]
          (self:raw_remove line1 col1 line2 col2 redo-stack cmd.time))
        (= cmd.type :selection)
        (do
          (set-forcibly! (self.selection.a.line self.selection.a.col)
                         (values (. cmd 1) (. cmd 2)))
          (set-forcibly! (self.selection.b.line self.selection.b.col)
                         (values (. cmd 3) (. cmd 4)))))
    (local next (. undo-stack (- undo-stack.idx 1)))
    (when (and next (< (math.abs (- cmd.time next.time))
                       config.undo_merge_timeout))
      (pop-undo self undo-stack redo-stack))))

(fn Doc.raw_insert [self line col text undo-stack time]
  (let [lines (split-lines text)
        before (: (. self.lines line) :sub 1 (- col 1))
        after (: (. self.lines line) :sub col)]
    (for [i 1 (- (length lines) 1) 1]
      (tset lines i (.. (. lines i) "\n")))
    (tset lines 1 (.. before (. lines 1)))
    (tset lines (length lines) (.. (. lines (length lines)) after))
    (splice self.lines line 1 lines)
    (local (line2 col2) (self:position_offset line col (length text)))
    (push-undo undo-stack time :selection (self:get_selection))
    (push-undo undo-stack time :remove line col line2 col2)
    (self.highlighter:invalidate line)
    (self:sanitize_selection)))

(fn Doc.raw_remove [self line1 col1 line2 col2 undo-stack time]
  (let [text (self:get_text line1 col1 line2 col2)]
    (push-undo undo-stack time :selection (self:get_selection))
    (push-undo undo-stack time :insert line1 col1 text)
    (local before (: (. self.lines line1) :sub 1 (- col1 1)))
    (local after (: (. self.lines line2) :sub col2))
    (splice self.lines line1 (+ (- line2 line1) 1) {1 (.. before after)})
    (self.highlighter:invalidate line1)
    (self:sanitize_selection)))

(fn Doc.insert [self line col text]
  (set self.redo_stack {:idx 1})
  (set-forcibly! (line col) (self:sanitize_position line col))
  (self:raw_insert line col text self.undo_stack (system.get_time)))

(fn Doc.remove [self line1 col1 line2 col2]
  (set self.redo_stack {:idx 1})
  (set-forcibly! (line1 col1) (self:sanitize_position line1 col1))
  (set-forcibly! (line2 col2) (self:sanitize_position line2 col2))
  (set-forcibly! (line1 col1 line2 col2) (sort-positions line1 col1 line2 col2))
  (self:raw_remove line1 col1 line2 col2 self.undo_stack (system.get_time)))

(fn Doc.undo [self]
  (pop-undo self self.undo_stack self.redo_stack))

(fn Doc.redo [self]
  (pop-undo self self.redo_stack self.undo_stack))

(fn Doc.text_input [self text]
  (when (self:has_selection)
    (self:delete_to))
  (local (line col) (self:get_selection))
  (self:insert line col text)
  (self:move_to (length text)))

(fn Doc.replace [self ___fn-__]
  (let [(line1 col1 line2 col2 swap) nil
        had-selection (self:has_selection)]
    (if had-selection
        (set-forcibly! (line1 col1 line2 col2 swap) (self:get_selection true))
        (set-forcibly! (line1 col1 line2 col2)
                       (values 1 1 (length self.lines)
                               (length (. self.lines (length self.lines))))))
    (local old-text (self:get_text line1 col1 line2 col2))
    (local (new-text n) (___fn-__ old-text))
    (when (not= old-text new-text)
      (self:insert line2 col2 new-text)
      (self:remove line1 col1 line2 col2)
      (when had-selection
        (set-forcibly! (line2 col2)
                       (self:position_offset line1 col1 (length new-text)))
        (self:set_selection line1 col1 line2 col2 swap)))
    n))

(fn Doc.delete_to [self ...]
  (let [(line col) (self:get_selection true)]
    (if (self:has_selection) (self:remove (self:get_selection))
        (let [(line2 col2) (self:position_offset line col ...)]
          (self:remove line col line2 col2)
          (set-forcibly! (line col) (sort-positions line col line2 col2))))
    (self:set_selection line col)))

(fn Doc.move_to [self ...]
  (let [(line col) (self:get_selection)]
    (self:set_selection (self:position_offset line col ...))))

(fn Doc.select_to [self ...]
  (let [(line col line2 col2) (self:get_selection)]
    (set-forcibly! (line col) (self:position_offset line col ...))
    (self:set_selection line col line2 col2)))

Doc

