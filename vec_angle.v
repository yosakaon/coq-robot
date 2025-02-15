(* coq-robot (c) 2017 AIST and INRIA. License: LGPL-2.1-or-later. *)
From mathcomp Require Import all_ssreflect ssralg ssrint ssrnum rat poly.
From mathcomp Require Import closed_field polyrcf matrix mxalgebra mxpoly zmodp.
From mathcomp Require Import realalg complex fingroup perm reals interval trigo.
Require Import ssr_ext euclidean extra_trigo.
From mathcomp.analysis Require Import forms.

(******************************************************************************)
(*                          Vector angles and lines                           *)
(*                                                                            *)
(* This file defines angles between two vectors and develops their theory     *)
(* (e.g., multiplication by an orthogonal matrix preserves the angle between  *)
(* two vectors, etc.) and a theory of lines.                                  *)
(*                                                                            *)
(*         vec_angle v w == angle in [0;pi] formed by the vectors v and w     *)
(*          colinear u v == the vectors u and v are colinear, defined using   *)
(*                          the cross-product                                 *)
(*         axialcomp v e == the axial component of vector v along e, or the   *)
(*                          projection of v on e                              *)
(*        normalcomp v e == the normal component of vector v w.r.t. e         *)
(*                                                                            *)
(*              Line.t T == the type of lines defined in a parametric way     *)
(*                          using a point belonging to the line and a vector  *)
(*                          (the direction of the line)                       *)
(*                \pt{l} == the point used to define the line l               *)
(*               \vec{l} == the direction of the line l                       *)
(*        parallel l1 l2 == the lines l1 and l2 are parallel                  *)
(*   perpendicular l1 l2 == the lines l1 and l2 are perpendicular             *)
(*  coplanar p1 p2 p3 p3 == the four points p1, p2, p3, and p4 are coplanar   *)
(*            skew l1 l2 == l1 and l2 are skew lines                          *)
(*      intersects l1 l2 == the lines l1 and l2 intersects                    *)
(* is_interpoint p l1 l2 == the lines l1 and l2 intersects at the point p     *)
(* distance_point_line p l == the distance between the point p and the line l *)
(* distance_between_lines l1 l2 == the distance between the lines l1 and l2   *)
(******************************************************************************)

Reserved Notation "'\pt(' l ')'" (at level 3, format "'\pt(' l ')'").
Reserved Notation "'\pt2(' l ')'" (at level 3, format "'\pt2(' l ')'").
Reserved Notation "'\vec(' l ')'" (at level 3, format "'\vec(' l ')'").

Set Implicit Arguments.
Unset Strict Implicit.
Unset Printing Implicit Defensive.

Import Order.TTheory GRing.Theory Num.Def Num.Theory.

(* TODO: overrides forms.v *)
Notation "u '``_' i" := (u (@GRing.zero _) i) : ring_scope.

Local Open Scope ring_scope.

Lemma norm_le1 [T : rcfType] (u : 'rV[T]_2) :
  norm u <= 1 -> (- 1 <= u``_ 0 <= 1) /\ (- 1 <= u``_1 <= 1).
Proof.
move=> nuL1; rewrite -!ler_norml.
rewrite -!(expr_le1 (_ : 0 < 2)%N (normr_ge0 _)) //.
suff sL1 : `|u``_0| ^+ 2 + `|u``_1| ^+ 2 <= 1.
  split; apply: le_trans sL1.
    by rewrite -[X in X <= _]addr0 lerD // sqr_ge0.
  by rewrite -[X in X <= _]add0r lerD // sqr_ge0.
rewrite !sqr_normr //.
suff : norm u ^+ 2 <= 1 by rewrite sqr_norm sum2E.
by apply: exprn_ile1 (norm_ge0 _) _.
Qed.

Lemma norm1_cossin (T : realType) (v : 'rV[T]_2) :
  norm v = 1 -> {a | v``_0 = cos a /\ v``_1 = sin a}.
Proof.
move=> nvE.
exists (if 0 <= v``_1 then acos v``_0 else -acos v``_0).
have /norm_le1[v0B v1B] : norm v <= 1 by rewrite nvE.
have [v0_ge0|v0_gt0] := leP 0%R (v``_1).
  rewrite acosK ?in_itv //= sin_acos ?in_itv //=.
  rewrite -(expr1n T 2) -nvE sqr_norm sum2E [_ + _^+2] addrC addrK.
  by rewrite sqrtr_sqr ger0_norm.
rewrite cosN sinN acosK ?in_itv //= sin_acos ?in_itv //=.
rewrite -(expr1n T 2) -nvE sqr_norm sum2E [_ + _^+2] addrC addrK.
by rewrite sqrtr_sqr ltr0_norm ?opprK.
Qed.

Section vec_angle.
Variable T : realType.
Implicit Types u v : 'rV[T]_3.

Definition vec_angle v w : T :=
  if v == 0 then 0 else
  if w == 0 then 0 else acos (v *d w / (norm v * norm w)).

Lemma vec_anglev0 v : vec_angle v 0 = 0.
Proof. by rewrite /vec_angle eqxx if_same. Qed.

Lemma vec_angle0v v : vec_angle 0 v = 0.
Proof. by rewrite /vec_angle eqxx. Qed.

Definition vec_angle0 := (vec_anglev0, vec_angle0v).

Lemma vec_angleC v w : vec_angle v w = vec_angle w v.
Proof.
by rewrite /vec_angle  dotmulC [norm _ * _]mulrC; do 2 case: eqP.
Qed.

Lemma vec_anglevZ u v k : 0 < k -> vec_angle u (k *: v) = vec_angle u v.
Proof.
move=> k_gt0; rewrite /vec_angle; case: eqP => // /eqP u0.
rewrite scaler_eq0 (negPf (lt0r_neq0 _)) //=.
rewrite dotmulvZ normZ gtr0_norm // mulrCA -mulf_div divff ?mul1r //.
by rewrite lt0r_neq0.
Qed.

Lemma vec_angleZv u v (k : T) : 0 < k -> vec_angle (k *: u) v = vec_angle u v.
Proof. move=> ?; rewrite vec_angleC vec_anglevZ; by [rewrite vec_angleC|]. Qed.

Lemma vec_anglevZN u v k : k < 0 -> vec_angle u (k *: v) = vec_angle u (- v).
Proof.
move=> k_lt0; rewrite /vec_angle; case: eqP => // /eqP u0.
rewrite scaler_eq0 (negPf (ltr0_neq0 _)) //= oppr_eq0.
rewrite dotmulvZ normZ ltr0_norm // normN dotmulvN mulrCA -mulf_div.
rewrite invrN mulrN divff ?(mulN1r, mulNr) //.
by rewrite ltr0_neq0.
Qed.

Lemma vec_angleZNv u v k : k < 0 -> vec_angle (k *: u) v = vec_angle (- u) v.
Proof. move=> ?; rewrite vec_angleC vec_anglevZN; by [rewrite vec_angleC|]. Qed.

Lemma vec_anglevv u : u != 0 -> vec_angle u u = 0.
Proof.
move=> u0.
rewrite /vec_angle /= (negPf u0) dotmulvv -expr2 divff ?acos1 //.
by rewrite expf_eq0 //= norm_eq0.
Qed.

Lemma dotmul_div_N11 v w :
  v != 0 -> w != 0 -> v *d w / (norm v * norm w) \in `[(-1), 1].
Proof.
move=> u0 v0.
rewrite in_itv /= -ler_norml -(expr_le1 (_ : 0 < 2)%N) //.
rewrite sqr_normr expr_div_n ler_pdivr_mulr ?mul1r.
rewrite -subr_ge0 -norm_crossmul' ?exprn_ge0 ?norm_ge0 //.
by rewrite exprn_gt0 // mulr_gt0 // norm_gt0.
Qed.

Lemma cos_vec_angleNv v w : v != 0 -> w != 0 ->
  cos (vec_angle (- v) w) = - cos (vec_angle v w).
Proof.
move=> u0 v0.
rewrite /vec_angle oppr_eq0 (negPf u0) (negPf v0) normN dotmulNv mulNr.
have H := dotmul_div_N11 u0 v0.
by rewrite !acosK ?oppr_itvcc ?opprK.
Qed.

Lemma cos_vec_anglevN v w : v != 0 -> w != 0 ->
  cos (vec_angle v (- w)) = - cos (vec_angle v w).
Proof.
by move=> u0 v0; rewrite ![_ v _]vec_angleC; apply: cos_vec_angleNv.
Qed.

Lemma sin_vec_angle_ge0 u v (u0 : u != 0) (v0 : v != 0) :
  0 <= sin (vec_angle u v).
Proof.
rewrite /vec_angle (negPf u0) (negPf v0).
rewrite sin_acos ?sqrtr_ge0 //.
by have := dotmul_div_N11 u0 v0; rewrite in_itv.
Qed.

Lemma sin_vec_anglevN u v : sin (vec_angle u (- v)) = sin (vec_angle u v).
Proof.
rewrite /vec_angle oppr_eq0; case: eqP => [//|/eqP uD0].
case: eqP => [//|/eqP vD0].
have H := dotmul_div_N11 uD0 vD0; rewrite in_itv in H.
rewrite normN dotmulvN mulNr !sin_acos ?sqrrN //.
by rewrite ler_oppr opprK ler_oppl andbC.
Qed.

Lemma sin_vec_angleNv u v : sin (vec_angle (- u) v) = sin (vec_angle u v).
Proof. by rewrite vec_angleC [in RHS]vec_angleC [in LHS]sin_vec_anglevN. Qed.

Lemma dotmul_cos u v : u *d v = norm u * norm v * cos (vec_angle u v).
Proof.
wlog /andP[u0 v0] : u v / (u != 0) && (v != 0).
  case/boolP : (u == 0) => [/eqP ->{u}|u0]; first by rewrite dotmul0v norm0 !mul0r.
  case/boolP : (v == 0) => [/eqP ->{v}|v0]; first by rewrite dotmulv0 norm0 !(mulr0,mul0r).
  apply; by rewrite u0.
rewrite /vec_angle (negPf u0) (negPf v0) acosK; last by apply: dotmul_div_N11.
by rewrite mulrC divfK // mulf_eq0 negb_or !norm_eq0 u0.
Qed.

Lemma dotmul0_vec_angle u v : u != 0 -> v != 0 ->
  u *d v = 0 -> `| sin (vec_angle u v) | = 1.
Proof.
move=> u0 v0 uv0.
by rewrite /vec_angle (negPf u0) (negPf v0) uv0 mul0r acos0 sin_pihalf normr1.
Qed.

Lemma triine u v :
  (norm u * norm v * cos (vec_angle u v)) *+ 2 <= norm u ^+ 2 + norm v ^+ 2.
Proof.
move/eqP: (sqrrD (norm u) (norm v)); rewrite addrAC -subr_eq => /eqP <-.
rewrite lerBrDr -mulrnDl -{2}(mulr1 (norm u * norm v)) -mulrDr.
apply (@le_trans _ _ (norm u * norm v * 2%:R *+ 2)).
  rewrite ler_muln2r /=; apply ler_pmul => //.
    by apply mulr_ge0; apply norm_ge0.
    rewrite -lerBlDr add0r; move: (cos_max (vec_angle u v)).
    by rewrite ler_norml => /andP[].
  rewrite -lerBrDr {2}(_ : 1 = 1%:R) // -natrB //.
  move: (cos_max (vec_angle u v)); by rewrite ler_norml => /andP[].
rewrite sqrrD mulr2n addrAC; apply: lerD; last by rewrite mulr_natr.
by rewrite -subr_ge0 addrAC mulr_natr -sqrrB sqr_ge0.
Qed.

Lemma normB u v : norm (u - v) ^+ 2 =
  norm u ^+ 2 + norm u * norm v * cos (vec_angle u v) *- 2 + norm v ^+ 2.
Proof.
rewrite /norm dotmulD {1}dotmulvv sqr_sqrtr; last first.
  rewrite !dotmulvN !dotmulNv opprK dotmulvv dotmul_cos.
  by rewrite addrAC mulNrn subr_ge0 triine.
rewrite sqr_sqrtr ?le0dotmul // !dotmulvv !sqrtr_sqr normN dotmulvN dotmul_cos.
by rewrite ger0_norm ?norm_ge0 // ger0_norm ?norm_ge0 // mulNrn.
Qed.

Lemma normD u v : norm (u + v) ^+ 2 =
  norm u ^+ 2 + norm u * norm v * cos (vec_angle u v) *+ 2 + norm v ^+ 2.
Proof.
rewrite {1}(_ : v = - - v); last by rewrite opprK.
rewrite normB normN.
case/boolP: (u == 0) => [/eqP ->|u0].
  by rewrite !(norm0,expr0n,add0r,vec_angle0,mul0r,mul0rn,oppr0).
case/boolP: (v == 0) => [/eqP ->|v0].
  by rewrite norm0 mulr0 oppr0 vec_angle0 cos0 mul0r mul0rn subr0 addr0.
by rewrite [in LHS]cos_vec_anglevN // mulrN mulNrn opprK.
Qed.

Lemma cosine_law' a b c :
  norm (b - c) ^+ 2 = norm (c - a) ^+ 2 + norm (b - a) ^+ 2 -
  norm (c - a) * norm (b - a) * cos (vec_angle (b - a) (c - a)) *+ 2.
Proof.
rewrite -[in LHS]dotmulvv (_ : b - c = b - a - (c - a)); last first.
  by rewrite -!addrA opprB (addrC (- a)) (addrC a) addrK.
rewrite dotmulD dotmulvv [in X in _ + _ + X = _]dotmulvN dotmulNv opprK.
rewrite dotmulvv dotmulvN addrAC (addrC (norm (b - a) ^+ _)); congr (_ + _).
by rewrite dotmul_cos mulNrn (mulrC (norm (b - a))).
Qed.

Lemma cosine_law a b c : norm (c - a) != 0 -> norm (b - a) != 0 ->
  cos (vec_angle (b - a) (c - a)) =
  (norm (b - c) ^+ 2 - norm (c - a) ^+ 2 - norm (b - a) ^+ 2) /
  (norm (c - a) * norm (b - a) *- 2).
Proof.
move=> H0 H1.
rewrite (cosine_law' a b c) -2!addrA addrCA -opprD subrr addr0.
rewrite -[in X in _ / X]mulNrn -mulr_natr.
rewrite mulNr mulNrn -(mulr_natr (_ * _) 2) divrN opprK.
rewrite (mulrC _ 2) 2!mulrA.
rewrite (mulrC _ 2) mulrA.
rewrite mulrAC divff ?mul1r//.
rewrite -mulrA mulf_eq0 pnatr_eq0/=.
by rewrite mulf_eq0 negb_or H0 H1.
Qed.

Lemma norm_crossmul u v :
  norm (u *v v) = norm u * norm v * `| sin (vec_angle u v) |.
Proof.
suff /eqP : (norm (u *v v))^+2 = (norm u * norm v * `| sin (vec_angle u v) |)^+2.
  rewrite -eqr_sqrt ?sqr_ge0 // 2!sqrtr_sqr ger0_norm; last by rewrite norm_ge0.
  rewrite ger0_norm; first by move/eqP.
  by rewrite -mulrA mulr_ge0 // ?norm_ge0 // mulr_ge0 // ? norm_ge0.
rewrite norm_crossmul' dotmul_cos !exprMn.
apply/eqP; rewrite subr_eq -mulrDr.
rewrite real_normK //; first by rewrite addrC cos2Dsin2 mulr1.
by rewrite realE; case: ltgtP.
Qed.

Lemma norm_dotmul_crossmul u v : u != 0 -> v != 0 ->
  (`|u *d v +i* norm (u *v v)| = (norm u * norm v)%:C)%C.
Proof.
move=> u0 v0 .
rewrite {1}dotmul_cos {1}norm_crossmul normc_def.
rewrite exprMn (@exprMn _ 2 _ `| sin _ |) -mulrDr.
rewrite sqrtrM ?sqr_ge0 // sqr_normr cos2Dsin2 sqrtr1 mulr1.
rewrite sqrtr_sqr normrM; by do 2 rewrite ger0_norm ?norm_ge0 //.
Qed.

Lemma vec_angle0_inv u v : u != 0 -> v != 0 ->
  vec_angle u v = 0 -> u = (norm u / norm v) *: v.
Proof.
move=> uD0 vD0 uv0.
apply/eqP; rewrite -subr_eq0 -norm_eq0.
rewrite -(@eqrXn2 _ 2) // ?norm_ge0 // expr0n /= normB.
rewrite vec_anglevZ; last by rewrite divr_gt0 // norm_gt0.
rewrite uv0 cos0 mulr1 !normZ ger0_norm; last first.
  by rewrite divr_ge0 // norm_ge0.
by rewrite divfK ?norm_eq0 // -expr2 addrAC -mulr2n subrr.
Qed.

Lemma vec_anglepi_inv u v : u != 0 -> v != 0 ->
  vec_angle u v = pi -> u = - (norm u / norm v) *: v.
Proof.
move=> uD0 vD0 uvpi.
apply/eqP; rewrite -subr_eq0 -norm_eq0 scaleNr opprK.
rewrite -(@eqrXn2 _ 2) // ?norm_ge0 // expr0n /= normD.
rewrite vec_anglevZ; last by rewrite divr_gt0 // norm_gt0.
rewrite uvpi cospi mulrN1 !normZ ger0_norm; last first.
  by rewrite divr_ge0 // norm_ge0.
rewrite mulNrn divfK ?norm_eq0 //.
by rewrite addrC addrA -expr2 -mulr2n subrr.
Qed.

Lemma vec_angle_bound u v : 0 <= vec_angle u v <= pi.
Proof.
have z_bound : 0 <= (0 : T) <= pi by rewrite lexx pi_ge0.
rewrite /vec_angle; case: eqP => // /eqP uD0; case: eqP => // /eqP vD0.
have := dotmul_div_N11 uD0 vD0; rewrite in_itv /= => uv_bound.
by rewrite acos_ge0 // acos_lepi.
Qed.

Lemma dotmul1_inv u v : norm u = 1 -> norm v = 1 -> u *d v = 1 -> u = v.
Proof.
move=> u1 v1; rewrite dotmul_cos u1 v1 2!mul1r => Huv.
suff: u = (norm u / norm v) *: v.
rewrite u1 v1 ?divff ?(scale1r, oner_neq0) //.
apply: vec_angle0_inv; first by rewrite -norm_eq0 u1 oner_neq0.
  by rewrite -norm_eq0 v1 oner_neq0.
apply: cos_inj; rewrite ?in_itv /=; last by rewrite cos0.
  by apply: vec_angle_bound.
by rewrite lexx pi_ge0.
Qed.

Lemma dotmulN1_inv u v : norm u = 1 -> norm v = 1 -> u *d v = - 1 -> u = - v.
Proof.
move=> u1 v1 Huv.
by apply: dotmul1_inv; rewrite ?normN // dotmulvN Huv opprK.
Qed.

Lemma cos_vec_angle a b : a != 0 -> b != 0 ->
  `| cos (vec_angle a b) | = Num.sqrt (1 - (norm (a *v b) / (norm a * norm b)) ^+ 2).
Proof.
move=> Ha Hb.
rewrite norm_crossmul mulrAC divrr // ?mul1r.
  by rewrite sqr_normr -cos2sin2 sqrtr_sqr.
by rewrite unitfE mulf_neq0 // norm_eq0.
Qed.

Lemma orth_preserves_vec_angle M : M \is 'O[T]_3 ->
  {mono (fun u => u *m M) : v w / vec_angle v w}.
Proof.
move=> MO v w.
have [->|/eqP vD0]:= v =P 0; first by rewrite mul0mx !vec_angle0.
have [->|/eqP wD0]:= w =P 0; first by rewrite mul0mx !vec_angle0.
apply: cos_inj; try by apply: vec_angle_bound.
have /mulfI : norm v * norm w != 0.
  by rewrite mulf_eq0 !norm_eq0 negb_or vD0 wD0.
apply; rewrite -[RHS]dotmul_cos.
have /orth_preserves_dotmul/(_ v w)<-  := MO.
by rewrite [RHS]dotmul_cos !orth_preserves_norm.
Qed.

End vec_angle.

Section colinear.
Variable R : comRingType.
Implicit Types u v : 'rV[R]_3.

Definition colinear u v := u *v v == 0.

Lemma colinearvv u : colinear u u.
Proof. by rewrite /colinear (@liexx _ (vec3 R)). Qed.

Lemma scale_colinear k v : colinear (k *: v) v.
Proof. by rewrite /colinear (@lieC _ (vec3 R))/= linearZ/= (@liexx _ (vec3 R)) scaler0 oppr0. Qed.

Lemma colinear_refl : reflexive colinear.
Proof. by move=> ?; rewrite /colinear (@liexx _ (vec3 R)). Qed.

Lemma colinear_sym : symmetric colinear.
Proof. by move=> u v; rewrite /colinear (@lieC _ (vec3 R)) -eqr_opp opprK oppr0. Qed.

Lemma colinear0v u : colinear 0 u.
Proof. by rewrite /colinear linear0l. Qed.

Lemma colinearv0 u : colinear u 0.
Proof. by rewrite colinear_sym colinear0v. Qed.

Definition colinear0 := (colinear0v, colinearv0).

Lemma colinearNv u v : colinear (- u) v = colinear u v.
Proof. by rewrite /colinear linearNl eqr_oppLR oppr0. Qed.

Lemma colinearvN u v : colinear u (- v) = colinear u v.
Proof. by rewrite colinear_sym colinearNv colinear_sym. Qed.

Lemma colinearD u v w : colinear u w -> colinear v w -> colinear (u + v) w.
Proof. by rewrite /colinear linearDl /= => /eqP-> /eqP->; rewrite addr0. Qed.

End colinear.

Lemma col_perm_eq0 (T : ringType) (u : 'rV[T]_3) (s : 'S_3) :
  (col_perm s u == 0) = (u == 0).
Proof.
apply/eqP/eqP; last by move->; rewrite col_permE mul0mx.
move=> /rowP u0; apply/rowP=> i.
by have := u0 (s^-1%g i); rewrite !mxE /= permKV.
Qed.

Lemma colinear_permE (T : idomainType) (s : 'S_3) (u v : 'rV[T]_3) :
  colinear u v = colinear (col_perm s u) (col_perm s v).
Proof.
rewrite /colinear !col_permE -mulmx_crossmul; last exact: unitmx_perm.
rewrite -scalemxAr scalemx_eq0 det_perm signr_eq0 /=.
by rewrite perm_mxV invrK tr_perm_mx -col_permE col_perm_eq0.
Qed.

Lemma colinear_trans (T : idomainType) (v u w : 'rV[T]_3) :
  u != 0 -> colinear v u -> colinear u w -> colinear v w.
Proof.
move=> /eqP/rowP/eqfunP; rewrite negb_forall => /existsP [j].
rewrite mxE; wlog: v u w j / j = 0.
  move=> hwlog ujn0; set s := tperm j 0.
  rewrite (colinear_permE s) => vu; rewrite (colinear_permE s) => uw.
  rewrite (colinear_permE s); apply: hwlog 0 _ _ vu uw => //.
  by rewrite mxE tpermR.
move=>-> /lregP u0n0; rewrite /colinear !crossmulE => /eqP/rowP vu /eqP/rowP uw.
apply/eqP/rowP=> i; rewrite !mxE /=; case: ifP => _.
  apply/eqP; rewrite -(mulrI_eq0 _ u0n0) mulrBr !mulrA.
  have := vu 1; rewrite !mxE /= => /subr0_eq; rewrite mulrC =>->.
  rewrite [u``_0 * _]mulrC; have := vu 2%:R; rewrite !mxE /= => /subr0_eq => <-.
  rewrite -mulrA; have := uw 0; rewrite !mxE /= => /subr0_eq =>->.
  by rewrite mulrA subrr.
case: ifP => _.
  apply/eqP; rewrite -(mulrI_eq0 _ u0n0) mulrBr !mulrA.
  rewrite [u``_0 * _]mulrC; have := vu 1; rewrite !mxE /= => /subr0_eq ->.
  rewrite -[X in X - _]mulrA; have := uw 1; rewrite !mxE /= => /subr0_eq ->.
  by rewrite mulrCA mulrA subrr.
case: ifP => _ //; apply/eqP; rewrite -(mulrI_eq0 _ u0n0) mulrBr !mulrA.
rewrite mulrAC; have := uw 2%:R; rewrite !mxE /= => /subr0_eq ->.
rewrite mulrAC [u``_1 * _]mulrC; have := vu 2%:R; rewrite !mxE /= => /subr0_eq.
by move->; rewrite [v``_1 * _]mulrC subrr.
Qed.

Lemma colinearZv (T : fieldType) (u v : 'rV[T]_3) k :
  colinear (k *: u) v = (k == 0) || colinear u v.
Proof. by rewrite /colinear linearZl_LR scaler_eq0. Qed.

Lemma colinearvZ (T : fieldType) (u v : 'rV[T]_3) k :
  colinear u (k *: v) = (k == 0) || colinear u v.
Proof. by rewrite /colinear linearZr_LR scaler_eq0. Qed.

Lemma colinearP (T : fieldType) (u v : 'rV[T]_3) :
  reflect (v == 0 \/ (v != 0 /\ exists k, u = k *: v)) (colinear u v).
Proof.
apply: (iffP idP); last first.
  case=> [/eqP ->|]; first by rewrite colinear0.
  case=> v0 [k ukv].
  by rewrite ukv scale_colinear.
rewrite /colinear => uv.
case/boolP : (v == 0) => v0; [by left | right; split; first by done].
move: v0 => /eqP/rowP/eqfunP; rewrite negb_forall => /existsP [j].
rewrite mxE => v0; exists (u``_j / v``_j); apply/rowP => i; rewrite mxE.
case: (eqVneq i j) => [->|inej]; first by rewrite mulrVK ?unitfE.
move: uv; rewrite crossmul0E => /forallP /(_ j) /forallP /(_ i).
rewrite eq_sym => /implyP /(_ inej) /eqP uvij; apply: (mulfI v0).
by rewrite mulrC !mulrA -mulrA mulrACA mulfV ?mul1r.
Qed.

Section colinear1.

Variable T : realType.
Implicit Types u v : 'rV[T]_3.

Lemma colinear_sin u v (uD0 : u != 0) (vD0 : v != 0) :
  (colinear u v) = (sin (vec_angle u v) == 0).
Proof.
have uND0 : -u != 0 by rewrite oppr_eq0.
have vND0 : -v != 0 by rewrite oppr_eq0.
apply/idP/idP.
  rewrite colinear_sym => /colinearP.
  rewrite (negbTE uD0).
  case=> // -[_ [k Hk]]; rewrite Hk; case: (ltgtP 0 k) => [k_gt0|k_gt0|<-].
  - by rewrite vec_anglevZ // vec_anglevv // sin0.
  - by rewrite vec_anglevZN // sin_vec_anglevN vec_anglevv // sin0.
  by rewrite scale0r vec_angle0 sin0.
rewrite -norm_cos_eq1 -cos0 => /eqP.
have [c_le0|c_gt0 Hc] := ler0P (cos (vec_angle u v)).
  rewrite -cos_vec_anglevN // -colinearvN => Hc.
  rewrite (vec_angle0_inv uD0 vND0).
    by rewrite colinearZv colinearvv orbT.
  apply: cos_inj => //; rewrite in_itv /= ?(lexx, pi_ge0) //.
  by apply: vec_angle_bound.
rewrite (vec_angle0_inv uD0 vD0).
  by rewrite colinearZv colinearvv orbT.
apply: cos_inj => //; rewrite in_itv /= ?(lexx, pi_ge0) //.
by apply: vec_angle_bound.
Qed.

Lemma sin_vec_angle_iff (u v : 'rV[T]_3) (u0 : u != 0) (v0 : v != 0) :
  0 <= sin (vec_angle u v) ?= iff (colinear u v).
Proof. split; [exact: sin_vec_angle_ge0|by rewrite colinear_sin]. Qed.

Lemma invariant_colinear (u : 'rV[T]_3) (M : 'M[T]_3) :
  u != 0 -> u *m M = u -> forall v, colinear u v -> v *m M = v.
Proof.
move=> u0 uMu v /colinearP[/eqP->|[v0 [k Hk]]]; first by rewrite mul0mx.
move: uMu; rewrite Hk -scalemxAl => /eqP.
rewrite -subr_eq0 -scalerBr scaler_eq0 => /orP [/eqP k0|].
  by move: u0; rewrite Hk k0 scale0r eq_refl.
by rewrite subr_eq0 => /eqP.
Qed.

End colinear1.

Section axial_normal_decomposition.

Variable T : realType.
Let vector := 'rV[T]_3.
Implicit Types u v e : vector.

Definition axialcomp v e := normalize e *d v *: normalize e.

Lemma axialcomp0v e : axialcomp 0 e = 0.
Proof. by rewrite /axialcomp dotmulv0 scale0r. Qed.

Lemma axialcompv0 v : axialcomp v 0 = 0.
Proof. by rewrite /axialcomp /normalize norm0 invr0 ?(scale0r,dotmul0v). Qed.

Lemma axialcompE v e : axialcomp v e = (norm e) ^- 2 *: (v *m e^T *m e).
Proof.
have [/eqP ->|?] := boolP (e == 0); first by rewrite axialcompv0 mulmx0 scaler0.
rewrite /axialcomp dotmulZv scalerA mulrAC dotmulP mul_scalar_mx dotmulC.
by rewrite -invrM ?unitfE ?norm_eq0 // -expr2 scalerA.
Qed.

Lemma axialcompvN v e : axialcomp v (- e) = axialcomp v e.
Proof. by rewrite /axialcomp normalizeN dotmulNv scalerN scaleNr opprK. Qed.

Lemma axialcompNv v e : axialcomp (- v) e = - axialcomp v e.
Proof. by rewrite /axialcomp dotmulvN scaleNr. Qed.

Lemma axialcompZ k e : axialcomp (k *: e) e = k *: e.
Proof.
rewrite /axialcomp dotmulvZ dotmulC dotmul_normalize_norm.
have [/eqP u0|u0] := boolP (e == 0); first by rewrite u0 normalize0 2!scaler0.
by rewrite scalerA -mulrA divrr ?unitfE ?norm_eq0 // mulr1.
Qed.

Lemma axialcomp_dotmul v e : e *d v = 0 -> axialcomp v e = 0.
Proof.
move=> H; by rewrite axialcompE dotmulP dotmulC H mul_scalar_mx scale0r scaler0.
Qed.

Lemma crossmul_axialcomp v e : e *v axialcomp v e = 0.
Proof.
by apply/eqP; rewrite /axialcomp linearZ /= linearZr_LR /= (@liexx _ (vec3 T)) 2!scaler0.
Qed.

(* NB: not used *)
Lemma colinear_axialcomp v e : colinear e (axialcomp v e).
Proof. by rewrite /colinear crossmul_axialcomp. Qed.

Lemma axialcomp_crossmul v e : axialcomp (e *v v) e == 0.
Proof.
rewrite /axialcomp -dotmul_crossmul2 /normalize !linearZl_LR /= linearZr_LR /=.
by rewrite (@liexx _ (vec3 T)) linear0l 2!scaler0.
Qed.

Lemma norm_axialcomp v e : e *d v < 0 ->
  norm (axialcomp v e) = - (normalize e *d v).
Proof.
move=> H.
have ? : e != 0 by apply: contraTN H => /eqP ->; rewrite dotmul0v ltxx.
rewrite /axialcomp scalerA normZ ltr0_norm; last first.
  rewrite pmulr_llt0 ?invr_gt0 ?norm_gt0 //.
  by rewrite /normalize dotmulZv pmulr_rlt0 // invr_gt0 norm_gt0.
by rewrite mulNr -(mulrA _ _ (norm e)) mulVr ?mulr1 ?unitfE ?norm_eq0.
Qed.

Lemma axialcomp_mulO Q p e : Q \is 'O[T]_3 -> e *m Q = e ->
  axialcomp (p *m Q) e = axialcomp p e.
Proof.
move=> HQ uQu.
rewrite !axialcompE; congr (_ *: _).
rewrite -!mulmxA; congr (_ *m _).
rewrite !mulmxA; congr (_ *m _).
by rewrite -{1}uQu trmx_mul mulmxA orthogonal_mul_tr // mul1mx.
Qed.

Lemma vec_angle_axialcomp v e : 0 < e *d v ->
  vec_angle v (axialcomp v e) = vec_angle v e.
Proof.
move=> H.
have ? : e != 0 by apply: contraTN H => /eqP ->; rewrite dotmul0v ltxx.
rewrite /axialcomp scalerA vec_anglevZ // divr_gt0 // ?norm_gt0 //.
by rewrite /normalize dotmulZv mulr_gt0 // invr_gt0 norm_gt0.
Qed.

Definition normalcomp v e := v - axialcomp v e.

Lemma axialnormalcomp v e : v = axialcomp v e + normalcomp v e.
Proof. by rewrite /axialcomp /normalcomp addrC subrK. Qed.

Lemma normalcompE v e : normalcomp v e = v *m (1 - norm e ^-2 *: (e^T *m e)).
Proof.
by rewrite /normalcomp axialcompE -mulmxA scalemxAr -{1}(mulmx1 v) -mulmxBr.
Qed.

Lemma normalcomp0v e : normalcomp 0 e = 0.
Proof. by rewrite /normalcomp axialcomp0v subrr. Qed.

Lemma normalcompv0 v : normalcomp v 0 = v.
Proof. by rewrite /normalcomp axialcompv0 subr0. Qed.

Lemma normalcompvN v e : normalcomp v (- e) = normalcomp v e.
Proof. by rewrite /normalcomp axialcompvN. Qed.

Lemma normalcompNv v e : normalcomp (- v) e = - normalcomp v e.
Proof. by rewrite /normalcomp opprB axialcompNv opprK addrC. Qed.

Lemma normalcompZ k e : normalcomp (k *: e) e = 0.
Proof. by rewrite /normalcomp axialcompZ subrr. Qed.

Lemma normalcompB v1 v2 : normalcomp (v1 - v2) v2 = normalcomp v1 v2.
Proof.
apply/esym/eqP.
rewrite /normalcomp subr_eq /axialcomp -scaleNr -!addrA -scalerDl -dotmulvN.
rewrite -dotmulDr opprB subrK dotmulC dotmul_normalize_norm.
by rewrite norm_scale_normalize addrA subrK.
Qed.

Lemma normalcomp_colinear_helper v e : normalcomp v e = 0 -> colinear v e.
Proof.
move/eqP; rewrite subr_eq0 => /eqP ->.
by rewrite !colinearZv ?colinear_refl 2!orbT.
Qed.

Lemma normalcomp_colinear v e (e0 : e != 0) :
  (normalcomp v e == 0) = colinear v e.
Proof.
apply/idP/idP => [/eqP|/colinearP]; first exact: normalcomp_colinear_helper.
case; first by rewrite (negbTE e0).
case=> _ [k ->]; by rewrite normalcompZ.
Qed.

Lemma crossmul_normalcomp v e : e *v normalcomp v e = e *v v.
Proof.
by rewrite /normalcomp linearD /= linearNr /= crossmul_axialcomp subr0.
Qed.

Lemma dotmul_normalcomp v e : normalcomp v e *d e = 0.
Proof.
case/boolP : (e == 0) => [/eqP ->|?]; first by rewrite dotmulv0.
rewrite /normalcomp dotmulBl !dotmulZv dotmulvv (exprD _ 1 1) expr1.
rewrite (mulrA (_^-1)) mulVr ?unitfE ?norm_eq0 // mul1r mulrAC.
by rewrite mulVr ?unitfE ?norm_eq0 // mul1r dotmulC subrr.
Qed.

Lemma axialnormal v e : axialcomp v e *d normalcomp v e = 0.
Proof.
by rewrite /axialcomp !dotmulZv (dotmulC _ (normalcomp v e))
  dotmul_normalcomp // !mulr0.
Qed.

Lemma ortho_normalcomp v e : (v *d e == 0) = (normalcomp v e == v).
Proof.
apply/idP/idP => [/eqP uv0|/eqP <-].
  by rewrite /normalcomp axialcomp_dotmul ?subr0 // dotmulC.
by rewrite dotmul_normalcomp.
Qed.

Lemma normalcomp_mulO e p Q : Q \is 'O[T]_3 -> e *m Q = e ->
  normalcomp (p *m Q) e = normalcomp p e *m Q.
Proof.
move=> QO uQu.
rewrite 2!normalcompE -!mulmxA; congr (_ *m _).
rewrite mulmxBr mulmx1 mulmxBl mul1mx; congr (_ - _).
rewrite -scalemxAr -scalemxAl; congr (_ *: _).
by rewrite -{1}uQu trmx_mul !mulmxA orthogonal_mul_tr // mul1mx -mulmxA uQu.
Qed.

Lemma normalcomp_mul_tr e (e1 : norm e = 1) : normalcomp 'e_0 e *m e^T == 0.
Proof.
rewrite /normalcomp mulmxBl -scalemxAl -scalemxAl dotmul1 // dotmulC /dotmul.
by rewrite e1 invr1 scalemx1 scalemx1 normalizeI // {1}dotmulP subrr.
Qed.

Definition orthogonalize v e := normalcomp v (normalize e).

Lemma dotmul_orthogonalize v e : e *d orthogonalize v e = 0.
Proof.
rewrite /normalcomp /normalize dotmulBr !(dotmulZv, dotmulvZ).
rewrite mulrACA -invfM -expr2 dotmulvv mulrCA.
have [->|u_neq0] := eqVneq e 0; first by rewrite norm0 invr0 dotmul0v !mul0r subrr.
rewrite norm_normalize // expr1n invr1 mul1r.
rewrite (mulrC _ (e *d _)).
rewrite -mulrA (mulrA (_^-1)) -expr2 -exprMn mulVr ?expr1n ?mulr1 ?subrr //.
by rewrite unitfE norm_eq0.
Qed.

End axial_normal_decomposition.

Section law_of_sines.

Variable T : comRingType.
Let point := 'rV[T]_3.
Let vector := 'rV[T]_3.
Implicit Types a b c : point.
Implicit Types v : vector.

Definition tricolinear a b c := colinear (b - a) (c - a).

Lemma tricolinear_rot a b c : tricolinear a b c = tricolinear b c a.
Proof.
rewrite /tricolinear /colinear !linearD /= !linearDl /= !(linearNl,linearNr) /=.
by rewrite !opprK !(@liexx _ (vec3 T)) !addr0 -addrA addrC (@lieC _ (vec3 T) a c) opprK (@lieC _ (vec3 T) b c).
Qed.

Lemma tricolinear_perm a b c : tricolinear a b c = tricolinear b a c.
Proof.
rewrite /tricolinear /colinear !linearD /= !linearDl /= !(linearNl,linearNr) /=.
rewrite !(opprK,(@liexx _ (vec3 T)),addr0) -{1}oppr0 -eqr_oppLR 2!opprB addrC (@lieC _ (vec3 T) a b).
by rewrite opprK.
Qed.

End law_of_sines.

Section law_of_sines1.

Variable T : realType.
Let point := 'rV[T]_3.
Let vector := 'rV[T]_3.
Implicit Types a b c : point.
Implicit Types v : vector.

Lemma cos0sin1 [R : realType] [x : R] : cos x = 0 -> `|sin x| = 1.
Proof. by move/eqP; rewrite -norm_sin_eq1 => /eqP. Qed.

Lemma triangle_sin_vector_helper v1 v2 : ~~ colinear v1 v2 ->
  norm v1 ^+ 2 * sin (vec_angle v1 v2) ^+ 2 = norm (normalcomp v1 v2) ^+ 2.
Proof.
move=> H.
have v10 : v1 != 0 by apply: contra H => /eqP ->; rewrite colinear0.
have v20 : v2 != 0 by apply: contra H => /eqP ->; rewrite colinear_sym colinear0.
rewrite /normalcomp [in RHS]normB.
case/boolP : (0 < v2 *d v1) => [v2v1|].
  rewrite normZ gtr0_norm; last first.
    by rewrite dotmulZv mulr_gt0 // invr_gt0 norm_gt0.
  rewrite norm_normalize // mulr1 vec_angle_axialcomp //.
  rewrite dotmul_cos norm_normalize // mul1r vec_angleZv; last first.
    by rewrite invr_gt0 norm_gt0.
  rewrite [in RHS]mulrA (vec_angleC v1) -expr2 -mulrA -expr2 exprMn.
  by rewrite mulr2n opprD addrA subrK sin2cos2 mulrBr mulr1.
rewrite -leNgt le_eqVlt => /orP[|v2v1].
  rewrite {1}dotmul_cos -mulrA mulf_eq0 norm_eq0 (negbTE v20) /=.
  rewrite mulf_eq0 norm_eq0 (negbTE v10) /= => /eqP Hcos.
  rewrite axialcomp_dotmul; last by rewrite dotmul_cos Hcos mulr0.
  rewrite norm0 mulr0 mul0r expr0n mul0rn addr0 subr0.
  by rewrite -(sqr_normr (sin _)) vec_angleC cos0sin1 ?expr1n ?mulr1.
rewrite vec_anglevZN //; last first.
  by rewrite /normalize dotmulZv pmulr_rlt0 // invr_gt0 norm_gt0.
rewrite cos_vec_anglevN // ?normalize_eq0 //.
rewrite norm_axialcomp // !(mulrN,mulNr,opprK,sqrrN).
rewrite vec_anglevZ // ?invr_gt0 ?norm_gt0 //.
rewrite dotmul_cos norm_normalize // mul1r vec_angleZv ?invr_gt0 ?norm_gt0 //.
rewrite (vec_angleC v2) -!mulrA -expr2 exprMn addrAC -addrA -mulrA -mulrnAr.
rewrite -mulrBr mulr2n opprD addrA subrr sub0r.
rewrite mulrA -expr2 mulrN mulrA -expr2.
by rewrite sin2cos2 mulrBr mulr1.
Qed.

Lemma triangle_sin_vector v1 v2 : ~~ colinear v1 v2 ->
  sin (vec_angle v1 v2) = norm (normalcomp v1 v2) / norm v1.
Proof.
move=> H.
have v10 : v1 != 0 by apply: contra H => /eqP ->; rewrite colinear0.
have v20 : v2 != 0 by apply: contra H => /eqP ->; rewrite colinear_sym colinear0.
apply/eqP.
rewrite -(@eqrXn2 _ 2) // ?divr_ge0 // ?norm_ge0 // ?sin_vec_angle_ge0 //.
rewrite exprMn -triangle_sin_vector_helper // mulrAC exprVn divrr ?mul1r //.
by rewrite unitfE sqrf_eq0 norm_eq0.
Qed.

Lemma triangle_sin_point (p1 p2 p : 'rV[T]_3) : ~~ tricolinear p1 p2 p ->
  let v1 := p1 - p in let v2 := p2 - p in
  sin (vec_angle v1 v2) = norm (normalcomp v1 v2) / norm v1.
Proof.
move=> H v1 v2; apply triangle_sin_vector; apply: contra H.
by rewrite tricolinear_perm 2!tricolinear_rot /tricolinear /v1 /v2 colinear_sym.
Qed.

Lemma law_of_sines_vector v1 v2 : ~~ colinear v1 v2 ->
  sin (vec_angle v1 v2) / norm (v2 - v1) = sin (vec_angle (v2 - v1) v2) / norm v1.
Proof.
move=> H.
move: (triangle_sin_vector H) => /= H1.
rewrite [in LHS]H1.
have H' : ~~ colinear v2 (v2 - v1).
  rewrite colinear_sym; apply: contra H => H.
  move: (colinear_refl v2); rewrite -colinearNv => /(colinearD H).
  by rewrite addrAC subrr add0r colinearNv.
have H2 : sin (vec_angle v2 (v2 - v1)) = norm (normalcomp (v2 - v1) v2) / norm (v2 - v1).
  rewrite vec_angleC; apply triangle_sin_vector; by rewrite colinear_sym.
rewrite [in RHS]vec_angleC [in RHS]H2.
by rewrite -normalcompB mulrAC -(opprB v2) normalcompNv normN.
Qed.

Lemma law_of_sines_point (p1 p2 p : 'rV[T]_3) : ~~ tricolinear p1 p2 p ->
  let v1 := p1 - p in let v2 := p2 - p in
  sin (vec_angle v1 v2) / norm (p2 - p1) =
  sin (vec_angle (p2 - p1) (p2 - p)) / norm (p1 - p).
Proof.
move=> H v1 v2.
rewrite (_ : p2 - p1 = v2 - v1); last by rewrite /v1 /v2 opprB addrA subrK.
apply law_of_sines_vector.
apply: contra H.
by rewrite tricolinear_perm 2!tricolinear_rot /tricolinear /v1 /v2 colinear_sym.
Qed.

End law_of_sines1.

Module Line.
Section line_def.
(* could be zmodType but then the coercion line_pred does not satisfy the
   uniform inheritance condition *)
Variable T : comRingType.
Record t := mk {
  point : 'rV[T]_3 ;
  vector :> 'rV[T]_3
}.
Definition point2 (l : t) := point l + vector l.
Lemma vectorE l : vector l = point2 l - point l.
Proof. by rewrite /point2 addrAC subrr add0r. Qed.
End line_def.
End Line.

Notation "'\pt(' l ')'" := (Line.point l).
Notation "'\pt2(' l ')'" := (Line.point2 l).
Notation "'\vec(' l ')'" := (Line.vector l).

Coercion line_pred (T : comRingType) (l : Line.t T) : pred 'rV[T]_3 :=
  [pred p | (p == \pt( l )) ||
    (\vec( l ) != 0) && colinear \vec( l ) (p - \pt( l ))].

Lemma line_point_in (T : comRingType) (l : Line.t T) : \pt(l) \in (l : pred _).
Proof. by case: l => p v /=; rewrite inE /= eqxx. Qed.

Section line.

Variable T : fieldType.
Let point := 'rV[T]_3.
Let vector := 'rV[T]_3.
Implicit Types l : Line.t T.

Lemma lineP p l :
  reflect (exists k', p = \pt( l ) + k' *: \vec( l)) (p \in (l : pred _)).
Proof.
apply (iffP idP) => [|[k' ->]].
  rewrite inE.
  case/orP => [/eqP pl|]; first by exists 0; rewrite scale0r addr0.
  case/andP => l0 /colinearP[|[pl [k Hk]]].
    rewrite subr_eq0 => /eqP ->; exists 0; by rewrite scale0r addr0.
  have k0 : k != 0.
    by apply/negP => /eqP k0; move: l0; rewrite Hk k0 scale0r eq_refl.
  exists k^-1.
  by rewrite Hk scalerA mulVr ?unitfE // scale1r addrCA subrr addr0.
rewrite inE.
case/boolP : (\vec( l ) == 0) => [/eqP ->|l0 /=].
  by rewrite scaler0 addr0 eqxx.
by rewrite addrAC subrr add0r colinearvZ colinear_refl 2!orbT.
Qed.

Lemma mem_add_line l (p : point) (v : vector) : \vec( l ) != 0 ->
  colinear v \vec( l ) -> p + v \in (l : pred _) = (p \in (l : pred _)).
Proof.
move=> l0 vl.
apply/lineP/idP => [[] x /eqP|pl].
  rewrite eq_sym -subr_eq => /eqP <-.
  rewrite inE l0 /=; apply/orP; right.
  rewrite -!addrA addrC !addrA subrK colinear_sym.
  by rewrite colinearD // ?colinearZv ?colinear_refl ?orbT // colinearNv.
case/colinearP : vl => [|[_ [k ->]]]; first by rewrite (negPf l0).
case/lineP : pl => k' ->.
exists (k' + k); by rewrite -addrA -scalerDl.
Qed.

End line.

Definition parallel (T : comRingType) : rel (Line.t T) :=
  [rel l1 l2 | colinear \vec( l1 ) \vec( l2 )].

Definition perpendicular (T : comRingType) : rel (Line.t T) :=
  [rel l1 l2 | \vec( l1 ) *d \vec( l2 ) == 0].

Definition coplanar (T : comRingType) (p1 p2 p3 p4 : 'rV[T]_3) : bool :=
  (p1 - p3) *d ((p2 - p1) *v (p4 - p3)) == 0.

Definition skew (T : comRingType) : rel (Line.t T) := [rel l1 l2 |
  ~~ coplanar \pt( l1 ) \pt2( l1 ) \pt( l2 ) \pt2( l2) ].

Lemma skewE (T : comRingType) (l1 l2 : Line.t T) :
  skew l1 l2 = ~~ coplanar \pt( l1 ) \pt2( l1 ) \pt( l2 ) \pt2( l2).
Proof. by []. Qed.

Section line_line_intersection.

Variable T : realFieldType.
Let point := 'rV[T]_3.
Implicit Types l : Line.t T.

Definition intersects : rel (Line.t T) :=
  [rel l1 l2 | ~~ skew l1 l2 && ~~ parallel l1 l2 ].

Definition is_interpoint p l1 l2 :=
  (p \in (l1 : pred _)) && (p \in (l2 : pred _)).

Definition interpoint_param x l1 l2 :=
  let v1 := \vec( l1 ) in let v2 := \vec( l2 ) in
  \det (col_mx3 (\pt( l2 ) - \pt( l1 )) x (v1 *v v2)) / ((v1 *v v2) *d (v1 *v v2)).

Lemma interpoint_param0 l1 l2 v : \pt( l1 ) = \pt( l2 ) ->
  interpoint_param v l1 l2 = 0.
Proof.
move=> p1p2.
by rewrite /interpoint_param p1p2 subrr -crossmul_triple dotmul0v mul0r.
Qed.

Definition interpoint_s l1 l2 := interpoint_param \vec( l1 ) l1 l2.

Definition interpoint_t l1 l2 := interpoint_param \vec( l2 ) l1 l2.

Lemma interparamP l1 l2 : intersects l1 l2 ->
  let v1 := \vec( l1 ) in let v2 := \vec( l2 ) in
  \pt( l1 ) + interpoint_t l1 l2 *: v1 = \pt( l2 ) + interpoint_s l1 l2 *: v2.
Proof.
move=> Hinter v1 v2.
rewrite /interpoint_t /interpoint_s /interpoint_param  -/v1 -/v2.
do 2 rewrite -crossmul_triple (dot_crossmulC (\pt( l2) - \pt( l1 ))).
apply/eqP; set v1v2 := v1 *v v2.
rewrite -subr_eq -addrA eq_sym addrC -subr_eq.
rewrite 2!(mulrC _ _^-1) -2!scalerA -scalerBr.
rewrite dotmulC dot_crossmulC (dotmulC _ v1v2) (dot_crossmulC).
rewrite -double_crossmul.
rewrite (@lieC _ (vec3 T) (v1v2 *v _)) /= double_crossmul dotmulC -{2}(opprB _ \pt( l2 )) dotmulNv.
case/andP: Hinter.
rewrite skewE negbK /coplanar -2!Line.vectorE => /eqP -> ?.
rewrite oppr0 scale0r add0r opprK scalerA mulVr ?scale1r //.
by rewrite unitfE dotmulvv0.
Qed.

Lemma intersects_interpoint l1 l2 : intersects l1 l2 ->
  {p | is_interpoint p l1 l2 /\
   p = \pt( l1 ) + interpoint_t l1 l2 *: \vec( l1 ) /\
   p = \pt( l2 ) + interpoint_s l1 l2 *: \vec( l2 )}.
Proof.
move=> Hinter.
case/boolP : (\pt( l1 ) == \pt( l2 )) => [/eqP|]p1p2.
  exists \pt( l1 ); split.
    rewrite /is_interpoint; apply/andP; split; by [
      rewrite inE eqxx !(orTb,orbT) | rewrite inE p1p2 eqxx orTb].
  rewrite /interpoint_t /interpoint_s interpoint_param0 //.
  by rewrite interpoint_param0 // 2!scale0r 2!addr0.
exists (\pt( l1) + interpoint_t l1 l2 *: \vec( l1 )).
split; last first.
  split=> //; exact: interparamP.
rewrite /is_interpoint; apply/andP; split.
  apply/lineP; by exists (interpoint_t l1 l2).
apply/lineP; eexists; exact: interparamP.
Qed.

Lemma interpoint_intersects l1 l2 : {p | is_interpoint p l1 l2} ->
  ~~ skew l1 l2.
Proof.
case=> p; rewrite /is_interpoint => /andP[H1 H2].
rewrite skewE negbK /coplanar -2!Line.vectorE.
case/lineP : (H1) => k1 /eqP; rewrite -subr_eq => /eqP <-.
case/lineP : (H2) => k2 /eqP; rewrite -subr_eq => /eqP <-.
rewrite opprB -addrA addrC addrA subrK dotmulDl !(dotmulNv,dotmulZv).
rewrite dot_crossmulC 2!dotmul_crossmul_shift 2!(@liexx _ (vec3 T)).
by rewrite !(dotmul0v,dotmulv0,mulr0,oppr0,addr0).
Qed.

Lemma interpointE p l1 l2 : ~~ parallel l1 l2 -> is_interpoint p l1 l2 ->
  let s := interpoint_s l1 l2 in let t := interpoint_t l1 l2 in
  let v1 := \vec( l1 ) in let v2 := \vec( l2 ) in
  \pt( l1 ) + t *: v1 = p /\ \pt( l2 ) + s *: v2 = p.
Proof.
move=> ?.
case/andP => /lineP[t' Hs] /lineP[s' Ht] s t.
move=> v1 v2.
have H (a b va vb : 'rV[T]_3) (k l : T) :
  a + k *: va = b + l *: vb -> k *: (va *v vb) = (b - a) *v vb.
  clear.
  move=> /(congr1 (fun x => x - a)).
  rewrite addrAC subrr add0r addrAC => /(congr1 (fun x => x *v vb)).
  rewrite (linearZl_LR _ vb) /= linearDl /=.
  by rewrite (linearZl_LR _ _ l) /= (@liexx _ (vec3 T)) scaler0 addr0.
have Ht' : t' = interpoint_t l1 l2.
  have : t' *: (v1 *v v2) = (\pt( l2 ) - \pt( l1 )) *v v2.
    by rewrite (H \pt( l1 ) \pt( l2 ) _ _ _ s') // -Hs -Ht.
  move/(congr1 (fun x => x *d (v1 *v v2))).
  rewrite dotmulZv.
  move/(congr1 (fun x => x / ((v1 *v v2) *d (v1 *v v2)))).
  rewrite -mulrA divrr ?mulr1; first by rewrite -dot_crossmulC crossmul_triple.
  by rewrite unitfE dotmulvv0.
have Hs' : s' = interpoint_s l1 l2.
  have : s' *: (v1 *v v2) = (\pt( l2) - \pt( l1 )) *v v1.
    move: (H \pt( l2 ) \pt( l1 ) v2 v1 s' t').
    rewrite -Hs -Ht => /(_ erefl).
    by rewrite (@lieC _ (vec3 T) v1 v2) /= scalerN -opprB => ->; rewrite linearNl opprK.
  move/(congr1 (fun x => x *d (v1 *v v2))).
  rewrite dotmulZv.
  move/(congr1 (fun x => x / ((v1 *v v2) *d (v1 *v v2)))).
  rewrite -mulrA divrr ?mulr1; first by rewrite -dot_crossmulC crossmul_triple.
  by rewrite unitfE dotmulvv0.
by rewrite /t /s -Ht' -Hs'.
Qed.

Lemma interpoint_unique p q l1 l2 : ~~ parallel l1 l2 ->
  is_interpoint p l1 l2 -> is_interpoint q l1 l2 -> p = q.
Proof.
by move=> l1l2 /interpointE => /(_ l1l2) [<- _] /interpointE => /(_ l1l2) [<- _].
Qed.

Definition intersection l1 l2 : option point :=
  if ~~ intersects l1 l2 then None
  else Some (\pt( l1 ) + interpoint_t l1 l2 *: \vec( l1 )).

End line_line_intersection.

Section distance_line.

Variable T : rcfType.
Let point := 'rV[T]_3.

Definition distance_point_line (p : point) l : T :=
  norm ((p - \pt( l )) *v \vec( l )) / norm \vec( l ).

Definition distance_between_lines (l1 l2 : Line.t T) : T :=
  if intersects l1 l2 then
    0
  else if parallel l1 l2 then
    distance_point_line \pt( l1 ) l2
  else (* skew lines *)
    let n := \vec( l1 ) *v \vec( l2 ) in
    `| (\pt( l2 ) - \pt( l1 )) *d n | / norm n.

End distance_line.
