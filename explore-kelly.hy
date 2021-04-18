(import [functools [partial]]
        [matplotlib.pyplot :as plt]
        [matplotlib.patches [Patch]]
        [pandas :as pd]
        [numpy :as np]
        zgulde.extend-pandas
        [zgulde.ds-util.plotting [style]]
        kelly)
(plt.style.use style)

;;

(setv df (kelly.make-df :sims 2000 :iters 20))

;;

(setv iterations 15
      simulations 500
      do-sims (partial kelly.do-sims :simulations simulations :iterations iterations :include-history? True)
      kelly-sims (do-sims)
      half-sims (do-sims :strategy kelly.BettingStrategy.half)
      half-kelly-sims (do-sims :strategy kelly.BettingStrategy.half-kelly)
      conservative-sims (do-sims :strategy kelly.BettingStrategy.conservative)
      plots [[kelly-sims "Kelly" "blue"]
             [half-sims "Half" "darkorange"]
             [half-kelly-sims "Half Kelly" "green"]
             [conservative-sims "Conservative" "red"]])
(for [[x label c] plots]
  (plt.plot x :c c :alpha .1 :lw 10))
(plt.yscale "log")
(plt.xticks (range iterations))
(plt.legend :title "Betting Strategy" :handles (lfor [_ l c] plots (Patch :color c :label l)))
(.set (plt.gca)
      :xlabel "Iteration No."
      :ylabel "Balance"
      :title "")
(plt.show)

(plt.savefig "strategies_overtime.png")




;; 

(setv by-group (df.apply
                 (fn [s] (pd.Series {"Lose Money" (.mean (< s 100))
                                     "Gain Money" (.mean (> s 100))
                                     "2x Your Money" (.mean (>= s 200))
                                     "5x Your Money" (.mean (>= s 500))
                                     "10 x Your Money" (.mean (>= s 1000))}))))
(by-group.plot.barh :width .6 :title "After 20 rounds of betting, how likely are you to:")
(plt.legend :title "Betting Strategy")
(plt.tight-layout)
(.invert-yaxis (plt.gca))
(.set-major-formatter (. (plt.gca) xaxis) "{x:.0%}")
(plt.savefig "bar_probs.png")

(-> df
    (.apply (fn [s] (-> s
                      (.cut :bins (lfor i (range 0 34 3) (* i 100)))
                      (.value-counts)))))


(defn get-xtick-labels []
  (map (fn [n] (+ "$" (format (* 100 n) ",")))
       (range 21)))

(.plot
  (df.apply (fn [s]
              (pd.Series (dfor t (range 21)
                               [(str t) (.mean (<= s (* 100 t)))]))))
  :title "Kelly Criteria -- $100 starting, 70% chance, 20 iterations"
  :ylabel "% of samples <="
  :xlabel "end balance")
(.set (plt.gca) :xticks (range 21) :xticklabels (get-xtick-labels))
(plt.grid)

(.sort-values (. df.kelly [(> df.kelly 200)]))

(plt.ion)

(do
    (setv bins [0 100 150 200 400 1000 5000 10000 50000])
    (pd.concat [(.value-counts (df.kelly.cut :bins bins))
                (.value-counts (df.half.cut :bins bins))
                (.value-counts (df.conservative.cut :bins bins))]
               :axis 1))

(df.apply (fn [col] (col.mean))

(.value-counts (df.kelly.qcut 4))

(.value-counts (df.half.qcut 4))

; (. (.transpose (np.array (lfor _ (range 5)
;                              (do-kelly :iterations 10)))) shape)

(df.kelly.plot.hist :bins (np.logspace 0 5 25))
(plt.show)

(plt.close)
(plt.hist df.kelly :bins "auto")
(plt.show)

(setv bins (np.logspace 0 (np.log10 (-> df (.max) (.max))) 200)
      ge-bins (fn [s] (pd.Series (dfor bin bins [bin (-> s (>= bin) (.mean))])))
      le-bins (fn [s] (pd.Series (dfor bin bins [bin (-> s (<= bin) (.mean))])))
      explanation-sims "1 simultaion is 20 iterations of applying\nthe selected betting strategy with an initial\nbalance of $100"
      explanation-strats ["Betting Strategies:"
                          "- Kelly: bet the amount dictated by the kelly criterion"
                          "- Half: bet half of available funds every time"
                          "- Conservative: bet 10% of available funds every time"
                          "- Half Kelly: bet half of the kelly amount"]
      explanation-strats (.join "\n" explanation-strats))
(-> df (.apply ge-bins) (.plot))
(.set (plt.gca)
      :title "Distribution of Ending Balances After 20 Iterations By Betting Strategy\n(2000 sims per group, 70% win chance, $100 initial balance)"
      :xlabel "Ending Balance\n(logspace binned from 0 -> max(ending_balance))"
      :ylabel "% of group >= ending balance")
(plt.xscale "log")
(plt.text (** 10 3.2) .65 explanation-strats)
(plt.text 1 .6 explanation-sims)
(plt.legend :title "Betting Strategy")
(plt.vlines 100 #* (plt.ylim) :ls "--" :color "black")
(plt.annotate "Break Even Point" (, 100 .15) :xytext (, 10 .3) :arrowprops (dict :arrowstyle "->"))
(plt.savefig "ending_distribution.png")

(-> df (.apply le-bins) (.plot))
(plt.xscale "log")
(plt.show)


(-> df
    (.apply (fn [s] (s.value_counts :bins bins)))
    (.plot.bar))

(plt.show)