(local syntax (require :core.syntax))

(syntax.add {:files {1 "%.c$" 2 "%.h$" 3 "%.inl$" 4 "%.cpp$" 5 "%.hpp$"}
             :patterns {1 {:pattern "//.-\n" :type :comment}
                        2 {:pattern {1 "/%*" 2 "%*/"} :type :comment}
                        3 {:pattern {1 "#" 2 "[^\\]\n"} :type :comment}
                        4 {:pattern {1 "\"" 2 "\"" 3 "\\"} :type :string}
                        5 {:pattern {1 "'" 2 "'" 3 "\\"} :type :string}
                        6 {:pattern "-?0x%x+" :type :number}
                        7 {:pattern "-?%d+[%d%.eE]*f?" :type :number}
                        8 {:pattern "-?%.?%d+f?" :type :number}
                        9 {:pattern "[%+%-=/%*%^%%<>!~|&]" :type :operator}
                        10 {:pattern "[%a_][%w_]*%f[(]" :type :function}
                        11 {:pattern "[%a_][%w_]*" :type :symbol}}
             :comment "//"
             :symbols {:typedef :keyword
                       :extern :keyword
                       :static :keyword
                       :case :keyword
                       :float :keyword2
                       :double :keyword2
                       :long :keyword2
                       :short :keyword2
                       :default :keyword
                       :break :keyword
                       :do :keyword
                       :struct :keyword
                       :elseif :keyword
                       :enum :keyword
                       :false :literal
                       :for :keyword
                       :goto :keyword
                       :if :keyword
                       :char :keyword2
                       :return :keyword
                       :then :keyword
                       :true :literal
                       :while :keyword
                       :continue :keyword
                       :unsigned :keyword2
                       :const :keyword
                       :NULL :literal
                       :bool :keyword2
                       :volatile :keyword
                       :switch :keyword
                       :int :keyword2
                       :union :keyword
                       :else :keyword
                       :auto :keyword
                       :inline :keyword
                       :void :keyword}})

