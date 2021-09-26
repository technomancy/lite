(local core (require :core))

(local command (require :core.command))

(local keymap (require :core.keymap))

(local escapes {"\"" "\\\""
                "\r" "\\r"
                "\b" "\\b"
                "\t" "\\t"
                "\n" "\\n"
                "\\" "\\\\"})

(fn replace [chr]
  (or (. escapes chr) (string.format "\\x%02x" (chr:byte))))

(command.add :core.docview
             {"quote:quote" (fn []
                              (core.active_view.doc:replace (fn [text]
                                                              (.. "\""
                                                                  (text:gsub "[\000-\031\\\"]"
                                                                             replace)
                                                                  "\""))))})

(keymap.add {"ctrl+'" "quote:quote"})

