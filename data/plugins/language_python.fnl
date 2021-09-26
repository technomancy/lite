(local syntax (require :core.syntax))

(syntax.add {:comment "#"
             :patterns {1 {:type :comment :pattern {1 "#" 2 "\n"}}
                        2 {:type :string :pattern {1 "[ruU]?\"" 2 "\"" 3 "\\"}}
                        3 {:type :string :pattern {1 "[ruU]?'" 2 "'" 3 "\\"}}
                        4 {:type :string :pattern {1 "\"\"\"" 2 "\"\"\""}}
                        5 {:type :number :pattern "0x[%da-fA-F]+"}
                        6 {:type :number :pattern "-?%d+[%d%.eE]*"}
                        7 {:type :number :pattern "-?%.?%d+"}
                        8 {:type :operator :pattern "[%+%-=/%*%^%%<>!~|&]"}
                        9 {:type :function :pattern "[%a_][%w_]*%f[(]"}
                        10 {:type :symbol :pattern "[%a_][%w_]*"}}
             :symbols {:is :keyword
                       :False :literal
                       :self :keyword2
                       :None :literal
                       :continue :keyword
                       :elif :keyword
                       :import :keyword
                       :True :literal
                       :pass :keyword
                       :global :keyword
                       :try :keyword
                       :def :keyword
                       :break :keyword
                       :except :keyword
                       :else :keyword
                       :from :keyword
                       :yield :keyword
                       :for :keyword
                       :class :keyword
                       :if :keyword
                       :in :keyword
                       :raise :keyword
                       :nonlocal :keyword
                       :or :keyword
                       :return :keyword
                       :and :keyword
                       :as :keyword
                       :while :keyword
                       :del :keyword
                       :lambda :keyword
                       :not :keyword
                       :finally :keyword
                       :with :keyword
                       :assert :keyword}
             :files {1 "%.py$" 2 "%.pyw$"}
             :headers "^#!.*[ /]python"})

