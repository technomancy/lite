(local strict {})

(set strict.defined {})

(set-forcibly! ___global-__ (fn [t]
                              (each [k v (pairs t)]
                                (tset strict.defined k true)
                                (rawset _G k v))))

(fn strict.__newindex [t k v]
  (error (.. "cannot set undefined variable: " k) 2))

(fn strict.__index [t k]
  (when (not (. strict.defined k))
    (error (.. "cannot get undefined variable: " k) 2)))

(setmetatable _G strict)

