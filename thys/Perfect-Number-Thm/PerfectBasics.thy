section{*Basics needed*}

theory PerfectBasics
imports Main "~~/src/HOL/Number_Theory/Primes" "~~/src/HOL/Algebra/Exponent"
begin

lemma setsum_mono2_nat: "finite (B::nat set) \<Longrightarrow> A <= B \<Longrightarrow> \<Sum> A <= \<Sum> B"
  by (auto simp add: setsum_mono2)


lemma exp_is_max_div:
   assumes m0:"m>0" and p: "prime p"
   shows "~ p dvd (m div (p^(exponent p m)))"
proof (rule ccontr)
 assume "~ ~ p dvd (m div (p^(exponent p m)))"
 hence a:"p dvd (m div (p^(exponent p m)))" by auto
 from m0 have "p^(exponent p m) dvd m" by (auto simp add: power_exponent_dvd)
 with a have "p*(p^exponent p m) dvd m"
   by (metis dvd_div_iff_mult mult_is_0)
 with p have "m=0" by (auto simp add: power_Suc_exponent_Not_dvd)
 with m0 show "False" by auto
qed

lemma coprime_exponent:
  assumes "prime p" and "m > 0"
  shows "coprime p (m div (p ^ exponent p m))"
proof (rule ccontr)
  assume "\<not> coprime p (m div p ^ exponent p m)"
  with \<open>prime p\<close> have "\<exists>q. prime q \<and> q dvd p \<and> q dvd m div p ^ exponent p m"
    by (metis dvd_refl prime_imp_coprime_nat)
  with \<open>prime p\<close> have "\<exists>q. q = p \<and> q dvd m div p ^ exponent p m"
    by (metis one_not_prime_nat prime_def)
  then have "p dvd m div p ^ exponent p m"
    by auto
  with assms show False
    by (auto simp add: exp_is_max_div)
qed

lemma add_mult_distrib_three: "(x::nat)*(a+b+c)=x*a+x*b+x*c" 
proof -
  have "(x::nat)*(a+b+c) = x*((a+b)+c)" by auto
  hence "x*(a+b+c) = x*(a+b)+x*c" by (metis add_mult_distrib2 add.commute add.left_commute)
  thus "x*(a+b+c) = x*a+x*b+x*c" by (metis add_mult_distrib2 add.commute add.left_commute) 
qed

lemma nat_interval_minus_zero: "{0..Suc n} = {0} Un {Suc 0..Suc n}" by auto
lemma nat_interval_minus_zero2:
 assumes "n>0"
 shows "{0..n} = {0} Un {Suc 0..n}" by (auto simp add: nat_interval_minus_zero)

theorem simplify_sum_of_powers: "(x - 1::nat) * (\<Sum>i=0 .. n . x^i)  = x^(n + 1) - 1" (is "?l = ?r")
proof (cases)
  assume "n = 0"
  thus "?l = x^(n+1) - 1" by auto
  next
  assume "n~=0"
  hence n0: "n>0" by auto 
  have "?l  = (x::nat)*(\<Sum>i=0 .. n . x^i) - (\<Sum>i=0 .. n . x^i)"
    by (metis diff_mult_distrib nat_mult_1)
  also have "... = (\<Sum>i=0 .. n . x^(Suc i))    - (\<Sum>i=0 .. n . x^i)"
    by (simp add: setsum_right_distrib)
  also have "... = (\<Sum>i=Suc 0 .. Suc n . x^i)  - (\<Sum>i=0 .. n . x^i)"
    by (metis setsum_shift_bounds_cl_Suc_ivl)
  also with n0
  have "... = ((\<Sum>i=Suc 0 .. n. x^i)+x^(Suc n)) - (x^0 + (\<Sum>i=Suc 0 .. n. x^i))"
    by (auto simp add: setsum.union_disjoint nat_interval_minus_zero2)
  finally show "?thesis" by auto
qed

end
