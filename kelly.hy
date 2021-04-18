; For an even money bet, the Kelly criterion computes the wager size percentage
; by multiplying the percent chance to win by two, then subtracting one-hundred
; percent. So, for a bet with a 70% chance to win the optimal wager size is 40%
; of available funds.

; (local-set-key (kbd "C-c C-e") 'my-hy-eval-last-sexp)

(import json
        [numpy :as np]
        [pandas :as pd]
        [matplotlib.pyplot :as plt]
        [functools [partial]]
        zgulde.extend_pandas)


(defclass BettingStrategy []
    "map of strategy name -> strategy function
    the strategy function takes in the current balance and the probability of
    winning and returns"
    (setv kelly (fn [available-funds p-win]
                    (* (- (* 2 p-win) 1) available-funds)))
    (setv half (fn [available-funds p-win] (/ available-funds 2)))
    (setv conservative (fn [available-funds p-win] (/ available-funds 10)))
    (setv half-kelly (fn [available-funds p-win]
                         (/ (BettingStrategy.kelly available-funds p-win)
                            2))))

(defn make-reducer [p-win get-bet-amount include-history?]
  "Create a reducing function to be applied to a list of booleans indicating win or loss"
  (if include-history?
      (fn [history win]
        (setv balance (last history)
              bet-amount (get-bet-amount balance p-win))
        (if win
            (+ history [(+ balance bet-amount)])
            (+ history [(- balance bet-amount)])))
      (fn [balance win]
        (setv bet-amount (get-bet-amount balance p-win))
        (if win
            (+ balance bet-amount)
            (- balance bet-amount)))))

(defn do-sim [&optional [iterations 100]
                        [p-win .7]
                        [initial-balance 100]
                        [strategy BettingStrategy.kelly]
                        [include-history? False]]
    "Return a list of values of lengh iterations + 1.
    Each element corresponds to the current balance at one iteration
    (including the initial)"
    (setv wins-losses
          (np.random.choice [True False]
                            :p [p-win (- 1 p-win)]
                            :size [iterations])
          reducer (make-reducer p-win strategy include-history?)
          init (if include-history? [initial-balance] initial-balance))
    (reduce reducer wins-losses init))

(defn do-sims [&optional [iterations 10]
                         [simulations 5]
                         [p-win .7]
                         [initial-balance 100]
                         [strategy BettingStrategy.kelly]
                         [include-history? False]]
  (setv dataset (if include-history?
                    (lfor _ (range simulations)
                          (do-sim iterations p-win initial-balance strategy include-history?))
                    (lfor _ (range simulations)
                          (do-sim iterations p-win initial-balance strategy include-history?)))
        dataset (np.array dataset))
  (if include-history? (.transpose dataset) dataset))

(defn make-df [sims iters]
  "Each value represents ending funds."
  (setv sim-fn (partial do-sims :iterations iters :simulations sims))
  (pd.DataFrame (dict :kelly (sim-fn :strategy BettingStrategy.kelly)
                      :half (sim-fn :strategy BettingStrategy.half)
                      :conservative (sim-fn :strategy BettingStrategy.conservative)
                      :half-kelly (sim-fn :strategy BettingStrategy.half-kelly))))
