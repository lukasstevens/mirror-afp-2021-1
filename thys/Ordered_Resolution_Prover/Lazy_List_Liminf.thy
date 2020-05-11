(*  Title:       Liminf of Lazy Lists
    Author:      Jasmin Blanchette <j.c.blanchette at vu.nl>, 2014, 2017
    Author:      Dmitriy Traytel <traytel at inf.ethz.ch>, 2014
    Maintainer:  Jasmin Blanchette <j.c.blanchette at vu.nl>
*)

section \<open>Liminf of Lazy Lists\<close>

theory Lazy_List_Liminf
  imports Coinductive.Coinductive_List
begin

text \<open>
Lazy lists, as defined in the \emph{Archive of Formal Proofs}, provide finite and infinite lists in
one type, defined coinductively. The present theory introduces the concept of the union of all
elements of a lazy list of sets and the limit of such a lazy list. The definitions are stated more
generally in terms of lattices. The basis for this theory is Section 4.1 (``Theorem Proving
Processes'') of Bachmair and Ganzinger's chapter.
\<close>

definition Sup_llist :: "'a set llist \<Rightarrow> 'a set" where
  "Sup_llist Xs = (\<Union>i \<in> {i. enat i < llength Xs}. lnth Xs i)"

lemma lnth_subset_Sup_llist: "enat i < llength xs \<Longrightarrow> lnth xs i \<subseteq> Sup_llist xs"
  unfolding Sup_llist_def by auto

lemma Sup_llist_LNil[simp]: "Sup_llist LNil = {}"
  unfolding Sup_llist_def by auto

lemma Sup_llist_LCons[simp]: "Sup_llist (LCons X Xs) = X \<union> Sup_llist Xs"
  unfolding Sup_llist_def
proof (intro subset_antisym subsetI)
  fix x
  assume "x \<in> (\<Union>i \<in> {i. enat i < llength (LCons X Xs)}. lnth (LCons X Xs) i)"
  then obtain i where len: "enat i < llength (LCons X Xs)" and nth: "x \<in> lnth (LCons X Xs) i"
    by blast
  from nth have "x \<in> X \<or> i > 0 \<and> x \<in> lnth Xs (i - 1)"
    by (metis lnth_LCons' neq0_conv)
  then have "x \<in> X \<or> (\<exists>i. enat i < llength Xs \<and> x \<in> lnth Xs i)"
    by (metis len Suc_pred' eSuc_enat iless_Suc_eq less_irrefl llength_LCons not_less order_trans)
  then show "x \<in> X \<union> (\<Union>i \<in> {i. enat i < llength Xs}. lnth Xs i)"
    by blast
qed ((auto)[], metis i0_lb lnth_0 zero_enat_def, metis Suc_ile_eq lnth_Suc_LCons)

lemma lhd_subset_Sup_llist: "\<not> lnull Xs \<Longrightarrow> lhd Xs \<subseteq> Sup_llist Xs"
  by (cases Xs) simp_all

definition Sup_upto_llist :: "'a set llist \<Rightarrow> nat \<Rightarrow> 'a set" where
  "Sup_upto_llist Xs j = (\<Union>i \<in> {i. enat i < llength Xs \<and> i \<le> j}. lnth Xs i)"

lemma Sup_upto_llist_0[simp]: "Sup_upto_llist Xs 0 = (if 0 < llength Xs then lnth Xs 0 else {})"
  unfolding Sup_upto_llist_def image_def by (simp add: enat_0)

lemma Sup_upto_llist_Suc[simp]:
  "Sup_upto_llist Xs (Suc j) =
   Sup_upto_llist Xs j \<union> (if enat (Suc j) < llength Xs then lnth Xs (Suc j) else {})"
  unfolding Sup_upto_llist_def image_def by (auto intro: le_SucI elim: le_SucE)

lemma Sup_upto_llist_mono: "j \<le> k \<Longrightarrow> Sup_upto_llist Xs j \<subseteq> Sup_upto_llist Xs k"
  unfolding Sup_upto_llist_def by auto

lemma Sup_upto_llist_subset_Sup_llist: "j \<le> k \<Longrightarrow> Sup_upto_llist Xs j \<subseteq> Sup_llist Xs"
  unfolding Sup_llist_def Sup_upto_llist_def by auto

lemma elem_Sup_llist_imp_Sup_upto_llist:
	"x \<in> Sup_llist Xs \<Longrightarrow> \<exists>j < llength Xs. x \<in> Sup_upto_llist Xs j"
  unfolding Sup_llist_def Sup_upto_llist_def by blast

lemma lnth_subset_Sup_upto_llist: "enat j < llength Xs \<Longrightarrow> lnth Xs j \<subseteq> Sup_upto_llist Xs j"
  unfolding Sup_upto_llist_def by auto

lemma finite_Sup_llist_imp_Sup_upto_llist:
  assumes "finite X" and "X \<subseteq> Sup_llist Xs"
  shows "\<exists>k. X \<subseteq> Sup_upto_llist Xs k"
  using assms
proof induct
  case (insert x X)
  then have x: "x \<in> Sup_llist Xs" and X: "X \<subseteq> Sup_llist Xs"
    by simp+
  from x obtain k where k: "x \<in> Sup_upto_llist Xs k"
    using elem_Sup_llist_imp_Sup_upto_llist by fast
  from X obtain k' where k': "X \<subseteq> Sup_upto_llist Xs k'"
    using insert.hyps(3) by fast
  have "insert x X \<subseteq> Sup_upto_llist Xs (max k k')"
    using k k'
    by (metis insert_absorb insert_subset Sup_upto_llist_mono max.cobounded2 max.commute
        order.trans)
  then show ?case
    by fast
qed simp

definition Liminf_llist :: "'a set llist \<Rightarrow> 'a set" where
  "Liminf_llist Xs =
   (\<Union>i \<in> {i. enat i < llength Xs}. \<Inter>j \<in> {j. i \<le> j \<and> enat j < llength Xs}. lnth Xs j)"

lemma Liminf_llist_LNil[simp]: "Liminf_llist LNil = {}"
  unfolding Liminf_llist_def by simp

lemma Liminf_llist_LCons:
  "Liminf_llist (LCons X Xs) = (if lnull Xs then X else Liminf_llist Xs)" (is "?lhs = ?rhs")
proof (cases "lnull Xs")
  case nnull: False
  show ?thesis
  proof
    {
      fix x
      assume "\<exists>i. enat i \<le> llength Xs
        \<and> (\<forall>j. i \<le> j \<and> enat j \<le> llength Xs \<longrightarrow> x \<in> lnth (LCons X Xs) j)"
      then have "\<exists>i. enat (Suc i) \<le> llength Xs
        \<and> (\<forall>j. Suc i \<le> j \<and> enat j \<le> llength Xs \<longrightarrow> x \<in> lnth (LCons X Xs) j)"
        by (cases "llength Xs",
            metis not_lnull_conv[THEN iffD1, OF nnull] Suc_le_D eSuc_enat eSuc_ile_mono
              llength_LCons not_less_eq_eq zero_enat_def zero_le,
            metis Suc_leD enat_ord_code(3))
      then have "\<exists>i. enat i < llength Xs \<and> (\<forall>j. i \<le> j \<and> enat j < llength Xs \<longrightarrow> x \<in> lnth Xs j)"
        by (metis Suc_ile_eq Suc_n_not_le_n lift_Suc_mono_le lnth_Suc_LCons nat_le_linear)
    }
    then show "?lhs \<subseteq> ?rhs"
      by (simp add: Liminf_llist_def nnull) (rule subsetI, simp)

    {
      fix x
      assume "\<exists>i. enat i < llength Xs \<and> (\<forall>j. i \<le> j \<and> enat j < llength Xs \<longrightarrow> x \<in> lnth Xs j)"
      then obtain i where
        i: "enat i < llength Xs" and
        j: "\<forall>j. i \<le> j \<and> enat j < llength Xs \<longrightarrow> x \<in> lnth Xs j"
        by blast

      have "enat (Suc i) \<le> llength Xs"
        using i by (simp add: Suc_ile_eq)
      moreover have "\<forall>j. Suc i \<le> j \<and> enat j \<le> llength Xs \<longrightarrow> x \<in> lnth (LCons X Xs) j"
        using Suc_ile_eq Suc_le_D j by force
      ultimately have "\<exists>i. enat i \<le> llength Xs \<and> (\<forall>j. i \<le> j \<and> enat j \<le> llength Xs \<longrightarrow>
        x \<in> lnth (LCons X Xs) j)"
        by blast
    }
    then show "?rhs \<subseteq> ?lhs"
      by (simp add: Liminf_llist_def nnull) (rule subsetI, simp)
  qed
qed (simp add: Liminf_llist_def enat_0_iff(1))

lemma lfinite_Liminf_llist: "lfinite Xs \<Longrightarrow> Liminf_llist Xs = (if lnull Xs then {} else llast Xs)"
proof (induction rule: lfinite_induct)
  case (LCons xs)
  then obtain y ys where
    xs: "xs = LCons y ys"
    by (meson not_lnull_conv)
  show ?case
    unfolding xs by (simp add: Liminf_llist_LCons LCons.IH[unfolded xs, simplified] llast_LCons)
qed (simp add: Liminf_llist_def)

lemma Liminf_llist_ltl: "\<not> lnull (ltl Xs) \<Longrightarrow> Liminf_llist Xs = Liminf_llist (ltl Xs)"
  by (metis Liminf_llist_LCons lhd_LCons_ltl lnull_ltlI)

lemma Liminf_llist_subset_Sup_llist: "Liminf_llist Xs \<subseteq> Sup_llist Xs"
  unfolding Liminf_llist_def Sup_llist_def by fast

lemma image_Liminf_llist_subset: "f ` Liminf_llist Ns \<subseteq> Liminf_llist (lmap ((`) f) Ns)"
  unfolding Liminf_llist_def by auto

lemma Liminf_llist_imp_exists_index:
  "x \<in> Liminf_llist Xs \<Longrightarrow> \<exists>i. enat i < llength Xs \<and> x \<in> lnth Xs i"
  unfolding Liminf_llist_def by auto

lemma Liminf_llist_lmap_image:
  assumes f_inj: "inj_on f (Sup_llist (lmap g xs))"
  shows "Liminf_llist (lmap (\<lambda>x. f ` g x) xs) = f ` Liminf_llist (lmap g xs)" (is "?lhs = ?rhs")
proof
  show "?lhs \<subseteq> ?rhs"
  proof
    fix x
    assume "x \<in> Liminf_llist (lmap (\<lambda>x. f ` g x) xs)"
    then obtain i where
      i_lt: "enat i < llength xs" and
      x_in_fgj: "\<forall>j. i \<le> j \<longrightarrow> enat j < llength xs \<longrightarrow> x \<in> f ` g (lnth xs j)"
      unfolding Liminf_llist_def by auto

    have ex_in_gi: "\<exists>y. y \<in> g (lnth xs i) \<and> x = f y"
      using f_inj i_lt x_in_fgj unfolding inj_on_def Sup_llist_def by auto
    have "\<exists>y. \<forall>j. i \<le> j \<longrightarrow> enat j < llength xs \<longrightarrow> y \<in> g (lnth xs j) \<and> x = f y"
      apply (rule exI[of _ "SOME y. y \<in> g (lnth xs i) \<and> x = f y"])
      using someI_ex[OF ex_in_gi] x_in_fgj f_inj i_lt x_in_fgj unfolding inj_on_def Sup_llist_def
      by simp (metis (no_types, lifting) imageE)
    then show "x \<in> f ` Liminf_llist (lmap g xs)"
      using i_lt unfolding Liminf_llist_def by auto
  qed
next
  show "?rhs \<subseteq> ?lhs"
    using image_Liminf_llist_subset[of f "lmap g xs", unfolded llist.map_comp] by auto
qed

lemma Liminf_llist_lmap_union:
  assumes "\<forall>x \<in> lset xs. \<forall>Y \<in> lset xs. g x \<inter> h Y = {}"
  shows "Liminf_llist (lmap (\<lambda>x. g x \<union> h x) xs) =
    Liminf_llist (lmap g xs) \<union> Liminf_llist (lmap h xs)" (is "?lhs = ?rhs")
proof (intro equalityI subsetI)
  fix x
  assume x_in: "x \<in> ?lhs"
  then obtain i where
    i_lt: "enat i < llength xs" and
    j: "\<forall>j. i \<le> j \<and> enat j < llength xs \<longrightarrow> x \<in> g (lnth xs j) \<or> x \<in> h (lnth xs j)"
    using x_in[unfolded Liminf_llist_def, simplified] by blast

  then have "(\<exists>i'. enat i' < llength xs \<and> (\<forall>j. i' \<le> j \<and> enat j < llength xs \<longrightarrow> x \<in> g (lnth xs j)))
     \<or> (\<exists>i'. enat i' < llength xs \<and> (\<forall>j. i' \<le> j \<and> enat j < llength xs \<longrightarrow> x \<in> h (lnth xs j)))"
    using assms[unfolded disjoint_iff_not_equal] by (metis in_lset_conv_lnth)
  then show "x \<in> ?rhs"
    unfolding Liminf_llist_def by simp
next
  fix x
  show "x \<in> ?rhs \<Longrightarrow> x \<in> ?lhs"
    using assms unfolding Liminf_llist_def by auto
qed

end
