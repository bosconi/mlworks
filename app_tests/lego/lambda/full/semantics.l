(*
 * Copyright 2013 Ravenbrook Limited <http://www.ravenbrook.com/>.
 * All rights reserved.
 * 
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions are
 * met:
 * 
 * 1. Redistributions of source code must retain the above copyright
 *    notice, this list of conditions and the following disclaimer.
 * 
 * 2. Redistributions in binary form must reproduce the above copyright
 *    notice, this list of conditions and the following disclaimer in the
 *    documentation and/or other materials provided with the distribution.
 * 
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS
 * IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED
 * TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A
 * PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
 * HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
 * SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED
 * TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR
 * PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF
 * LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING
 * NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
 * SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 *
 * $Log: semantics.l,v $
 * Revision 1.1  1998/08/06 10:36:10  jont
 * new unit
 * Lego test application
 *
 *
 *)
(* The semantics *)

Forget val_env;

(* Some aliases *)

[val_env = vallist];
[extend_ve = valcons];
[empty_ve = valnil];

Goal val_env->(LL|exp)->(LL|exp)->val_env;
Intros ve el;
Refine LLrec[_:LL|exp]val_env;
Refine empty_ve;
Intros;
Refine extend_ve(clos b el ve) LLih;
Save recextend_aux;

Goal val_env->(LL|exp)->val_env;
Intros;
Refine recextend_aux H H1 H1;
Save recextend;

Inductive [sem:val_env->state->exp->val->state->Prop][sem_list:val_env->state->explist->val_env->state->Prop]
Constructors 
[sem_num:{ve:val_env}{s:state}{n:NN}sem ve s (num n) (vnum n) s]
[sem_var:{ve:val_env}{s:state}{n:NN}sem ve s (var n) (lookup n ve) s]
[sem_fn:{ve:val_env}{s:state}{e:exp}
         sem ve s (fn e) (clos e (NIL|exp) ve) s]
[sem_app:{ve,ve':val_env}{s,s',s'',s''':state}{e,e1,e2:exp}{el:expLL}{v,v2:val}
         {rator:sem ve s e1 (clos e el ve') s'}
         {rand:sem ve s' e2 v2 s''}
         {eval:sem (extend_ve v2 (ve_append (recextend ve' el) ve')) s'' e v s'''}
         sem ve s (app e1 e2) v s''']
[sem_letrec: {ve:val_env}{s,s':state}{e:exp}{el:explist}{v:val}
             {rand:sem (ve_append (recextend ve (explist_to_expLL el)) ve) s e v s'}
             sem ve s (letrec el e) v s']
[sem_bopapp: {ve:val_env}{s,s',s'':state}{e:exp}{v,v':val}{b:bop}
             {rand:sem ve s e v s'}
             {eval:bopapply b v s' v' s''}
             sem ve s (bopapp b e) v' s'']
[sem_tuple:{ve:val_env}{s,s':state}{el:explist}{vl:val_env}
           (sem_list ve s el vl s') ->
           sem ve s (mktuple el) (vtuple vl) s']
[sem_nil:{ve:val_env}{s:state}
         sem_list ve s expnil empty_ve s]
[sem_cons:{ve:val_env}
          {s,s',s'':state}
          {e:exp}{el:explist}
          {v:val}{vl:val_env}
          (sem ve s e v s')->
          (sem_list ve s' el vl s'')->
          (sem_list ve s (expcons e el) (extend_ve v vl) s'')];

(* Define the apply relation between values *)
[apply=
[s:state][v1,v2,v3:val][s':state]
{ve:val_env}{e:exp}{el:expLL}
(Q v1 (clos e el ve)) ->
sem (extend_ve v2 (ve_append (recextend ve el) ve)) s e v3 s'];

(* Theorems *)
Goal {s,s'|state}{e|exp}{ve|val_env}{a,r|val}
(apply s (clos e (NIL|exp) ve) a r s') ->
(sem (extend_ve a ve) s e r s');
Intros s s' e ve a r;
Expand apply;
Intros;
H ve e (NIL|exp);
Refine H ve e (NIL|exp);
Refine Q_refl;
Save apply_thm;

(* Application extraction *)
Goal {ve|val_env}{e1,e2|exp}{v|val}{s,s'''|state}
     (sem ve s (app e1 e2) v s''')->
     Ex4 ([v1,v2:val][s',s'':state]and3 (sem ve s e1 v1 s') (sem ve s' e2 v2 s'') (apply s'' v1 v2 v s'''));
intros _______;
Refine sem_elim ([ve|val_env][s|state][e|exp][v|val][s'''|state][_:sem ve s e v s''']{e1,e2:exp}
(Q e (app e1 e2))-> Ex4 ([v1,v2:val][s',s'':state]and3 (sem ve s e1 v1 s') (sem ve s' e2 v2 s'') (apply s'' v1 v2 v s''')));
Intros;Refine BB;
Intros;Refine ss_lemma H1;Refine Q_refl;
Intros;Refine ss_lemma H1;Refine Q_refl;
Intros;Refine ss_lemma H1;Refine Q_refl;
Intros;
Refine H2;Next +4;Expand and3;
Intros;Refine H3;
Qrepl (Q_sym (Q_resp exp_exp1 H1));
Refine rator;
Qrepl (Q_sym (Q_resp exp_exp2 H1));
Refine rand;
Expand apply;
Intros;
Qrepl (Q_sym (Q_resp valexp_proj H4));
Qrepl (Q_sym (Q_resp valenv_proj H4));
Qrepl (Q_sym (Q_resp valexpLL_proj H4));
Refine eval;
Intros;Refine ss_lemma H1;Refine Q_refl;
Intros;Refine ss_lemma H1;Refine Q_refl;
Intros;Refine ss_lemma H1;Refine Q_refl;
Intros;Refine tt;
Intros;Refine tt;
Refine app e1 e2;
Refine H;
Refine Q_refl;
Save extract_app;

(* More extractions of parts of derivations *)

[extract_letrec:
{ve|val_env}{s|state}{el|explist}{e|exp}{v|val}{s'|state}
(sem ve s (letrec el e) v s') ->
sem (ve_append (recextend ve (explist_to_expLL el)) ve) s e v s'];

[extract_bopapp:
{ve|val_env}{s|state}{b|bop}{e|exp}{v'|val}{s''|state}
(sem ve s (bopapp b e) v' s'') ->
Ex2 ([s':state][v:val] and (sem ve s e v s') (bopapply b v s' v' s''))];

[extract_tuple:
{ve|val_env}{s|state}{el|explist}{v|val}{s'|state}
(sem ve s (mktuple el) v s') ->
(Ex [vl:val_env] and (Q v (vtuple vl)) (sem_list ve s el vl s'))];

[extract_num:
{ve|val_env}{s|state}{n|NN}{v|val}{s'|state}
(sem ve s (num n) v s') ->
and (Q v (vnum n)) (Q s' s)];

[extract_var:
{ve|val_env}{s|state}{n|NN}{v|val}{s'|state}
(sem ve s (var n) v s') ->
and (Q v (lookup n ve)) (Q s' s)];

[extract_fn:
{ve|val_env}{s|state}{e|exp}{v|val}{s'|state}
(sem ve s (fn e) v s') ->
and (Q v (clos e (NIL|exp) ve)) (Q s' s)];

[sem_list_nil_vl:
{ve|val_env}{s|state}{vl|val_env}{s'|state}
(sem_list ve s expnil vl s') -> Q vl empty_ve];

[sem_list_nil_state:
{ve|val_env}{s|state}{vl|val_env}{s'|state}
(sem_list ve s expnil vl s') -> Q s s'];

[extract_list:
{ve|val_env}{s|state}{e|exp}{el|explist}{vl|val_env}{s''|state}
(sem_list ve s (expcons e el) vl s'') ->
Ex3([s':state][v:val][vl':val_env]and3 (Q vl (extend_ve v vl')) (sem ve s e v s') (sem_list ve s' el vl' s''))];

(* Safety *)

(* This also needs to include the fact that a safe expression always evaluates *)

[safe_no_update [e:exp] [ve:val_env] =
 {s1,s1'|state}{v|val} (sem ve s1 e v s1') -> (Q s1 s1')];

[safe_no_ref [e:exp] [ve:val_env] =
 {s1,s1'|state}{v|val}
 (sem ve s1 e v s1') -> {s2, s3|state}{v'|val}(sem ve s2 e v' s3)-> Q v v'];

[safe_always_evaluates [e:exp][ve:val_env] =
 {s:state}Ex2[s':state][v:val]sem ve s e v s'];

[safe [e:exp][ve:val_env] = and3 (safe_no_update e ve) (safe_no_ref e ve)(safe_always_evaluates e ve)];

[safe_theorem : 
{e|exp}{ve|val_env}
(safe e ve) ->
{s1,s1'|state}{v|val}
(sem ve s1 e v s1') -> {s2:state}(sem ve s2 e v s2)];

[safe_theorem2 :
{e|exp}{ve|val_env}
(safe e ve) ->
{s1,s1'|state}{v|val}
(sem ve s1 e v s1') -> Q s1 s1'];
