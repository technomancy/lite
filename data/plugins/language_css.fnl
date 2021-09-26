(local syntax (require :core.syntax))

(syntax.add {:symbols {}
             :files {1 "%.css$"}
             :patterns {1 {:pattern "\\." :type :normal}
                        2 {:pattern "//.-\n" :type :comment}
                        3 {:pattern {1 "/%*" 2 "%*/"} :type :comment}
                        4 {:pattern {1 "\"" 2 "\"" 3 "\\"} :type :string}
                        5 {:pattern {1 "'" 2 "'" 3 "\\"} :type :string}
                        6 {:pattern "[%a][%w-]*%s*%f[:]" :type :keyword}
                        7 {:pattern "#%x+" :type :string}
                        8 {:pattern "-?%d+[%d%.]*p[xt]" :type :number}
                        9 {:pattern "-?%d+[%d%.]*deg" :type :number}
                        10 {:pattern "-?%d+[%d%.]*" :type :number}
                        11 {:pattern "[%a_][%w_]*" :type :symbol}
                        12 {:pattern "#[%a][%w_-]*" :type :keyword2}
                        13 {:pattern "@[%a][%w_-]*" :type :keyword2}
                        14 {:pattern "%.[%a][%w_-]*" :type :keyword2}
                        15 {:pattern "[{}:]" :type :operator}}})

