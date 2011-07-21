theory SC_Schedulers imports
  "Random_Scheduler"
  "Round_Robin"
  "../MM/SC_Collections"
  "../../Collections/RBTMapImpl"
  "../../Collections/RBTSetImpl"
  "../../Collections/Fifo"
  "../../Collections/ListSetImpl_Invar"
begin

text {*
  Adapt Cset code setup such that @{term "Cset.insert"}, @{term "sup :: 'a Cset.set \<Rightarrow> 'a Cset.set \<Rightarrow> 'a Cset.set"}
  and @{term "cset_of_pred"} do not generate sort constraint @{text equal}.
*}

context Cset begin

definition insert' :: "'a \<Rightarrow> 'a Cset.set \<Rightarrow> 'a Cset.set"
where "insert' = Cset.insert"

definition union' :: "'a Cset.set \<Rightarrow> 'a Cset.set \<Rightarrow> 'a Cset.set"
where "union' A B = semilattice_sup_class.sup A B"

end

declare
  Cset.insert'_def[symmetric, code_inline]
  Cset.union'_def[symmetric, code_inline]

context List_Cset begin

lemma insert'_code:
  "Cset.insert' x (List_Cset.set xs) = List_Cset.set (x # xs)"
by(rule Cset.set_eqI)(simp add: Cset.insert'_def)

lemma union'_code:
  "Cset.union' (List_Cset.set xs) (List_Cset.set ys) = List_Cset.set (xs @ ys)"
by(rule Cset.set_eqI)(simp add: Cset.union'_def)

end

declare
  List_Cset.insert'_code [code]
  List_Cset.union'_code [code]

abbreviation sc_start_state_refine ::
  "'m_t \<Rightarrow> (thread_id \<Rightarrow> ('x \<times> addr released_locks) \<Rightarrow> 'm_t \<Rightarrow> 'm_t) \<Rightarrow> 'm_w \<Rightarrow> 's_i
  \<Rightarrow> (cname \<Rightarrow> mname \<Rightarrow> ty list \<Rightarrow> ty \<Rightarrow> 'md \<Rightarrow> addr val list \<Rightarrow> 'x) \<Rightarrow> 'md prog \<Rightarrow> cname \<Rightarrow> mname \<Rightarrow> addr val list
  \<Rightarrow> (addr, thread_id, heap, 'm_t, 'm_w, 's_i) state_refine"
where
  "\<And>is_empty.
   sc_start_state_refine thr_empty thr_update ws_empty is_empty f P \<equiv>
   heap_base.start_state_refine addr2thread_id sc_empty (sc_new_obj P) thr_empty thr_update ws_empty is_empty f P"

abbreviation sc_state_\<alpha> ::
  "('l, 't :: linorder, 'm, ('t, 'x \<times> 'l \<Rightarrow>\<^isub>f nat) rm, ('t, 'w wait_set_status) rm, 't rs) state_refine
  \<Rightarrow> ('l,'t,'x,'m,'w) state"
where "sc_state_\<alpha> \<equiv> state_refine_base.state_\<alpha> rm_\<alpha> rm_\<alpha> rs_\<alpha>"

lemma sc_state_\<alpha>_sc_start_state_refine [simp]:
  "sc_state_\<alpha> (sc_start_state_refine rm_empty rm_update rm_empty rs_empty f P C M vs) = sc_start_state f P C M vs"
by(simp add: heap_base.start_state_refine_def state_refine_base.state_\<alpha>.simps split_beta sc.start_state_def rm_correct rs_correct)

locale sc_scheduler =
  scheduler
    final r convert_RA 
    schedule "output" pick_wakeup \<sigma>_invar
    rm_\<alpha> rm_invar rm_lookup rm_update
    rm_\<alpha> rm_invar rm_lookup rm_update rm_delete rm_iterate
    rs_\<alpha> rs_invar rs_memb rs_ins rs_delete
    invariant
  for final :: "'x \<Rightarrow> bool"
  and r :: "'t \<Rightarrow> ('x \<times> 'm) \<Rightarrow> (('l,'t :: linorder,'x,'m,'w,'o) thread_action \<times> 'x \<times> 'm) Predicate.pred"
  and convert_RA :: "'l released_locks \<Rightarrow> 'o list"
  and schedule :: "('l,'t,'x,'m,'w,'o,('t, 'x \<times> 'l \<Rightarrow>\<^isub>f nat) rm,('t, 'w wait_set_status) rm, 't rs, 's) scheduler"
  and "output" :: "'s \<Rightarrow> 't \<Rightarrow> ('l,'t,'x,'m,'w,'o) thread_action \<Rightarrow> 'q option"
  and pick_wakeup :: "'s \<Rightarrow> 't \<Rightarrow> 'w \<Rightarrow> ('t, 'w wait_set_status) RBT.rbt \<Rightarrow> 't option"
  and \<sigma>_invar :: "'s \<Rightarrow> 't set \<Rightarrow> bool"
  and invariant :: "('l,'t,'x,'m,'w) state \<Rightarrow> bool"

locale sc_round_robin_base =
  round_robin_base
    final r convert_RA "output"
    rm_\<alpha> rm_invar rm_lookup rm_update 
    rm_\<alpha> rm_invar rm_lookup rm_update rm_delete rm_iterate rm_sel'
    rs_\<alpha> rs_invar rs_memb rs_ins rs_delete
    fifo_\<alpha> fifo_invar fifo_empty fifo_isEmpty fifo_enqueue fifo_dequeue fifo_push
  for final :: "'x \<Rightarrow> bool"
  and r :: "'t \<Rightarrow> ('x \<times> 'm) \<Rightarrow> (('l,'t :: linorder,'x,'m,'w,'o) thread_action \<times> 'x \<times> 'm) Predicate.pred"
  and convert_RA :: "'l released_locks \<Rightarrow> 'o list"
  and "output" :: "'t fifo round_robin \<Rightarrow> 't \<Rightarrow> ('l,'t,'x,'m,'w,'o) thread_action \<Rightarrow> 'q option"

locale sc_round_robin =
  round_robin 
    final r convert_RA "output"
    rm_\<alpha> rm_invar rm_lookup rm_update 
    rm_\<alpha> rm_invar rm_lookup rm_update rm_delete rm_iterate rm_sel'
    rs_\<alpha> rs_invar rs_memb rs_ins rs_delete
    fifo_\<alpha> fifo_invar fifo_empty fifo_isEmpty fifo_enqueue fifo_dequeue fifo_push
  for final :: "'x \<Rightarrow> bool"
  and r :: "'t \<Rightarrow> ('x \<times> 'm) \<Rightarrow> (('l,'t :: linorder,'x,'m,'w,'o) thread_action \<times> 'x \<times> 'm) Predicate.pred"
  and convert_RA :: "'l released_locks \<Rightarrow> 'o list"
  and "output" :: "'t fifo round_robin \<Rightarrow> 't \<Rightarrow> ('l,'t,'x,'m,'w,'o) thread_action \<Rightarrow> 'q option"

sublocale sc_round_robin < sc_round_robin_base .

locale sc_random_scheduler_base =
  random_scheduler_base
    final r convert_RA "output"
    rm_\<alpha> rm_invar rm_lookup rm_update rm_iterate 
    rm_\<alpha> rm_invar rm_lookup rm_update rm_delete rm_iterate rm_sel'
    rs_\<alpha> rs_invar rs_memb rs_ins rs_delete
    lsi_\<alpha> lsi_invar lsi_empty lsi_ins_dj lsi_to_list
  for final :: "'x \<Rightarrow> bool"
  and r :: "'t \<Rightarrow> ('x \<times> 'm) \<Rightarrow> (('l,'t :: linorder,'x,'m,'w,'o) thread_action \<times> 'x \<times> 'm) Predicate.pred"
  and convert_RA :: "'l released_locks \<Rightarrow> 'o list"
  and "output" :: "random_scheduler \<Rightarrow> 't \<Rightarrow> ('l,'t,'x,'m,'w,'o) thread_action \<Rightarrow> 'q option"

locale sc_random_scheduler =
  random_scheduler
    final r convert_RA "output"
    rm_\<alpha> rm_invar rm_lookup rm_update rm_iterate 
    rm_\<alpha> rm_invar rm_lookup rm_update rm_delete rm_iterate rm_sel'
    rs_\<alpha> rs_invar rs_memb rs_ins rs_delete
    lsi_\<alpha> lsi_invar lsi_empty lsi_ins_dj lsi_to_list
  for final :: "'x \<Rightarrow> bool"
  and r :: "'t \<Rightarrow> ('x \<times> 'm) \<Rightarrow> (('l,'t :: linorder,'x,'m,'w,'o) thread_action \<times> 'x \<times> 'm) Predicate.pred"
  and convert_RA :: "'l released_locks \<Rightarrow> 'o list"
  and "output" :: "random_scheduler \<Rightarrow> 't \<Rightarrow> ('l,'t,'x,'m,'w,'o) thread_action \<Rightarrow> 'q option"

sublocale sc_random_scheduler < sc_random_scheduler_base .

end