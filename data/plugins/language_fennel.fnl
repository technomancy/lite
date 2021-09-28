(local syntax (require :core.syntax))

(syntax.add {:files "%.fnl$"
             :symbols {:-?>> :keyword
                       := :keyword
                       :- :keyword
                       :macros :keyword2
                       :local :keyword2
                       :nil :literal
                       :not :keyword2
                       :or :keyword2
                       :$9 :keyword
                       :$4 :keyword
                       :comment :keyword2
                       :$5 :keyword
                       :. :keyword
                       :$6 :keyword
                       :bnot :keyword2
                       :lshift :keyword2
                       :rshift :keyword2
                       :hashfn :keyword2
                       "#" :keyword
                       :quote :keyword2
                       :band :keyword2
                       :bor :keyword2
                       :.. :keyword
                       :when :keyword2
                       :doto :keyword2
                       :length :keyword2
                       :not= :keyword2
                       :tset :keyword2
                       :var :keyword2
                       :// :keyword
                       :global :keyword2
                       :set :keyword2
                       ":" :keyword
                       :$1 :keyword
                       :values :keyword2
                       :require-macros :keyword2
                       "%" :keyword
                       :* :keyword
                       :+ :keyword
                       :/ :keyword
                       :< :keyword
                       :<= :keyword
                       :> :keyword
                       :>= :keyword
                       :^ :keyword
                       :true :literal
                       :and :keyword2
                       :while :keyword2
                       :do :keyword2
                       :false :literal
                       :for :keyword2
                       :if :keyword2
                       :macrodebug :keyword2
                       :partial :keyword2
                       :$8 :keyword
                       :$7 :keyword
                       :$3 :keyword
                       :$2 :keyword
                       :collect :keyword2
                       :each :keyword2
                       :icollect :keyword2
                       :... :keyword
                       :$ :keyword
                       "λ" :keyword2
                       :fn :keyword2
                       :lambda :keyword2
                       :macro :keyword2
                       :?. :keyword
                       :eval-compiler :keyword2
                       :import-macros :keyword2
                       :bxor :keyword2
                       :let :keyword2
                       :accumulate :keyword2
                       :lua :keyword2
                       :doc :keyword2
                       :pick-values :keyword2
                       :set-forcibly! :keyword2
                       :include :keyword2
                       :match :keyword2
                       :pick-args :keyword2
                       :-> :keyword
                       :->> :keyword
                       :-?> :keyword}
             :patterns {1 {:pattern ";.-\n" :type :comment}
                        2 {:pattern {1 "\"" 2 "\"" 3 "\\"} :type :string}
                        3 {:pattern "0x[%da-fA-F]+" :type :number}
                        4 {:pattern "-?%d+[%d%.]*" :type :number}
                        5 {:pattern "-?%.?%d+" :type :number}
                        6 {:pattern "%f[^(][^()'%s\"]+" :type :function}
                        7 {:pattern "[^()'%s\"]+" :type :symbol}}
             :comment ";"})

