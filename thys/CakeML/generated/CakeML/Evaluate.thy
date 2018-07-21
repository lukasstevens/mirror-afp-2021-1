chapter \<open>Generated by Lem from \<open>semantics/evaluate.lem\<close>.\<close>

theory "Evaluate" 

imports
  Main
  "LEM.Lem_pervasives_extra"
  "Lib"
  "Namespace"
  "Ast"
  "SemanticPrimitives"
  "Ffi"

begin 

(*open import Pervasives_extra*)
(*open import Lib*)
(*open import Ast*)
(*open import Namespace*)
(*open import SemanticPrimitives*)
(*open import Ffi*)

(* The semantics is defined here using fix_clock so that HOL4 generates
 * provable termination conditions. However, after termination is proved, we
 * clean up the definition (in HOL4) to remove occurrences of fix_clock. *)

fun fix_clock  :: " 'a state \<Rightarrow> 'b state*'c \<Rightarrow> 'b state*'c "  where 
     " fix_clock s (s',res) = (
  (( s' (| clock := (if(clock   s') \<le>(clock   s)
                     then(clock   s') else(clock   s)) |)),res))"


definition dec_clock  :: " 'a state \<Rightarrow> 'a state "  where 
     " dec_clock s = ( ( s (| clock := ((clock   s) -( 1 :: nat)) |)))"


(* list_result is equivalent to map_result (v. [v]) I, where map_result is
 * defined in evalPropsTheory *)
fun 
list_result  :: "('a,'b)result \<Rightarrow>(('a list),'b)result "  where 
     "
list_result (Rval v2) = ( Rval [v2])"
|"
list_result (Rerr e) = ( Rerr e )"


(*val evaluate : forall 'ffi. state 'ffi -> sem_env v -> list exp -> state 'ffi * result (list v) v*)
(*val evaluate_match : forall 'ffi. state 'ffi -> sem_env v -> v -> list (pat * exp) -> v -> state 'ffi * result (list v) v*)
function (sequential,domintros) 
fun_evaluate_match  :: " 'ffi state \<Rightarrow>(v)sem_env \<Rightarrow> v \<Rightarrow>(pat*exp)list \<Rightarrow> v \<Rightarrow> 'ffi state*(((v)list),(v))result "  
                   and
fun_evaluate  :: " 'ffi state \<Rightarrow>(v)sem_env \<Rightarrow>(exp)list \<Rightarrow> 'ffi state*(((v)list),(v))result "  where 
     "
fun_evaluate st env [] = ( (st, Rval []))"
|"
fun_evaluate st env (e1 # e2 # es) = (
  (case  fix_clock st (fun_evaluate st env [e1]) of
    (st', Rval v1) =>
      (case  fun_evaluate st' env (e2 # es) of
        (st'', Rval vs) => (st'', Rval (List.hd v1 # vs))
      | res => res
      )
  | res => res
  ))"
|"
fun_evaluate st env [Lit l] = ( (st, Rval [Litv l]))"
|"
fun_evaluate st env [Raise e] = (
  (case  fun_evaluate st env [e] of
    (st', Rval v2) => (st', Rerr (Rraise (List.hd v2)))
  | res => res
  ))"
|"
fun_evaluate st env [Handle e pes] = (
  (case  fix_clock st (fun_evaluate st env [e]) of
    (st', Rerr (Rraise v2)) => fun_evaluate_match st' env v2 pes v2
  | res => res
  ))"
|"
fun_evaluate st env [Con cn es] = (
  if do_con_check(c   env) cn (List.length es) then
    (case  fun_evaluate st env (List.rev es) of
      (st', Rval vs) =>
        (case  build_conv(c   env) cn (List.rev vs) of
          Some v2 => (st', Rval [v2])
        | None => (st', Rerr (Rabort Rtype_error))
        )
    | res => res
    )
  else (st, Rerr (Rabort Rtype_error)))"
|"
fun_evaluate st env [Var n] = (
  (case  nsLookup(v   env) n of
    Some v2 => (st, Rval [v2])
  | None => (st, Rerr (Rabort Rtype_error))
  ))"
|"
fun_evaluate st env [Fun x e] = ( (st, Rval [Closure env x e]))"
|"
fun_evaluate st env [App op1 es] = (
  (case  fix_clock st (fun_evaluate st env (List.rev es)) of
    (st', Rval vs) =>
      if op1 = Opapp then
        (case  do_opapp (List.rev vs) of
          Some (env',e) =>
            if(clock   st') =( 0 :: nat) then
              (st', Rerr (Rabort Rtimeout_error))
            else
              fun_evaluate (dec_clock st') env' [e]
        | None => (st', Rerr (Rabort Rtype_error))
        )
      else
        (case  do_app ((refs   st'),(ffi   st')) op1 (List.rev vs) of
          Some ((refs1,ffi1),r) => (( st' (| refs := refs1, ffi := ffi1 |)), list_result r)
        | None => (st', Rerr (Rabort Rtype_error))
        )
  | res => res
  ))"
|"
fun_evaluate st env [Log lop e1 e2] = (
  (case  fix_clock st (fun_evaluate st env [e1]) of
    (st', Rval v1) =>
      (case  do_log lop (List.hd v1) e2 of
        Some (Exp e) => fun_evaluate st' env [e]
      | Some (Val v2) => (st', Rval [v2])
      | None => (st', Rerr (Rabort Rtype_error))
      )
  | res => res
  ))"
|"
fun_evaluate st env [If e1 e2 e3] = (
  (case  fix_clock st (fun_evaluate st env [e1]) of
    (st', Rval v2) =>
      (case  do_if (List.hd v2) e2 e3 of
        Some e => fun_evaluate st' env [e]
      | None => (st', Rerr (Rabort Rtype_error))
      )
  | res => res
  ))"
|"
fun_evaluate st env [Mat e pes] = (
  (case  fix_clock st (fun_evaluate st env [e]) of
    (st', Rval v2) =>
      fun_evaluate_match st' env (List.hd v2) pes Bindv
  | res => res
  ))"
|"
fun_evaluate st env [Let xo e1 e2] = (
  (case  fix_clock st (fun_evaluate st env [e1]) of
    (st', Rval v2) => fun_evaluate st' ( env (| v := (nsOptBind xo (List.hd v2)(v   env)) |)) [e2]
  | res => res
  ))"
|"
fun_evaluate st env [Letrec funs e] = (
  if allDistinct (List.map ( \<lambda>x .  
  (case  x of (x,y,z) => x )) funs) then
    fun_evaluate st ( env (| v := (build_rec_env funs env(v   env)) |)) [e]
  else
    (st, Rerr (Rabort Rtype_error)))"
|"
fun_evaluate st env [Tannot e t1] = (
  fun_evaluate st env [e])"
|"
fun_evaluate st env [Lannot e l] = (
  fun_evaluate st env [e])"
|"
fun_evaluate_match st env v2 [] err_v = ( (st, Rerr (Rraise err_v)))"
|"
fun_evaluate_match st env v2 ((p,e)# pes) err_v  = (
  if allDistinct (pat_bindings p []) then
    (case  pmatch(c   env)(refs   st) p v2 [] of
      Match env_v' => fun_evaluate st ( env (| v := (nsAppend (alist_to_ns env_v')(v   env)) |)) [e]
    | No_match => fun_evaluate_match st env v2 pes err_v
    | Match_type_error => (st, Rerr (Rabort Rtype_error))
    )
  else (st, Rerr (Rabort Rtype_error)))" 
by pat_completeness auto


(*val evaluate_decs :
  forall 'ffi. list modN -> state 'ffi -> sem_env v -> list dec -> state 'ffi * result (sem_env v) v*)
fun 
fun_evaluate_decs  :: "(string)list \<Rightarrow> 'ffi state \<Rightarrow>(v)sem_env \<Rightarrow>(dec)list \<Rightarrow> 'ffi state*(((v)sem_env),(v))result "  where 
     "
fun_evaluate_decs mn st env [] = ( (st, Rval (| v = nsEmpty, c = nsEmpty |)))"
|"
fun_evaluate_decs mn st env (d1 # d2 # ds) = (
  (case  fun_evaluate_decs mn st env [d1] of
    (st1, Rval env1) =>
    (case  fun_evaluate_decs mn st1 (extend_dec_env env1 env) (d2 # ds) of
      (st2,r) => (st2, combine_dec_result env1 r)
    )
  | res => res
  ))"
|"
fun_evaluate_decs mn st env [Dlet locs p e] = (
  if allDistinct (pat_bindings p []) then
    (case  fun_evaluate st env [e] of
      (st', Rval v2) =>
        (st',
         (case  pmatch(c   env)(refs   st') p (List.hd v2) [] of
           Match new_vals => Rval (| v = (alist_to_ns new_vals), c = nsEmpty |)
         | No_match => Rerr (Rraise Bindv)
         | Match_type_error => Rerr (Rabort Rtype_error)
         ))
    | (st', Rerr err) => (st', Rerr err)
    )
  else
    (st, Rerr (Rabort Rtype_error)))"
|"
fun_evaluate_decs mn st env [Dletrec locs funs] = (
  (st,
   (if allDistinct (List.map ( \<lambda>x .  
  (case  x of (x,y,z) => x )) funs) then
     Rval (| v = (build_rec_env funs env nsEmpty), c = nsEmpty |)
   else
     Rerr (Rabort Rtype_error))))"
|"
fun_evaluate_decs mn st env [Dtype locs tds] = (
  (let new_tdecs = (type_defs_to_new_tdecs mn tds) in
    if check_dup_ctors tds \<and>
       ((% M N. M \<inter> N = {}) new_tdecs(defined_types   st) \<and>
       allDistinct (List.map ( \<lambda>x .  
  (case  x of (tvs,tn,ctors) => tn )) tds))
    then
      (( st (| defined_types := (new_tdecs \<union>(defined_types   st)) |)),
       Rval (| v = nsEmpty, c = (build_tdefs mn tds) |))
    else
      (st, Rerr (Rabort Rtype_error))))"
|"
fun_evaluate_decs mn st env [Dtabbrev locs tvs tn t1] = (
  (st, Rval (| v = nsEmpty, c = nsEmpty |)))"
|"
fun_evaluate_decs mn st env [Dexn locs cn ts] = (
  if TypeExn (mk_id mn cn) \<in>(defined_types   st) then
    (st, Rerr (Rabort Rtype_error))
  else
    (( st (| defined_types := ({TypeExn (mk_id mn cn)} \<union>(defined_types   st)) |)),
     Rval (| v = nsEmpty, c = (nsSing cn (List.length ts, TypeExn (mk_id mn cn))) |)))"


definition envLift  :: " string \<Rightarrow> 'a sem_env \<Rightarrow> 'a sem_env "  where 
     " envLift mn env = (
  (| v = (nsLift mn(v   env)), c = (nsLift mn(c   env)) |) )"


(*val evaluate_tops :
  forall 'ffi. state 'ffi -> sem_env v -> list top -> state 'ffi *  result (sem_env v) v*)
fun 
evaluate_tops  :: " 'ffi state \<Rightarrow>(v)sem_env \<Rightarrow>(top0)list \<Rightarrow> 'ffi state*(((v)sem_env),(v))result "  where 
     "
evaluate_tops st env [] = ( (st, Rval (| v = nsEmpty, c = nsEmpty |)))"
|"
evaluate_tops st env (top1 # top2 # tops) = (
  (case  evaluate_tops st env [top1] of
    (st1, Rval env1) =>
      (case  evaluate_tops st1 (extend_dec_env env1 env) (top2 # tops) of
        (st2, r) => (st2, combine_dec_result env1 r)
      )
  | res => res
  ))"
|"
evaluate_tops st env [Tdec d] = ( fun_evaluate_decs [] st env [d])"
|"
evaluate_tops st env [Tmod mn specs ds] = (
  if \<not> ([mn] \<in>(defined_mods   st)) \<and> no_dup_types ds
  then
    (case  fun_evaluate_decs [mn] st env ds of
      (st', r) =>
        (( st' (| defined_mods := ({[mn]} \<union>(defined_mods   st')) |)),
         (case  r of
           Rval env' => Rval (| v = (nsLift mn(v   env')), c = (nsLift mn(c   env')) |)
         | Rerr err => Rerr err
         ))
    )
  else
    (st, Rerr (Rabort Rtype_error)))"


(*val evaluate_prog : forall 'ffi. state 'ffi -> sem_env v -> prog -> state 'ffi * result (sem_env v) v*)
definition
fun_evaluate_prog  :: " 'ffi state \<Rightarrow>(v)sem_env \<Rightarrow>(top0)list \<Rightarrow> 'ffi state*(((v)sem_env),(v))result "  where 
     "
fun_evaluate_prog st env prog = (
  if no_dup_mods prog(defined_mods   st) \<and> no_dup_top_types prog(defined_types   st) then
    evaluate_tops st env prog
  else
    (st, Rerr (Rabort Rtype_error)))"

end
