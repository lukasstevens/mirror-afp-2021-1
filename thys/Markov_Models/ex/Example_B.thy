theory Example_B
  imports "../Classifying_Markov_Chain_States"
begin

section {* Example B *} text_raw {* \label{ex:B} *}

text {*

We now formalize the following Markov chain:

\begin{center}
\begin{tikzpicture}[thick]

  \begin{scope} [rotate = 45]
    \path [fill, color = gray!30] (7.5, -6) ellipse(3 and 1) ;
  \end{scope}
  
  \node (bot2)  at (7, -0.5) {} ;
  \node[draw, circle] (1) at ( 8, -0.5) {$0$} ;
  \node[draw, circle] (2) at ( 9,  0.5) {$1$} ;
  \node[draw, circle] (3) at (10,  1.5) {$2$} ;
  \node (inft) at (10.7, 2.6) {} ;
  \node (infb) at (11,   2) {} ;

  \node (inf1) at (10.5, 2) {} ;
  \node (inf2) at (11.5, 3) {} ;
  
  \path[->, >=latex]
    (bot2) edge (1)
    (1)    edge [loop below]   node [right] {$\frac{2}{3}$} (1)
           edge [bend left=30] node [above] {$\frac{1}{3}$} (2)
    (2)    edge [bend left=30] node [below] {$\frac{2}{3}$} (1)
           edge [bend left=30] node [above] {$\frac{1}{3}$} (3)
    (3)    edge [bend left=30] node [below] {$\frac{2}{3}$} (2)
           edge [bend left=30] node [above] {} (inft)
    (infb)  edge [bend left=30] node [above] {} (3) ;

  \path (inf1) edge [loosely dotted] (inf2) ;

\end{tikzpicture}
\end{center}

As state space we have the set of natural numbers, the transition function @{term tau} has three
cases:

*}

definition K :: "nat \<Rightarrow> nat pmf" where
  "K x = map_pmf (\<lambda>True \<Rightarrow> x + 1 | False \<Rightarrow> x - 1) (bernoulli_pmf (1/3))"

text {* For the special case when @{term "x = (0::real)"} we have @{term "x - 1 = (0::real)"} and hence
@{term "tau 0 0 = 2 / 3"}. *}

text {* We pack this transition function into a discrete Markov kernel. *}

text {* We call the locale of the Markov chain @{text B}, hence all constants and theorems
  from this Markov chain get a @{text B} prefix. *}

interpretation B: MC_syntax K .

subsection {* Enabled, accessible and communicating states *}

text {* For each step the predecessor and the successor are enabled (in the @{term 0} case, the
predecessor is again @{term 0}. Hence every state is accessible from everywhere and every states is
communicating with each other state. Finally we know that the state space is an essential class. *}

lemma B_E_eq: "set_pmf (K x) = {x - 1, x + 1}"
  by (auto simp: set_pmf_bernoulli K_def split: bool.split)

lemma B_E_Suc: "Suc x \<in> set_pmf (K x)" "x \<in> set_pmf (K (Suc x))"
  unfolding B_E_eq by auto

lemma B_accessible[intro]: "(i, j) \<in> B.acc"
proof (cases i j rule: linorder_le_cases)
  assume "i \<le> j" then show ?thesis
    by (induct rule: inc_induct) (auto intro: B_E_Suc converse_rtrancl_into_rtrancl)
next
  assume "j \<le> i" then show ?thesis
    by (induct rule: dec_induct) (auto intro: B_E_Suc converse_rtrancl_into_rtrancl)
qed

lemma B_communicating[intro]: "(i, j) \<in> B.communicating"
  by (simp add: B.communicating_def B_accessible)

lemma B_essential: "B.essential_class UNIV"
  by (rule B.essential_classI2) auto

subsection {* B is aperiodic *}

lemma B_aperiodic: "B.aperiodic UNIV"
  unfolding B.aperiodic_def
proof safe
  have eq: "\<And>x'. (if x' = 0 then 1 else 0) = indicator {0} x'" by auto

  show "UNIV \<in> UNIV // B.communicating"
    using B_essential by (simp add: B.essential_class_def)
  then have "B.period UNIV = Gcd (B.period_set 0)"
    by (rule B.period_eq) simp
  also have "\<dots> = 1"
    by (rule Gcd_eq_one) (simp add: B.period_set_def B.p_Suc' B.p_0 eq measure_pmf_single pmf_positive_iff K_def set_pmf_bernoulli UNIV_bool)
  finally show "B.period UNIV = 1" .
qed

subsection {* The stationary distribution @{text N} *}

abbreviation N :: "nat pmf" where
  "N \<equiv> geometric_pmf (1 / 2)"

lemma stationary_distribution_N: "B.stationary_distribution N"
  unfolding B.stationary_distribution_def
proof (rule pmf_eqI)
  fix a show "pmf N a = pmf (bind_pmf N K) a"
    apply (simp add: pmf_bind K_def map_pmf_def)
    apply (subst integral_measure_pmf[of "{a - 1, a + 1}"])
    apply (auto split: split_indicator_asm nat.splits simp: minus_nat.diff_Suc)
    done
qed

lemma exclusive_N: "measure N (UNIV - UNIV) = 0"
  by simp

subsection {* Limit behavior and recurrence times *}

lemma limit: "(B.p i j) \<longlonglongrightarrow> (1/2)^Suc j"
proof -
  have "B.p i j \<longlonglongrightarrow> pmf N j"
    by (rule B.stationary_distribution_imp_p_limit[OF B_aperiodic B_essential _ stationary_distribution_N])
       auto
  then show ?thesis
    by (simp add: ac_simps)
qed

lemma pos_recurrent: "B.pos_recurrent i"
  using B.stationary_distributionD(1)[OF B_essential _ stationary_distribution_N _] by auto

lemma recurrence_time: "B.U' i i = 2^Suc i"
proof -
  have "B.stat UNIV = N"
    using B.stationary_distributionD(2)[OF B_essential _ stationary_distribution_N _] by simp
  then have "2^Suc i = 1 / emeasure (B.stat UNIV) {i}"
    by (simp add: one_divide_ereal field_simps emeasure_pmf_single pmf_eq_0_set_pmf)
  also have "\<dots> = B.U' i i"
    unfolding B.stat_def
    by (subst emeasure_point_measure_finite2)
       (simp_all add: nn_integral_nonneg divide_ereal_def inverse_ereal_ge0I B.U'_def)
  finally show ?thesis
    by simp
qed

end