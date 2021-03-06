
Require Import Omega.

Require Export FcEtt.imports.
Require Import FcEtt.utils.
Require Export FcEtt.tactics.
Require Export FcEtt.ett_ott.
Require Export FcEtt.ett_inf.
Require Export FcEtt.ett_ind.
Require Export FcEtt.ett_roleing.
Require Import FcEtt.ett_path.
Require Export FcEtt.ett_par.
Require Import FcEtt.ext_wf.
Require Import FcEtt.ett_match.
Require Import FcEtt.ett_rename.
Require Import FcEtt.ext_invert.
Require Import FcEtt.ext_red_one.
Require Import FcEtt.param.

Set Implicit Arguments.
Set Bullet Behavior "Strict Subproofs".

 Definition Good (G : context) (D : available_props):=
  forall c1 A B1 T1 R,
    binds c1 (Co (Eq A B1 T1 R)) G
    -> c1 `in` D
    -> exists C, Par (ctx_nom G) A C R /\ Par (ctx_nom G) B1 C R.

(* ---------------------------------------- *)

Lemma Subset_trans' : forall S1 S2 S3, S2 [<=] S3 -> S1 [<=] S2 -> S1 [<=] S3.
Proof. intros. eapply Subset_trans; eauto.
Qed.

Lemma open2 :
  forall x b b' W a a' R R',
    x `notin` fv_tm_tm_tm a' \u fv_tm_tm_tm a \u dom W ->
    Par ([(x,R)] ++ W) (open_tm_wrt_tm a (a_Var_f x)) (open_tm_wrt_tm a' (a_Var_f x)) R' ->
    Par W b b' R ->
    Par W (open_tm_wrt_tm a b) (open_tm_wrt_tm a' b') R'.
Proof.
  intros x b b'. intros.
  rewrite (tm_subst_tm_tm_intro x); auto.
  rewrite [(_ _ b')] (tm_subst_tm_tm_intro x); auto.
  replace W with (nil ++ W); auto.
  eapply subst3; eauto.
Qed.

Lemma open3 :
  forall c L W a a' R',
    c `notin` fv_co_co_tm a' \u fv_co_co_tm a \u dom W \u L ->
    Par W (open_tm_wrt_co a (g_Var_f c)) (open_tm_wrt_co a' (g_Var_f c)) R' ->
    Par W (open_tm_wrt_co a g_Triv) (open_tm_wrt_co a' g_Triv) R'.
Proof.
  intros x L. intros.
  rewrite (co_subst_co_tm_intro x); auto.
  rewrite [(_ a' g_Triv)] (co_subst_co_tm_intro x); auto.
  replace W with (nil ++ W); auto.
  eapply subst4; eauto.
Qed.

Lemma a_Pi_head : forall W b A rho B R',
    Par W (a_Pi rho A B) b R' -> exists A' B' L,
      b = a_Pi rho A' B' /\ Par W A A' R' /\
      (forall x, x `notin` L -> 
        Par([(x,Nom)] ++ W) (open_tm_wrt_tm B (a_Var_f x)) 
                               (open_tm_wrt_tm B' (a_Var_f x)) R').
Proof.
  intros. inversion H. subst.
  inversion H0. subst.  exists A , B, L. repeat split; auto.
  intros. econstructor; eauto.
  subst. exists A', B', L.  split; auto.
Qed.

Lemma Par_Abs_inversion : forall W a b rho R',
    Par W (a_UAbs rho a) b R' ->
    exists a', b = (a_UAbs rho a') /\
          forall x, x `notin` fv_tm_tm_tm a \u fv_tm_tm_tm a' \u dom W ->
         Par ([(x,Nom)] ++ W) (open_tm_wrt_tm a (a_Var_f x)) (open_tm_wrt_tm a' (a_Var_f x)) R'.

Proof.
  intros W a a' rho R' P.
  inversion P; subst.
  + inversion H. subst. exists a. split. reflexivity.
    intros. econstructor. eapply rctx_uniq in H.
    pick fresh y.
    rewrite (tm_subst_tm_tm_intro y); eauto.
    replace ([(x,Nom)] ++ W) with (nil ++ ([(x,Nom)] ++ W)); auto.
    eapply subst_tm_roleing. simpl_env.
    eapply roleing_app_rctx; simpl_env.
    solve_uniq. auto. econstructor. solve_uniq. auto. auto.
  + exists a'0. split. auto. intros. eapply Par_rctx_uniq in P.
    pick fresh y.
    rewrite (tm_subst_tm_tm_intro y); eauto.
    rewrite (tm_subst_tm_tm_intro y a'0); eauto.
    replace ([(x,Nom)] ++ W) with (nil ++ ([(x,Nom)] ++ W)); auto.
    eapply subst2. simpl_env.
    eapply par_app_rctx; simpl_env.
    solve_uniq. auto. econstructor. solve_uniq. auto. auto.
Qed.


(* -------------------------------------------------------------------------------- *)

Ltac try_refl :=
  try match goal with
      | [ P2 : Par _ ?b |- _ ] =>
        exists b; assert (lc_tm b); try eapply Par_lc2; eauto; try split; eauto; fail
      end.


Ltac invert_equality :=
  match goal with
  | [ H : _ = _ |- _ ] =>
    inversion H
  end.

  Ltac try_Refl_left :=
  try match goal with
      | [ P1 : Par _ ?b ?b _,
          P2 : Par _ ?b ?c _ |-
          exists cc:tm, Par _ ?b cc _ /\ Par _ ?c cc _ ] =>
        exists c; split; auto; 
        apply Par_Refl; eapply Par_roleing_tm_snd;
        eauto; fail
      end.

  Ltac try_Refl_right :=
  try match goal with
      | [ P1 : Par _ ?b ?c _,
          P2 : Par _ ?b ?b _ |- 
          exists cc:tm, Par _ ?c cc _ /\ Par _ ?b cc _ ] =>
        exists c; split; auto; 
        apply Par_Refl; eapply Par_roleing_tm_snd;
        eauto; fail
      end.

Ltac use_size_induction a conf L1 L2 :=
  match goal with
  | [   IH : forall y: nat, ?T,
        H1 : Par ?W a ?b0 ?R,
        H2 : Par ?W a ?b1 ?R |- _ ] =>
      move: (@IH (size_tm a) ltac:(omega) a ltac:(auto) _ _ _ H1 _ H2) => 
      [ conf [L1 L2]]
  end.

Ltac use_size_induction_open a0 x ac Par1 Par2 :=
      let h0 := fresh in
      let h1 := fresh in
      let h2 := fresh in
      let EQ1 := fresh in
      let EQ2 := fresh in
      match goal with
        | [  H : ??? x : atom,
              x `notin` ?L
              ??? Par ?W (?open_tm_wrt_tm a0 (?a_Var_f x)) ?b ?R,
             H4: ??? x : atom,
                 x `notin` ?L0
                 ??? Par ?W (?open_tm_wrt_tm a0 (?a_Var_f x)) ?c ?R
                        |- _ ] =>
    move: (H x ltac:(auto)) => h0; clear H;
    move: (H4 x ltac:(auto)) => h1; clear H4;
    move: (size_tm_open_tm_wrt_tm_var a0 x) => EQ1;
    move: (size_tm_open_tm_wrt_co_var a0 x) => EQ2;

    use_size_induction (open_tm_wrt_tm a0 (a_Var_f x)) ac Par1 Par2;
    clear h0; clear h1; clear EQ1; clear EQ2
    end.

Lemma tm_proper_subpattern_agree_cong : forall a1 a2 p, tm_subpattern_agree a1 p
    /\ ~(tm_pattern_agree a1 p) -> tm_tm_agree a1 a2 -> tm_subpattern_agree a2 p
    /\ ~(tm_pattern_agree a2 p).
Proof. intros. inversion H. split. eapply tm_subpattern_agree_cong; eauto.
       intro. apply H2. eapply tm_pattern_agree_cong; eauto.
       apply tm_tm_agree_sym; auto.
Qed.

Lemma pattern_agree_refl : forall p, Pattern p -> tm_pattern_agree p p.
Proof. intros. induction H; eauto.
Qed.

Lemma tm_pattern_agree_ValuePath : forall F p b A R Rs a p',
      tm_pattern_agree a p' -> tm_subpattern_agree p' p ->
      binds F (Ax p b A R Rs) toplevel -> ValuePath a F.
Proof. intros. generalize dependent p. induction H; intros; eauto.
       all: try (econstructor; eauto; eapply IHtm_pattern_agree; eauto).
       all: try (eapply tm_subpattern_agree_sub_app; eauto; fail).
        - move: (tm_subpattern_agree_const_same H0) => h0.
          move: (axiom_pattern_head H1) => h1.
          simpl in h0. rewrite h1 in h0. inversion h0; subst. eauto.
        - eapply tm_subpattern_agree_sub_capp; eauto.
Qed.

Lemma tm_subpattern_agree_ValuePath_helper : forall F p b A R Rs a p',
      tm_subpattern_agree a p' -> tm_subpattern_agree p' p ->
      binds F (Ax p b A R Rs) toplevel -> ValuePath a F.
Proof. intros. induction H; eauto.
       all: try eapply IHtm_subpattern_agree.
       all: try (eapply tm_subpattern_agree_sub_app; eauto; fail).
        - eapply tm_pattern_agree_ValuePath; eauto.
        - eapply tm_subpattern_agree_sub_capp; eauto.
Qed.

Lemma tm_subpattern_agree_ValuePath : forall F p b A R Rs a,
      tm_subpattern_agree a p -> binds F (Ax p b A R Rs) toplevel ->
      ValuePath a F.
Proof. intros. eapply tm_subpattern_agree_ValuePath_helper; eauto.
       econstructor. apply pattern_agree_refl. eapply axiom_pattern; eauto.
Qed.

Lemma tm_pattern_agree_sub : forall a p, tm_subpattern_agree a p ->
      subtm_pattern_agree a p -> tm_pattern_agree a p.
Proof. intros. induction H; eauto.
        all: (inversion H0; subst; eauto;
              apply tm_subpattern_agree_length_leq in H;
              [ apply subtm_pattern_agree_length_geq in H2; simpl in H, H2;
                omega | apply subtm_pattern_agree_length_geq in H1;
                        simpl in H, H1; omega]).
Qed.

Lemma pattern_app_rel_rctx : forall p x R,
     combine (vars_Pattern p) (pat_app_roles p) ++ [(x,R)]
   = combine (vars_Pattern (a_App p (Role R) (a_Var_f x)))
                  (pat_app_roles (a_App p (Role R) (a_Var_f x))).
Proof. intros. rewrite combine_app. auto.
Qed.

Lemma pattern_app_rel_rctx_2 : forall p x R,
     [(x, R)] ++ rev (combine (vars_Pattern p) (pat_app_roles p))
   = nil ++ rev (combine (vars_Pattern (a_App p (Role R) (a_Var_f x)))
                  (pat_app_roles (a_App p (Role R) (a_Var_f x)))).
Proof. intros. simpl. rewrite combine_app. rewrite rev_app_distr. auto.
Qed.

Lemma pattern_app_irrel_rctx : forall p,
     combine (vars_Pattern p) (pat_app_roles p)
   = combine (vars_Pattern (a_App p (Rho Irrel) a_Bullet))
                  (pat_app_roles (a_App p (Rho Irrel) a_Bullet)).
Proof. intros. auto.
Qed.

Lemma pattern_capp_rctx : forall p,
     combine (vars_Pattern p) (pat_app_roles p)
   = combine (vars_Pattern (a_CApp p g_Triv))
                  (pat_app_roles (a_CApp p g_Triv)).
Proof. intros. auto.
Qed.

Lemma axiom_app_confluence : forall F p b A R Rs p' b' D' a a1 av
                                              aw ax ay a2 nu W R1,
      binds F (Ax p b A R Rs) toplevel ->
      tm_subpattern_agree a p /\ ~(tm_pattern_agree a p) ->
      Par W a av R1 -> Par W a1 aw (app_role nu R1) ->
      Rename p b p' b' ((dom W) \u fv_tm_tm_tm p) D' ->
      MatchSubst (a_App av nu aw) p' b' a2 ->
      Par W av ax R1 -> Par W aw ay (app_role nu R1) ->
      SubRole R R1 -> Par W a2 (matchsubst (a_App ax nu ay) p' b') R1.
Proof. intros. inversion H0 as [Q1 Q2].
       assert (tm_tm_agree a av). { eapply pattern_like_tm_par; eauto. }
       assert (~(tm_pattern_agree av p)).
           { intro. eapply Q2. eapply tm_pattern_agree_cong. eauto.
             apply tm_tm_agree_sym. auto. }
       assert (tm_subpattern_agree av p).
           { eapply tm_subpattern_agree_cong; eauto. }
       assert (tm_tm_agree av ax). { eapply pattern_like_tm_par; eauto. }
       inversion H4; subst; simpl in *.
      - replace W with (nil ++ W); eauto.
        eapply subst3 with (R1 := R0). rewrite app_nil_l.
        eapply MatchSubst_par with (p1 := p); eauto.
        + rewrite pattern_app_rel_rctx_2.
          eapply roleing_Rename; eauto.
          eapply Rename_inter_sub_empty. eauto.
          clear. fsetdec. eapply Rename_fv_new_pattern. eauto.
          apply toplevel_inversion in H.
          inversion H as [W1 [G [D [B [Q5 [_ [Q6 _]]]]]]].
          apply pat_ctx_rctx in Q5. subst. simpl.
          eapply roleing_sub; eauto.
        + eapply matchsubst_fun_ind; eauto.
          eapply tm_pattern_agree_cong. eapply MatchSubst_match; eauto.
          auto. eapply MatchSubst_lc3; eauto.
        + rewrite app_assoc. apply uniq_app.
          apply uniq_reorder_1. rewrite pattern_app_rel_rctx.
          eapply uniq_new_pattern_ctx. eauto.
          eapply Par_rctx_uniq; eauto.
          unfold disjoint. rewrite AtomSetProperties.inter_sym.
          eapply Rename_inter_sub_empty; eauto.
          eapply Subset_trans'. eapply Rename_fv_new_pattern. eauto.
          simpl. apply AtomSetProperties.subset_add_3. eauto.
          intro. intro. apply AtomSetImpl.union_2. apply dom_combine_fv; auto.
        + eapply Par_sub; eauto using param_sub1.
      - replace W with (nil ++ W); eauto.
        eapply MatchSubst_par with (p1 := p); eauto.
        + rewrite pattern_app_irrel_rctx. eapply roleing_Rename.
          eauto. eapply Rename_inter_sub_empty. eapply H3.
          clear. fsetdec. eapply Rename_fv_new_pattern. eauto.
          apply toplevel_inversion in H.
          inversion H as [W1 [G [D [B [Q5 [_ [Q6 _]]]]]]].
          apply pat_ctx_rctx in Q5. subst. simpl.
          simpl. eapply roleing_sub; eauto.
        + eapply matchsubst_fun_ind.
          eapply tm_pattern_agree_cong. eapply MatchSubst_match; eauto.
          auto. eapply MatchSubst_lc3; eauto. auto.
        + simpl. rewrite pattern_app_irrel_rctx. apply uniq_app.
          eapply uniq_new_pattern_ctx. eauto.
          eapply Par_rctx_uniq; eauto.
          unfold disjoint. rewrite AtomSetProperties.inter_sym.
          eapply Rename_inter_sub_empty. eapply H3. eauto.
          eapply Subset_trans'. eapply Rename_fv_new_pattern. eauto.
          intro. intro. apply dom_combine_fv. auto.
Qed.

Lemma axiom_capp_confluence : forall F p b A R Rs p' b' D' a av ax a2 W R1,
      binds F (Ax p b A R Rs) toplevel ->
      tm_subpattern_agree a p /\ ~(tm_pattern_agree a p) ->
      Par W a av R1 ->
      Rename p b p' b' ((dom W) \u fv_tm_tm_tm p) D' ->
      MatchSubst (a_CApp av g_Triv) p' b' a2 ->
      Par W av ax R1 ->
      SubRole R R1 -> Par W a2 (matchsubst (a_CApp ax g_Triv) p' b') R1.
Proof. intros. inversion H0 as [Q1 Q2].
       assert (tm_tm_agree a av). { eapply pattern_like_tm_par; eauto. }
       assert (~(tm_pattern_agree av p)).
           { intro. eapply Q2. eapply tm_pattern_agree_cong. eauto.
             apply tm_tm_agree_sym. auto. }
       assert (tm_subpattern_agree av p).
           { eapply tm_subpattern_agree_cong; eauto. }
       assert (tm_tm_agree av ax). { eapply pattern_like_tm_par; eauto. }
       inversion H3; subst; simpl in *.
       replace W with (nil ++ W); eauto.
       eapply MatchSubst_par with (p1 := p); eauto.
        + rewrite pattern_capp_rctx.
          eapply roleing_Rename; eauto.
          eapply Rename_inter_sub_empty; eauto.
          clear. fsetdec. eapply Rename_fv_new_pattern. eauto.
          apply toplevel_inversion in H.
          inversion H as [W1 [G [B[D [Q5 [_ [Q6 _]]]]]]].
          apply pat_ctx_rctx in Q5. subst. simpl.
          eapply roleing_sub; eauto.
        + eapply matchsubst_fun_ind; eauto.
          eapply tm_pattern_agree_cong. eapply MatchSubst_match; eauto.
          auto. eapply MatchSubst_lc3; eauto.
        + simpl. rewrite pattern_capp_rctx. apply uniq_app.
          eapply uniq_new_pattern_ctx. eauto.
          eapply Par_rctx_uniq; eauto.
          unfold disjoint. rewrite AtomSetProperties.inter_sym.
          eapply Rename_inter_sub_empty; eauto.
          eapply Subset_trans'. eapply Rename_fv_new_pattern. eauto.
          intro. intro. apply dom_combine_fv; auto.
Qed.


Lemma confluence_size : forall n a, size_tm a <= n ->  forall W a1 R, Par W a a1 R -> forall a2, Par W a a2 R -> exists b, Par W a1 b R /\ Par W a2 b R.
Proof.
  pose confluence_size_def n :=
      forall a, size_tm a <= n ->  forall W a1 R, Par W a a1 R -> forall a2, Par W a a2 R -> exists b, Par W a1 b R /\ Par W a2 b R.
  intro n. fold (confluence_size_def n).  eapply (well_founded_induction_type lt_wf).
  clear n. intros n IH. unfold confluence_size_def in *. clear confluence_size_def.
  intros a SZ W a1 R P1 a2 P2.
  inversion P1; inversion P2; subst.
  all: try solve [invert_equality].

  all: try_Refl_left.
  all: try_Refl_right.
  all: try invert_syntactic_equality.
  all: simpl in SZ; destruct n; try solve [ inversion SZ ].

  - (* two betas *)
    use_size_induction a0 ac Par1 Par2.
    use_size_induction b bc Par3 Par4.
    destruct (Par_Abs_inversion Par1) as [ax [EQ h0]]; subst;
    destruct (Par_Abs_inversion Par2) as [ay [EQ2 h1]]; subst.
    inversion EQ2. subst.
    exists (open_tm_wrt_tm ay bc).
    split. pick fresh x; eapply open2. auto. eauto.
    eauto using Par_sub, param_sub1.
    pick fresh x; eapply open2; eauto using Par_sub, param_sub1.
  - (* app beta / app cong *)
    use_size_induction a0 ac Par1 Par2.
    use_size_induction b bc Par3 Par4.
    destruct (Par_Abs_inversion Par1) as [ax [EQ h0]]; subst.
    exists (open_tm_wrt_tm ax bc). inversion Par1; subst.
     + split. pick fresh x; eapply open2. auto. eauto.
       eauto using Par_sub, param_sub1.
       eapply Par_Beta; eauto.
     + split. pick fresh x; eapply open2. auto. eauto.
       eauto using Par_sub, param_sub1.
       eapply Par_Beta; eauto.
  - inversion H6. assert False.
    eapply pattern_like_tm_par; try apply H; eauto.
    contradiction.
  - (* app cong / app beta *)
    use_size_induction a0 ac Par1 Par2.
    use_size_induction b bc Par3 Par4.
    destruct (Par_Abs_inversion Par2) as [ax [EQ h0]]; subst.
    exists (open_tm_wrt_tm ax bc). inversion Par2; subst.
     + split. eapply Par_Beta; eauto.
       pick fresh x; eapply open2. auto. eauto. eauto using Par_sub, param_sub1.
     + split. eapply Par_Beta; eauto. 
       pick fresh x; eapply open2. auto. eauto. eauto using Par_sub, param_sub1.
  - (* app cong / app cong *)
    use_size_induction a0 ac Par1 Par2.
    use_size_induction b bc Par3 Par4.
    exists (a_App ac nu bc). split; auto.
  - (* app / axiom app *)
    inversion H6.
    assert (tm_tm_agree a0 a'). eapply pattern_like_tm_par; eauto.
    use_size_induction a0 ac Par1 Par2.
    use_size_induction b bc Par3 Par4.
    pose (Q1 := tm_pattern_agree_rename_inv_2 (MatchSubst_match H10) H9).
    assert (tm_tm_agree a'0 ac).
        { eapply pattern_like_tm_par; eauto.
          eapply tm_subpattern_agree_sub_app; eauto.
          intro. eapply tm_subpattern_agree_app_contr; eauto.
         }
    exists (matchsubst (a_App ac nu bc) p' b'0). split.
     + eapply Par_AxiomApp; eauto.
       split. eapply tm_subpattern_agree_cong. eapply H1. auto.
       intro. apply H2. eapply tm_pattern_agree_cong; eauto.
       apply tm_tm_agree_sym; auto. eapply matchsubst_fun_ind.
       eapply tm_pattern_agree_cong. eapply MatchSubst_match; eauto.
       econstructor. auto. eapply Par_lc2; eauto. eapply Par_lc2; eauto.
       eapply MatchSubst_lc3; eauto. auto.
     + eapply axiom_app_confluence.
       6: eauto.
       all: eauto.
  - (* two cbetas *)
    use_size_induction a0 ac Par1 Par2. inversion Par1; subst.
    + exists (open_tm_wrt_co a' g_Triv); split.
      econstructor. eapply Par_roleing_tm_snd. eauto.
      inversion Par2; subst. econstructor. eapply Par_roleing_tm_snd. eauto.
      pick fresh c. eapply open3 with (c := c) (L := L); eauto.
    + exists (open_tm_wrt_co a'1 g_Triv); split.
      pick fresh c. eapply open3 with (c := c) (L := L); eauto.
      inversion Par2; subst. econstructor. eapply Par_roleing_tm_snd. eauto.
      pick fresh c. eapply open3 with (c := c) (L := L); eauto.
  - (* cbeta / capp cong *)
    use_size_induction a0 ac Par1 Par2.
    inversion Par1; subst.
    + exists (open_tm_wrt_co a' g_Triv). split.
      econstructor. eapply Par_roleing_tm_snd. eauto.
      econstructor. eauto.
    + exists (open_tm_wrt_co a'1 g_Triv). split.
      pick fresh c. eapply open3 with (c := c) (L := L); eauto.
      econstructor. eauto.
  - inversion H5. assert False.
    eapply pattern_like_tm_par; try apply H; eauto.
    contradiction.
  - (* capp cong / cbeta *)
    use_size_induction a0 ac Par1 Par2.
    inversion Par2; subst.
    + exists (open_tm_wrt_co a'0 g_Triv). split. econstructor. eauto.
      econstructor. eapply Par_roleing_tm_snd. eauto.
    + exists (open_tm_wrt_co a'1 g_Triv). split. econstructor. eauto.
      pick fresh c. eapply open3 with (c := c) (L := L); eauto.
  - (* capp cong / capp cong *)
    use_size_induction a0 ac Par1 Par2.
    exists (a_CApp ac g_Triv). auto.
  - (* capp / axiom capp *)
    inversion H5.
    assert (tm_tm_agree a0 a'). eapply pattern_like_tm_par; eauto.
    use_size_induction a0 ac Par1 Par2.
    pose (Q1 := tm_pattern_agree_rename_inv_2 (MatchSubst_match H8) H7).
    assert (tm_tm_agree a'0 ac).
        { eapply pattern_like_tm_par; eauto.
          eapply tm_subpattern_agree_sub_capp; eauto.
          intro. eapply tm_subpattern_agree_capp_contr; eauto.
         }
    exists (matchsubst (a_CApp ac g_Triv) p' b'). split.
     + eapply Par_AxiomCApp; eauto.
       split. eapply tm_subpattern_agree_cong. eapply H0. auto.
       intro. apply H1. eapply tm_pattern_agree_cong; eauto.
       apply tm_tm_agree_sym; auto. eapply matchsubst_fun_ind.
       eapply tm_pattern_agree_cong. eapply MatchSubst_match; eauto. eauto.
       eapply MatchSubst_lc3; eauto. auto.
     + eapply axiom_capp_confluence. eauto. eapply H5. eapply H6.
       all: eauto.
  - (* abs cong / abs cong *)
    pick fresh x.
    use_size_induction_open a0 x ac Par1 Par2.
    exists (a_UAbs rho (close_tm_wrt_tm x ac)).
    split; apply (@Par_Abs_exists x); eauto.
  - (* pi cong / pi cong *)
    pick fresh x.
    use_size_induction A ac Par1 Par2.
    use_size_induction_open B x bc Par3 Par4.
    exists (a_Pi rho ac (close_tm_wrt_tm x bc)).
    split; apply (@Par_Pi_exists x); eauto.
  - (* cabs cong / cabs cong *)
    pick fresh c.
    use_size_induction_open a0 c ac Par1 Par2.
    exists (a_UCAbs (close_tm_wrt_co c ac)).
    split; apply (@Par_CAbs_exists c); eauto.
  - (* cpi cong / cpi cong *) 
    apply Par_sub with (R2 := Rep) in H; auto.
    apply Par_sub with (R2 := Rep) in H7; auto.
    use_size_induction A AC Par1 Par2.
    use_size_induction a0 aC Par3 Par4.
    use_size_induction b bC Par5 Par6.
    pick fresh c.
    use_size_induction_open B c BC Par7 Par8.
    exists (a_CPi (Eq aC bC AC R1) (close_tm_wrt_co c BC)).
    split; apply (@Par_CPi_exists c); eauto.
  - axioms_head_same. apply Par_roleing_tm_snd in P1. exists a2; split; eauto.
  - inversion H0. assert False.
    eapply pattern_like_tm_par; try apply H10; eauto.
    contradiction.
  - (* axiom app / app *)
    inversion H0.
    assert (tm_tm_agree a0 a'0). eapply pattern_like_tm_par; eauto.
    use_size_induction a0 ac Par1 Par2.
    use_size_induction a3 bc Par3 Par4.
    pose (Q1 := tm_pattern_agree_rename_inv_2 (MatchSubst_match H4) H3).
    assert (tm_tm_agree a' ac).
        { eapply pattern_like_tm_par; eauto.
          eapply tm_subpattern_agree_sub_app; eauto.
          intro. eapply tm_subpattern_agree_app_contr; eauto.
         }
    exists (matchsubst (a_App ac nu bc) p' b'). split.
     + eapply axiom_app_confluence. eauto. eapply H0. eapply H1.
       eapply H2. all: eauto.
     + eapply Par_AxiomApp; eauto.
       split. eapply tm_subpattern_agree_cong. eapply H6. auto.
       intro. apply H7. eapply tm_pattern_agree_cong; eauto.
       apply tm_tm_agree_sym; auto. eapply matchsubst_fun_ind.
       eapply tm_pattern_agree_cong. eapply MatchSubst_match; eauto.
       econstructor. auto. eapply Par_lc2; eauto. eapply Par_lc2; eauto.
       eapply MatchSubst_lc3; eauto. auto.
  - (* axiom app / axiom app *)
    inversion H0; subst. inversion H11; subst.
    pattern_head_tm_agree.
    assert (a_Fam F = a_Fam F0).
      { eapply transitivity. symmetry. eapply axiom_pattern_head; eauto.
        eapply transitivity. symmetry. eapply tm_subpattern_agree_const_same.
        eauto. auto.
      }
    inversion H17; subst. axioms_head_same.
    use_size_induction a0 ac Par1 Par2.
    use_size_induction a3 bc Par3 Par4.
    exists (matchsubst (a_App ac nu bc) p' b'). split.
    + eapply axiom_app_confluence. eauto. eapply H0. eapply H1.
      eapply H2. all: eauto.
    + assert (Q : matchsubst (a_App ac nu bc) p' b' =
                          matchsubst (a_App ac nu bc) p'0 b'0).
      { assert (tm_tm_agree a0 a'). { eapply pattern_like_tm_par; eauto. }
        assert (tm_tm_agree a0 a'0). { eapply pattern_like_tm_par; eauto. }
        assert (Q3 : tm_tm_agree a' ac).
         { eapply pattern_like_tm_par; eauto.
           eapply tm_subpattern_agree_cong; eauto.
           intro. eapply H7. eapply tm_pattern_agree_cong; eauto.
           apply tm_tm_agree_sym. auto. }
        assert (Q4 : tm_tm_agree a'0 ac).
         { eapply pattern_like_tm_par; eauto.
           eapply tm_subpattern_agree_cong; eauto.
           intro. eapply H7. eapply tm_pattern_agree_cong; eauto.
           apply tm_tm_agree_sym. auto. }
        move: (axiom_body_fv_in_pattern H) => h. simpl in h.
        move: (rctx_fv (Par_roleing_tm_snd Par1)) => h'.
        move: (rctx_fv (Par_roleing_tm_snd Par3)) => h''.
        move: (Par_lc1 Par3) => l1. move: (Par_lc2 Par3) => l2.
        eapply MatchSubst_Rename_preserve with (a := a_App ac nu bc)(p := p0).
        eapply tm_pattern_agree_cong with (a1 := a_App a' nu a1').
        eapply (tm_pattern_agree_rename_inv_2 (MatchSubst_match H4) H3).
        clear - Q3 l1 l2. eauto. eapply H3. eapply H14. simpl.
        clear - h h' h''. fsetdec. simpl. clear - h h' h''. fsetdec.
        clear - H. apply uniq_atoms_toplevel in H. auto.
        eapply matchsubst_fun_ind.
        eapply tm_pattern_agree_cong with (a1 := a_App a' nu a1').
        eapply MatchSubst_match; eauto. clear - Q3 l1 l2. eauto.
        eapply Rename_lc4; eauto. auto.
        eapply matchsubst_fun_ind.
        eapply tm_pattern_agree_cong with (a1 := a_App a'0 nu a1'0).
        eapply MatchSubst_match; eauto. econstructor. auto.
        eapply Par_lc1; eauto. eapply Par_lc2; eauto.
        eapply Rename_lc4; eauto. auto. } rewrite Q.

        eapply axiom_app_confluence. eauto. eapply H0. eapply H12.
        eapply H13. all: eauto.
  - inversion H0. assert False.
    eapply pattern_like_tm_par; try apply H9; eauto.
    contradiction.
  - (* axiom capp / capp *)
    inversion H0.
    assert (tm_tm_agree a0 a'0). eapply pattern_like_tm_par; eauto.
    use_size_induction a0 ac Par1 Par2.
    pose (Q1 := tm_pattern_agree_rename_inv_2 (MatchSubst_match H3) H2).
    assert (tm_tm_agree a' ac).
        { eapply pattern_like_tm_par; eauto.
          eapply tm_subpattern_agree_sub_capp; eauto.
          intro. eapply tm_subpattern_agree_capp_contr; eauto.
         }
    exists (matchsubst (a_CApp ac g_Triv) p' b'). split.
     + eapply axiom_capp_confluence. eauto. eauto. eapply H1. all: eauto.
     + eapply Par_AxiomCApp; eauto.
       split. eapply tm_subpattern_agree_cong. eapply H5. auto.
       intro. apply H6. eapply tm_pattern_agree_cong; eauto.
       apply tm_tm_agree_sym; auto. eapply matchsubst_fun_ind.
       eapply tm_pattern_agree_cong. eapply MatchSubst_match; eauto. eauto.
       eapply MatchSubst_lc3; eauto. auto.
  - (* axiom capp / axiom capp *)
    inversion H0; subst. inversion H10; subst.
    pattern_head_tm_agree.
    assert (a_Fam F = a_Fam F0).
      { eapply transitivity. symmetry. eapply axiom_pattern_head; eauto.
        eapply transitivity. symmetry. eapply tm_subpattern_agree_const_same.
        eauto. auto.
      }
    inversion H15; subst. axioms_head_same.
    use_size_induction a0 ac Par1 Par2.
    exists (matchsubst (a_CApp ac g_Triv) p' b'). split.
    + eapply axiom_capp_confluence. eauto. eapply H0. eapply H1. all: eauto.
    + assert (Q : matchsubst (a_CApp ac g_Triv) p' b' =
                  matchsubst (a_CApp ac g_Triv) p'0 b'0).
      { assert (tm_tm_agree a0 a'). { eapply pattern_like_tm_par; eauto. }
        assert (tm_tm_agree a0 a'0). { eapply pattern_like_tm_par; eauto. }
        assert (Q3 : tm_tm_agree a' ac).
         { eapply pattern_like_tm_par; eauto.
           eapply tm_subpattern_agree_cong; eauto.
           intro. eapply H6. eapply tm_pattern_agree_cong; eauto.
           apply tm_tm_agree_sym. auto. }
        assert (Q4 : tm_tm_agree a'0 ac).
         { eapply pattern_like_tm_par; eauto.
           eapply tm_subpattern_agree_cong; eauto.
           intro. eapply H6. eapply tm_pattern_agree_cong; eauto.
           apply tm_tm_agree_sym. auto. }
        move: (axiom_body_fv_in_pattern H) => h. simpl in h.
        move: (rctx_fv (Par_roleing_tm_snd Par1)) => h'.
        eapply MatchSubst_Rename_preserve with (a := a_CApp ac g_Triv)(p := p0).
         * eapply tm_pattern_agree_cong.
           eapply tm_pattern_agree_rename_inv_2.
           eapply MatchSubst_match. eapply H3. eauto. eauto.
         * eapply H2.
         * eapply H12.
         * clear - h h'. simpl. fsetdec.
         * clear - h h'. simpl. fsetdec.
         * clear - H. apply uniq_atoms_toplevel in H. auto.
         * eapply matchsubst_fun_ind. eapply tm_pattern_agree_cong.
           eapply MatchSubst_match; eauto. eauto. eapply Rename_lc4; eauto.
           auto.
         * eapply matchsubst_fun_ind. eapply tm_pattern_agree_cong.
           eapply MatchSubst_match; eauto. eauto. eapply Rename_lc4; eauto.
           auto. 
         } rewrite Q.

        eapply axiom_capp_confluence. eauto. eapply H0. eapply H11.
        all: eauto.
    (* Patterns *)
  - use_size_induction a0 ac Par1 Par2.
    use_size_induction b1 b1c Par3 Par4.
    use_size_induction b2 b2c Par5 Par6.
    exists (a_Pattern Nom ac F Apps5 b1c b2c).
    split; eapply Par_Pattern; eauto.
  - use_size_induction a0 ac Par1 Par2.
    use_size_induction b1 b1c Par3 Par4.
    use_size_induction b2 b2c Par5 Par6.
    have h0: AppsPath Nom a'0 F Apps5.
    { auto. }
    pose (P := Par_AppsPath (conj h0 H11) Par2). inversion P.
    exists (a_CApp (applyArgs ac b1c) g_Triv).
    assert (ApplyArgs ac b1c (applyArgs ac b1c)).
    {eapply applyArgs_ApplyArgs. eapply AppsPath_CasePath; eauto.
     eapply Par_lc2; eauto. auto. }
    split. eapply Par_PatternTrue; eauto.
    econstructor. eapply apply_args_par; eauto using AppsPath_CasePath.
  - use_size_induction a0 ac Par1 Par2.
    use_size_induction b1 b1c Par3 Par4.
    use_size_induction b2 b2c Par5 Par6.
    assert (~ AppsPath Nom ac F Apps5). intro. apply H10.
    eapply AppsPath_Par; eauto. 
    exists b2c. split; eauto.
    eapply Par_PatternFalse; eauto. eapply Value_par_Value; eauto.
  - use_size_induction a0 ac Par1 Par2.
    use_size_induction b1 b1c Par3 Par4.
    use_size_induction b2 b2c Par5 Par6.
    have h0: AppsPath Nom a' F Apps5.
    { auto. } 
    pose (P := Par_AppsPath (conj h0 H4) Par1). inversion P.
    exists (a_CApp (applyArgs ac b1c) g_Triv).
    assert (ApplyArgs ac b1c (applyArgs ac b1c)).
    {eapply applyArgs_ApplyArgs; eauto using AppsPath_CasePath.
     eapply Par_lc2; eauto using AppsPath_CasePath. }
    split. econstructor. eapply apply_args_par; eauto using AppsPath_CasePath.
    eapply Par_PatternTrue; eauto.
  - use_size_induction a0 ac Par1 Par2.
    use_size_induction b1 b1c Par3 Par4.
    use_size_induction b2 b2c Par5 Par6.
    have h0: AppsPath Nom a' F Apps5. auto.
    have h1: AppsPath Nom a'0 F Apps5. auto.
    pose (P := Par_AppsPath (conj h0 H4) Par1). inversion P.
    pose (Q := Par_AppsPath (conj h1 H14) Par2). inversion Q.
    exists (a_CApp (applyArgs ac b1c) g_Triv).
    assert (ApplyArgs ac b1c (applyArgs ac b1c)).
    {eapply applyArgs_ApplyArgs; eauto using AppsPath_CasePath.
     eapply Par_lc2; eauto. }
    split. econstructor. eapply apply_args_par; eauto.
    eapply AppsPath_CasePath; eauto.
    eapply apply_args_par; eauto using AppsPath_CasePath.
  - use_size_induction a0 ac Par1 Par2.
    have P: AppsPath Nom ac F Apps5.
    { eapply Par_AppsPath. eauto. eauto. }
    assert (~ AppsPath Nom ac F Apps5). intro. apply H13.
    eapply AppsPath_Par; eauto. contradiction.
  - use_size_induction a0 ac Par1 Par2.
    use_size_induction b1 b1c Par3 Par4.
    use_size_induction b2 b2c Par5 Par6.
    assert (~ AppsPath Nom ac F Apps5). intro. apply H3.
    eapply AppsPath_Par; eauto. exists b2c. split; eauto.
    eapply Par_PatternFalse; eauto. eapply Value_par_Value; eauto.
  - use_size_induction a0 ac Par1 Par2.
    pose (P := H11). pose (Q := Par_AppsPath (conj P H13) Par2); eauto.
    inversion Q. assert (~ AppsPath Nom ac F Apps5). intro. apply H3.
    eapply AppsPath_Par; eauto. contradiction.
  - use_size_induction a0 ac Par1 Par2.
    use_size_induction b1 b1c Par3 Par4.
    use_size_induction b2 b2c Par5 Par6. eauto.
Qed. 

Lemma confluence : forall W a a1 R, Par W a a1 R -> 
                   forall a2, Par W a a2 R -> exists b,
                           Par W a1 b R /\ Par W a2 b R.
Proof.
  intros.
  eapply confluence_size; eauto.
Qed.


(* ---------------------------------------------------------------------- *)

Lemma multipar_lc1 : forall W a b R, multipar W a b R -> lc_tm a.
Proof. intros. eapply roleing_lc; eapply multipar_roleing_tm_fst; eauto.
Qed.

Lemma multipar_lc2 : forall W a b R, multipar W a b R -> lc_tm b.
Proof. intros. eapply roleing_lc; eapply multipar_roleing_tm_snd; eauto.
Qed.

Lemma multipar_Star : forall W A B R, multipar W A B R -> A = a_Star -> B = a_Star.
Proof.
  intros W A B R H. induction H. auto.
  inversion H; intro K; auto; try inversion K.
Qed.


Lemma multipar_Bullet : forall W B R, multipar W a_Bullet B R -> B = a_Bullet.
Proof.
  intros W B R H. dependent induction H. auto.
  inversion H; auto; try inversion K.
Qed.


Lemma multipar_Pi : forall W rho A B R', multipar W A B R' -> 
      forall A1 A2, A = a_Pi rho A1 A2 -> exists B1 B2, B = (a_Pi rho B1 B2).
Proof.
intros W rho A B R' H. induction H. intros. subst. exists A1, A2. auto.
intros. subst.
inversion H; subst; try (destruct (IHmultipar _ _ eq_refl) as [B1 [B2 EQ]]; auto;
exists B1, B2; auto).
Qed.

Lemma multipar_CPi : forall W A C R', multipar W A C R' -> 
        forall A1 A2 A3 R B, A = a_CPi (Eq A1 A2 A3 R) B -> exists B1 B2 B3 C2,
        C = (a_CPi (Eq B1 B2 B3 R) C2).
Proof.
  intros W A C R' H. induction H; intros; subst.
  exists A1, A2, A3, B. auto.
  inversion H; subst; try (destruct (IHmultipar _ _ _ _ _ eq_refl) as [B1 [B2 [C2 EQ]]];
  auto; exists B1, B2, C2; auto).
Qed.

Lemma multipar_UAbs : forall W rho a b R',
    multipar W (a_UAbs rho a) b R' ->
    (exists b2, b = (a_UAbs rho b2)).
Proof.
  intros W rho a b R' H. dependent induction H.
  - exists a. auto.
  - destruct (Par_Abs_inversion H) as [a' [EQ _]]; subst.
    destruct (IHmultipar _ a' eq_refl) as [b2 EQ2]; subst; clear IHmultipar.
    exists b2. auto.
Qed.

Lemma multipar_CAbs : forall W A C R', multipar W A C R' -> 
        forall A1 A2 A3 R B, A = a_CAbs (Eq A1 A2 A3 R) B -> exists B1 B2 B3 C2,
        C = (a_CAbs (Eq B1 B2 B3 R) C2).
Proof.
  intros W A C R' H. induction H; intros; subst.
  exists A1, A2, A3, B. auto.
  inversion H; subst; try (destruct (IHmultipar _ _ _ _ _ eq_refl) as [B1 [B2 [C2 EQ]]];
    auto; exists B1, B2, C2; auto).
Qed.

Lemma consist_sym : forall a b R, consistent a b R -> consistent b a R.
Proof. intros. induction H; eauto.
Qed.

(* --------------------------------------------------- *)

(* RolePaths and consistency *)

Inductive Path_head_form : tm -> Prop :=
   | head_Fam : forall F, Path_head_form (a_Fam F)
   | head_App : forall a nu b, Path_head_form (a_App a nu b)
   | head_CApp : forall a g, Path_head_form (a_CApp a g).
Hint Constructors Path_head_form.

Inductive not_Path_head_form : tm -> Prop :=
   | not_head_Pi : forall rho A b, not_Path_head_form (a_Pi rho A b)
   | not_head_CPi : forall phi b, not_Path_head_form (a_CPi phi b).
Hint Constructors not_Path_head_form.

Lemma Path_head_form_Path_consist : forall W F a b R, CasePath R a F ->
                       multipar W a b R -> consistent a b R.
Proof. intros. eapply consistent_a_CasePath; eauto.
       eapply multipar_CasePath; eauto.
Qed.

Lemma Path_head_form_no_Path_consist : forall a b R, Path_head_form a ->
         lc_tm b -> (forall F, ~(CasePath R a F)) -> consistent a b R.
Proof. intros. eapply consistent_a_Step_L. auto.
       intro H2; inversion H2; subst; try (inversion H; fail).
       pose (Q := H1 F); contradiction.
Qed.

Lemma Path_head_form_consist : forall W a b R, Path_head_form a ->
                multipar W a b R -> consistent a b R.
Proof. intros. inversion H; subst.
       all: (assert (H' := H0); apply multipar_roleing_tm_fst in H';
       apply decide_CasePath in H'; inversion H' as [[F0 Q]|n]).
       all: try(eapply Path_head_form_Path_consist; eauto; fail).
       all: try(apply multipar_lc2 in H0;
            eapply Path_head_form_no_Path_consist; eauto; fail).
Qed.

Lemma Path_head_form_join_consist : forall W a b R, joins W a b R ->
             Path_head_form a -> Path_head_form b -> consistent a b R.
Proof. intros. destruct H as (t & MSL & MSR).
       assert (P := MSL); assert (Q := MSR).
       apply multipar_roleing_tm_fst in P. apply multipar_roleing_tm_fst in Q.
       apply decide_CasePath in P. apply decide_CasePath in Q.
       inversion P as [[F1 S]|n]. inversion Q as [[F2 S']|n'].
       assert (F1 = F2). eapply multipar_CasePath_join_head. eapply MSL.
       eapply MSR. auto. auto. subst. eauto.
       apply multipar_lc1 in MSL. apply consist_sym.
       eapply Path_head_form_no_Path_consist; eauto.
       apply multipar_lc1 in MSR. eapply Path_head_form_no_Path_consist; eauto.
Qed.


Lemma Path_head_not_head_join_consist : forall W a b R, joins W a b R ->
             Path_head_form a -> not_Path_head_form b -> consistent a b R.
Proof. intros. destruct H as (t & MSL & MSR).
    assert (P := MSL). apply multipar_roleing_tm_fst in P.
    apply decide_CasePath in P. inversion P as [[F S]|n].
    eapply multipar_CasePath in MSL; eauto. inversion H1; subst.
    destruct (multipar_Pi MSR eq_refl) as (b1 & b2 & Q); subst.
    apply CasePath_ValuePath in MSL. inversion MSL.
    destruct phi; subst. 
    destruct (multipar_CPi MSR eq_refl) as (b1 & b2 & B & C & Q). subst.
    apply CasePath_ValuePath in MSL. inversion MSL. apply multipar_lc1 in MSR.
    apply Path_head_form_no_Path_consist; eauto.
Qed.

Lemma Path_not_head_head_join_consist : forall W a b R, joins W a b R ->
             not_Path_head_form a -> Path_head_form b -> consistent a b R.
Proof. intros. destruct H as (t & MSL & MSR).
    assert (Q := MSR). apply multipar_roleing_tm_fst in Q.
    apply decide_CasePath in Q. inversion Q as [[F S]|n].
    eapply multipar_CasePath in MSR; eauto. inversion H0; subst.
    destruct (multipar_Pi MSL eq_refl) as (b1 & b2 & U); subst.
    apply CasePath_ValuePath in MSR. inversion MSR. destruct phi; subst.
    destruct (multipar_CPi MSL eq_refl) as (b' & b2 & B & C & U). subst.
    apply CasePath_ValuePath in MSR. inversion MSR. apply multipar_lc1 in MSL.
    apply consist_sym. apply Path_head_form_no_Path_consist; eauto.
Qed.

(* --------------------------------------------------- *)

Lemma ValuePath_sub_app : forall a nu b F, ValuePath (a_App a nu b) F ->
                                                        ValuePath a F.
Proof. intros. dependent induction H; eauto.
Qed.

Lemma ValuePath_sub_capp : forall a F, ValuePath (a_CApp a g_Triv) F ->
                                                        ValuePath a F.
Proof. intros. dependent induction H; eauto.
Qed.

Lemma Path_par_app_inversion : forall W F nu a b c R,
          CasePath R (a_App a nu b) F -> Par W (a_App a nu b) c R ->
          exists a' b', c = a_App a' nu b'.
Proof. intros. inversion H; subst; eauto.
        - inversion H0; subst. eauto.
          pose (P := ValuePath_cs_par_ValuePath (ValuePath_sub_app H1) H2 H9).
          inversion P. inversion H3. exists a',b'; auto. inversion H7.
          pattern_head_tm_agree. apply ValuePath_head in H1.
          simpl in H1. rewrite H1 in U1. inversion U1; subst.
          axioms_head_same.
        - inversion H0; subst. eauto.
          pose (P := ValuePath_ax_par_ValuePath_1 (ValuePath_sub_app H1)
          H2 H3 H10). inversion P. inversion H4. exists a',b'; auto.
          inversion H8. pattern_head_tm_agree. apply ValuePath_head in H1.
          simpl in H1. rewrite H1 in U1. inversion U1; subst.
          axioms_head_same. contradiction.
        - assert(~ subtm_pattern_agree a p). {intro. apply H3.
          eapply subtm_pattern_agree_App. apply ValuePath_lc in H1.
          inversion H1; subst. auto. auto. }
          inversion H0; subst. eauto.
          pose (P := ValuePath_ax_par_ValuePath_2 (ValuePath_sub_app H1)
          H2 H4 H11). inversion P. inversion H5.
          exists a',b'; auto.
          inversion H9. pattern_head_tm_agree. pose (P0 := ValuePath_head H1).
          simpl in P0. rewrite P0 in U1. inversion U1; subst.
          axioms_head_same.
          pose (P := tm_pattern_agree_rename_inv_2 (MatchSubst_match H16) H13).
          assert False. eapply H3. econstructor. eapply tm_pattern_agree_cong.
          eauto. econstructor. apply tm_tm_agree_sym.
          eapply ValuePath_ax_par_ValuePath_2; eauto.
          apply (ValuePath_sub_app H1). eapply Par_lc2; eauto.
          eapply Par_lc1; eauto. contradiction.
Qed.

Lemma Path_par_capp_inversion : forall W F a c R,
          CasePath R (a_CApp a g_Triv) F -> Par W (a_CApp a g_Triv) c R ->
          exists a', c = a_CApp a' g_Triv.
Proof. intros. inversion H; subst; eauto.
        - inversion H0; subst. eauto.
          pose (P := ValuePath_cs_par_ValuePath (ValuePath_sub_capp H1) H2 H5).
          inversion P. inversion H4. exists a'; auto. inversion H5.
          pattern_head_tm_agree. apply ValuePath_head in H1.
          simpl in H1. rewrite H1 in U1. inversion U1; subst.
          axioms_head_same.
        - inversion H0; subst. eauto.
          pose (P := ValuePath_ax_par_ValuePath_1 (ValuePath_sub_capp H1)
          H2 H3 H6). inversion P. inversion H4. exists a'; auto.
          inversion H6. pattern_head_tm_agree. apply ValuePath_head in H1.
          simpl in H1. rewrite H1 in U1. inversion U1; subst.
          axioms_head_same. contradiction.
        - assert(~ subtm_pattern_agree a p). {intro. apply H3.
          eapply subtm_pattern_agree_CAppp. auto. }
          inversion H0; subst. eauto.
          pose (P := ValuePath_ax_par_ValuePath_2 (ValuePath_sub_capp H1)
          H2 H4 H7). inversion P. inversion H5.
          exists a'; auto.
          inversion H7. pattern_head_tm_agree. pose (P0 := ValuePath_head H1).
          simpl in P0. rewrite P0 in U1. inversion U1; subst.
          axioms_head_same.
          pose (P := tm_pattern_agree_rename_inv_2 (MatchSubst_match H10) H9).
          assert False. eapply H3. econstructor. eapply tm_pattern_agree_cong.
          eauto. econstructor. apply tm_tm_agree_sym.
          eapply ValuePath_ax_par_ValuePath_2; eauto.
          apply (ValuePath_sub_capp H1). contradiction.
Qed.

Lemma Path_par_app_fst : forall W F nu a b a' b' R,
      CasePath R (a_App a nu b) F ->
      Par W (a_App a nu b) (a_App a' nu b') R -> Par W a a' R.
Proof. intros. inversion H0; subst.
       - inversion H6; subst; eauto.
       - move: (Par_CasePath (CasePath_app H) H7) => h.
         apply CasePath_ValuePath in h. inversion h.
       - auto.
       - inversion H5; subst. pattern_head_tm_agree.
         move: (CasePath_head H) => h. simpl in h.
         rewrite U1 in h. inversion h; subst. inversion H; subst.
         all:axioms_head_same. contradiction.
         assert False. apply H10. econstructor.
         eapply tm_pattern_agree_cong.
         eapply tm_pattern_agree_rename_inv_2.
         eapply MatchSubst_match; eauto. eauto.
         econstructor. apply tm_tm_agree_sym.
         eapply ValuePath_ax_par_ValuePath_2; eauto.
         inversion H3; subst; auto. intro.
         apply H2. apply tm_pattern_agree_sub; auto.
         eapply Par_lc2; eauto. eapply Par_lc1; eauto.
         contradiction.
Qed.

Lemma Path_par_app_snd : forall W F nu a b a' b' R,
      CasePath R (a_App a nu b) F ->
      Par W (a_App a nu b) (a_App a' nu b') R ->
      Par W b b' (app_role nu R).
Proof. intros. inversion H0; subst.
       - inversion H6; subst; eauto.
       - move: (Par_CasePath (CasePath_app H) H7) => h.
         apply CasePath_ValuePath in h. inversion h.
       - auto.
       - inversion H5; subst. pattern_head_tm_agree.
         move: (CasePath_head H) => h. simpl in h.
         rewrite U1 in h. inversion h; subst. inversion H; subst.
         all:axioms_head_same. contradiction.
         assert False. apply H10. econstructor.
         eapply tm_pattern_agree_cong.
         eapply tm_pattern_agree_rename_inv_2.
         eapply MatchSubst_match; eauto. eauto.
         econstructor. apply tm_tm_agree_sym.
         eapply ValuePath_ax_par_ValuePath_2; eauto.
         inversion H3; subst; auto. intro.
         apply H2. apply tm_pattern_agree_sub; auto.
         eapply Par_lc2; eauto. eapply Par_lc1; eauto.
         contradiction.
Qed.

Lemma Path_par_capp : forall W F a a' R, CasePath R (a_CApp a g_Triv) F ->
      Par W (a_CApp a g_Triv) (a_CApp a' g_Triv) R -> Par W a a' R.
Proof. intros. inversion H0; subst.
       - inversion H4; subst; eauto.
       - move: (Par_CasePath (CasePath_capp H) H4) => h.
         apply CasePath_ValuePath in h. inversion h.
       - auto.
       - inversion H3; subst. pattern_head_tm_agree.
         move: (CasePath_head H) => h. simpl in h.
         rewrite U1 in h. inversion h; subst. inversion H; subst.
         all:axioms_head_same. contradiction.
         assert False. apply H11. econstructor.
         eapply tm_pattern_agree_cong.
         eapply tm_pattern_agree_rename_inv_2.
         eapply MatchSubst_match; eauto. eauto.
         econstructor. apply tm_tm_agree_sym.
         eapply ValuePath_ax_par_ValuePath_2; eauto.
         inversion H9; subst; auto.
         contradiction.
Qed.

Lemma Path_multipar_app_inversion : forall W F nu a b c R,
          CasePath R (a_App a nu b) F -> multipar W (a_App a nu b) c R ->
          exists a' b', c = a_App a' nu b'.
Proof. intros. dependent induction H0.
        - eauto.
        - pose (H2 := H1).
          apply Path_par_app_inversion with (F := F) in H2; eauto 1.
          inversion H2 as [a1 [b1 P]].
          pose (H3 := H1). subst.
          apply Par_CasePath with (F := F) in H3; auto 1.
          destruct (IHmultipar nu a1 b1 H3 ltac:(auto)) as [a2 [b2 Q]].
          eauto.
Qed.

Lemma Path_multipar_capp_inversion : forall W F a c R,
        CasePath R (a_CApp a g_Triv) F -> multipar W (a_CApp a g_Triv) c R ->
        exists a', c = a_CApp a' g_Triv.
Proof. intros. dependent induction H0.
        - eauto.
        - pose (H2 := H1).
          apply Path_par_capp_inversion with (F := F) in H2; eauto 1.
          inversion H2 as [a1 P]. subst.
          pose (H3 := H1).
          apply Par_CasePath with (F := F) in H3; auto 1.
          destruct (IHmultipar a1 H3 ltac:(auto)) as [a2 Q].
          eauto.
Qed.

Lemma Path_multipar_app_fst : forall W F nu a b a' b' R,
      CasePath R (a_App a nu b) F ->
      multipar W (a_App a nu b) (a_App a' nu b') R ->
      multipar W a a' R.
Proof. intros. dependent induction H0.
        - inversion H0; subst; eauto.
        - pose (H2 := H1).
          apply Path_par_app_inversion with (F := F) in H2; eauto 1.
          inversion H2 as [a1 [b1 P]]. subst.
          pose (H3 := H1). move: (Par_CasePath H H3) => h.
          apply Path_par_app_fst with (F := F) in H3; auto 1.
          eauto.
Qed.

Lemma Path_multipar_app_snd :  forall W F nu a b a' b' R,
      CasePath R (a_App a nu b) F ->
      multipar W (a_App a nu b) (a_App a' nu b') R ->
      multipar W b b' (app_role nu R).
Proof. intros. dependent induction H0.
        - inversion H0; subst; eapply multipar_sub; eauto.
        - pose (H2 := H1).
          apply Path_par_app_inversion with (F := F) in H2; eauto 1.
          inversion H2 as [a1 [b1 P]]. subst.
          pose (H3 := H1). move: (Par_CasePath H H3) => h.
          apply Path_par_app_snd with (F := F) in H3; auto 1.
          eauto.
Qed.

Lemma Path_multipar_capp : forall W F a a' R, CasePath R (a_CApp a g_Triv) F ->
      multipar W (a_CApp a g_Triv) (a_CApp a' g_Triv) R ->
      multipar W a a' R.
Proof. intros. dependent induction H0.
        - inversion H0; subst; eauto.
        - pose (H2 := H1).
          apply Path_par_capp_inversion with (F := F) in H2; eauto 1.
          inversion H2 as [a1 P]. subst.
          pose (H3 := H1). move: (Par_CasePath H H3) => h.
          apply Path_par_capp with (F := F) in H3; auto 1.
          eauto.
Qed.

(* ------------------------------------------------------ *)

Lemma joins_lc_fst : forall W a b R, joins W a b R -> lc_tm a.
Proof. intros. inversion H as [T [H1 H2]]. 
       apply multipar_roleing_tm_fst in H1.
       eapply roleing_lc. eauto.
Qed.

Lemma joins_lc_snd : forall W a b R, joins W a b R -> lc_tm b.
Proof. intros. inversion H as [T [H1 H2]].
       apply multipar_roleing_tm_fst in H2.
       eapply roleing_lc. eauto.
Qed.

(* Proof that joinability implies consistency. *)

Ltac step_left := eapply consistent_a_Step_R;
   [eapply joins_lc_fst; eauto | intro N; inversion N;
      subst; match goal with
             [ Q : CasePath _ _ _ |- _ ] => apply CasePath_ValuePath in Q;
                                            inversion Q
             end ]; fail.
Ltac step_right := eapply consistent_a_Step_L;
   [eapply joins_lc_snd; eauto | intro N; inversion N;
      subst; match goal with
             [ Q : CasePath _ _ _ |- _ ] => apply CasePath_ValuePath in Q;
                                            inversion Q
             end ]; fail.

(* look for a multipar involving a head form and apply the appropriate lemma for that
   head form. Note: for paths, the lemma has already been applied so we only need
   to look for a hypothesis about path consistency. *)
Ltac multipar_step :=
  match goal with
  | [ SIDE : multipar _ a_Star _ _ |- _ ] =>
    apply multipar_Star in SIDE; auto; subst
  (* *)
  | [ SIDE : multipar _ (a_Pi _ _ _) _ _ |- _ ] =>
    destruct (multipar_Pi SIDE eq_refl) as [b1' [b2' EQ]]; clear SIDE; subst
  | [ SIDE : multipar _ (a_CPi ?phi _) _ _ |- _ ] =>
    try (destruct phi); destruct (multipar_CPi SIDE eq_refl)
      as (B1' & B2' & C1' & C2' &  EQ); clear SIDE; subst
  end.

Lemma join_consistent : forall W a b R, joins W a b R -> consistent a b R.
Proof.
  intros. assert (H' := H).
  destruct H as (TT & MSL & MSR).
  destruct a; try step_right; destruct b; try step_left; auto.
  all: try multipar_step; try (multipar_step; inversion EQ).
  all: try (apply consist_sym; eapply Path_head_form_consist; eauto; fail).
  all: try (eapply Path_head_form_consist; eauto; fail).
  all: try (eapply Path_head_form_join_consist; eauto; fail).
  all: try (eapply Path_head_not_head_join_consist; eauto; fail).
  all: try (eapply Path_not_head_head_join_consist; eauto; fail).
  - destruct (multipar_Pi MSL eq_refl) as [c1 [c2 EQ]].
    inversion EQ; subst. econstructor. apply joins_lc_fst in H'.
    inversion H'; auto. eapply joins_lc_fst; eauto. apply joins_lc_snd in H'.
    inversion H'; auto. eapply joins_lc_snd; eauto.
  - destruct phi. destruct (multipar_CPi MSL eq_refl)
    as (c1 & c2 & c3 & c4 &  EQ). inversion EQ; subst. econstructor.
    apply joins_lc_fst in H'. inversion H'; auto. 
    eapply joins_lc_fst; eauto. apply joins_lc_snd in H'.
    inversion H'; auto. eapply joins_lc_snd; eauto.
Qed.

(*

a  -> b -->* c      d - by confluence
|     |      |      e - by induction
v     v      v
a2 -> d -->* e
*)

Lemma multipar_confluence_helper : forall W a a1 R, multipar W a a1 R
-> forall a2, Par W a a2 R -> exists e, Par W a1 e R /\ multipar W a2 e R.
Proof.
  intros W a a1 R H. induction H.
  - intros. exists a2. split. auto. econstructor.
    eapply Par_roleing_tm_snd; eauto.
  - intros. destruct (confluence H H1) as [d [Hx Hy]].
      destruct (IHmultipar d Hx) as [e [LL RR]]; auto.
      exists e. split; eauto.
Qed.

(*

a -->  b -->* c    d - by prior lemma
|      |      |    e - by induction.
v      v      v
*      *      *
a2 --> d -->* e

*)

Lemma multipar_confluence : forall W a a1 R, multipar W a a1 R
-> forall a2, multipar W a a2 R ->
   exists b, multipar W a1 b R /\ multipar W a2 b R.
Proof.
  intros W a a1 R MP. induction MP; intros.
 - exists a2. split. eauto. econstructor.
   eapply multipar_roleing_tm_snd; eauto.
 - destruct (multipar_confluence_helper H0 H) as [d [Hx Hy]].
   destruct (IHMP d Hy) as [e [LL RR]]; auto.
   exists e. split; eauto.
Qed.

Lemma multipar_append : forall W a b c R, multipar W a b R -> 
                        multipar W b c R -> multipar W a c R.
Proof.
  intros.
  induction H. auto.
  eauto.
Qed.

(*
    a   b   c
     \ / \ /
      ab  bc
       \ /
        d
 *)


Lemma join_transitive : forall W a b R, joins W a b R -> 
                        forall c, joins W b c R -> joins W a c R.
Proof.
  intros W a b R H. destruct H as [t [H1 H2]].
  intros c H. destruct H as [t' [H3 H4]].
  destruct (multipar_confluence H2 H3) as [d [H5 H6]].
  unfold joins.
  exists d. split; eapply multipar_append; eauto.
Qed.

Lemma join_symmetry: forall W a b R, joins W a b R -> joins W b a R.
Proof.
  intros W a b R H.
  destruct H as [ac h0].
  split_hyp.
  exists ac; eauto.
Qed.


Definition extends (G G2 : context) := exists G1, G = G1 ++ G2.

Lemma Good_NoAssn: forall c phi G D, Good G D -> c `notin` D -> Good ((c, Co phi) :: G) D.
Proof.
  intros.
  unfold Good in *. intros.
  apply binds_cons_iff in H1.
  inversion H1. inversion H3; subst. contradiction.
  eapply H; eauto.
Qed.

Hint Resolve Good_NoAssn.

Lemma Good_add_tm: forall G D x A, Good G D -> x `notin` (dom G) ->
                                     Good ((x, Tm A)::G ) D.
Proof.
  intros.
  unfold Good in *.
  intros. apply binds_cons_iff in H1.
  inversion H1 as [P1 | P2]. inversion P1. inversion H4.
  destruct (H c1 A0 B1 T1 R P2 H2) as (t & Eq). simpl.
  replace ((x, Nom) :: (ctx_nom G)) with (nil ++ [(x, Nom)] ++ (ctx_nom G)); auto.
  inversion Eq. pose (Q := Par_rctx_uniq H3). apply notin_ctx_rctx in H0.
  exists t; split; eapply par_app_rctx; simpl_env; eauto.
Qed.

Lemma Good_add_tm_2: forall G D x A, x `notin` dom G -> Good G D -> Good ((x, Tm A)::G ) (add x D).
Proof.
  intros G D x A N H0.
  unfold Good in *. intros.
  apply binds_cons_1 in H.
  destruct H. destruct H. inversion H2.
  destruct (H0 c1 A0 B1 T1 R H) as [C [H2 H3]].
  move: (binds_In _ c1 _ _ H) => b0. fsetdec. simpl.
  replace ((x, Nom) :: (ctx_nom G)) with (nil ++ [(x, Nom)] ++ (ctx_nom G)); auto.
  pose (Q := Par_rctx_uniq H3). apply notin_ctx_rctx in N.
  exists C; split; eapply par_app_rctx; simpl_env; eauto.
Qed.


Lemma multipar_app_left:
  forall nu R a a' c' W, roleing W a R -> multipar W a' c' (app_role nu R) ->
                      multipar W (a_App a nu a') (a_App a nu c') R.
Proof.
  intros.
  dependent induction H0; intros; eauto; try done.
  eapply par_multipar. eapply Par_App; eauto.
Qed.

Lemma multipar_capp_left: forall a a' W R, multipar W a a' R ->
                     multipar W (a_CApp a g_Triv) (a_CApp a' g_Triv) R.
Proof.
  induction 1; eauto; try done.
Qed.

Lemma join_capp: forall a a' W R, joins W a a' R ->
                     joins W (a_CApp a g_Triv) (a_CApp a' g_Triv) R.
Proof.
  unfold joins.
  intros a a' W R H.
  destruct H as [ac h0].
  split_hyp.
  exists (a_CApp ac g_Triv).
  repeat split; eauto.
  apply multipar_capp_left; auto.
  apply multipar_capp_left; auto.
Qed.

Lemma multipar_app_lr: forall nu R a a' c c' W,
                       multipar W a c R -> multipar W  a' c' (app_role nu R) ->
                       multipar W (a_App a nu a') (a_App c nu c') R.
Proof. intros. induction H.
  eapply multipar_app_left; auto.
  apply (@mp_step W _ _ (a_App b nu a')); eauto. eapply Par_App; auto.
  eapply Par_sub. econstructor. eapply multipar_roleing_tm_fst; eauto. auto.
Qed.

Lemma join_app: forall nu R a a' b b' W, joins W a b R ->
                       joins W a' b' (app_role nu R) ->
                       joins W (a_App a nu a') (a_App b nu b') R.
Proof.
  unfold joins.
  intros nu R a a' b b' W H H0.
  destruct H as [ac h0].
  destruct H0 as [ac' h1].
  split_hyp.
  exists (a_App ac nu ac').
  repeat split; eauto.
  apply multipar_app_lr; auto; try solve [eapply roleing_lc; eauto].
  apply multipar_app_lr; auto; try solve [eapply roleing_lc; eauto].
Qed.

Lemma multipar_UAbs_exists :  ??? (x : atom) W(rho : relflag) R' (a a' : tm),
    x `notin` fv_tm_tm_tm a
       ??? multipar ([(x,Nom)] ++ W) (open_tm_wrt_tm a (a_Var_f x)) a' R'
       ??? multipar W (a_UAbs rho a) (a_UAbs rho (close_tm_wrt_tm x a')) R'.
Proof.
  intros.
  dependent induction H0.
  autorewrite with lngen. econstructor.
  apply (role_a_Abs (union (singleton x) (dom W))); eauto.
  intros x0 h0.
  rewrite (tm_subst_tm_tm_intro x a (a_Var_f x0)); auto.
  replace (app (one (pair x0 Nom)) W) with (nil ++ app (one (pair x0 Nom)) W); auto.
  assert (uniq (app (one (pair x Nom)) W)). {eapply rctx_uniq; eauto. }
  eapply subst_tm_roleing. simpl_env. eapply roleing_app_rctx; eauto.
  econstructor; eauto. solve_uniq.
  eapply mp_step.
  eapply Par_Abs_exists with (x:=x); eauto.
  eapply IHmultipar; eauto. autorewrite with lngen. auto.
  autorewrite with lngen. auto.
Qed.

Lemma multipar_iapp : forall W a c y L R',
    y `notin` fv_tm_tm_tm a \u L ->
    (forall x, x `notin` L -> RhoCheck Irrel x (open_tm_wrt_tm a (a_Var_f x))) ->
    multipar ([(y,Nom)] ++ W) (open_tm_wrt_tm a a_Bullet) c R' ->
    multipar W (a_UAbs Irrel a) (a_UAbs Irrel (close_tm_wrt_tm y c)) R'.
Proof.
  intros.
  eapply multipar_UAbs_exists; auto.
  move: (H0 y ltac:(auto)) => h0.
  inversion h0.
  rewrite -(tm_subst_tm_tm_fresh_eq (open_tm_wrt_tm a (a_Var_f y)) a_Bullet y); eauto.
  rewrite - tm_subst_tm_tm_intro; eauto.
Qed.

Lemma joins_iapp : forall W a1 a2 L1 L2 R',
    (forall x, x `notin` L1 -> RhoCheck Irrel x (open_tm_wrt_tm a1 (a_Var_f x))) ->
    (forall x, x `notin` L2 -> RhoCheck Irrel x (open_tm_wrt_tm a2 (a_Var_f x))) ->
    joins W (open_tm_wrt_tm a1 a_Bullet) (open_tm_wrt_tm a2 a_Bullet) R' ->
    joins W (a_UAbs Irrel a1) (a_UAbs Irrel a2) R'.
Proof.
  intros.
  destruct H1 as (T & P1 & P2).
  unfold joins.
  pick fresh y.
  exists (a_UAbs Irrel (close_tm_wrt_tm y T)).
  assert (uniq W). { eapply rctx_uniq. eapply multipar_roleing_tm_fst; eauto. }
  repeat split; eauto.
  eapply multipar_iapp with L1; auto.
  replace ([(y,Nom)] ++ W) with (nil ++ [(y,Nom)] ++ W); auto.
  apply multipar_app_rctx; auto.
  eapply multipar_iapp with L2; auto.
  replace ([(y,Nom)] ++ W) with (nil ++ [(y,Nom)] ++ W); auto.
  apply multipar_app_rctx; auto.
Qed.

Lemma multipar_Pattern: forall W F r a a' b1 b1' b2 b2' R0,
          multipar W a a' Nom -> multipar W b1 b1' R0 -> multipar W b2 b2' R0 ->
          multipar W (a_Pattern Nom a F r b1 b2) (a_Pattern Nom a' F r b1' b2') R0.
Proof. intros. dependent induction H. induction H0. induction H1. eauto.
  eapply mp_step with (b := (a_Pattern Nom a F r a0 b)).
  eapply Par_Pattern; eauto. auto.
  eapply mp_step with (b := (a_Pattern Nom a F r b b2)).
  eapply Par_Pattern; eauto. econstructor. eapply multipar_roleing_tm_fst; eauto.
  auto.
  eapply mp_step with (b := (a_Pattern Nom b F r b1 b2)).
  eapply Par_Pattern; eauto. econstructor. eapply multipar_roleing_tm_fst; eauto.
  econstructor. eapply multipar_roleing_tm_fst; eauto. auto.
Qed.

Ltac subst_tm_roleing_open x :=
  let K := fresh in
  let h0 := fresh in
  match goal with
  | [H16 : ??? x : atom, x `notin` ?L0 ???
                       roleing  (open_tm_wrt_tm ?B (a_Var_f x)),
     H2 : roleing ?a
     |- roleing (open_tm_wrt_tm ?B ?a) ] =>
    have: x `notin` L0; auto => h0;
    pose K := subst_tm_roleing x H2 (H16 x h0);
    clearbody K;
    repeat rewrite tm_subst_tm_tm_open_tm_wrt_tm in K; auto; try solve [apply roleing_lc; auto];
    simpl in K;
    destruct eq_dec; try congruence;
    rewrite tm_subst_tm_tm_fresh_eq in K; auto
  end.

Lemma multipar_trans : forall W a b c R, multipar W a b R -> multipar W b c R ->
                                         multipar W a c R.
Proof. intros. generalize dependent c. induction H; auto.
       intros. eauto.
Qed.

Lemma joins_SubRole : forall D a b R R', joins D a b R -> SubRole R R' -> joins D a b R'.
Proof.
  intros.
  move: H => [x [y z]].
  econstructor;
  eauto using multipar_sub.
Qed.

Lemma consistent_mutual:
  (forall S a A,   Typing S a A -> True) /\
  (forall S phi,   PropWff S phi -> True) /\
  (forall S D p1 p2, Iso S D p1 p2 -> Good S D -> (forall A1 B1 T1 A2 B2 T2 R1 R2,
                     p1 = Eq A1 B1 T1 R1 -> p2 = Eq A2 B2 T2 R2 ->
    (R1 = R2 /\ joins (ctx_nom S) A1 A2 R1 /\ joins (ctx_nom S) B1 B2 R1 /\ 
     joins (ctx_nom S) T1 T2 Rep))) /\
  (forall S D A B T R,   DefEq S D A B T R -> Good S D -> joins(ctx_nom S) A B R) /\
  (forall S,       Ctx S -> True).
Proof.
  apply typing_wff_iso_defeq_mutual; eauto; try done.
  - intros.
    inversion H2; subst.
    inversion H3; subst.
    repeat split; eauto. unfold joins.
    exists T2; eauto. apply DefEq_regularity in d0. inversion d0; subst.
    split; econstructor; eapply roleing_sub; try eapply Typing_roleing; eauto.
  - intros. inversion H3; subst.
    inversion H4; subst.
    eapply typing_roleing_mutual in p; eauto; inversion p as [px [py pz]].
    repeat split; eauto.
    all: unfold joins.
    exists A3; split; econstructor; eauto.
    exists B2; split; econstructor; eauto.
    apply H in H2. unfold joins in H2. inversion H2 as [c [P1 P2]].
    exists c; split; eapply multipar_sub; eauto.
  - intros. destruct (H H0) as [T [P1 P2]]. 
    inversion H1. inversion H2.
    subst.
    destruct (multipar_CPi P1 eq_refl) as [Ax [Bx [Tx [By EQ]]]].
    subst. 
    pose K1 := multipar_CPi_phi_proj P1.
    pose K2 := multipar_CPi_phi_proj P2.
    split_hyp. subst.
    repeat split; unfold joins.
    exists Ax; split; auto.
    exists Bx; split; auto.
    exists Tx; split; auto.
  - intros. edestruct H0; eauto. inversion H1.
    exists x; split; apply par_multipar; auto.
  - (* refl *)
    intros.
    unfold joins. exists a; split; econstructor; eapply roleing_sub;
    try eapply Typing_roleing; eauto.
  - (* symmetry *)
    intros.
    unfold joins in *. destruct H as [c [L R0]]; auto.
    exists c. tauto.
  - (* transitivity *)
    intros. eapply join_transitive; eauto.
  - (* sub *)
    intros. unfold joins in *. destruct H as [c [L R0]]; auto.
    exists c; split; eapply multipar_sub; eauto.
  - (* confluence *)
    intros.
    unfold joins in *.
    have p: Par (ctx_nom G) a1 a2 R.
    { inversion b; subst.
       - apply Typing_roleing in t; inversion t; subst.
         econstructor; econstructor; eauto.
         eapply roleing_sub; eauto.
       - apply Typing_roleing in t; inversion t; subst.
         econstructor; eauto. econstructor; eauto. eapply roleing_sub; eauto.
       - inversion H4; subst.
           + inversion H3; subst. assert (a_Fam F = a_Fam F0).
             eapply transitivity. symmetry. eapply axiom_pattern_head; eauto.
             auto. inversion H7; subst. eapply Par_AxiomBase.
             eauto. auto. eapply rctx_uniq. eapply Typing_roleing; eauto.
           + apply Typing_roleing in t; inversion t; subst.
             move: (Rename_exists (union (dom (ctx_nom G)) (fv_tm_tm_tm p))
              (axiom_pattern H2) (Rename_lc2 H3)) => h.
             inversion h as [p2 [b2 [D2 h1]]].
             assert (tm_pattern_agree (a_App a0 (Role R0) a) p2).
             { eapply tm_pattern_agree_rename_inv_1.
               eapply tm_pattern_agree_rename_inv_2.
               eapply MatchSubst_match; eauto. eauto. eauto.
             }
             eapply Par_AxiomApp. eauto.
             pose (Q := tm_pattern_agree_rename_inv_2 (MatchSubst_match H4) H3).
             split. eapply tm_subpattern_agree_sub_app; eauto.
             intro. eapply tm_pattern_agree_app_contr; try apply Q; eauto.
             eapply Par_sub; eauto. simpl. 
             eapply Par_sub with (R1 := param R0 Nom).
             eauto. eapply param_covariant; eauto.
             eauto.
             replace (tm_subst_tm_tm a x b3) with
                     (matchsubst (a_App a0 (Role R0) a) p2 b2).
             apply matchsubst_fun_ind. 
             eauto. eapply Rename_lc4; eauto. auto.
             move: (axiom_body_fv_in_pattern H2) => h2.
             apply rctx_fv in H13. apply rctx_fv in H14.
             eapply MatchSubst_Rename_preserve.
             eapply tm_pattern_agree_rename_inv_2.
             eapply MatchSubst_match. eapply H4. eauto. eauto. eapply H3.
             simpl. clear - H13 H14 h2. apply union_s_m.
             eapply AtomSetProperties.union_subset_3; eauto.
             eapply AtomSetProperties.union_subset_3; eauto.
             simpl. clear - h2. apply union_s_m. eauto.
             eapply AtomSetProperties.union_subset_3; eauto.
             eapply uniq_atoms_toplevel; eauto.
             apply matchsubst_fun_ind. auto. eapply Rename_lc4; eauto.
             auto. auto. auto.
           + move: (Rename_exists (union (dom (ctx_nom G)) (fv_tm_tm_tm p))
              (axiom_pattern H2) (Rename_lc2 H3)) => h.
             inversion h as [p2 [b2 [D2 h1]]].
             assert (tm_pattern_agree (a_App a0 (Rho Irrel) a) p2).
             { eapply tm_pattern_agree_rename_inv_1.
               eapply tm_pattern_agree_rename_inv_2.
               eapply MatchSubst_match; eauto. eauto. eauto.
             }
             apply Typing_roleing in t; inversion t; subst.
             eapply Par_AxiomApp. eauto.
             pose (Q := tm_pattern_agree_rename_inv_2 (MatchSubst_match H4) H3).
             split. eapply tm_subpattern_agree_sub_app; eauto.
             intro. eapply tm_pattern_agree_app_contr; try apply Q; eauto.
             eapply Par_sub; eauto. simpl. eauto. eauto.
             replace a2 with (matchsubst (a_App a0 (Rho Irrel) a) p2 b2).
             apply matchsubst_fun_ind.
             auto. eapply Rename_lc4; eauto. auto.
             move: (axiom_body_fv_in_pattern H2) => h2.
             apply rctx_fv in H14. apply rctx_fv in H15.
             eapply MatchSubst_Rename_preserve.
             eapply tm_pattern_agree_rename_inv_2.
             eapply MatchSubst_match. eapply H4. eauto. eauto. eapply H3.
             simpl. clear - H14 H15 h2. apply union_s_m.
             eapply AtomSetProperties.union_subset_3; eauto.
             eapply AtomSetProperties.union_subset_3; eauto.
             simpl. clear - h2. apply union_s_m. eauto.
             eapply AtomSetProperties.union_subset_3; eauto.
             eapply uniq_atoms_toplevel; eauto.
             apply matchsubst_fun_ind. auto. eapply Rename_lc4; eauto.
             auto. auto. auto.
           + move: (Rename_exists (union (dom (ctx_nom G)) (fv_tm_tm_tm p))
              (axiom_pattern H2) (Rename_lc2 H3)) => h.
             inversion h as [p2 [b2 [D2 h1]]].
             assert (tm_pattern_agree (a_CApp a0 g_Triv) p2).
             { eapply tm_pattern_agree_rename_inv_1.
               eapply tm_pattern_agree_rename_inv_2.
               eapply MatchSubst_match; eauto. eauto. eauto.
             }
             apply Typing_roleing in t; inversion t; subst.
             eapply Par_AxiomCApp. eauto.
             pose (Q := tm_pattern_agree_rename_inv_2 (MatchSubst_match H4) H3).
             split. eapply tm_subpattern_agree_sub_capp; eauto.
             intro. eapply tm_pattern_agree_capp_contr; try apply Q; eauto.
             eapply Par_sub; eauto. eauto.
             replace a2 with (matchsubst (a_CApp a0 g_Triv) p2 b2).
             apply matchsubst_fun_ind.
             auto. eapply Rename_lc4; eauto. auto.
             move: (axiom_body_fv_in_pattern H2) => h2.
             apply rctx_fv in H10.
             eapply MatchSubst_Rename_preserve.
             eapply tm_pattern_agree_rename_inv_2.
             eapply MatchSubst_match. eapply H4. eauto. eauto. eapply H3.
             simpl. clear - H10 h2. apply union_s_m.
             rewrite union_empty_r. auto.
             eapply AtomSetProperties.union_subset_3; eauto.
             simpl. clear - h2. apply union_s_m. eauto.
             eapply AtomSetProperties.union_subset_3; eauto.
             eapply uniq_atoms_toplevel; eauto.
             apply matchsubst_fun_ind. auto. eapply Rename_lc4; eauto.
             auto. auto. auto.
       - apply Typing_roleing in t; inversion t; subst.
         eapply Par_PatternTrue; eauto.
         econstructor; eapply roleing_sub; eauto.
         econstructor; eapply roleing_sub; eauto.
       - apply Typing_roleing in t; inversion t; subst.
         eapply Par_PatternFalse; eauto.
         econstructor; eapply roleing_sub; eauto.
         econstructor; eapply roleing_sub; eauto.
      }
    exists a2; split; econstructor; eauto.
    econstructor. all: eapply Par_roleing_tm_snd; eauto.
  - (* pi-cong *)
    intros. destruct (H H4) as [Ax [P1 P2]].
    pick fresh x.
    destruct (H0 x ltac:(auto) (Good_add_tm H4 ltac:(auto))) as [Bx [Q1 Q2]].
    unfold joins. exists (a_Pi rho Ax (close_tm_wrt_tm x Bx)); split;
    apply multipar_Pi_exists; eauto.
  - (* abs-cong *)
    intros. pick fresh x.
    destruct (H x ltac:(auto) (Good_add_tm H1 ltac:(auto))) as [b [Q1 Q2]].
    unfold joins. exists (a_UAbs rho (close_tm_wrt_tm x b)); split;
    apply multipar_Abs_exists; eauto.
  - intros.
    apply join_app; auto.
  - intros. 
    eapply join_app; eauto using joins_SubRole, param_sub1.
  - intros. destruct (H H1) as [T [P1 P2]]. apply join_app. apply H; auto.
    apply multipar_rctx_uniq in P1.
    unfold joins; exists a_Bullet; split; econstructor; econstructor; eauto.
  - intros. destruct (H H0) as [T [P1 P2]].
    destruct (multipar_Pi P1 eq_refl) as [Ax [Bx P]]. subst.
    apply multipar_Pi_A_proj in P1.
    apply multipar_Pi_A_proj in P2.
    exists Ax; auto.
  - intros. destruct (H H1) as [T [P1 P2]].
    destruct (multipar_Pi P1 eq_refl) as [Ax [Bx P]]. subst.
    apply (multipar_Pi_B_proj) in P1.
    apply (multipar_Pi_B_proj) in P2.
    inversion P1 as [L1 Q1]. inversion P2 as [L2 Q2].
    destruct (H0 H1) as [ax [P3 P4]].
    pick fresh x.
    rewrite (tm_subst_tm_tm_intro x); auto.
    rewrite (tm_subst_tm_tm_intro x B2); auto.
    replace (ctx_nom G) with (nil ++ (ctx_nom G)); auto.
    exists (tm_subst_tm_tm ax x (open_tm_wrt_tm Bx (a_Var_f x))); split;
    eapply multipar_subst3; simpl_env; eauto using param_sub1, multipar_sub.
  - (* cpi-cong *)
    intros. destruct (H H4 a1 b1 A1 a2 b2 A2 R R eq_refl eq_refl) as [_ [J1 [J2 J3]]].
    inversion J1 as [ax [P1 P2]]. inversion J2 as [bx [P3 P4]].
    inversion J3 as [Ax [P5 P6]].
    pick fresh c. destruct (H0 c ltac:(auto)) as [Bx [P7 P8]].
    apply Good_NoAssn; auto.
    exists (a_CPi (Eq ax bx Ax R) (close_tm_wrt_co c Bx)); split;
    apply multipar_CPi_exists; auto.
  - intros. pick fresh c.
    destruct (H c ltac:(auto) (Good_NoAssn H1 ltac:(auto))) as [t [P1 P2]].
    exists (a_UCAbs (close_tm_wrt_co c t)); split;
    apply multipar_CAbs_exists; auto.
  - intros.
    apply join_capp; auto.
  - intros. destruct (H H2) as [t [P1 P2]].
    destruct (multipar_CPi P1 eq_refl) as (c1 & c2 & C & E & P).
    subst. apply multipar_CPi_B_proj in P1. apply multipar_CPi_B_proj in P2.
    inversion P1 as [L1 Q1]. inversion P2 as [L2 Q2].
    pick fresh c.
    rewrite (co_subst_co_tm_intro c); auto.
    rewrite (co_subst_co_tm_intro c B2); auto.
    exists (co_subst_co_tm g_Triv c (open_tm_wrt_co E (g_Var_f c))); split;
    apply multipar_subst4; auto.
  - intros. destruct (H0 H1 a b A a' b' A' R R' eq_refl eq_refl) as (EQ & P1 & P2 & P3).
    subst.
    apply join_transitive with (b := a); eauto.
    apply join_symmetry; auto.
    apply join_transitive with (b := b); eauto.
  - intros. destruct (H H0 a b A a' b' A' R1 R1 eq_refl eq_refl) as (_ & P1 & P2 & P3).
    auto.
  - intros.
    destruct (H H4) as [ac [Q1 Q2]].
    destruct (H0 H4) as [b1c [Q3 Q4]].
    destruct (H1 H4) as [b2c [Q5 Q6]].
    exists (a_Pattern Nom ac F Apps5 b1c b2c); split;
    eapply multipar_Pattern; eauto.
  - intros. apply H3 in H5. unfold joins in H5.
    inversion H5 as [c1 [P1 P2]].
    pose (P3 := P1). pose (P4 := P1).
    eapply Path_multipar_app_inversion with (F := F) in P3; eauto 1.
    inversion P3 as [a1 [b1 Q]]. subst.
    eapply Path_multipar_app_fst with (F := F) in P2; eauto 1.
    eapply Path_multipar_app_fst with (F := F) in P4; eauto 1.
    exists a1. split; auto.
  - intros. apply H3 in H5. unfold joins in H5.
    inversion H5 as [c1 [P1 P2]].
    pose (P3 := P1). pose (P4 := P1).
    eapply Path_multipar_app_inversion with (F := F) in P3; eauto 1.
    inversion P3 as [a1 [b1 Q]]. subst.
    eapply Path_multipar_app_fst with (F := F) in P2; eauto 1.
    eapply Path_multipar_app_fst with (F := F) in P4; eauto 1.
    exists a1. split; auto.
  - intros. apply H3 in H5. unfold joins in H5.
    inversion H5 as [c1 [P1 P2]].
    pose (P3 := P1). pose (P4 := P1).
    eapply Path_multipar_app_inversion with (F := F) in P3; eauto 1.
    inversion P3 as [a1 [b1 Q]]. subst.
    eapply Path_multipar_app_snd with (F := F) in P2; eauto 1.
    eapply Path_multipar_app_snd with (F := F) in P4; eauto 1.
    exists b1. split; auto.
  - intros. apply H2 in H3. unfold joins in H3.
    inversion H3 as [c1 [P1 P2]].
    pose (P3 := P1). pose (P4 := P1).
    eapply Path_multipar_capp_inversion with (F := F) in P3; eauto 1.
    inversion P3 as [a0 Q]. subst.
    eapply Path_multipar_capp with (F := F) in P2; eauto 1.
    eapply Path_multipar_capp with (F := F) in P4; eauto 1.
    exists a0. split; auto.
    Unshelve. auto.
Qed.

Lemma defeq_joins: forall S D A B T R, DefEq S D A B T R -> Good S D ->
                                         joins (ctx_nom S) A B R.
Proof.
  apply consistent_mutual.
Qed.

Lemma defeq_consistent : forall S D A B T R, DefEq S D A B T R -> Good S D ->
                                        consistent A B R.
Proof. intros. eapply join_consistent. eapply defeq_joins; eauto.
Qed.

(* ------------------------------------------------------- *)

Lemma no_aAbs : forall G rho A' a A, Typing G (a_Abs rho A' a) A -> False.
Proof.
  intros. dependent induction H. by apply: IHTyping1.
Qed.

Lemma no_aCAbs : forall G A' a A, Typing G (a_CAbs A' a) A -> False.
Proof.
  intros. dependent induction H. by apply: IHTyping1.
Qed.

Lemma consistent_Star : forall A0 R,
    consistent a_Star A0 R -> value_type R A0 -> A0 = a_Star.
Proof.
  intros A0 R C V.
  destruct A0; try destruct rho;
    simpl in *; inversion C; inversion V.
  all: subst; auto.
  all: try solve [apply CasePath_ValuePath in H; inversion H].
  all: try solve [apply CasePath_ValuePath in H4; inversion H4].
  all: done.
Qed.


(* When we have a defeq in the context between two value types, show that it
   can't happen. *)
Ltac impossible_defeq :=
  let h0 := fresh in
  let VT := fresh in
  let VT2 := fresh in
  match goal with
  | [ H : DefEq ?G (dom ?G) ?B ?A ?C ?R |- _ ] =>
    pose h0:= H; clearbody h0;
    eapply defeq_consistent in h0; eauto;
    destruct (DefEq_lc H) as (l0 & l1 & l2); inversion l0; inversion l1; subst;
    have VT: value_type R A; eauto;
    have VT2 : value_type R B; eauto;
    inversion h0; subst;
    eauto; try done
  end.


Lemma canonical_forms_Star : forall G a R, Good G (dom G) ->
    Typing G a a_Star -> Value R a -> value_type R a.
Proof.
  intros. induction H1; eauto.
  - assert False. eapply no_aAbs. eauto 2. done.
  - apply invert_a_UAbs in H0; eauto.
    destruct H0 as [A1 [B2 [H2 _]]].
    impossible_defeq. apply CasePath_ValuePath in H8. inversion H8.
  - apply invert_a_UAbs in H0; eauto.
    destruct H0 as (A1 & A2 & DE & A).
    impossible_defeq. apply CasePath_ValuePath in H6. inversion H6.
  - assert False. eapply no_aCAbs. eauto 2. done.
  - apply invert_a_UCAbs in H0; eauto.
    destruct H0 as [a0 [b [T [R1 [B1 [R2 [Q [P _]]]]]]]].
    impossible_defeq. apply CasePath_ValuePath in H7. inversion H7.
Qed.



Lemma DefEq_Star: forall A G D R, Good G D -> value_type R A ->
           DefEq G D A a_Star a_Star R -> A = a_Star.
Proof.
  intros.
  apply defeq_consistent in H1; eauto.
  inversion H1; eauto; subst; try done. apply CasePath_ValuePath in H3.
  inversion H3.
Qed.

Lemma canonical_forms_Pi : forall G rho a A B R', Good G (dom G) ->
    Typing G a (a_Pi rho A B) -> Value R' a ->
    (exists a1, a = a_UAbs rho a1) \/ (exists F, CasePath R' a F).
Proof.
  intros G rho a A B R' C H H0.
  inversion H0; subst; eauto.
  - apply invert_a_Star in H; eauto.
    impossible_defeq.
    apply CasePath_ValuePath in H5. inversion H5.
  - eapply invert_a_Pi in H; eauto.
    destruct H as [H _]; eauto.
    impossible_defeq. apply CasePath_ValuePath in H7. inversion H7.
  - eapply invert_a_CPi in H; eauto.
    destruct H as [H _].
    impossible_defeq. apply CasePath_ValuePath in H7. inversion H7.
  - assert False. eapply no_aAbs. eauto 2. done.
  - eapply invert_a_UAbs in H; eauto.
    destruct H as (A1 & A2 & H & _); eauto.
    impossible_defeq. apply CasePath_ValuePath in H6. inversion H6.
  - eapply invert_a_UAbs in H; eauto.
    destruct H as (A1 & B1 & H & _); eauto.
    impossible_defeq. apply CasePath_ValuePath in H8. inversion H8.
  - assert False. eapply no_aCAbs. eauto 2. done.
  - eapply invert_a_UCAbs in H; eauto.
    destruct H as [a [b [T [R1 [B1 [_ [H _]]]]]]]; eauto.
    impossible_defeq. apply CasePath_ValuePath in H6. inversion H6.
Qed.

Lemma canonical_forms_CPi : forall G a phi B R, Good G (dom G) ->
    Typing G a (a_CPi phi B) -> Value R a ->
    (exists a1, a = a_UCAbs a1) \/ (exists F, CasePath R a F).
Proof.
  intros G a phi B R C H H0.
  inversion H0; subst; eauto.
  - apply invert_a_Star in H; eauto.
    impossible_defeq. apply CasePath_ValuePath in H6. inversion H6.
  - eapply invert_a_Pi in H; eauto.
    destruct H as [H _]; eauto.
    impossible_defeq. apply CasePath_ValuePath in H8. inversion H8.
  - eapply invert_a_CPi in H; eauto.
    destruct H as [H _].
    impossible_defeq. apply CasePath_ValuePath in H8. inversion H8.
  - assert False. eapply no_aAbs. eauto 2. done.
  - eapply invert_a_UAbs in H; eauto.
    destruct H as [A1 [A2 [R' [H _]]]]; eauto.
    impossible_defeq. apply CasePath_ValuePath in H7. inversion H7.
  - eapply invert_a_UAbs in H; eauto.
    destruct H as [A1 [A2 [R' [H _]]]]; eauto.
    impossible_defeq. apply CasePath_ValuePath in H7. inversion H7.
  - assert False. eapply no_aCAbs. eauto 2. done.
Qed.


Definition irrelevant G D (a : tm) :=
  (forall x A, binds x (Tm A) G -> x `notin` fv_tm_tm_tm a) /\ Good G D.

Lemma irrelevant_Good : forall G D a, irrelevant G D a -> Good G D.
intros. inversion H.
auto.
Qed.

Lemma notin_sub : forall x a b, x `notin` a -> b [<=] a -> x `notin` b.
  intros. fsetdec.
Qed.


Lemma subtm_pattern_agree_steps : forall F p b A R1 Rs R a,
      binds F (Ax p b A R1 Rs) toplevel -> subtm_pattern_agree a p ->
      SubRole R1 R -> exists a', reduction_in_one a a' R.
Proof. intros. induction H0.
       - move: (Rename_exists (fv_tm_tm_tm a \u fv_tm_tm_tm p)
             (axiom_pattern H) (axiom_body_lc H)) => h.
         inversion h as [p' [b' [D' h']]].
         exists (matchsubst a p' b'). econstructor. econstructor.
         eauto. eauto. eapply matchsubst_fun_ind.
         eapply tm_pattern_agree_rename_inv_1; eauto. eapply Rename_lc4; eauto.
         auto. auto.
       - apply IHsubtm_pattern_agree in H. inversion H as [a' h].
         exists (a_App a' nu a2); eauto.
       - apply IHsubtm_pattern_agree in H. inversion H as [a' h].
         exists (a_CApp a' g_Triv); eauto.
Qed.

(*
   The progress lemma is stated in terms of the reduction_in_one relation,
   which is a subrelation of the Par relation.
*)

Lemma progress : forall G a A R, Typing G a A ->
                          irrelevant G (dom G) a ->
                          Value R a \/ exists a', reduction_in_one a a' R.
Proof. intros. generalize dependent R.
       assert (lc_tm a). {eapply Typing_lc1; eauto. }
       induction H; intros; eauto; try done.
  - unfold irrelevant in *.
    apply H0 in H2. simpl in H2. fsetdec.
  - left; econstructor; auto.
    inversion H1; auto.
  - destruct rho.
    + left. constructor; eauto.
    + pick fresh x. assert (x `notin` L). auto. move: (H4 x H5) => h0.
      inversion h0. subst. edestruct (H2 x H5) as [V | [a' S]].
      { unfold irrelevant in H0. split_hyp.
      have ctx: (Ctx ([(x, Tm A)] ++ G)) by eauto 3.
      move: (Ctx_uniq ctx) => u. inversion u. subst.
      split. intros. apply binds_cons_uniq_1 in H8. destruct H8.
      ++ split_hyp. subst. auto.
      ++ split_hyp. eapply notin_sub; [idtac|eapply fv_tm_tm_tm_open_tm_wrt_tm_upper].
         simpl in *. eauto.
      ++ eauto.
      ++ simpl. eapply Good_add_tm_2; eauto using Typing_roleing. }
      inversion H1; auto.
      -- left.
         eapply Value_UAbsIrrel_exists with (x := x); eauto.
      -- right. exists (a_UAbs Irrel (close_tm_wrt_tm x a')).
         eapply E_AbsTerm_exists with (x := x).
         { eapply notin_union; auto.
           simpl. rewrite fv_tm_tm_tm_close_tm_wrt_tm. auto. }
         rewrite open_tm_wrt_tm_close_tm_wrt_tm. auto.
  - unfold irrelevant in H0. inversion H0.
    inversion H1; subst. edestruct IHTyping1 as [V | [b' h0]]; auto 1.
    + unfold irrelevant in H0. inversion H0. split; auto.
      intros. pose (Q := H3 x A0 H8). simpl in Q. eauto.
    + apply canonical_forms_Pi with (R' := R) in H; auto.
      destruct H as [[a1 e1] | [F Q]]; subst. right.
      exists (open_tm_wrt_tm a1 a); eauto. inversion Q; subst.
        * left; eauto.
        * left; eauto.
        * pose (P1 := sub_dec R1 R). inversion P1 as [P11 | P11].
           ** pose (P2 := subtm_pattern_agree_dec p H1).
              inversion P2 as [P21 | P21].
              move: (subtm_pattern_agree_steps H5 P21 P11) => h.
              inversion h as [a' h']. right. exists a'; auto.
              left; eauto.
           ** left; eauto.
         * auto.
    + right. exists (a_App b' (Rho Rel) a); eauto.
  - unfold irrelevant in H0. inversion H0.
    inversion H1; subst.
    edestruct IHTyping1 with (R := R0) as [V | [b' h0]]; auto 1.
    + unfold irrelevant in H0. inversion H0. split; auto.
      intros. pose (Q := H4 x A0 H9). simpl in Q. eauto.
    + apply canonical_forms_Pi with (R' := R0) in H; auto.
      destruct H as [[a1 e1] | [F0 Q]]; subst. inversion H3.
      inversion Q; subst.
        * left; eauto.
        * left; eauto.
        * pose (P1 := sub_dec R2 R0). inversion P1 as [P11 | P11].
           ** pose (P2 := subtm_pattern_agree_dec p H1).
              inversion P2 as [P21 | P21].
              move: (subtm_pattern_agree_steps H6 P21 P11) => h.
              inversion h as [a' h']. right. exists a'; auto.
              left; eauto.
           ** left; eauto.
    + right. exists (a_App b' (Role R) a); eauto.
  - unfold irrelevant in H0. inversion H0.
    inversion H1; subst.
    edestruct IHTyping1 with (R := R) as [V | [b' h0]]; auto 1.
    + unfold irrelevant in H0. inversion H0. split; auto.
      intros. pose (Q := H5 x A0 H8). simpl in Q. eauto.
    + apply canonical_forms_Pi with (R' := R) in H; auto.
      destruct H as [[a1 e1] | [F Q]]; subst. right.
      exists (open_tm_wrt_tm a1 a_Bullet); eauto. inversion Q; subst.
        * left; eauto.
        * left; eauto.
        * pose (P1 := sub_dec R1 R). inversion P1 as [P11 | P11].
           ** pose (P2 := subtm_pattern_agree_dec p H1).
              inversion P2 as [P21 | P21].
              move: (subtm_pattern_agree_steps H5 P21 P11) => h.
              inversion h as [a' h']. right. exists a'; auto.
              left; eauto.
           ** left; eauto.
    + right. exists (a_App b' (Rho Irrel) a_Bullet); eauto.
  - left. constructor; eauto. inversion H1; auto.
  - unfold irrelevant in H0. inversion H0.
    inversion H1; subst.
    edestruct IHTyping with (R := R0) as [V | [b' h0]]; auto 1.
    + unfold irrelevant in H0. inversion H0. split; auto.
      intros. pose (Q := H5 x A0 H9). simpl in Q. eauto.
    + apply canonical_forms_CPi with (R := R0) in H; auto.
      destruct H as [[a2 e2] | [F Q]]; subst. right.
      exists (open_tm_wrt_co a2 g_Triv); eauto. inversion Q; subst.
        * left; eauto.
        * left; eauto.
        * pose (P1 := sub_dec R2 R0). inversion P1 as [P11 | P11].
           ** pose (P2 := subtm_pattern_agree_dec p H1).
              inversion P2 as [P21 | P21].
              move: (subtm_pattern_agree_steps H5 P21 P11) => h.
              inversion h as [a' h']. right. exists a'; auto.
              left; eauto.
           ** left; eauto.
    + right. exists (a_CApp b' g_Triv); eauto.
  - destruct (sub_dec R1 R) as [S1 | S2].
    + pose (P := subtm_pattern_agree_dec p H1). inversion P as [P1 | P1].
      * move: (subtm_pattern_agree_steps H2 P1 S1) => h.
        inversion h as [a' h']. right. exists a'; auto.
      * left; eauto.
    + left; eauto.
  - inversion H1; subst. unfold irrelevant in H0. inversion H0.
    assert (irrelevant G (dom G) a). split; auto 1. intros.
    pose (Q := H7 x A0 H9). simpl in Q. eauto.
    destruct (IHTyping1 H9 H10 Nom) as [Q1 | Q1].
    assert (AppsPath Nom a F Apps5  \/ ~AppsPath Nom a F Apps5).
    eapply decide_AppsPath. eapply roleing_sub. eapply Typing_roleing; eauto. auto.
    inversion H11 as [Q2 | Q2].
    right. exists (a_CApp (applyArgs a b1) g_Triv).
    eapply E_Prim; eapply Beta_PatternTrue; eauto.
    eapply applyArgs_ApplyArgs; eauto using AppsPath_CasePath.
    right. exists b2. eapply E_Prim; eapply Beta_PatternFalse; eauto.
    inversion Q1 as [a' Q2].
    right. exists (a_Pattern Nom a' F Apps5 b1 b2); eauto.
    Unshelve. all:auto.
Qed.
