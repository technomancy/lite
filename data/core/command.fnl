(local core (require :core))

(local command {})

(set command.map {})

(fn always-true []
  true)

(fn command.add [predicate map]
  (set-forcibly! predicate (or predicate always-true))
  (when (= (type predicate) :string)
    (set-forcibly! predicate (require predicate)))
  (when (= (type predicate) :table)
    (local class predicate)
    (set-forcibly! predicate
                   (fn []
                     (core.active_view:is class))))
  (each [name ___fn-__ (pairs map)]
    (assert (not (. command.map name)) (.. "command already exists: " name))
    (tset command.map name {:perform ___fn-__ : predicate})))

(fn capitalize-first [str]
  (.. (: (str:sub 1 1) :upper) (str:sub 2)))

(fn command.prettify_name [name]
  (: (: (name:gsub ":" ": ") :gsub "-" " ") :gsub "%S+" capitalize-first))

(fn command.get_all_valid []
  (let [res {}]
    (each [name cmd (pairs command.map)]
      (when (cmd.predicate)
        (table.insert res name)))
    res))

(fn perform [name]
  (let [cmd (. command.map name)]
    (when (and cmd (cmd.predicate))
      (cmd.perform)
      (lua "return true"))
    false))

(fn command.perform [...]
  (let [(ok res) (core.try perform ...)]
    (or (not ok) res)))

(fn command.add_defaults []
  (let [reg {1 :core 2 :root 3 :command 4 :doc 5 :findreplace}]
    (each [_ name (ipairs reg)]
      (require (.. :core.commands. name)))))

command

