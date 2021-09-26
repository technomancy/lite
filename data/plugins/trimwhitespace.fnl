(local core (require :core))

(local command (require :core.command))

(local Doc (require :core.doc))

(fn trim-trailing-whitespace [___doc-__]
  (let [(cline ccol) (___doc-__:get_selection)]
    (for [i 1 (length ___doc-__.lines) 1]
      (local old-text (___doc-__:get_text i 1 i math.huge))
      (var new-text (old-text:gsub "%s*$" ""))
      (when (and (= cline i) (> ccol (length new-text)))
        (set new-text (old-text:sub 1 (- ccol 1))))
      (when (not= old-text new-text)
        (___doc-__:insert i 1 new-text)
        (___doc-__:remove i (+ (length new-text) 1) i math.huge)))))

(command.add :core.docview
             {"trim-whitespace:trim-trailing-whitespace" (fn []
                                                           (trim-trailing-whitespace core.active_view.doc))})

(local save Doc.save)

(set Doc.save (fn [self ...]
                (trim-trailing-whitespace self)
                (save self ...)))

