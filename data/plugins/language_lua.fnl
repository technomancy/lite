(local syntax (require :core.syntax))

(syntax.add {:symbols {:and :keyword
                       :break :keyword
                       :do :keyword
                       :else :keyword
                       :elseif :keyword
                       :end :keyword
                       :false :literal
                       :for :keyword
                       :function :keyword
                       :goto :keyword
                       :if :keyword
                       :in :keyword
                       :local :keyword
                       :nil :literal
                       :not :keyword
                       :or :keyword
                       :repeat :keyword
                       :return :keyword
                       :then :keyword
                       :true :literal
                       :until :keyword
                       :while :keyword
                       :self :keyword2}
             :patterns {1 {:pattern {1 "\"" 2 "\"" 3 "\\"} :type :string}
                        2 {:pattern {1 "'" 2 "'" 3 "\\"} :type :string}
                        3 {:pattern {1 "%[%[" 2 "%]%]"} :type :string}
                        4 {:pattern {1 "%-%-%[%[" 2 "%]%]"} :type :comment}
                        5 {:pattern "%-%-.-\n" :type :comment}
                        6 {:pattern "-?0x%x+" :type :number}
                        7 {:pattern "-?%d+[%d%.eE]*" :type :number}
                        8 {:pattern "-?%.?%d+" :type :number}
                        9 {:pattern "<%a+>" :type :keyword2}
                        10 {:pattern "%.%.%.?" :type :operator}
                        11 {:pattern "[<>~=]=" :type :operator}
                        12 {:pattern "[%+%-=/%*%^%%#<>]" :type :operator}
                        13 {:pattern "[%a_][%w_]*%s*%f[(\"{]" :type :function}
                        14 {:pattern "[%a_][%w_]*" :type :symbol}
                        15 {:pattern "::[%a_][%w_]*::" :type :function}}
             :headers "^#!.*[ /]lua"
             :comment "--"
             :files "%.lua$"})

