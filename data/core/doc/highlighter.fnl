(local core (require :core))

(local config (require :core.config))

(local tokenizer (require :core.tokenizer))

(local Object (require :core.object))

(local Highlighter (Object:extend))

(fn Highlighter.new [self ___doc-__]
  (set self.doc ___doc-__)
  (self:reset)
  (core.add_thread (fn []
                     (while true
                       (if (> self.first_invalid_line self.max_wanted_line)
                           (do
                             (set self.max_wanted_line 0)
                             (coroutine.yield (/ 1 config.fps)))
                           (let [max (math.min (+ self.first_invalid_line 40)
                                               self.max_wanted_line)]
                             (for [i self.first_invalid_line max 1]
                               (local state
                                      (and (> i 1)
                                           (. (. self.lines (- i 1)) :state)))
                               (local line (. self.lines i))
                               (when (not (and line (= line.init_state state)))
                                 (tset self.lines i
                                       (self:tokenize_line i state))))
                             (set self.first_invalid_line (+ max 1))
                             (set core.redraw true)
                             (coroutine.yield))))) self))

(fn Highlighter.reset [self]
  (set self.lines {})
  (set self.first_invalid_line 1)
  (set self.max_wanted_line 0))

(fn Highlighter.invalidate [self idx]
  (set self.first_invalid_line (math.min self.first_invalid_line idx))
  (set self.max_wanted_line
       (math.min self.max_wanted_line (length self.doc.lines))))

(fn Highlighter.tokenize_line [self idx state]
  (let [res {}]
    (set res.init_state state)
    (set res.text (. self.doc.lines idx))
    (set-forcibly! (res.tokens res.state)
                   (tokenizer.tokenize self.doc.syntax res.text state))
    res))

(fn Highlighter.get_line [self idx]
  (var line (. self.lines idx))
  (when (or (not line) (not= line.text (. self.doc.lines idx)))
    (local prev (. self.lines (- idx 1)))
    (set line (self:tokenize_line idx (and prev prev.state)))
    (tset self.lines idx line))
  (set self.max_wanted_line (math.max self.max_wanted_line idx))
  line)

(fn Highlighter.each_token [self idx]
  (tokenizer.each_token (. (self:get_line idx) :tokens)))

Highlighter

