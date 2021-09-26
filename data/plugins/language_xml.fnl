(local syntax (require :core.syntax))

(syntax.add {:patterns {1 {:pattern {1 "<!%-%-" 2 "%-%->"} :type :comment}
                        2 {:pattern {1 "%f[^>][^<]" 2 "%f[<]"} :type :normal}
                        3 {:pattern {1 "\"" 2 "\"" 3 "\\"} :type :string}
                        4 {:pattern {1 "'" 2 "'" 3 "\\"} :type :string}
                        5 {:pattern "0x[%da-fA-F]+" :type :number}
                        6 {:pattern "-?%d+[%d%.]*f?" :type :number}
                        7 {:pattern "-?%.?%d+f?" :type :number}
                        8 {:pattern "%f[^<]![%a_][%w_]*" :type :keyword2}
                        9 {:pattern "%f[^<][%a_][%w_]*" :type :function}
                        10 {:pattern "%f[^<]/[%a_][%w_]*" :type :function}
                        11 {:pattern "[%a_][%w_]*" :type :keyword}
                        12 {:pattern "[/<>=]" :type :operator}}
             :files {1 "%.xml$" 2 "%.html?$"}
             :symbols {}
             :headers "<%?xml"})

