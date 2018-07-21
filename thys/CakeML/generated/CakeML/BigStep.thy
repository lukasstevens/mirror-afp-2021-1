chapter \<open>Generated by Lem from \<open>semantics/alt_semantics/bigStep.lem\<close>.\<close>

theory "BigStep" 

imports
  Main
  "LEM.Lem_pervasives_extra"
  "Lib"
  "Namespace"
  "Ast"
  "SemanticPrimitives"
  "Ffi"
  "SmallStep"

begin 

(*open import Pervasives_extra*)
(*open import Lib*)
(*open import Namespace*)
(*open import Ast*)
(*open import SemanticPrimitives*)
(*open import Ffi*)

(* To get the definition of expression divergence to use in defining definition
 * divergence *)
(*open import SmallStep*)

(* ------------------------ Big step semantics -------------------------- *)

(* If the first argument is true, the big step semantics counts down how many
   functions applications have happened, and raises an exception when the counter
   runs out. *)

inductive
evaluate_match  :: " bool \<Rightarrow>(v)sem_env \<Rightarrow> 'ffi state \<Rightarrow> v \<Rightarrow>(pat*exp)list \<Rightarrow> v \<Rightarrow> 'ffi state*((v),(v))result \<Rightarrow> bool "  
      and
evaluate_list  :: " bool \<Rightarrow>(v)sem_env \<Rightarrow> 'ffi state \<Rightarrow>(exp)list \<Rightarrow> 'ffi state*(((v)list),(v))result \<Rightarrow> bool "  
      and
evaluate  :: " bool \<Rightarrow>(v)sem_env \<Rightarrow> 'ffi state \<Rightarrow> exp \<Rightarrow> 'ffi state*((v),(v))result \<Rightarrow> bool "  where

"lit" : " \<And> ck env l s.

evaluate ck env s (Lit l) (s, Rval (Litv l))"

|

"raise1" : " \<And> ck env e s1 s2 v1.
evaluate ck s1 env e (s2, Rval v1)
==>
evaluate ck s1 env (Raise e) (s2, Rerr (Rraise v1))"

|

"raise2" : " \<And> ck env e s1 s2 err.
evaluate ck s1 env e (s2, Rerr err)
==>
evaluate ck s1 env (Raise e) (s2, Rerr err)"

|

"handle1" : " \<And> ck s1 s2 env e v1 pes.
evaluate ck s1 env e (s2, Rval v1)
==>
evaluate ck s1 env (Handle e pes) (s2, Rval v1)"

|

"handle2" : " \<And> ck s1 s2 env e pes v1 bv.
evaluate ck env s1 e (s2, Rerr (Rraise v1)) \<and>
evaluate_match ck env s2 v1 pes v1 bv
==>
evaluate ck env s1 (Handle e pes) bv "

|

"handle3" : " \<And> ck s1 s2 env e pes a.
evaluate ck env s1 e (s2, Rerr (Rabort a))
==>
evaluate ck env s1 (Handle e pes) (s2, Rerr (Rabort a))"

|

"con1" : " \<And> ck env cn es vs s s' v1.
do_con_check(c   env) cn (List.length es) \<and>
((build_conv(c   env) cn (List.rev vs) = Some v1) \<and>
evaluate_list ck env s (List.rev es) (s', Rval vs))
==>
evaluate ck env s (Con cn es) (s', Rval v1)"

|

"con2" : " \<And> ck env cn es s.
\<not> (do_con_check(c   env) cn (List.length es))
==>
evaluate ck env s (Con cn es) (s, Rerr (Rabort Rtype_error))"

|

"con3" : " \<And> ck env cn es err s s'.
do_con_check(c   env) cn (List.length es) \<and>
evaluate_list ck env s (List.rev es) (s', Rerr err)
==>
evaluate ck env s (Con cn es) (s', Rerr err)"

|

"var1" : " \<And> ck env n v1 s.
nsLookup(v   env) n = Some v1
==>
evaluate ck env s (Var n) (s, Rval v1)"

|

"var2" : " \<And> ck env n s.
nsLookup(v   env) n = None
==>
evaluate ck env s (Var n) (s, Rerr (Rabort Rtype_error))"

|

"fn" : " \<And> ck env n e s.

evaluate ck env s (Fun n e) (s, Rval (Closure env n e))"

|

"app1" : " \<And> ck env es vs env' e bv s1 s2.
evaluate_list ck env s1 (List.rev es) (s2, Rval vs) \<and>
((do_opapp (List.rev vs) = Some (env', e)) \<and>
((ck \<longrightarrow> \<not> ((clock   s2) =(( 0 :: nat)))) \<and>
evaluate ck env' (if ck then ( s2 (| clock := ((clock   s2) -( 1 :: nat)) |)) else s2) e bv))
==>
evaluate ck env s1 (App Opapp es) bv "

|

"app2" : " \<And> ck env es vs env' e s1 s2.
evaluate_list ck env s1 (List.rev es) (s2, Rval vs) \<and>
((do_opapp (List.rev vs) = Some (env', e)) \<and>
(((clock   s2) =( 0 :: nat)) \<and>
ck))
==>
evaluate ck env s1 (App Opapp es) (s2, Rerr (Rabort Rtimeout_error))"

|

"app3" : " \<And> ck env es vs s1 s2.
evaluate_list ck env s1 (List.rev es) (s2, Rval vs) \<and>
(do_opapp (List.rev vs) = None)
==>
evaluate ck env s1 (App Opapp es) (s2, Rerr (Rabort Rtype_error))"

|

"app4" : " \<And> ck env op0 es vs res s1 s2 refs' ffi'.
evaluate_list ck env s1 (List.rev es) (s2, Rval vs) \<and>
((do_app ((refs   s2),(ffi   s2)) op0 (List.rev vs) = Some ((refs',ffi'), res)) \<and>
(op0 \<noteq> Opapp))
==>
evaluate ck env s1 (App op0 es) (( s2 (| refs := refs', ffi :=ffi' |)), res)"

|

"app5" : " \<And> ck env op0 es vs s1 s2.
evaluate_list ck env s1 (List.rev es) (s2, Rval vs) \<and>
((do_app ((refs   s2),(ffi   s2)) op0 (List.rev vs) = None) \<and>
(op0 \<noteq> Opapp))
==>
evaluate ck env s1 (App op0 es) (s2, Rerr (Rabort Rtype_error))"

|

"app6" : " \<And> ck env op0 es err s1 s2.
evaluate_list ck env s1 (List.rev es) (s2, Rerr err)
==>
evaluate ck env s1 (App op0 es) (s2, Rerr err)"

|

"log1" : " \<And> ck env op0 e1 e2 v1 e' bv s1 s2.
evaluate ck env s1 e1 (s2, Rval v1) \<and>
((do_log op0 v1 e2 = Some (Exp e')) \<and>
evaluate ck env s2 e' bv)
==>
evaluate ck env s1 (Log op0 e1 e2) bv "

|

"log2" : " \<And> ck env op0 e1 e2 v1 bv s1 s2.
evaluate ck env s1 e1 (s2, Rval v1) \<and>
(do_log op0 v1 e2 = Some (Val bv))
==>
evaluate ck env s1 (Log op0 e1 e2) (s2, Rval bv)"

|

"log3" : " \<And> ck env op0 e1 e2 v1 s1 s2.
evaluate ck env s1 e1 (s2, Rval v1) \<and>
(do_log op0 v1 e2 = None)
==>
evaluate ck env s1 (Log op0 e1 e2) (s2, Rerr (Rabort Rtype_error))"

|

"log4" : " \<And> ck env op0 e1 e2 err s s'.
evaluate ck env s e1 (s', Rerr err)
==>
evaluate ck env s (Log op0 e1 e2) (s', Rerr err)"

|

"if1" : " \<And> ck env e1 e2 e3 v1 e' bv s1 s2.
evaluate ck env s1 e1 (s2, Rval v1) \<and>
((do_if v1 e2 e3 = Some e') \<and>
evaluate ck env s2 e' bv)
==>
evaluate ck env s1 (If e1 e2 e3) bv "

|

"if2" : " \<And> ck env e1 e2 e3 v1 s1 s2.
evaluate ck env s1 e1 (s2, Rval v1) \<and>
(do_if v1 e2 e3 = None)
==>
evaluate ck env s1 (If e1 e2 e3) (s2, Rerr (Rabort Rtype_error))"

|

"if3" : " \<And> ck env e1 e2 e3 err s s'.
evaluate ck env s e1 (s', Rerr err)
==>
evaluate ck env s (If e1 e2 e3) (s', Rerr err)"

|

"mat1" : " \<And> ck env e pes v1 bv s1 s2.
evaluate ck env s1 e (s2, Rval v1) \<and>
evaluate_match ck env s2 v1 pes (Conv (Some ((''Bind''), TypeExn (Short (''Bind'')))) []) bv
==>
evaluate ck env s1 (Mat e pes) bv "

|

"mat2" : " \<And> ck env e pes err s s'.
evaluate ck env s e (s', Rerr err)
==>
evaluate ck env s (Mat e pes) (s', Rerr err)"

|

"let1" : " \<And> ck env n e1 e2 v1 bv s1 s2.
evaluate ck env s1 e1 (s2, Rval v1) \<and>
evaluate ck ( env (| v := (nsOptBind n v1(v   env)) |)) s2 e2 bv
==>
evaluate ck env s1 (Let n e1 e2) bv "

|

"let2" : " \<And> ck env n e1 e2 err s s'.
evaluate ck env s e1 (s', Rerr err)
==>
evaluate ck env s (Let n e1 e2) (s', Rerr err)"

|

"letrec1" : " \<And> ck env funs e bv s.
Lem_list.allDistinct (List.map ( \<lambda>x .  
  (case  x of (x,y,z) => x )) funs) \<and>
evaluate ck ( env (| v := (build_rec_env funs env(v   env)) |)) s e bv
==>
evaluate ck env s (Letrec funs e) bv "

|

"letrec2" : " \<And> ck env funs e s.
\<not> (Lem_list.allDistinct (List.map ( \<lambda>x .  
  (case  x of (x,y,z) => x )) funs))
==>
evaluate ck env s (Letrec funs e) (s, Rerr (Rabort Rtype_error))"

|

"tannot" : " \<And> ck env e t0 s bv.
evaluate ck env s e bv
==>
evaluate ck env s (Tannot e t0) bv "

|

"locannot" : " \<And> ck env e l s bv.
evaluate ck env s e bv
==>
evaluate ck env s (Lannot e l) bv "

|

"empty" : " \<And> ck env s.

evaluate_list ck env s [] (s, Rval [])"

|

"cons1" : " \<And> ck env e es v1 vs s1 s2 s3.
evaluate ck env s1 e (s2, Rval v1) \<and>
evaluate_list ck env s2 es (s3, Rval vs)
==>
evaluate_list ck env s1 (e # es) (s3, Rval (v1 # vs))"

|

"cons2" : " \<And> ck env e es err s s'.
evaluate ck env s e (s', Rerr err)
==>
evaluate_list ck env s (e # es) (s', Rerr err)"

|

"cons3" : " \<And> ck env e es v1 err s1 s2 s3.
evaluate ck env s1 e (s2, Rval v1) \<and>
evaluate_list ck env s2 es (s3, Rerr err)
==>
evaluate_list ck env s1 (e # es) (s3, Rerr err)"

|

"mat_empty" : " \<And> ck env v1 err_v s.

evaluate_match ck env s v1 [] err_v (s, Rerr (Rraise err_v))"

|

"mat_cons1" : " \<And> ck env env' v1 p pes e bv err_v s.
Lem_list.allDistinct (pat_bindings p []) \<and>
((pmatch(c   env)(refs   s) p v1 [] = Match env') \<and>
evaluate ck ( env (| v := (nsAppend (alist_to_ns env')(v   env)) |)) s e bv)
==>
evaluate_match ck env s v1 ((p,e)# pes) err_v bv "

|

"mat_cons2" : " \<And> ck env v1 p e pes bv s err_v.
Lem_list.allDistinct (pat_bindings p []) \<and>
((pmatch(c   env)(refs   s) p v1 [] = No_match) \<and>
evaluate_match ck env s v1 pes err_v bv)
==>
evaluate_match ck env s v1 ((p,e)# pes) err_v bv "

|

"mat_cons3" : " \<And> ck env v1 p e pes s err_v.
pmatch(c   env)(refs   s) p v1 [] = Match_type_error
==>
evaluate_match ck env s v1 ((p,e)# pes) err_v (s, Rerr (Rabort Rtype_error))"

|

"mat_cons4" : " \<And> ck env v1 p e pes s err_v.
\<not> (Lem_list.allDistinct (pat_bindings p []))
==>
evaluate_match ck env s v1 ((p,e)# pes) err_v (s, Rerr (Rabort Rtype_error))"

(* The set tid_or_exn part of the state tracks all of the types and exceptions
 * that have been declared *)
inductive
evaluate_dec  :: " bool \<Rightarrow>(modN)list \<Rightarrow>(v)sem_env \<Rightarrow> 'ffi state \<Rightarrow> dec \<Rightarrow> 'ffi state*(((v)sem_env),(v))result \<Rightarrow> bool "  where

"dlet1" : " \<And> ck mn env p e v1 env' s1 s2 locs.
evaluate ck env s1 e (s2, Rval v1) \<and>
(Lem_list.allDistinct (pat_bindings p []) \<and>
(pmatch(c   env)(refs   s2) p v1 [] = Match env'))
==>
evaluate_dec ck mn env s1 (Dlet locs p e) (s2, Rval (| v = (alist_to_ns env'), c = nsEmpty |))"

|

"dlet2" : " \<And> ck mn env p e v1 s1 s2 locs.
evaluate ck env s1 e (s2, Rval v1) \<and>
(Lem_list.allDistinct (pat_bindings p []) \<and>
(pmatch(c   env)(refs   s2) p v1 [] = No_match))
==>
evaluate_dec ck mn env s1 (Dlet locs p e) (s2, Rerr (Rraise Bindv))"

|

"dlet3" : " \<And> ck mn env p e v1 s1 s2 locs.
evaluate ck env s1 e (s2, Rval v1) \<and>
(Lem_list.allDistinct (pat_bindings p []) \<and>
(pmatch(c   env)(refs   s2) p v1 [] = Match_type_error))
==>
evaluate_dec ck mn env s1 (Dlet locs p e) (s2, Rerr (Rabort Rtype_error))"

|

"dlet4" : " \<And> ck mn env p e s locs.
\<not> (Lem_list.allDistinct (pat_bindings p []))
==>
evaluate_dec ck mn env s (Dlet locs p e) (s, Rerr (Rabort Rtype_error))"

|

"dlet5" : " \<And> ck mn env p e err s s' locs.
evaluate ck env s e (s', Rerr err) \<and>
Lem_list.allDistinct (pat_bindings p [])
==>
evaluate_dec ck mn env s (Dlet locs p e) (s', Rerr err)"

|

"dletrec1" : " \<And> ck mn env funs s locs.
Lem_list.allDistinct (List.map ( \<lambda>x .  
  (case  x of (x,y,z) => x )) funs)
==>
evaluate_dec ck mn env s (Dletrec locs funs) (s, Rval (| v = (build_rec_env funs env nsEmpty), c = nsEmpty |))"

|

"dletrec2" : " \<And> ck mn env funs s locs.
\<not> (Lem_list.allDistinct (List.map ( \<lambda>x .  
  (case  x of (x,y,z) => x )) funs))
==>
evaluate_dec ck mn env s (Dletrec locs funs) (s, Rerr (Rabort Rtype_error))"

|

"dtype1" : " \<And> ck mn env tds s new_tdecs locs.
check_dup_ctors tds \<and>
((new_tdecs = type_defs_to_new_tdecs mn tds) \<and>
((% M N. M \<inter> N = {}) new_tdecs(defined_types   s) \<and>
Lem_list.allDistinct (List.map ( \<lambda>x .  
  (case  x of (tvs,tn,ctors) => tn )) tds)))
==>
evaluate_dec ck mn env s (Dtype locs tds) (( s (| defined_types := (new_tdecs \<union>(defined_types   s)) |)), Rval (| v = nsEmpty, c = (build_tdefs mn tds) |))"

|

"dtype2" : " \<And> ck mn env tds s locs.
\<not> (check_dup_ctors tds) \<or>
(\<not> ((% M N. M \<inter> N = {}) (type_defs_to_new_tdecs mn tds)(defined_types   s)) \<or>
\<not> (Lem_list.allDistinct (List.map ( \<lambda>x .  
  (case  x of (tvs,tn,ctors) => tn )) tds)))
==>
evaluate_dec ck mn env s (Dtype locs tds) (s, Rerr (Rabort Rtype_error))"

|

"dtabbrev" : " \<And> ck mn env tvs tn t0 s locs.

evaluate_dec ck mn env s (Dtabbrev locs tvs tn t0) (s, Rval (| v = nsEmpty, c = nsEmpty |))"

|

"dexn1" : " \<And> ck mn env cn ts s locs.
\<not> (TypeExn (mk_id mn cn) \<in>(defined_types   s))
==>
evaluate_dec ck mn env s (Dexn locs cn ts) (( s (| defined_types := ({TypeExn (mk_id mn cn)} \<union>(defined_types   s)) |)), Rval  (| v = nsEmpty, c = (nsSing cn (List.length ts, TypeExn (mk_id mn cn))) |))"

|

"dexn2" : " \<And> ck mn env cn ts s locs.
TypeExn (mk_id mn cn) \<in>(defined_types   s)
==>
evaluate_dec ck mn env s (Dexn locs cn ts) (s, Rerr (Rabort Rtype_error))"

inductive
evaluate_decs  :: " bool \<Rightarrow>(modN)list \<Rightarrow>(v)sem_env \<Rightarrow> 'ffi state \<Rightarrow>(dec)list \<Rightarrow> 'ffi state*(((v)sem_env),(v))result \<Rightarrow> bool "  where

"empty" : " \<And> ck mn env s.

evaluate_decs ck mn env s [] (s, Rval (| v = nsEmpty, c = nsEmpty |))"

|

"cons1" : " \<And> ck mn s1 s2 env d ds e.
evaluate_dec ck mn env s1 d (s2, Rerr e)
==>
evaluate_decs ck mn env s1 (d # ds) (s2, Rerr e)"

|

"cons2" : " \<And> ck mn s1 s2 s3 env d ds new_env r.
evaluate_dec ck mn env s1 d (s2, Rval new_env) \<and>
evaluate_decs ck mn (extend_dec_env new_env env) s2 ds (s3, r)
==>
evaluate_decs ck mn env s1 (d # ds) (s3, combine_dec_result new_env r)"

inductive
evaluate_top  :: " bool \<Rightarrow>(v)sem_env \<Rightarrow> 'ffi state \<Rightarrow> top0 \<Rightarrow> 'ffi state*(((v)sem_env),(v))result \<Rightarrow> bool "  where

"tdec1" : " \<And> ck s1 s2 env d new_env.
evaluate_dec ck [] env s1 d (s2, Rval new_env)
==>
evaluate_top ck env s1 (Tdec d) (s2, Rval new_env)"
|

"tdec2" : " \<And> ck s1 s2 env d err.
evaluate_dec ck [] env s1 d (s2, Rerr err)
==>
evaluate_top ck env s1 (Tdec d) (s2, Rerr err)"

|

"tmod1" : " \<And> ck s1 s2 env ds mn specs new_env.
\<not> ([mn] \<in>(defined_mods   s1)) \<and>
(no_dup_types ds \<and>
evaluate_decs ck [mn] env s1 ds (s2, Rval new_env))
==>
evaluate_top ck env s1 (Tmod mn specs ds) (( s2 (| defined_mods := ({[mn]} \<union>(defined_mods   s2)) |)), Rval (| v = (nsLift mn(v   new_env)), c = (nsLift mn(c   new_env)) |))"

|

"tmod2" : " \<And> ck s1 s2 env ds mn specs err.
\<not> ([mn] \<in>(defined_mods   s1)) \<and>
(no_dup_types ds \<and>
evaluate_decs ck [mn] env s1 ds (s2, Rerr err))
==>
evaluate_top ck env s1 (Tmod mn specs ds) (( s2 (| defined_mods := ({[mn]} \<union>(defined_mods   s2)) |)), Rerr err)"

|

"tmod3" : " \<And> ck s1 env ds mn specs.
\<not> (no_dup_types ds)
==>
evaluate_top ck env s1 (Tmod mn specs ds) (s1, Rerr (Rabort Rtype_error))"

|

"tmod4" : " \<And> ck env s mn specs ds.
[mn] \<in>(defined_mods   s)
==>
evaluate_top ck env s (Tmod mn specs ds) (s, Rerr (Rabort Rtype_error))"

inductive
evaluate_prog  :: " bool \<Rightarrow>(v)sem_env \<Rightarrow> 'ffi state \<Rightarrow> prog \<Rightarrow> 'ffi state*(((v)sem_env),(v))result \<Rightarrow> bool "  where

"empty" : " \<And> ck env s.

evaluate_prog ck env s [] (s, Rval (| v = nsEmpty, c = nsEmpty |))"

|

"cons1" : " \<And> ck s1 s2 s3 env top0 tops new_env r.
evaluate_top ck env s1 top0 (s2, Rval new_env) \<and>
evaluate_prog ck (extend_dec_env new_env env) s2 tops (s3,r)
==>
evaluate_prog ck env s1 (top0 # tops) (s3, combine_dec_result new_env r)"

|

"cons2" : " \<And> ck s1 s2 env top0 tops err.
evaluate_top ck env s1 top0 (s2, Rerr err)
==>
evaluate_prog ck env s1 (top0 # tops) (s2, Rerr err)"


(*val evaluate_whole_prog : forall 'ffi. Eq 'ffi => bool -> sem_env v -> state 'ffi -> prog ->
          state 'ffi * result (sem_env v) v -> bool*)
fun evaluate_whole_prog  :: " bool \<Rightarrow>(v)sem_env \<Rightarrow> 'ffi state \<Rightarrow>(top0)list \<Rightarrow> 'ffi state*(((v)sem_env),(v))result \<Rightarrow> bool "  where 
     " evaluate_whole_prog ck env s1 tops (s2, res) = (
  if no_dup_mods tops(defined_mods   s1) \<and> no_dup_top_types tops(defined_types   s1) then
    evaluate_prog ck env s1 tops (s2, res)
  else
    (s1 = s2) \<and> (res = Rerr (Rabort Rtype_error)))"


(*val dec_diverges : forall 'ffi. sem_env v -> state 'ffi -> dec -> bool*)
fun dec_diverges  :: "(v)sem_env \<Rightarrow> 'ffi state \<Rightarrow> dec \<Rightarrow> bool "  where 
     " dec_diverges env st (Dlet locs p e) = ( Lem_list.allDistinct (pat_bindings p []) \<and> e_diverges env ((refs   st),(ffi   st)) e )"
|" dec_diverges env st (Dletrec locs funs) = ( False )"
|" dec_diverges env st (Dtype locs tds) = ( False )"
|" dec_diverges env st (Dtabbrev locs tvs tn t1) = ( False )"
|" dec_diverges env st (Dexn locs cn ts) = ( False )"


inductive
decs_diverges  :: "(modN)list \<Rightarrow>(v)sem_env \<Rightarrow> 'ffi state \<Rightarrow> decs \<Rightarrow> bool "  where

"cons1" : " \<And> mn st env d ds.
dec_diverges env st d
==>
decs_diverges mn env st (d # ds)"

|

"cons2" : " \<And> mn s1 s2 env d ds new_env.
evaluate_dec False mn env s1 d (s2, Rval new_env) \<and>
decs_diverges mn (extend_dec_env new_env env) s2 ds
==>
decs_diverges mn env s1 (d # ds)"

inductive
top_diverges  :: "(v)sem_env \<Rightarrow> 'ffi state \<Rightarrow> top0 \<Rightarrow> bool "  where

"tdec" : " \<And> st env d.
dec_diverges env st d
==>
top_diverges env st (Tdec d)"

|

"tmod" : " \<And> env s1 ds mn specs.
\<not> ([mn] \<in>(defined_mods   s1)) \<and>
(no_dup_types ds \<and>
decs_diverges [mn] env s1 ds)
==>
top_diverges env s1 (Tmod mn specs ds)"

inductive
prog_diverges  :: "(v)sem_env \<Rightarrow> 'ffi state \<Rightarrow> prog \<Rightarrow> bool "  where

"cons1" : " \<And> st env top0 tops.
top_diverges env st top0
==>
prog_diverges env st (top0 # tops)"

|

"cons2" : " \<And> s1 s2 env top0 tops new_env.
evaluate_top False env s1 top0 (s2, Rval new_env) \<and>
prog_diverges (extend_dec_env new_env env) s2 tops
==>
prog_diverges env s1 (top0 # tops)"
end
