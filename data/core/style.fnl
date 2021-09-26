(local common (require :core.common))

(local style {})

(set style.padding {:y (common.round (* 7 SCALE))
                    :x (common.round (* 14 SCALE))})

(set style.divider_size (common.round (* 1 SCALE)))

(set style.scrollbar_size (common.round (* 4 SCALE)))

(set style.caret_width (common.round (* 2 SCALE)))

(set style.tab_width (common.round (* 170 SCALE)))

(set style.font (renderer.font.load (.. EXEDIR :/data/fonts/font.ttf)
                                    (* 14 SCALE)))

(set style.big_font (renderer.font.load (.. EXEDIR :/data/fonts/font.ttf)
                                        (* 34 SCALE)))

(set style.icon_font (renderer.font.load (.. EXEDIR :/data/fonts/icons.ttf)
                                         (* 14 SCALE)))

(set style.code_font (renderer.font.load (.. EXEDIR :/data/fonts/monospace.ttf)
                                         (* 13.5 SCALE)))

(set style.background {1 (common.color "#2e2e32")})

(set style.background2 {1 (common.color "#252529")})

(set style.background3 {1 (common.color "#252529")})

(set style.text {1 (common.color "#97979c")})

(set style.caret {1 (common.color "#93DDFA")})

(set style.accent {1 (common.color "#e1e1e6")})

(set style.dim {1 (common.color "#525257")})

(set style.divider {1 (common.color "#202024")})

(set style.selection {1 (common.color "#48484f")})

(set style.line_number {1 (common.color "#525259")})

(set style.line_number2 {1 (common.color "#83838f")})

(set style.line_highlight {1 (common.color "#343438")})

(set style.scrollbar {1 (common.color "#414146")})

(set style.scrollbar2 {1 (common.color "#4b4b52")})

(set style.syntax {})

(tset style.syntax :normal {1 (common.color "#e1e1e6")})

(tset style.syntax :symbol {1 (common.color "#e1e1e6")})

(tset style.syntax :comment {1 (common.color "#676b6f")})

(tset style.syntax :keyword {1 (common.color "#E58AC9")})

(tset style.syntax :keyword2 {1 (common.color "#F77483")})

(tset style.syntax :number {1 (common.color "#FFA94D")})

(tset style.syntax :literal {1 (common.color "#FFA94D")})

(tset style.syntax :string {1 (common.color "#f7c95c")})

(tset style.syntax :operator {1 (common.color "#93DDFA")})

(tset style.syntax :function {1 (common.color "#93DDFA")})

style

