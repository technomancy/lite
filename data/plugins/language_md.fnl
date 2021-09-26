(local syntax (require :core.syntax))

(syntax.add {:files {1 "%.md$" 2 "%.markdown$"}
             :symbols {}
             :patterns {1 {:pattern "\\." :type :normal}
                        2 {:pattern {1 "<!%-%-" 2 "%-%->"} :type :comment}
                        3 {:pattern {1 "```" 2 "```"} :type :string}
                        4 {:pattern {1 "``" 2 "``" 3 "\\"} :type :string}
                        5 {:pattern {1 "`" 2 "`" 3 "\\"} :type :string}
                        6 {:pattern {1 "~~" 2 "~~" 3 "\\"} :type :keyword2}
                        7 {:pattern "%-%-%-+" :type :comment}
                        8 {:pattern "%*%s+" :type :operator}
                        9 {:pattern {1 "%*" 2 "[%*\n]" 3 "\\"} :type :operator}
                        10 {:pattern {1 "%_" 2 "[%_\n]" 3 "\\"}
                            :type :keyword2}
                        11 {:pattern "#.-\n" :type :keyword}
                        12 {:pattern "!?%[.-%]%(.-%)" :type :function}
                        13 {:pattern "https?://%S+" :type :function}}})

