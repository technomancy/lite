(local syntax (require :core.syntax))

(syntax.add {:patterns {1 {:type :comment :pattern "//.-\n"}
                        2 {:type :comment :pattern {1 "/%*" 2 "%*/"}}
                        3 {:type :string :pattern {1 "\"" 2 "\"" 3 "\\"}}
                        4 {:type :string :pattern {1 "'" 2 "'" 3 "\\"}}
                        5 {:type :string :pattern {1 "`" 2 "`" 3 "\\"}}
                        6 {:type :number :pattern "0x[%da-fA-F]+"}
                        7 {:type :number :pattern "-?%d+[%d%.eE]*"}
                        8 {:type :number :pattern "-?%.?%d+"}
                        9 {:type :operator :pattern "[%+%-=/%*%^%%<>!~|&]"}
                        10 {:type :function :pattern "[%a_][%w_]*%f[(]"}
                        11 {:type :symbol :pattern "[%a_][%w_]*"}}
             :comment "//"
             :symbols {:switch :keyword
                       :export :keyword
                       :NaN :keyword2
                       :throw :keyword
                       :arguments :keyword2
                       :case :keyword
                       :extends :keyword
                       :try :keyword
                       :new :keyword
                       :import :keyword
                       :finally :keyword
                       :class :keyword
                       :do :keyword
                       :else :keyword
                       :yield :keyword
                       :for :keyword
                       :function :keyword
                       :instanceof :keyword
                       :in :keyword
                       :continue :keyword
                       :let :keyword
                       :return :keyword
                       :true :literal
                       :const :keyword
                       :debugger :keyword
                       :this :keyword2
                       :Infinity :keyword2
                       :var :keyword
                       :async :keyword
                       :undefined :literal
                       :default :keyword
                       :null :literal
                       :false :literal
                       :with :keyword
                       :while :keyword
                       :void :keyword
                       :static :keyword
                       :delete :keyword
                       :typeof :keyword
                       :super :keyword
                       :break :keyword
                       :catch :keyword
                       :get :keyword
                       :await :keyword
                       :if :keyword
                       :set :keyword}
             :files {1 "%.js$" 2 "%.json$" 3 "%.cson$"}})

