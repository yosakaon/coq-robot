(* coq-robot (c) 2017 AIST and INRIA. License: LGPL-2.1-or-later. *)
From HB Require Import structures.
Require Import NsatzTactic.
From mathcomp Require Import all_ssreflect ssralg ssrint ssrnum rat poly.
From mathcomp Require Import closed_field polyrcf matrix mxalgebra mxpoly zmodp.
From mathcomp Require Import realalg reals complex.
From mathcomp Require Import interval trigo fingroup perm.
Require Import extra_trigo.
Require Import ssr_ext euclidean skew vec_angle frame.
From mathcomp.analysis Require Import forms.

(******************************************************************************)
(*                              Rotations                                     *)
(*                                                                            *)
(* This file develops the theory of 3D rotations with results such as         *)
(* Rodrigues formula, the fact that any rotation matrix can be represented    *)
(* by its exponential coordinates, angle-axis representation, Euler angles,   *)
(* etc. See also quaternion.v for rotations using quaternions.                *)
(*                                                                            *)
(*  RO a, RO' a == two dimensional rotations of angle a                       *)
(*                                                                            *)
(* Elementary rotations (row vector convention):                              *)
(*  Rx a, Rx' a == rotations about axis x of angle a                          *)
(*  Ry a == rotation about axis y of angle a                                  *)
(*  Rz a == rotation about axis z of angle a                                  *)
(*                                                                            *)
(*  isRot a u f == f is a rotation of angle a w.r.t. vector u                 *)
(*    sample lemmas:                                                          *)
(*    all rotations around a vector of angle a have trace "1 + 2 * cos a"     *)
(*    equivalence SO[R]_3 <-> Rot (isRot_SO, SO_is_Rot)                       *)
(*                                                                            *)
(*   `e(a, M) == specialized exponential map for angle a and matrix M         *)
(*  `e^(a, w) == specialized exponential map for the matrix \S(w), i.e., the  *)
(*               skew-symmetric matrix corresponding to vector w              *)
(*    sample lemmas:                                                          *)
(*    inverse of the exponential map,                                         *)
(*    exponential map of a skew matrix is a rotation                          *)
(*                                                                            *)
(* rodrigues u a w == linear combination of the vectors u, (u *d w)w, w *v u  *)
(*                    that provides an alternative expression for the vector  *)
(*                    u * e^(a,w)                                             *)
(*                                                                            *)
(* Angle-axis representation:                                                 *)
(*   Aa.angle M == angle of angle-axis representation for the matrix M        *)
(*   Aa.vaxis M == axis of angle-axis representation for the matrix M         *)
(*    sample lemma                                                            *)
(*    a rotation matrix has Aa.angle M and normalize (Aa.vaxis M) for         *)
(*    exponential coordinates                                                 *)
(*                                                                            *)
(* Composition of elementary rotations (row vector convention):               *)
(*   Rzyz a b c == composition of a Rz rotation of angle c, a Ry rotation of  *)
(*                 angle b, and a Rz rotation of angle a                      *)
(*   Rxyz a b c == composition of a Rx rotation of angle c, a Ry rotation of  *)
(*                 angle b, and a Rz notation of angle a                      *)
(*                                                                            *)
(* ZYZ angles given a rotation matrix M (ref: [sciavicco] 2.4.1):             *)
(* with zyz_b in ]0;pi[:                                                      *)
(*   zyz_a M == angle of the last Rz rotation                                 *)
(*   zyz_b M == angle of the Ry rotation                                      *)
(*   zyz_c M == angle of the first Rz rotation                                *)
(*                                                                            *)
(* Roll-Pitch-Yaw (ZYX) angles given a rotation matrix M                      *)
(* with pitch in ]-pi/2;pi/2[ (ref: [sciavicco] 2.4.2):                       *)
(*   rpy_a M == angle about axis z (roll)                                     *)
(*   rpy_b M == angle about axis y (pitch)                                    *)
(*   rpy_c M == angle about axis x (yaw)                                      *)
(*                                                                            *)
(* Alternative formulation of ZYX angles:                                     *)
(* (ref: [Gregory G. Slabaugh, Computer Euler angles from a rotation matrix]) *)
(*   euler_a == angle about z                                                 *)
(*   euler_b == angle about y                                                 *)
(*   euler_c == angle about x                                                 *)
(******************************************************************************)

Reserved Notation "'`e(' a ',' M ')'" (format "'`e(' a ','  M ')'").
Reserved Notation "'`e^(' a ',' w ')'" (format "'`e^(' a ','  w ')'").

Set Implicit Arguments.
Unset Strict Implicit.
Unset Printing Implicit Defensive.

(* TODO: overrides forms.v *)
Notation "u '``_' i" := (u (@GRing.zero _) i) : ring_scope.

Import Order.TTheory GRing.Theory Num.Def Num.Theory.

Local Open Scope ring_scope.

Section two_dimensional_rotation.

Variable T : realType.
Implicit Types (a b : T) (M : 'M[T]_2).

Definition RO a := col_mx2 (row2 (cos a) (sin a)) (row2 (- sin a) (cos a)).

Lemma trmx_RO a : (RO a)^T = RO (- a).
Proof.
apply/matrixP => i j.
rewrite !mxE /= cosN sinN opprK.
case: ifPn => [/eqP ->{j}|].
  case: ifPn => [/eqP ->{i}|]; first by rewrite !mxE.
  by rewrite ifnot01 => /eqP ->{i}; rewrite eqxx !mxE.
rewrite ifnot01 => /eqP ->; rewrite eqxx.
case: ifPn => [/eqP ->{i}|]; rewrite ?mxE //= ifnot01 => /eqP ->{i}.
by rewrite eqxx /= mxE.
Qed.

Lemma tr_RO a : \tr (RO a) = (cos a) *+ 2.
Proof. by rewrite /mxtrace sum2E !mxE /= mulr2n. Qed.

Lemma RO_is_O a : RO a \is 'O[T]_2.
Proof.
apply/orthogonal2P; rewrite !rowK /= !dotmulE !sum2E !mxE /= -!expr2 cos2Dsin2.
by rewrite addrC mulrN mulrC subrr addrC mulNr mulrC subrr sqrrN addrC cos2Dsin2 !eqxx.
Qed.

Lemma RO_is_SO a : RO a \is 'SO[T]_2.
Proof.
by rewrite rotationE RO_is_O /= det_mx22 !mxE /= mulrN opprK -!expr2 cos2Dsin2.
Qed.

Lemma rot2d_helper M a b : sin (b - a) = 1 ->
  M = col_mx2 (row2 (cos a) (sin a)) (row2 (cos b) (sin b)) ->
  { a0 | - pi < a0 <= pi & M = RO a0 }.
Proof.
move=> abpi.
have -> : sin b = cos a.
  rewrite -[b](subrK a) sinD abpi mul1r [cos (_ - _)]sin1cos0.
    by rewrite mul0r addr0.
  by rewrite abpi normr1.
have -> : cos b = - sin a.
  rewrite -[b](subrK a) cosD abpi mul1r [cos (_ - _)]sin1cos0.
    by rewrite mul0r sub0r.
  by rewrite abpi normr1.
move=> ->; exists (norm_angle a); first by apply: norm_angle_bound.
by rewrite /RO cos_norm_angle sin_norm_angle.
Qed.

Lemma rot2d M : M \is 'SO[T]_2 -> {a | - pi < a <= pi & M = RO a}.
Proof.
move=> MSO.
move: (MSO); rewrite rotationE => /andP[MO _].
case: (norm1_cossin (norm_row_of_O MO 0)); rewrite !mxE => a [a1 a2].
case: (norm1_cossin (norm_row_of_O MO 1)); rewrite !mxE => b [b1 b2].
move/orthogonalP : (MO) => /(_ 0 1) /=.
rewrite dotmulE sum2E !mxE a1 a2 b1 b2 -cosB => cE.
have : `|sin (a - b)| = 1 by apply: cos0sin1.
case: (ler0P (sin (a - b))) => sE; last first.
  exfalso.
  move/rotation_det : MSO.
  rewrite det_mx22 a1 a2 b1 b2 mulrC -(mulrC (cos b)) -sinB => /esym/eqP.
  rewrite -eqr_opp -sinN opprB => /eqP sE1.
  by move: sE; rewrite -sE1 ltr_oppr oppr0 (ltr_nat _ 1 0).
rewrite -sinN opprB => /(@rot2d_helper M a b); apply.
by rewrite -a1 -a2 -b1 -b2 [in LHS](col_mx2_rowE M) 2!row2_of_row.
Qed.

Definition RO' a := col_mx2 (row2 (cos a) (sin a)) (row2 (sin a) (- cos a)).

Lemma rot2d_helper' M a b : sin (a - b) = 1 ->
  M = col_mx2 (row2 (cos a) (sin a)) (row2 (cos b) (sin b)) ->
  {a0 | -pi < a0 <= pi & M = RO' a0}.
Proof.
move=> abpi.
have -> : sin b = - cos a.
  rewrite -[a](subrK b) cosD abpi mul1r [cos (_ - _)]sin1cos0.
    by rewrite mul0r sub0r opprK.
  by rewrite abpi normr1.
have -> : cos b = sin a.
  rewrite -[a](subrK b) sinD abpi mul1r [cos (_ - _)]sin1cos0.
    by rewrite mul0r addr0.
  by rewrite abpi normr1.
move=> ->; exists (norm_angle a); first exact: norm_angle_bound.
by rewrite /RO' cos_norm_angle sin_norm_angle.
Qed.

Lemma rot2d' M :
  M \is 'O[T]_2 -> 
    {a : T & { - pi < a <= pi /\ M = RO a} + 
             { - pi < a <= pi /\ M = RO' a}}.
Proof.
move=> MO.
case: (norm1_cossin (norm_row_of_O MO 0)); rewrite !mxE => a [a1 a2].
case: (norm1_cossin (norm_row_of_O MO 1)); rewrite !mxE => b [b1 b2].
move/orthogonalP : (MO) => /(_ 0 1) /=.
rewrite dotmulE sum2E !mxE a1 a2 b1 b2 -cosB.
have HM : M = col_mx2 (row2 (cos a) (sin a)) (row2 (cos b) (sin b)).
  by rewrite -a1 -a2 -b1 -b2 [in LHS](col_mx2_rowE M) 2!row2_of_row.
move=> cE.
have : `|sin (a - b)| = 1 by apply: cos0sin1.
case: (ler0P (sin (a - b))) => sE; last first.
  case/(@rot2d_helper' M)/(_ HM) => a0.
  by exists a0; right.
rewrite -sinN opprB => abpi.
case: (rot2d_helper abpi HM) => a0 KM.
exists a0; by left.
Qed.

Lemma tr_SO2 M : M \is 'SO[T]_2 -> `|\tr M| <= 2%:R.
Proof.
case/rot2d => a aB PRO; move: (cos_max a) => ca.
rewrite PRO tr_RO -(mulr_natr (cos a)) normrM normr_nat.
by rewrite -[in X in _ <= X]mulr_natr ler_pmul.
Qed.

End two_dimensional_rotation.

Section elementary_rotations.
Variable T : realType.
Implicit Types a b : T.

Local Open Scope frame_scope.

Definition Rx a := col_mx3
  'e_0
  (row3 0 (cos a) (sin a))
  (row3 0 (- sin a) (cos a)).

Lemma Rx0 : Rx 0 = 1.
Proof.
by rewrite /Rx cos0 sin0 oppr0; apply/matrix3P/and9P; split; rewrite !mxE.
Qed.

Lemma Rxpi : Rx pi = diag_mx (row3 1 (-1) (-1)).
Proof.
rewrite /Rx cospi sinpi oppr0; apply/matrix3P/and9P; split;
  by rewrite !mxE /= -?mulNrn ?mulr1n ?mulr0n.
Qed.

Lemma Rx_RO a : Rx a = block_mx (1 : 'M_1) 0 0 (RO a).
Proof.
rewrite -(@submxK _ 1 2 1 2 (Rx a)) (_ : ulsubmx _ = 1); last first.
  apply/rowP => i; by rewrite (ord1 i) !mxE /=.
rewrite (_ : ursubmx _ = 0); last by apply/rowP => i; rewrite !mxE.
rewrite (_ : dlsubmx _ = 0); last first.
  apply/colP => i; rewrite !mxE /=.
  case: ifPn; [by rewrite !mxE | by case: ifPn; rewrite !mxE].
rewrite (_ : drsubmx _ = RO a) //; by apply/matrix2P; rewrite !mxE /= !eqxx.
Qed.

Lemma Rx_is_SO a : Rx a \is 'SO[T]_3.
Proof. by rewrite Rx_RO (SOSn_SOn 1) RO_is_SO. Qed.

Lemma mxtrace_Rx a : \tr (Rx a) = 1 + cos a *+ 2.
Proof. by rewrite /Rx /mxtrace sum3E !mxE /= -addrA -mulr2n. Qed.

Lemma inv_Rx a : (Rx a)^-1 = Rx (- a).
Proof.
move/rotation_inv : (Rx_is_SO a) => ->.
rewrite /Rx cosN sinN opprK; by apply/matrix3P/and9P; split; rewrite !mxE.
Qed.

Definition Rx' a := col_mx3
  'e_0
  (row3 0 (cos a) (sin a))
  (row3 0 (sin a) (- cos a)).

Lemma Rx'_RO a : Rx' a = block_mx (1 : 'M_1) 0 0 (RO' a).
Proof.
rewrite -(@submxK _ 1 2 1 2 (Rx' a)) (_ : ulsubmx _ = 1); last first.
  apply/rowP => i; by rewrite (ord1 i) !mxE /=.
rewrite (_ : ursubmx _ = 0); last by apply/rowP => i; rewrite !mxE.
rewrite (_ : dlsubmx _ = 0); last first.
  apply/colP => i; rewrite !mxE /=.
  case: ifPn; first by rewrite !mxE.
  by case: ifPn; rewrite !mxE.
rewrite (_ : drsubmx _ = RO' a) //; by apply/matrix2P; rewrite !mxE /= !eqxx.
Qed.

Lemma det_Rx' a : \det (Rx' a) = -1.
Proof.
rewrite det_mx33 !mxE /=. Simp.r. by rewrite -!expr2 -opprD cos2Dsin2.
Qed.

Definition Ry a := col_mx3
  (row3 (cos a) 0 (- sin a))
  'e_1
  (row3 (sin a) 0 (cos a)).

Lemma Ry_is_SO a : Ry a \is 'SO[T]_3.
Proof.
apply/rotation3P/and4P; split.
- rewrite -(@eqr_expn2 _ 2) // ?norm_ge0 // expr1n.
  by rewrite -dotmulvv dotmulE sum3E !mxE /= mulr0 addr0 -2!expr2 sqrrN cos2Dsin2.
- rewrite -(@eqr_expn2 _ 2) // ?norm_ge0 // expr1n.
   by rewrite -dotmulvv dotmulE sum3E !mxE /= mulr0 addr0 add0r mulr1.
- by rewrite 2!rowK /= dotmulE sum3E !mxE /= !mulr0 mul0r !add0r.
- rewrite 3!rowK /= crossmulE !mxE /=. by Simp.r.
Qed.

Definition Rz a := col_mx3
  (row3 (cos a) (sin a) 0)
  (row3 (- sin a) (cos a) 0)
  'e_2%:R.

Lemma Rz_RO a : Rz a = block_mx (RO a) 0 0 (1 : 'M_1).
Proof.
rewrite -(@submxK _ 2 1 2 1 (Rz a)) (_ : drsubmx _ = 1); last first.
  apply/rowP => i; by rewrite (ord1 i) !mxE.
rewrite (_ : ulsubmx _ = RO a); last by apply/matrix2P; rewrite !mxE !eqxx.
rewrite (_ : ursubmx _ = 0); last first.
  apply/colP => i; case/boolP : (i == 0) => [|/ifnot01P]/eqP->; by rewrite !mxE.
rewrite (_ : dlsubmx _ = 0) //; apply/rowP => i; rewrite !mxE /=.
by case/boolP : (i == 0) => [|/ifnot01P]/eqP->.
Qed.

Lemma trmx_Rz a : (Rz a)^T = Rz (- a).
Proof. by rewrite Rz_RO (tr_block_mx (RO a)) !(trmx0,trmx1) trmx_RO -Rz_RO. Qed.

Lemma RzM a b : Rz a * Rz b = Rz (a + b).
Proof.
rewrite {1 2}/Rz e2row -col_mx3_mul 3!mulmx_row3_col3. Simp.r.
rewrite !row3Z !row3D. Simp.r. rewrite -e2row; congr col_mx3.
- by rewrite -cosD sinD (addrC (_ * _)).
- by rewrite -opprD -sinD [in X in row3 _ X _]addrC -cosD.
Qed.

Lemma Rz_is_SO a : Rz a \is 'SO[T]_3.
Proof.
apply/rotation3P/and4P; split.
- rewrite -(@eqr_expn2 _ 2) // ?norm_ge0 // expr1n.
  by rewrite -dotmulvv dotmulE sum3E !mxE /= mulr0 addr0 -2!expr2 cos2Dsin2.
- rewrite -(@eqr_expn2 _ 2) // ?norm_ge0 // expr1n.
- by rewrite -dotmulvv dotmulE sum3E !mxE /= mulr0 addr0 mulrN mulNr opprK addrC cos2Dsin2.
- by rewrite 2!rowK /= dotmulE sum3E !mxE /= mulrN mulr0 addr0 addrC mulrC subrr.
- rewrite 3!rowK /= crossmulE !mxE /=. Simp.r. by rewrite -!expr2 cos2Dsin2 e2row.
Qed.

Lemma RzE a : Rz a = (frame_of_SO (Rz_is_SO a)) _R^ (can_frame T).
Proof. rewrite FromTo_to_can; by apply/matrix3P/and9P; split; rewrite !mxE. Qed.

Lemma rmap_Rz_e0 a :
  rmap (can_tframe T) `[ 'e_0 $ frame_of_SO (Rz_is_SO a) ] =
                      `[ row 0 (Rz a) $ can_tframe T ].
Proof. by rewrite rmapE_to_can rowE [in RHS]RzE FromTo_to_can. Qed.

Definition Rzy a b := col_mx3
    (row3 (cos a * cos b) (sin a) (- cos a * sin b))
    (row3 (- sin a * cos b) (cos a) (sin a * sin b))
    (row3 (sin b) 0 (cos b)).

Lemma RzyE a b : Rz a * Ry b = Rzy a b.
Proof.
rewrite /Rz /Ry -col_mx3_mul; congr col_mx3.
- rewrite mulmx_row3_col3 scale0r addr0 row3Z mulr0.
  by rewrite e1row row3Z row3D ?(addr0,mulr0,add0r,mulr1,mulrN,mulNr).
- rewrite mulmx_row3_col3 scale0r addr0 row3Z mulr0.
  by rewrite e1row row3Z row3D mulr0 addr0 add0r mulr1 addr0 mulrN !mulNr opprK.
- by rewrite e2row mulmx_row3_col3 scale0r add0r scale0r add0r scale1r.
Qed.

Lemma Rzy_is_SO a b : Rzy a b \is 'SO[T]_3.
Proof. by rewrite -RzyE rpredM//= ?Rz_is_SO // Ry_is_SO. Qed.

End elementary_rotations.

Section isRot.

Local Open Scope frame_scope.

Variable T : realType.
Implicit Types a : T.

Definition isRot a (u : 'rV[T]_3) (f : {linear 'rV_3 -> 'rV_3}) : bool :=
  let: j := (Base.frame u) |, 1 in let: k := (Base.frame u) |, 2%:R in
  [&& f u == u,
      f j == cos a *: j + sin a *: k &
      f k == - sin a *: j + cos a *: k].

Lemma isRotP a u (f : {linear 'rV_3 -> 'rV_3}) : reflect
  (let: j := (Base.frame u) |, 1 in let: k := (Base.frame u) |, 2%:R in
  [/\ f u = u, f j = cos a *: j + sin a *: k & f k = - sin a *: j + cos a *: k])
  (isRot a u f).
Proof.
apply: (iffP idP); first by case/and3P => /eqP ? /eqP ? /eqP ?.
by case => H1 H2 H3; apply/and3P; rewrite H1 H2 H3.
Qed.

Section properties_of_isRot.

Variable u : 'rV[T]_3.
Implicit Types M N : 'M[T]_3.

Lemma isRot_axis a M : isRot a u (mx_lin1 M) -> u *m M = u.
Proof. by case/isRotP. Qed.

Lemma isRot1 : isRot 0 u (mx_lin1 1).
Proof.
apply/isRotP; split => /=; first by rewrite mulmx1.
by rewrite cos0 sin0 mulmx1 scale0r addr0 scale1r.
by rewrite mulmx1 sin0 cos0 scaleNr scale0r oppr0 add0r scale1r.
Qed.

Lemma isRotpi (u1 : norm u = 1) : isRot pi u (mx_lin1 (u^T *m u *+ 2 - 1)).
Proof.
apply/isRotP; split => /=.
- by rewrite mulmxBr mulmx1 mulr2n mulmxDr mulmxA dotmul1 // ?mul1mx addrK.
- rewrite cospi sinpi scale0r addr0 scaleN1r -Base.jE ?norm1_neq0 //=.
  rewrite mulmxDr -scaler_nat -scalemxAr mulmxA.
  by rewrite Base.j_tr_mul // mul0mx scaler0 add0r mulmxN mulmx1.
- rewrite sinpi oppr0 scale0r add0r cospi scaleN1r.
  rewrite -Base.kE ?norm1_neq0 //= mulmxBr mulmx1.
  by rewrite -scaler_nat -scalemxAr mulmxA Base.k_tr_mul // scaler0 add0r.
Qed.

Lemma isRotD a b M N : isRot a u (mx_lin1 M) -> isRot b u (mx_lin1 N) ->
  isRot (a + b) u (mx_lin1 (M * N)).
Proof.
move=> /isRotP[/= H1 H2 H3] /isRotP[/= K1 K2 K3]; apply/isRotP; split => /=.
- by rewrite mulmxA H1 K1.
- rewrite mulmxA H2 mulmxDl cosD sinD -2!scalemxAl K2 K3 2!scalerDr addrACA.
  by rewrite !scalerA mulrN -2!scalerDl (addrC (cos a * sin b)).
- rewrite mulmxA H3 mulmxDl -2!scalemxAl K2 K3 2!scalerDr !scalerA sinD cosD.
  rewrite addrACA mulrN -2!scalerDl -opprB mulNr opprK (addrC (- _ * _)) mulNr.
  by rewrite (addrC (cos a * sin b)).
Qed.

Lemma isRotN a M (u0 : u != 0) :
  isRot (- a) u (mx_lin1 M) -> isRot a (- u) (mx_lin1 M).
Proof.
move=> /isRotP [/= H1 H2 H3]; apply/isRotP; split => /=.
by rewrite mulNmx H1.
by rewrite Base.jN (Base.kN u0) H2 cosN sinN scalerN scaleNr.
by rewrite (Base.kN u0) Base.jN mulNmx H3 sinN cosN opprK scalerN scaleNr opprD.
Qed.

Lemma isRotZ a f k (u0 : u != 0) (k0 : 0 < k) :
  isRot a (k *: u) f = isRot a u f.
Proof.
rewrite /isRot !Base.Z // !linearZ; congr andb.
apply/idP/idP => [/eqP/scalerI ->//|/eqP ->//]; by move/gt_eqF : k0 => /negbT.
Qed.

Lemma isRotZN a f k (u0 : u != 0) (k0 : k < 0):
  isRot a (k *: u) (mx_lin1 f) = isRot (- a) u (mx_lin1 f).
Proof.
rewrite /isRot /= sinN cosN opprK Base.ZN // Base.jN (Base.kN u0).
rewrite !scalerN !scaleNr mulNmx eqr_oppLR opprD !opprK -scalemxAl; congr andb.
apply/idP/idP => [/eqP/scalerI ->//|/eqP ->//]; by move/lt_eqF : k0 => /negbT.
Qed.

Lemma mxtrace_isRot a M (u0 : u != 0) :
  isRot a u (mx_lin1 M) -> \tr M = 1 + cos a *+ 2.
Proof.
case/isRotP=> /= Hu Hj Hk.
move: (@basis_change _ M (Base.frame u) (Rx a)).
rewrite /= !mxE /= !scale1r !scale0r !add0r !addr0.
rewrite (invariant_colinear u0 Hu) ?colinear_frame0 // => /(_ erefl Hj Hk) ->.
rewrite mxtrace_mulC mulmxA mulmxV ?mul1mx ?mxtrace_Rx //.
by rewrite unitmxE unitfE rotation_det ?oner_neq0 // Base.is_SO.
Qed.

Lemma same_isRot M N v k (u0 : u != 0) (k0 : 0 < k) a :
  u = k *: v ->
  isRot a u (mx_lin1 M) -> isRot a v (mx_lin1 N) ->
  M = N.
Proof.
move=> mkp /isRotP[/= HMi HMj HMk] /isRotP[/= HNi HNj HNk].
apply/eqP/mulmxP => w.
rewrite (orthogonal_expansion (Base.frame u) w).
rewrite !mulmxDl -!scalemxAl.
have v0 : v != 0 by apply: contra u0; rewrite mkp => /eqP ->; rewrite scaler0.
congr (_ *: _ + _ *: _ + _ *: _).
- by rewrite (Base.frame0E u0) /normalize -scalemxAl HMi {2}mkp -HNi scalemxAl -mkp
    scalemxAl.
- by rewrite HMj /= mkp (Base.Z _ k0) -HNj.
- by rewrite HMk /= mkp (Base.Z _ k0) -HNk.
Qed.

Lemma isRot_0_inv (u0 : u != 0) M : isRot 0 u (mx_lin1 M) -> M = 1.
Proof.
move=> H; move/(same_isRot u0 ltr01 _ H) : isRot1; apply; by rewrite scale1r.
Qed.

Lemma isRot_tr a (u0 : u != 0) M : M \in unitmx ->
  isRot (- a) u (mx_lin1 M) -> isRot a u (mx_lin1 M^-1).
Proof.
move=> Hf /isRotP /= [/= H1 H2 H3].
move: (@basis_change _ M (Base.frame u) (Rx (- a))).
rewrite /= !mxE /= !(scale0r,addr0,add0r,scale1r) -H2 -H3.
rewrite (invariant_colinear u0 H1) ?colinear_frame0 //.
move/(_ erefl erefl erefl) => fRx.
have HfRx : M^-1 = (col_mx3 (Base.frame u)|,0 (Base.frame u)|,1 (Base.frame u)|,2%:R)^T *m
   (Rx (- a))^-1 *m col_mx3 (Base.frame u)|,0 (Base.frame u)|,1 (Base.frame u)|,2%:R.
  rewrite fRx invrM /=; last 2 first.
    rewrite unitrMr orthogonal_unit // ?(rotation_sub (Rx_is_SO _)) //.
    by rewrite rotation_inv ?Base.is_SO // rotation_sub // rotationV Base.is_SO.
    by rewrite orthogonal_unit // rotation_sub // Base.is_SO.
  rewrite invrM; last 2 first.
    rewrite rotation_inv ?Base.is_SO // orthogonal_unit // rotation_sub //.
    by rewrite rotationV // Base.is_SO.
    by rewrite orthogonal_unit // ?(rotation_sub (Rx_is_SO _)).
  by rewrite invrK rotation_inv ?Base.is_SO // mulmxE mulrA.
apply/isRotP; split => /=.
- by rewrite -{1}H1 -mulmxA mulmxV // mulmx1.
- rewrite HfRx !mulmxA.
  rewrite (_ : (Base.frame u)|,1 *m _ = 'e_1); last first.
    by rewrite mul_tr_col_mx3 dotmulC dotmulvv normj // expr1n idotj // jdotk // e1row.
  rewrite (_ : 'e_1 *m _ = row3 0 (cos (- a)) (sin a)); last first.
    rewrite (rotation_inv (Rx_is_SO (- a))) /Rx mul_tr_col_mx3.
    rewrite dote2 /= 2!dotmulE 2!sum3E !mxE /= cosN sinN opprK. by Simp.r.
  by rewrite mulmx_row3_col3 scale0r add0r cosN.
- rewrite HfRx !mulmxA.
  rewrite (_ : (Base.frame u)|,2%:R *m _ = 'e_2%:R); last first.
    by rewrite mul_tr_col_mx3 dotmulC idotk // dotmulC jdotk // dotmulvv normk // expr1n e2row.
  rewrite (_ : 'e_2%:R *m _ = row3 0 (- sin a) (cos a)); last first.
    rewrite (rotation_inv (Rx_is_SO (- a))) /Rx mul_tr_col_mx3.
    rewrite dote2 /= 2!dotmulE 2!sum3E !mxE /= cosN sinN opprK. by Simp.r.
  by rewrite mulmx_row3_col3 scale0r add0r.
Qed.

Lemma isRot_SO a M (u0 : u != 0) : isRot a u (mx_lin1 M) -> M \is 'SO[T]_3.
Proof.
move/isRotP=> /= [Hu Hj Hk].
move: (@basis_change _ M (Base.frame u) (Rx a)).
rewrite /= !mxE /= !(scale1r,scale0r,add0r,addr0).
rewrite (invariant_colinear u0 Hu) ?colinear_frame0 // => /(_ erefl Hj Hk) ->.
by rewrite rpredM // ?Base.is_SO // rpredM // ?Rx_is_SO // rotation_inv // ?Base.is_SO // rotationV Base.is_SO.
Qed.

End properties_of_isRot.

Section relation_with_rotation_matrices.

Lemma SO_isRot M : M \is 'SO[T]_3 ->
  {a | - pi < a <= pi & isRot a (vaxis_euler M) (mx_lin1 M)}.
Proof.
move=> MSO.
set e := vaxis_euler M.
case/boolP : (M == 1) => [/eqP ->|M1].
  exists 0; last by exact: isRot1.
  by rewrite oppr_cp0 ?(pi_ge0, pi_gt0).
have v0 := vaxis_euler_neq0 MSO.
rewrite -/e in v0.
have vMv := vaxis_eulerP MSO.
rewrite -/e in vMv.
set i := (Base.frame e)|,0. set j := (Base.frame e)|,1. set k := (Base.frame e)|,2%:R.
have iMi : i *m M = i.
  by rewrite (invariant_colinear v0) // ?colinear_frame0.
have iMj : i *d (j *m M) = 0.
  rewrite -iMi (proj2 (orth_preserves_dotmul M) (rotation_sub MSO) i j).
  by rewrite /i /j 2!rowframeE dot_row_of_O // NOFrame.MO.
have iMk : i *d (k *m M) = 0.
  rewrite -iMi (proj2 (orth_preserves_dotmul M) (rotation_sub MSO) i k).
  by rewrite /i /k 2!rowframeE dot_row_of_O // NOFrame.MO.
set a := (j *m M) *d j.
set b := (j *m M) *d k.
have ab : j *m M = a *: j + b *: k.
  by rewrite {1}(orthogonal_expansion (Base.frame e) (j *m M)) dotmulC iMj
    scale0r add0r.
set c := (k *m M) *d j.
set d := (k *m M) *d k.
have cd : k *m M = c *: j + d *: k.
  by rewrite {1}(orthogonal_expansion (Base.frame e) (k *m M)) dotmulC iMk
    scale0r add0r.
have H1 : a ^+ 2 + b ^+ 2 = 1.
  move/eqP: (norm_row_of_O (NOFrame.MO (Base.frame e)) 1).
  rewrite -(@eqr_expn2 _ 2) // ?norm_ge0 // expr1n -dotmulvv.
  rewrite -(proj2 (orth_preserves_dotmul M) (rotation_sub MSO)).
  rewrite -rowframeE ab dotmulDr 2!dotmulDl 4!dotmulvZ 4!dotmulZv 2!dotmulvv.
  by rewrite normj // normk // !(expr1n,mulr1) -!expr2 dotmulC jdotk // !(mulr0,add0r,addr0) => /eqP.
have H2 : a * c + b * d = 0.
  move/eqP: (dot_row_of_O (NOFrame.MO (Base.frame e)) 1 2%:R).
  rewrite -2!rowframeE -(proj2 (orth_preserves_dotmul M) (rotation_sub MSO) j k) ab cd.
  rewrite dotmulDr 2!dotmulDl 4!dotmulvZ 4!dotmulZv 2!dotmulvv normj // normk //.
  by rewrite expr1n !mulr1 dotmulC jdotk // 4!mulr0 add0r addr0 mulrC (mulrC d) => /eqP.
have H3 : c ^+ 2 + d ^+ 2 = 1.
  move/eqP: (norm_row_of_O (NOFrame.MO (Base.frame e)) 2%:R).
  rewrite -(@eqr_expn2 _ 2) // ?norm_ge0 // expr1n -dotmulvv.
  rewrite -(proj2 (orth_preserves_dotmul M) (rotation_sub MSO)) -!rowframeE -/k cd.
  rewrite dotmulDr 2!dotmulDl 4!dotmulvZ 4!dotmulZv 2!dotmulvv normj // normk //.
  by rewrite expr1n 2!mulr1 -2!expr2 dotmulC jdotk // !(mulr0,addr0,add0r) => /eqP.
set P := col_mx2 (row2 a b) (row2 c d).
have PO : P \is 'O[T]_2.
  apply/orthogonal2P; rewrite !rowK /= !dotmulE !sum2E !mxE /=.
  by rewrite -!expr2 H1 H2 mulrC (mulrC d) H2 H3 !eqxx.
case: (rot2d' PO) => phi [[phiB phiRO] | [phiB  phiRO']]; subst P.
- case/eq_col_mx2 : phiRO => Ha Hb Hc Hd.
  exists phi => //.
  rewrite -(@isRotZ _ phi (mx_lin1 M) 1 _ _) // scale1r; apply/isRotP; split => //.
  by rewrite -!(Ha,Hb,Hc).
  by rewrite -!(Hb,Hc,Hd).
- exfalso.
  case/eq_col_mx2 : phiRO' => Ha Hb Hc Hd.
  move: (@basis_change _ M (Base.frame e) (Rx' phi)).
  rewrite !mxE /= !(addr0,add0r,scale0r,scale1r) -/i -/j -/k.
  rewrite -{1}Ha -{1}Hb -{1}Hc -{1}Hd.
  rewrite -ab iMi -cd => /(_ erefl erefl erefl) => HM.
  move: (rotation_det MSO).
  rewrite HM 2!det_mulmx det_Rx' detV -crossmul_triple.
  move: (Frame.MSO (Base.frame e)).
  rewrite rotationE => /andP[_] /=.
  rewrite crossmul_triple => /eqP.
  rewrite /i /j /k.
  rewrite !rowframeE.
  rewrite col_mx3_row => ->.
  rewrite invr1 mulr1 mul1r => /eqP.
  by rewrite eqrNxx oner_eq0.
Qed.

End relation_with_rotation_matrices.

End isRot.

Section exponential_map_rot.

Variable T : realType.
Let vector := 'rV[T]_3.
Implicit Types (u v w : vector) (a b : T) (M : 'M[T]_3).

Definition emx3 a M : 'M_3 := 1 + sin a *: M + (1 - cos a) *: M ^+ 2.

Local Notation "'`e(' a ',' M ')'" := (emx3 a M).

Lemma emx3a0 a : `e(a, 0) = 1.
Proof. by rewrite /emx3 expr0n /= 2!scaler0 2!addr0. Qed.

Lemma emx30M M : `e(0, M) = 1.
Proof. by rewrite /emx3 sin0 cos0 subrr 2!scale0r 2!addr0. Qed.

Lemma emx30M' M a : cos a = 1 -> sin a = 0 -> `e(a, M) = 1.
Proof. 
by rewrite /emx3 => -> ->; rewrite subrr 2!scale0r 2!addr0. 
Qed.

Lemma tr_emx3 a M : `e(a, M)^T = `e(a, M^T).
Proof.
by rewrite /emx3 !linearD /= !linearZ /= trmx1 expr2 trmx_mul expr2.
Qed.

Lemma emx3M a b M : M ^+ 3 = - M -> `e(a, M) * `e(b, M) = `e(a + b, M).
Proof.
move=> cube_u.
rewrite /emx3 sinD cosD !mulrDr !mulrDl.
Simp.r => /=.
rewrite -scalerCA -2!scalerAl -expr2.
rewrite -scalerAl -scalerAr -exprSr cube_u (scalerN (sin b) M) (scalerN (1 - cos a)).
rewrite -(scalerAl (sin a)) -(scalerCA (1 - cos b) M) -(scalerAl (1 - cos b)) -exprS.
rewrite cube_u (scalerN _ M) (scalerN (sin a) (_ *: _)).
rewrite -!addrA; congr (_ + _).
do 2 rewrite addrC -!addrA.
rewrite addrC scalerA (mulrC (sin b)) -!addrA.
rewrite [in RHS]addrC [in RHS]scalerBl [in RHS]scalerBl [in RHS]opprB [in RHS]addrCA -![in RHS]addrA; congr (_ + _).
rewrite scalerBl scale1r opprB (scalerA (cos a)) -!addrA.
rewrite [in RHS]scalerDl ![in RHS]addrA [in RHS]addrC -[in RHS]addrA; congr (_ + _).
rewrite addrC ![in LHS]addrA addrK.
rewrite -![in LHS]addrA addrC scalerBl scale1r scalerBr opprB scalerA -![in LHS]addrA.
rewrite [in RHS]addrA [in RHS]addrC; congr (_ + _).
rewrite addrCA ![in LHS]addrA subrK -scalerCA -2!scalerAl -exprD.
rewrite (_ : M ^+ 4 = - M ^+ 2); last by rewrite exprS cube_u mulrN -expr2.
rewrite 2!scalerN scalerA.
rewrite addrC -scaleNr -2!scalerDl -scalerBl; congr (_ *: _).
rewrite -!addrA; congr (_ + _).
rewrite mulrBr mulr1 mulrBl mul1r opprB opprB !addrA subrK addrC.
rewrite -(addrC (cos a)) !addrA -(addrC (cos a)) subrr add0r.
by rewrite addrC addrA subrr add0r mulrC.
Qed.

Lemma inv_emx3 a M : M ^+ 4 = - M ^+ 2 -> `e(a, M) * `e(a, - M) = 1.
Proof.
move=> aM.
case/boolP : (cos a == 1) => [/eqP|] ca; rewrite /emx3.
  rewrite ca subrr (_ : sin a = 0) ; last by rewrite cos1sin0 // ca normr1.
  by rewrite !scale0r !addr0 mulr1.
rewrite !mulrDr !mulrDl !mulr1 !mul1r -[RHS]addr0 -!addrA; congr (_ + _).
rewrite !addrA sqrrN -!addrA (addrCA (_ *: M ^+ 2)) !addrA scalerN subrr add0r.
rewrite (_ : (1 - _) *: _ * _ = - (sin a *: M * ((1 - cos a) *: M ^+ 2))); last first.
  rewrite mulrN; congr (- _).
  by rewrite -2!scalerAr -!scalerAl -exprS -exprSr 2!scalerA mulrC.
rewrite -!addrA (addrCA (- (sin a *: _ * _))) !addrA subrK.
rewrite mulrN -scalerAr -scalerAl -expr2 scalerA -expr2.
rewrite -[in X in _ - _ + _ + X = _]scalerAr -scalerAl -exprD scalerA -expr2.
rewrite -scalerBl -scalerDl sin2cos2.
rewrite -{2}(expr1n _ 2) subr_sqr -{1 3}(mulr1 (1 - cos a)) -mulrBr -mulrDr.
rewrite opprD addrA subrr add0r -(addrC 1) -expr2 -scalerDr.
apply/eqP; rewrite scaler_eq0 sqrf_eq0 subr_eq0 eq_sym (negbTE ca) /=.
by rewrite aM subrr.
Qed.

Local Notation "'`e^(' a ',' w ')'" := (emx3 a \S( w )).

Lemma eskew_pi w : norm w = 1 -> `e^(pi, w) = w^T *m w *+ 2 - 1.
Proof.
move=> w1.
rewrite /emx3 sinpi scale0r addr0 cospi opprK -(natrD _ 1 1).
rewrite sqr_spin w1 expr1n scalerDr addrCA scalerN scaler_nat; congr (_ + _).
rewrite scaler_nat mulr2n opprD addrCA.
by rewrite (_ : 1%:A = 1) // ?subrCA ?subrr ?addr0 // -idmxE scale1r.
Qed.

Lemma eskew_pi' w a : 
  norm w = 1 -> cos a = -1 -> sin a = 0 -> `e^(a, w) = w^T *m w *+ 2 - 1.
Proof.
move=> w1 Hs Hc.
rewrite /emx3 Hs Hc scale0r addr0 opprK -(natrD _ 1 1).
rewrite sqr_spin w1 expr1n scalerDr addrCA scalerN scaler_nat; congr (_ + _).
rewrite scaler_nat mulr2n opprD addrCA.
by rewrite (_ : 1%:A = 1) // ?subrCA ?subrr ?addr0 // -idmxE scale1r.
Qed.

Lemma eskew_v0 a : `e^(a, 0) = 1.
Proof. by rewrite spin0 emx3a0. Qed.

Lemma unspin_eskew a w : unspin `e^(a, w) = sin a *: w.
Proof.
rewrite /emx3 !(unspinD,unspinZ,unspinN,sqr_spin,spinK,unspin_cst,scaler0,add0r,subr0).
by rewrite unspin_sym ?scaler0 ?addr0 // mul_tr_vec_sym.
Qed.

Lemma tr_eskew a w : `e^(a, w)^T = `e^(a, - w).
Proof. by rewrite tr_emx3 tr_spin /emx3 spinN. Qed.

Lemma eskewM a b w : norm w = 1 -> `e^(a, w) * `e^(b, w) = `e^(a + b, w).
Proof. move=> w1; by rewrite emx3M // spin3 w1 expr1n scaleN1r. Qed.

Lemma trace_eskew a w : norm w = 1 -> \tr `e^(a, w) = 1 + 2%:R * cos a.
Proof.
move=> w1.
rewrite 2!mxtraceD !mxtraceZ /= mxtrace1.
rewrite (trace_anti (spin_is_so w)) mulr0 addr0 mxtrace_sqr_spin w1.
rewrite (_ : - _ = - 2%:R); last by rewrite expr1n mulr1.
by rewrite mulrDl addrA mul1r -natrB // mulrC mulrN -mulNr opprK.
Qed.

(* table 1.1 of [springer]
   'equivalent rotation matrices for various representations of orientation'
   angle-axis angle a, vector u *)
Definition angle_axis_rot a u :=
  let va := 1 - cos a in let ca := cos a in let sa := sin a in
  col_mx3
  (row3 (u``_0 ^+2 * va + ca)
        (u``_0 * u``_1 * va + u``_2%:R * sa)
        (u``_0 * u``_2%:R * va - u``_1 * sa))
  (row3 (u``_0 * u``_1 * va - u``_2%:R * sa)
        (u``_1 ^+2 * va + ca)
        (u``_1 * u``_2%:R * va + u``_0 * sa))
  (row3 (u``_0 * u``_2%:R * va + u``_1 * sa)
        (u``_1 * u``_2%:R * va - u``_0 * sa)
        (u``_2%:R ^+2 * va + ca)).

Lemma eskewE a u : norm u = 1 -> `e^(a, u) = angle_axis_rot a u.
Proof.
pose va := 1 - cos a. pose ca := cos a. pose sa := sin a.
move=> w1; apply/matrix3P/and9P; split; apply/eqP.
- rewrite 2![in RHS]mxE /= [in LHS]mxE -/sa -/va 3!mxE /= !spinij; Simp.r => /=.
  rewrite sqr_spin' !mxE /=.
  rewrite (_ : - _ - _ = u``_0 ^+ 2 - 1); last first.
    rewrite -[in X in _ = _ - X](expr1n _ 2%N) -w1 -dotmulvv dotmulE sum3E -3!expr2.
  by rewrite !opprD !addrA subrr add0r addrC.
- rewrite mulrBr mulr1 addrCA mulrC; congr (_ + _).
  by rewrite /va opprB addrC subrK.
- rewrite 2![in RHS]mxE /= [in LHS]mxE -/sa -/va 3!mxE /= !spinij; Simp.r => /=.
  by rewrite sqr_spin' !mxE /= addrC mulrC (mulrC sa).
- rewrite 2![in RHS]mxE /= [in LHS]mxE -/sa -/va 3!mxE /= !spinij; Simp.r => /=.
  by rewrite sqr_spin' !mxE /= addrC mulrC (mulrC sa).
- rewrite 2![in RHS]mxE /= [in LHS]mxE -/sa -/va 3!mxE /= !spinij; Simp.r => /=.
  by rewrite sqr_spin' !mxE /= addrC mulrC (mulrC sa).
- rewrite 2![in RHS]mxE /= [in LHS]mxE -/sa -/va 3!mxE /= !spinij; Simp.r => /=.
  rewrite sqr_spin' !mxE /=.
  rewrite (_ : - _ - _ = u``_1 ^+ 2 - 1); last first.
    rewrite -[in X in _ = _ - X](expr1n _ 2%N) -w1 -dotmulvv dotmulE sum3E -3!expr2.
    by rewrite 2!opprD addrCA addrA subrK addrC.
  rewrite mulrBr mulr1 addrCA mulrC; congr (_ + _).
  by rewrite /va opprB addrC subrK.
- rewrite 2![in RHS]mxE /= [in LHS]mxE -/sa -/va 3!mxE /= !spinij; Simp.r => /=.
  by rewrite sqr_spin' !mxE /= addrC mulrC (mulrC sa).
- rewrite 2![in RHS]mxE /= [in LHS]mxE -/sa -/va 3!mxE /= !spinij; Simp.r => /=.
  by rewrite sqr_spin' !mxE /= addrC mulrC (mulrC sa).
- rewrite 2![in RHS]mxE /= [in LHS]mxE -/sa -/va 3!mxE /= !spinij; Simp.r => /=.
  by rewrite sqr_spin' !mxE /= addrC mulrC (mulrC sa).
- rewrite 2![in RHS]mxE /= [in LHS]mxE -/sa -/va 3!mxE /= !spinij; Simp.r => /=.
  rewrite sqr_spin' !mxE /=.
  rewrite (_ : - _ - _ = u``_2%:R ^+ 2 - 1); last first.
    rewrite -[in X in _ = _ - X](expr1n _ 2%N) -w1 -dotmulvv dotmulE sum3E -3!expr2.
    by rewrite 2!opprD [in RHS]addrC subrK addrC.
  rewrite mulrBr mulr1 addrCA mulrC; congr (_ + _).
  by rewrite /va opprB addrC subrK.
Qed.

Lemma eskew_is_O a u : norm u = 1 -> `e^(a, u) \is 'O[T]_3.
Proof.
move=> u1.
by rewrite orthogonalE tr_emx3 tr_spin inv_emx3 // exp_spin u1 expr1n scaleN1r.
Qed.

Lemma rank_eskew a w : norm w = 1 -> \rank `e^(a, w) = 3%N.
Proof.
move=> w1; by rewrite mxrank_unit // orthogonal_unit // eskew_is_O.
Qed.

Lemma det_eskew a w : norm w = 1 -> \det `e^(a, w) = 1.
Proof.
move=> w1.
move/orthogonal_det/eqP : (eskew_is_O (a / 2%:R) w1).
rewrite -(@eqr_expn2 _ 2) // expr1n sqr_normr expr2 -det_mulmx.
rewrite mulmxE emx3M; last by rewrite spin3 w1 expr1n scaleN1r.
by move/eqP; rewrite -splitr.
Qed.

Lemma eskew_is_SO a w : norm w = 1 -> `e^(a, w) \is 'SO[T]_3.
Proof. by move=> w1; rewrite rotationE eskew_is_O //= det_eskew. Qed.

Definition expi a := (cos a +i* sin a)%C.

Lemma expiD a b : expi (a + b) = expi a * expi b.
Proof.
rewrite /expi cosD sinD.
by apply/eqP/andP; rewrite eqxx addrC eqxx.
Qed.

Lemma expi0 : expi (0) = 1 :> T[i].
Proof. by rewrite /expi cos0 sin0. Qed.

Definition eskew_eigenvalues a : seq T[i] := [:: 1; expi a; expi (- a)].
From mathcomp Require Import ssrAC.
Lemma eigenvalue_ekew a w : norm w = 1 ->
  eigenvalue (map_mx (fun x => x%:C%C) `e^(a, w)) =1
    [pred k | k \in eskew_eigenvalues a].
Proof.
move=> u1 /= k.
rewrite inE eigenvalue_root_char -map_char_poly.
rewrite /= !inE.
rewrite  char_poly3 /= trace_eskew // det_eskew //.
rewrite [`e(_,_) ^+ _]expr2 eskewM // trace_eskew //.
rewrite (_ : _ - _ = (1 + cos a *+ 2) *+ 2); last first.
  rewrite opprD addrA cosD -2!expr2 sin2cos2 opprB addrA -mulr2n mulrDr mulrN1.
  rewrite opprB addrA -(addrA _ (-1)) (_ : -1 + 2 = 1)//; last first.
    by rewrite addrC; apply/eqP; rewrite subr_eq.
  rewrite -addrA mulr_natl; apply/eqP.
  rewrite eq_sym [eqbRHS]addrC -subr_eq.
  rewrite expr2 mulr2n -[in X in X - _ == _](mulr1 (1 + cos a *+ 2)).
  rewrite -mulrDr -mulrBr opprD [in X in _ * X == _]addrA addrK.
  rewrite mulrC -subr_sqr expr1n; apply/eqP; congr (1 - _).
  by rewrite mulr_natl -mulrnA exprMn_n.
rewrite -[(_ + _) *+ _]mulr_natl mulrA divfK ?(eqr_nat _ 2 0) // mul1r.
rewrite linearB /= map_polyC /= !(linearB, linearD, linearZ) /=.
rewrite !map_polyXn map_polyX.
  rewrite (_ : _ - _ = ('X - 1) * ('X - (expi a)%:P) * ('X - (expi (-a))%:P)).
  by rewrite !rootM !root_XsubC orbA.
have expiDexpiN  : expi a + expi (-a) = (cos a + cos a)%:C%C.
  rewrite /expi cosN sinN.
  by apply/eqP; rewrite eq_complex /= subrr !eqxx.
rewrite !(mulrBr, mulrBl, mulrDr, mulrDl, mul1r, mulr1).
rewrite -expr2 -exprSr !addrA !scalerN.
rewrite ['X * _ * 'X]mulrAC -expr2 !['X * _]mulrC !['X^2 * _]mulrC.
rewrite [_* 'X * _]mulrAC -rmorphM /= -expiD subrr expi0 mul1r.
rewrite -!addrA; congr (_ + _); rewrite !(addrA, opprB, opprD).
rewrite [in RHS](ACl (1 * 3 * 7 * 2 * 4 * 5 * 6))/=.
rewrite -(addrA (- 'X^2)) -opprD -mulrDl -rmorphD/= expiDexpiN.
rewrite -addrA -3![in RHS]addrA; congr (_ + _).
  by rewrite !rmorphD/= !scalerDl/= scale1r !opprD mulrDl opprD/= addrA mul_polyC.
rewrite !addrA [in RHS](ACl (1 * 2 * 4 * 3))/=.
congr (_ - _).
rewrite [RHS]addrAC -mulrDl -rmorphD/= expiDexpiN.
rewrite -(addrA 1) rmorphD/= scalerDl scale1r addrC; congr (_ + _).
by rewrite mul_polyC.
Qed.

Lemma Rz_eskew a : Rz a = `e^(a, 'e_2%:R).
Proof.
rewrite /Rz eskewE /angle_axis_rot ?norm_delta_mx //.
rewrite !mxE /= expr0n /=. Simp.r.
by rewrite expr1n mul1r subrK -e2row.
Qed.

(* the w vector of e(phi,w) is an axis *)
Lemma axial_eskew a w : axial `e^(a, w) = sin a *+ 2 *: w.
Proof.
rewrite axialE unspinD unspin_eskew tr_eskew unspinN unspin_eskew scalerN.
by rewrite opprK -mulr2n scalerMnl.
Qed.

Section rodrigues_formula.

Definition rodrigues u a w :=
  u - (1 - cos a) *: (norm w ^+ 2 *: u) + (1 - cos a) * (u *d w) *: w + sin a *: (w *v u).

Lemma rodriguesP u a w : rodrigues u a w = u *m `e^(a, w).
Proof.
rewrite /rodrigues.
rewrite addrAC !mulmxDr mulmx1 -!scalemxAr mulmxA !spinE -!addrA; congr (_ + _).
rewrite !addrA.
rewrite [in X in _ = _ + X](@lieC _ (vec3 T)) scalerN.
rewrite [in X in _ = _ - X](@lieC _ (vec3 T)) /=.
rewrite double_crossmul dotmulvv.
rewrite scalerN opprK.
rewrite scalerBr [in RHS]addrA [in RHS]addrC -!addrA; congr (_ + (_ + _)).
by rewrite dotmulC scalerA.
Qed.

Definition rodrigues_unit u a w :=
  cos a *: u + (1 - cos a) * (u *d w) *: w + sin a *: (w *v u).

Lemma rodrigues_unitP u a w : norm w = 1 -> rodrigues_unit u a w = u *m `e^(a, w).
Proof.
move=> w1; rewrite -(rodriguesP u a w).
rewrite /rodrigues /rodrigues_unit w1 expr1n scale1r; congr (_ + _ + _).
by rewrite scalerBl opprB scale1r addrCA addrA addrK.
Qed.

End rodrigues_formula.

Lemma isRot_eskew_normalize a w : w != 0 -> isRot a w (mx_lin1 `e^(a, normalize w)).
Proof.
move=> w0.
pose f := Base.frame w.
apply/isRotP; split => /=.
- rewrite -rodriguesP // /rodrigues (norm_normalize w0) expr1n scale1r.
  rewrite dotmul_normalize_norm scalerA -mulrA divrr ?mulr1 ?unitfE ?norm_eq0 //.
  by rewrite subrK linearZl_LR /= (@liexx _ (vec3 T)) 2!scaler0 addr0.
- rewrite -rodriguesP // /rodrigues dotmulC norm_normalize // expr1n scale1r.
  rewrite (_ : normalize w = Base.i w) (*NB: lemma?*); last by rewrite /Base.i (negbTE w0).
  rewrite -Base.jE -Base.kE.
  rewrite Base.idotj // mulr0 scale0r addr0 -Base.icrossj /=  scalerBl scale1r.
  by rewrite opprB addrCA subrr addr0.
- rewrite -rodriguesP /rodrigues dotmulC norm_normalize // expr1n scale1r.
  rewrite (_ : normalize w = Base.i w) (*NB: lemma?*); last by rewrite /Base.i (negbTE w0).
  rewrite -Base.jE -Base.kE.
  rewrite Base.idotk // mulr0 scale0r addr0 scalerBl scale1r opprB addrCA subrr.
  rewrite addr0 addrC; congr (_ + _).
  by rewrite -/(Base.i w) Base.icrossk // scalerN scaleNr.
Qed.

Lemma isRot_eskew a w w' : normalize w' = w -> norm w = 1 -> isRot a w' (mx_lin1 `e^(a, w)).
Proof.
move=> <- w1.
by rewrite isRot_eskew_normalize // -normalize_eq0 -norm_eq0 w1 oner_eq0.
Qed.

Lemma eskew_is_onto_SO M : M \is 'SO[T]_3 ->
  { a | - pi < a <= pi & M = `e^(a, normalize (vaxis_euler M)) }.
Proof.
move=> MSO.
set w : vector := normalize _.
case: (SO_isRot MSO) => a aB Ha.
exists a => //.
apply: (@same_isRot _ _ _ _ _ (norm (vaxis_euler M)) _ _ _ _ Ha); last first.
  apply (@isRot_eskew _ _ w).
  by rewrite normalizeI // norm_normalize // vaxis_euler_neq0.
  by rewrite norm_normalize // vaxis_euler_neq0.
by rewrite norm_scale_normalize.
by rewrite norm_gt0 vaxis_euler_neq0.
by rewrite vaxis_euler_neq0.
Qed.

Section alternative_definition_of_eskew.

(* rotation of angle a around (unit) vector e *)
Definition eskew_unit (a : T) (e : 'rV[T]_3) :=
  e^T *m e + (cos a) *: (1 - e^T *m e) + sin a *: \S( e ).

Lemma eskew_unitE w (a : T) : norm w = 1 -> eskew_unit a w = `e^(a, w).
Proof.
move=> w1.
rewrite /eskew_unit /emx3 addrAC sqr_spin -addrA addrCA.
rewrite -[in RHS]addrA [in RHS]addrCA; congr (_ + _).
rewrite scalerBl scale1r addrCA -addrA; congr (_ + _).
rewrite scalerBr [in RHS]scalerBr opprB !addrA; congr (_ - _).
by rewrite addrC w1 expr1n !scalemx1 (addrC _ 1) subrr addr0.
Qed.

Local Open Scope frame_scope.

(* TODO: move? *)
Lemma normalcomp_double_crossmul p (e : 'rV[T]_3) : norm e = 1 ->
  normalcomp p e *v ((Base.frame e)|,2%:R *v (Base.frame e)|,1) = e *v p.
Proof.
move=> u1.
rewrite 2!rowframeE (@lieC _ (vec3 T) (row _ _)) /= SO_jcrossk; last first.
  by rewrite -(col_mx3_row (NOFrame.M (Base.frame e))) -!rowframeE Base.is_SO.
rewrite -rowframeE Base.frame0E ?norm1_neq0 //.
rewrite normalizeI // {2}(axialnormalcomp p e) linearD /=.
by rewrite crossmul_axialcomp add0r (@lieC _ (vec3 T)) /= linearNl opprK.
Qed.

Lemma normalcomp_mulO' a Q u p : norm u = 1 -> isRot a u (mx_lin1 Q) ->
  normalcomp p u *m Q = cos a *: normalcomp p u + sin a *: (u *v p).
Proof.
move=> u1 H.
set v := normalcomp p u.
move: (orthogonal_expansion (Base.frame u) v).
set p0 := _|,0. set p1 := _|,1. set p2 := _|,2%:R.
rewrite (_ : (v *d p0) *: _ = 0) ?add0r; last first.
  by rewrite /p0 Base.frame0E ?norm1_neq0 // normalizeI // dotmul_normalcomp scale0r.
move=> ->.
rewrite mulmxDl -2!scalemxAl.
case/isRotP : H => /= _ -> ->.
rewrite -/p1 -/p2.
rewrite (scalerDr (normalcomp p u *d p1)) scalerA mulrC -scalerA.
rewrite [in RHS]scalerDr -!addrA; congr (_ + _).
rewrite (scalerDr (normalcomp p u *d p2)) addrA addrC.
rewrite scalerA mulrC -scalerA; congr (_ + _).
rewrite scalerA mulrC -scalerA [in X in _ + X = _]scalerA mulrC -scalerA.
rewrite scaleNr -scalerBr; congr (_ *: _).
by rewrite -double_crossmul normalcomp_double_crossmul.
Qed.

(* [angeles] p.42, eqn 2.49 *)
Lemma isRot_eskew_unit_inv a Q u : norm u = 1 ->
  isRot a u (mx_lin1 Q) -> Q = eskew_unit a u.
Proof.
move=> u1 H; apply/eqP/mulmxP => p.
rewrite (axialnormalcomp (p *m Q) u) axialcomp_mulO; last 2 first.
  exact/rotation_sub/(isRot_SO (norm1_neq0 u1) H).
  exact: isRot_axis H.
rewrite normalcomp_mulO //; last 2 first.
  exact/rotation_sub/(isRot_SO (norm1_neq0 u1) H).
  exact: isRot_axis H.
rewrite axialcompE u1 expr1n invr1 scale1r.
rewrite /eskew_unit -addrA mulmxDr mulmxA; congr (_ + _).
rewrite (@normalcomp_mulO' a) // mulmxDr.
rewrite -[in X in _ = _ + X]scalemxAr spinE; congr (_ + _).
by rewrite normalcompE u1 expr1n invr1 scale1r scalemxAr.
Qed.

Lemma isRot_eskew_unit e (e0 : e != 0) (a : T) :
  isRot a e (mx_lin1 (eskew_unit a (normalize e))).
Proof.
move: (isRot_eskew_normalize a e0); by rewrite eskew_unitE ?norm_normalize.
Qed.

Lemma axial_skew_unit (e : vector) a : axial (eskew_unit a e) = sin a *: e *+ 2.
Proof.
rewrite /eskew_unit 2!axialD (_ : axial _ = 0) ?add0r; last first.
  apply/eqP; by rewrite -axial_sym mul_tr_vec_sym.
rewrite (_ : axial _ = 0) ?add0r; last first.
  apply/eqP; rewrite -axial_sym sym_scaler_closed (* TODO: declare the right canonical to be able to use rpredZ *) //.
  by rewrite rpredD // ?sym_cst // rpredN mul_tr_vec_sym.
rewrite axialZ axialE scalerMnr; congr (_ *: _).
by rewrite unspinD spinK unspinN tr_spin unspinN spinK opprK mulr2n.
Qed.

(* [angeles], p.42, 2.50 *)
Lemma isRot_pi_inv (R : 'M[T]_3) u :
  u != 0 -> isRot pi u (mx_lin1 R) ->
  R = (normalize u)^T *m normalize u *+ 2 - 1.
Proof.
move=> u0 H.
have /isRot_eskew_unit_inv {H} : isRot pi (normalize u) (mx_lin1 R).
  by rewrite isRotZ // invr_gt0 norm_gt0.
rewrite norm_normalize // => /(_ erefl) ->.
by rewrite eskew_unitE ?norm_normalize // eskew_pi // norm_normalize.
Qed.

End alternative_definition_of_eskew.

End exponential_map_rot.

Notation "'`e(' a ',' M ')'" := (emx3 a M).
Notation "'`e^(' a ',' w ')'" := (emx3 a \S( w )).

Module Aa.
Section angle_of_angle_axis_representation.

Variable T : realType.
Let vector := 'rV[T]_3.
Implicit Types M : 'M[T]_3.

Definition angle M := acos ((\tr M - 1) / 2%:R).

Lemma angle1 : angle 1 = 0.
Proof.
rewrite /angle mxtrace1 (_ : 3%:R - 1 = 2%:R); last first.
  by apply/eqP; rewrite subr_eq -(natrD _ 2 1).
by rewrite divrr ?unitfE ?pnatr_eq0 // acos1.
Qed.


(* reflection w.r.t. plan of normal u *)
Lemma anglepi (n : vector) (n1 : norm n = 1) :
  angle (n^T *m n *+ 2 - 1) = pi.
Proof.
rewrite /angle mxtraceD linearN /= mxtrace1 mulr2n linearD /=.
rewrite mxtrace_tr_mul n1 expr1n (_ : _ - 1 = - 2%:R); last first.
  by apply/eqP; rewrite -opprB eqr_opp opprB (_ : 1 + 1 = 2%:R) // -natrB.
by rewrite -mulr_natl mulNr divrr ?mulr1 ?unitfE ?pnatr_eq0 // acosN1.
Qed.

Lemma tr_angle M : angle M^T = angle M.
Proof. by rewrite /angle mxtrace_tr. Qed.

Lemma isRot_angle M u a : u != 0 -> 0 <= a <= pi ->
  isRot a u (mx_lin1 M) -> a = angle M.
Proof.
move=> u0 Ha.
move/(mxtrace_isRot u0); rewrite /angle => ->.
rewrite addrAC subrr add0r -(mulr_natr (cos a)) -mulrA divff ?mulr1 ?cosK //.
by rewrite pnatr_eq0.
Qed.

Lemma isRot_angleN M u a : u != 0 -> - pi <= a <= 0 ->
  isRot a u (mx_lin1 M) -> a = - angle M.
Proof.
move=> u0 Ha /(mxtrace_isRot u0); rewrite /angle=> ->.
rewrite addrAC subrr add0r -(mulr_natr (cos a)) -mulrA divff; last first.
  by rewrite pnatr_eq0.
by rewrite mulr1 cosKN // opprK.
Qed.

Lemma sym_angle M : M \is 'SO[T]_3 ->
  M \is sym 3 T -> angle M = 0 \/ angle M = pi.
Proof.
move=> MSO Msym.
case/eskew_is_onto_SO : (MSO) => a aB Ma.
move: (Msym).
rewrite {1}Ma /emx3.
rewrite symE !linearD /= trmx1 /= !linearZ /= sqr_spin !linearD /= !linearN /=.
rewrite trmx_mul trmxK scalemx1 tr_scalar_mx tr_spin.
rewrite !addrA subr_eq subrK.
rewrite [in X in _ == X]addrC -subr_eq0 !addrA !opprD !addrA addrK.
rewrite scalerN opprK -addrA addrCA !addrA (addrC _ 1) subrr add0r.
rewrite -mulr2n scalerMnl scaler_eq0 mulrn_eq0 /=.
rewrite -spin0 spin_inj -norm_eq0 norm_normalize ?vaxis_euler_neq0 // oner_eq0 orbF.
move=> /eqP Hs.
have := sin0cos1 Hs; case: (ler0P (cos a)) => _ Hc; move: Ma; last first.
  by rewrite emx30M' // => ->; rewrite angle1; left.
rewrite -eskew_unitE ?norm_normalize // ?vaxis_euler_neq0 //.
rewrite eskew_unitE ?norm_normalize // ?vaxis_euler_neq0 //.
rewrite eskew_pi' // ?norm_normalize // ?vaxis_euler_neq0 //; last first.
  by rewrite -Hc opprK.
move => ->; right.
by rewrite anglepi // ?norm_normalize // ?vaxis_euler_neq0 //.
Qed.

Lemma tr_interval M : M \is 'SO[T]_3 -> -1 <= (\tr M - 1) / 2%:R <= 1.
Proof.
move=> MSO; case/SO_isRot : (MSO) => a aB HM.
rewrite (mxtrace_isRot (vaxis_euler_neq0 MSO) HM).
rewrite [1 + _]addrC addrK -[_ *+2]mulr_natr mulfK.
  by rewrite cos_geN1 cos_le1.
by rewrite (eqr_nat _ 2 0).
Qed.

Lemma angle_interval M : M \is 'SO[T]_3 -> 0 <= angle M <= pi.
Proof.
by move=> MSO; rewrite acos_ge0 ?acos_lepi // tr_interval.
Qed.

(* NB: useful? *)
Lemma angle_Rx a :
  (   0 <= a <= pi -> angle (Rx a) = a) /\
  (- pi <= a <=  0 -> angle (Rx a) = - a).
Proof.
split => Ha; rewrite /angle mxtrace_Rx addrAC subrr add0r
  -(mulr_natr (cos a)) -mulrA divff  ?pnatr_eq0 // mulr1;
  by [rewrite cosK | rewrite cosKN].
Qed.

Lemma angle_RO M a : M = block_mx (1 : 'M_1) 0 0 (RO a) ->
  (   0 <= a <= pi -> angle M = a) /\
  (- pi <= a <=  0 -> angle M = - a).
Proof.
move=> Ma.
rewrite /angle Ma (mxtrace_block (1 : 'M_1)) tr_RO mxtrace1 addrAC.
rewrite subrr add0r -(mulr_natr (cos a)) -mulrA divrr ?unitfE ?pnatr_eq0 // mulr1.
split => Ha; by [rewrite cosK | rewrite cosKN].
Qed.

Lemma angle_eskew a u : norm u = 1 -> 0 <= a <= pi -> angle `e^(a, u) = a.
Proof.
move=> u1 Ha.
rewrite /angle trace_eskew // addrAC subrr add0r.
by rewrite mulrAC divrr ?mul1r ?unitfE // ?pnatr_eq0 // cosK.
Qed.

Lemma angle0_tr M : M \is 'SO[T]_3 -> angle M = 0 -> \tr M = 3%:R.
Proof.
move=> MSO /(congr1 (fun x => cos x)).
rewrite cos0 /angle acosK; last by apply tr_interval.
move/(congr1 (fun x => x * 2%:R)).
rewrite -mulrA mulVr ?unitfE ?pnatr_eq0 // mulr1 mul1r.
move/(congr1 (fun x => x + 1)).
rewrite subrK => ->; by rewrite (natrD _ 2 1).
Qed.

Lemma angle_pi_tr M : M \is 'SO[T]_3 -> angle M = pi -> \tr M = - 1.
Proof.
move=> MSO /(congr1 (fun x => cos x)).
rewrite cospi /angle acosK; last by apply tr_interval.
move/(congr1 (fun x => x * 2%:R)).
rewrite -mulrA mulVf ?pnatr_eq0 // mulr1.
move/(congr1 (fun x => x + 1)).
by rewrite subrK mulN1r mulr2n opprD subrK.
Qed.

Lemma SO_pi_reflection M : M \is 'SO[T]_3 -> angle M = pi ->
  let u := normalize (vaxis_euler M) in
  M = u^T *m u *+ 2 - 1.
Proof.
move=> MSO Mpi u.
have [a /andP[a_gtpi a_lepi] H] := SO_isRot MSO.
case: (leP 0 a) => [a_ge0|a_lt0].
  suff aE : a = pi.
    apply: isRot_pi_inv (vaxis_euler_neq0 MSO) _.
    by rewrite -aE.
  rewrite -Mpi.  
  apply: isRot_angle (vaxis_euler_neq0 MSO) _ H.
  by rewrite a_ge0 a_lepi.
suff aE : a = - pi.
  apply: isRot_pi_inv (vaxis_euler_neq0 MSO) _.
  have : isRot (- pi) (vaxis_euler M) (mx_lin1 M) by rewrite -aE.
  by rewrite /isRot /= cosN sinN cospi sinpi !oppr0.
rewrite -Mpi.  
apply: isRot_angleN (vaxis_euler_neq0 MSO) _ H.
by rewrite 2?ltW.
Qed.

Lemma SO_pi_axial M : M \is 'SO[T]_3 -> angle M = pi -> axial M = 0.
Proof.
move=> MSO.
move/SO_pi_reflection => /(_ MSO) ->.
apply/eqP; rewrite -axial_sym rpredD // ?rpredN ?sym_cst //.
by rewrite mulr2n rpredD // mul_tr_vec_sym.
Qed.

Lemma rotation_is_Rx M k (k0 : 0 < k) : M \is 'SO[T]_3 ->
  axial M = k *: 'e_0 ->
  0 <= angle M <= pi /\
  (M = Rx (- angle M) \/ M = Rx (angle M)).
Proof.
move=> MSO axialVi.
have [M02 M01] : M 0 2%:R = M 2%:R 0 /\ M 0 1 = M 1 0.
  move/matrixP/(_ 0 1) : (axialVi).
  rewrite !mxE /= mulr0 => /eqP; rewrite subr_eq add0r => /eqP ->.
  move/matrixP/(_ 0 2%:R) : (axialVi).
  by rewrite !mxE /= mulr0 => /eqP; rewrite subr_eq add0r => /eqP ->.
have axial_eigen : axial M *m M = axial M.
  move: (axial_vec_eigenspace MSO) => /eigenspaceP; by rewrite scale1r.
have [M010 [M020 M001]] : M 0 1 = 0 /\ M 0 2%:R = 0 /\ M 0 0 = 1.
  move: axial_eigen.
  rewrite axialVi -scalemxAl => /scalerI.
  rewrite gt_eqF // => /(_ isT) ViM.
  have : 'e_0 *m M = row 0 M by rewrite rowE.
  rewrite {}ViM => ViM.
  move/matrixP : (ViM) => /(_ 0 1); rewrite !mxE /= => <-.
  move/matrixP : (ViM) => /(_ 0 2%:R); rewrite !mxE /= => <-.
  by move/matrixP : (ViM) => /(_ 0 0); rewrite !mxE /= => <-.
have [P MP] : exists P : 'M[T]_2, M = block_mx (1 : 'M_1) 0 0 P.
  exists (@drsubmx _ 1 2 1 2 M).
  rewrite -{1}(@submxK _ 1 2 1 2 M).
  rewrite (_ : ulsubmx _ = 1); last first.
    apply/matrixP => i j.
    rewrite (ord1 i) (ord1 j) !mxE /= -M001 mulr1n; congr (M _ _); by apply val_inj.
  rewrite (_ : ursubmx _ = 0); last first.
    apply/rowP => i.
    case/boolP : (i == 0) => [|/ifnot01P]/eqP->;
      [ rewrite !mxE -[RHS]M010; congr (M _ _); exact: val_inj |
        rewrite !mxE -[RHS]M020; congr (M _ _); exact: val_inj ].
  rewrite (_ : dlsubmx _ = 0) //.
  apply/colP => i.
  case/boolP : (i == 0) => [|/ifnot01P]/eqP->;
    [ rewrite !mxE -[RHS]M010 M01; congr (M _ _); exact: val_inj |
      rewrite !mxE -[RHS]M020 M02; congr (M _ _); exact: val_inj ].
have PSO : P \is 'SO[T]_2 by have := MSO; rewrite MP (SOSn_SOn 1).
move=> [: Hangle].
split.
  abstract: Hangle.
  suff trB : -1 <= (\tr M - 1) / 2%:R <= 1 by rewrite ?(acos_ge0, acos_lepi).
  by apply: tr_interval.
case/rot2d : PSO => a /andP[a_geNpi a_lepi] PRO; rewrite {}PRO in MP.
have := (angle_RO MP).
case: (leP 0 a) => Ha /=; first by case=> -> // _; right; rewrite MP Rx_RO.
case => _ -> //; last by rewrite (ltW a_geNpi) ltW.
by left; rewrite opprK MP Rx_RO.
Qed.

End angle_of_angle_axis_representation.

Section axis_of_angle_axis_representation.

Variable T : realType.
Let vector := 'rV[T]_3.

Definition naxial a (M : 'M[T]_3) := ((sin a) *+ 2)^-1 *: axial M.

Lemma naxial_eskew a w : sin a != 0 -> naxial a `e^(a, w) = w.
Proof.
move=> sa.
by rewrite /naxial axial_eskew scalerA mulVr ?unitfE ?mulrn_eq0 // scale1r.
Qed.

Definition vaxis M : 'rV[T]_3 :=
  if angle M == pi then vaxis_euler M else naxial (angle M) M.

Lemma vaxis_neq0 (M : 'M[T]_3) : M \is 'SO[T]_3 ->
  angle M != 0 -> vaxis M != 0.
Proof.
move=> MSO a0.
case/boolP : (Aa.angle M == pi) => [/eqP api|api].
  by rewrite /vaxis api eqxx vaxis_euler_neq0.
case/boolP : (axial M == 0) => M0.
  rewrite -axial_sym in M0.
  case: (Aa.sym_angle MSO M0) => /eqP.
    by rewrite (negbTE a0).
  by rewrite (negbTE api).
rewrite /vaxis (negbTE api) scaler_eq0 negb_or M0 andbT invr_eq0 mulrn_eq0 /=.
suff : 0 < sin (angle M) by case: ltgtP.
apply: sin_gt0_pi.
rewrite !lt_neqAle api eq_sym a0 /=.
by rewrite ?(acos_ge0, acos_lepi) // tr_interval.
Qed.

Lemma vaxis_eskew a (w : vector) :
  sin a != 0 -> 0 <= a <= pi -> norm w = 1 -> vaxis `e^(a, w) = w.
Proof.
move=> sphi Ha w1; rewrite /vaxis angle_eskew //.
case: eqP => [aE|/eqP aD]; first by move: (sphi); rewrite aE sinpi eqxx.
by rewrite naxial_eskew.
Qed.

Lemma vaxis_ortho_of_iso (M : 'M[T]_3) (MSO : M \is 'SO[T]_3) :
  vaxis M *m M = vaxis M.
Proof.
rewrite /vaxis.
case: ifPn => [_|pi]; first by apply/eqP; rewrite vaxis_eulerP.
move/axial_vec_eigenspace : MSO => /eigenspaceP.
rewrite -scalemxAl => ->; by rewrite scale1r.
Qed.

Lemma isRot_axis (M : 'M[T]_3) u a : u != 0 -> sin a != 0 ->
  isRot a u (mx_lin1 M) -> normalize u = naxial a M.
Proof.
move=> u0 sina0 H.
suff -> : M = `e^(a, normalize u) by rewrite naxial_eskew.
apply: (@same_isRot _ _ _ _ _ 1 u0 _ a) => //.
by rewrite scale1r.
exact: (isRot_eskew_normalize _ u0).
Qed.

End axis_of_angle_axis_representation.
End Aa.

Section angle_axis_of_rot.

Variable T : realType.
Let vector := 'rV[T]_3.

Definition log_rot (M : 'M[T]_3) : T * 'rV[T]_3 := (Aa.angle M, Aa.vaxis M).

Lemma log_exp_eskew (a : T) (w : 'rV[T]_3) :
  sin a != 0 -> 0 <= a <= pi -> norm w = 1 -> log_rot `e^(a, w) = (a, w).
Proof.
move=> ? ? ?; congr pair; by [rewrite Aa.angle_eskew | rewrite Aa.vaxis_eskew].
Qed.

Lemma angle_vaxis_eskew M : M \is 'SO[T]_3 -> M = `e^(Aa.angle M, normalize (Aa.vaxis M)).
Proof.
move=> MSO; case/boolP : (axial M == 0) => [|M0].
  rewrite -axial_sym => M0'.
  case/(Aa.sym_angle MSO) : (M0') => [a0|api].
    rewrite a0 emx30M.
    move/(Aa.angle0_tr MSO): a0.
    move/O_tr_idmx => M1; by rewrite {1}M1 ?rotation_sub.
  move/(Aa.SO_pi_reflection MSO) : (api) => api'.
  by rewrite /Aa.vaxis api eqxx eskew_pi // norm_normalize // vaxis_euler_neq0.
case/boolP : (Aa.angle M == 0) => [/eqP H|a0].
  rewrite H.
  move/(Aa.angle0_tr MSO) : H.
  move/O_tr_idmx => ->; by rewrite ?rotation_sub // emx30M.
case/boolP : (Aa.angle M == pi) => [/eqP H|api].
  rewrite H eskew_pi ?norm_normalize // /Aa.vaxis H eqxx ?vaxis_euler_neq0 //.
  exact: Aa.SO_pi_reflection.
(* 
have sina0 : sin (Aa.angle M) != 0.
  apply: contra a0 => /eqP/sin0_inv [->//|/eqP]; by rewrite (negbTE api).
*)
set w : 'rV_3 := normalize _.
have [a /andP[a_gtNpi a_lepi] Rota] := SO_isRot MSO.
have {}Rota : isRot a (normalize (vaxis_euler M)) (mx_lin1 M).
  rewrite (isRotZ a _ (vaxis_euler_neq0 MSO)) //.
  by rewrite invr_gt0 norm_gt0 vaxis_euler_neq0.
have w0 : normalize (vaxis_euler M) != 0 by rewrite normalize_eq0 vaxis_euler_neq0.
have w1 : norm w = 1 by rewrite norm_normalize // Aa.vaxis_neq0.
case: (leP 0 a) => Ha.
- have aB1 : 0 <= a <= pi by rewrite Ha a_lepi.
  move: (Aa.isRot_angle w0 aB1 Rota) => a_angle_of_rot.
  have sina0 : sin a != 0.
    suff : 0 < sin a by case: ltgtP.
    apply: sin_gt0_pi.
    by rewrite !lt_neqAle Ha a_lepi eq_sym a_angle_of_rot a0 api.
  move: (Aa.isRot_axis w0 sina0 Rota) => w'axial.
  rewrite /Aa.naxial in w'axial.
  set k := (_^-1) in w'axial.
  have k0 : 0 < k.
    rewrite /k invr_gt0 pmulrn_lgt0 // lt_neqAle eq_sym sina0 /=.
    by apply: sin_ge0_pi.
  have Hn : normalize (vaxis_euler M) = 
            ((sin a *+ 2) * k) *: (norm (Aa.vaxis M) *: w).
    rewrite -(norm_scale_normalize (normalize (vaxis_euler M))).
    rewrite norm_normalize ?vaxis_euler_neq0 // w'axial.
    rewrite scale1r {2}/k divff ?mulrn_eq0 // scale1r.
    by rewrite /w norm_scale_normalize /Aa.vaxis (negbTE api) -a_angle_of_rot.
  apply: (same_isRot w0 _ Hn Rota).
    rewrite pmulr_rgt0 // pmulrn_lgt0 // lt_neqAle eq_sym sina0.
    by rewrite  sin_ge0_pi.
  rewrite -a_angle_of_rot isRot_eskew //.
  rewrite normalizeZ ?normalizeI // -?norm_eq0 ?w1 ?oner_neq0 //.
  by rewrite norm_gt0 ?Aa.vaxis_neq0.
have aB1 : - pi <= a <= 0 by rewrite (ltW a_gtNpi) ltW.
move: (Aa.isRot_angleN w0 aB1 Rota) => a_angle_of_rot.
  have : M \in unitmx by rewrite orthogonal_unit // rotation_sub // -rotationV.
  move/(@isRot_tr _ _ (Aa.angle M^T) w0 M).
  rewrite {1}Aa.tr_angle -a_angle_of_rot => /(_ Rota).
  rewrite (rotation_inv MSO) Aa.tr_angle.
  move/(Aa.isRot_axis w0 _) => w'axial.
  have sina0 : sin a != 0.
    suff : 0 < sin (- a) by rewrite sinN oppr_cp0; case: ltgtP.
    by apply: sin_gt0_pi; rewrite oppr_cp0 andbC Ha ltr_oppl a_gtNpi.
rewrite /Aa.naxial in w'axial.
set k := (_ ^-1 ) in w'axial.
have sa_gt0 : 0 < sin (Aa.angle M).
  rewrite -oppr_cp0 -sinN -a_angle_of_rot.
  by rewrite -oppr_gt0 -sinN sin_gt0_pi // oppr_cp0 Ha ltr_oppl.
have se_neq0 : sin (Aa.angle M) != 0 by case: ltgtP sa_gt0.
have k0 : 0 < k by rewrite /k invr_gt0 pmulrn_lgt0. 
apply: (@same_isRot _ _ _ _ (- norm (Aa.vaxis M) *: w) ((sin (Aa.angle M) *+ 2) * k) w0 _ (- Aa.angle M)).
- by rewrite pmulr_rgt0 // pmulrn_lgt0.
- rewrite -(norm_scale_normalize (normalize (vaxis_euler M))) //.
  rewrite norm_normalize ?vaxis_euler_neq0 // w'axial //.
  rewrite scale1r {2}/k divff ?mulrn_eq0 //.
  rewrite scale1r /w scaleNr norm_scale_normalize /Aa.vaxis (negbTE api).
  by rewrite tr_axial scalerN.
- by rewrite -a_angle_of_rot //.
rewrite isRotZN; first by rewrite opprK isRot_eskew // normalizeI.
  by rewrite -norm_eq0 w1 oner_neq0.
by rewrite oppr_lt0 norm_gt0 // Aa.vaxis_neq0.
Qed.

Lemma angle_axis_isRot (Q : 'M[T]_3) : axial Q != 0 ->
  Q \is 'SO[T]_3 ->
  isRot (Aa.angle Q) (normalize (Aa.vaxis Q)) (mx_lin1 Q).
Proof.
move=> Q0 QSO.
move/angle_vaxis_eskew : (QSO) => H.
case/boolP : (Aa.angle Q == 0) => [|a0].
  move/eqP/(Aa.angle0_tr QSO).
  move/(O_tr_idmx (rotation_sub QSO)) => Q1; subst Q.
  rewrite Aa.angle1; by apply isRot1.
have aB: 0 <= Aa.angle Q <= pi.
  by rewrite ?(acos_ge0, acos_lepi) //; apply: rot.Aa.tr_interval.
case/boolP : (Aa.angle Q == pi) => [api|api].
  move/eqP/(Aa.SO_pi_reflection QSO) : (api) => HQ.
  rewrite /Aa.vaxis api (eqP api) {2}HQ.
  apply isRotpi; by rewrite norm_normalize // vaxis_euler_neq0.
have aB1: 0 < Aa.angle Q < pi by rewrite !lt_neqAle eq_sym a0 api.
move=> [:vaxis0].
rewrite {3}H isRotZ; last 2 first.
  abstract: vaxis0.
  rewrite /Aa.vaxis (negbTE api) scaler_eq0 negb_or Q0 andbT.
  rewrite invr_eq0 mulrn_eq0 /=.
    suff : 0 < sin (Aa.angle Q) by case: ltgtP.
    by apply: sin_gt0_pi.
  by rewrite invr_gt0 norm_gt0.
exact: isRot_eskew_normalize.
Qed.

End angle_axis_of_rot.

Section angle_axis_representation.

Variable T : realType.
Let vector := 'rV[T]_3.

Record angle_axis := AngleAxis {
  angle_axis_val : T * vector ;
  _ : norm (angle_axis_val.2) == 1 }.

HB.instance Definition _ := [isSub for angle_axis_val].
(*Canonical angle_axis_subType := [subType for angle_axis_val].*)

Definition aangle (a : angle_axis) := (val a).1.
Definition aaxis (a : angle_axis) := (val a).2.

Lemma norm_axis a : norm (aaxis a) = 1.
Proof. by case: a => *; apply/eqP. Qed.

Fact norm_e1_subproof : norm (@delta_mx T _ 3 0 0) == 1.
Proof. by rewrite norm_delta_mx. Qed.

Definition angle_axis_of (a : T) (v : vector) :=
  insubd (@AngleAxis (a,_) norm_e1_subproof) (a, normalize v).

Lemma aaxis_of (a : T) (v : vector) : v != 0 ->
  aaxis (angle_axis_of a v) = normalize v.
Proof.
move=> v_neq0 /=; rewrite /angle_axis_of /aaxis val_insubd /=.
by rewrite normZ normfV normr_norm mulVf ?norm_eq0 // eqxx.
Qed.

Lemma aangle_of (a : T) (v : vector) : aangle (angle_axis_of a v) = a.
Proof. by rewrite /angle_axis_of /aangle val_insubd /= fun_if if_same. Qed.

(*Coercion exp_skew_of_angle_axis r :=
  let (a, w) := (aangle r, aaxis r) in `e^(a, w).*)

Definition angle_axis_of_rot M := angle_axis_of (Aa.angle M) (Aa.vaxis M).

Lemma angle_axis_eskew_old M : M \is 'SO[T]_3 ->
  Aa.vaxis M != 0 ->
  let a := aangle (angle_axis_of_rot M) in
  let w := aaxis (angle_axis_of_rot M) in
  M = `e^(a, w).
Proof.
move=> MSO M0 a w.
rewrite (angle_vaxis_eskew MSO) /a aangle_of; congr (`e^(_, _)).
by rewrite /w /angle_axis_of_rot /= aaxis_of.
Qed.

End angle_axis_representation.

(* NB: work in progress *)
Section properties_of_orthogonal_matrices.

Variables (T : rcfType) (M : 'M[T]_3).
Hypothesis MO : M \is 'O[T]_3.

Lemma sqr_Mi0E i : M i 1 ^+ 2 + M i 2%:R ^+ 2 = 1 - M i 0 ^+ 2.
Proof.
move/norm_row_of_O : MO => /(_ i)/(congr1 (fun x => x ^+ 2)).
rewrite -dotmulvv dotmulE sum3E !mxE -!expr2 expr1n => /eqP.
by rewrite -addrA addrC eq_sym -subr_eq => /eqP <-.
Qed.

Lemma sqr_Mi1E i : M i 0 ^+ 2 + M i 2%:R ^+ 2 = 1 - M i 1 ^+ 2.
Proof.
move/norm_row_of_O : MO => /(_ i)/(congr1 (fun x => x ^+ 2)).
rewrite -dotmulvv dotmulE sum3E !mxE -!expr2 expr1n => /eqP.
by rewrite addrAC eq_sym -subr_eq => /eqP <-.
Qed.

Lemma sqr_Mi2E i : M i 0 ^+ 2 + M i 1 ^+ 2 = 1 - M i 2%:R ^+ 2.
Proof.
move/norm_row_of_O : MO => /(_ i)/(congr1 (fun x => x ^+ 2)).
rewrite -dotmulvv dotmulE sum3E !mxE -!expr2 expr1n => /eqP.
by rewrite eq_sym -subr_eq => /eqP <-.
Qed.

Lemma sqr_M2jE j : M 0 j ^+ 2 + M 1 j ^+ 2 = 1 - M 2%:R j ^+ 2.
Proof.
move/norm_col_of_O : MO => /(_ j)/(congr1 (fun x => x ^+ 2)).
rewrite -dotmulvv dotmulE sum3E !mxE -!expr2 expr1n => /eqP.
by rewrite eq_sym -subr_eq => /eqP <-.
Qed.

Lemma sqr_M0jE j : M 1 j ^+ 2 + M 2%:R j ^+ 2 = 1 - M 0 j ^+ 2.
Proof.
move/norm_col_of_O : MO => /(_ j)/(congr1 (fun x => x ^+ 2)).
rewrite -dotmulvv dotmulE sum3E !mxE -!expr2 expr1n => /eqP.
by rewrite -addrA addrC eq_sym -subr_eq => /eqP <-.
Qed.

Lemma Mi2_1 i : (`| M i 2%:R | == 1) = (M i 0 == 0) && (M i 1 == 0).
Proof.
move/eqP: (sqr_Mi2E i) => MO'.
apply/idP/idP => [Mi2|/andP[/eqP Mi0 /eqP Mi1]]; last first.
  move: MO'; by rewrite Mi0 Mi1 expr2 mulr0 addr0 eq_sym subr_eq add0r eq_sym sqr_norm_eq1.
move: MO'; rewrite -(sqr_normr (M i 2%:R)) (eqP Mi2) expr1n subrr.
by rewrite paddr_eq0 ?sqr_ge0 // => /andP[]; rewrite 2!sqrf_eq0 => /eqP -> /eqP ->; rewrite eqxx.
Qed.

Lemma M0j_1 j : (`| M 0 j | == 1) = (M 1 j == 0) && (M 2%:R j == 0).
Proof.
move/eqP: (sqr_M2jE j) => MO'.
apply/idP/idP => [M0j|/andP[/eqP Mi0 /eqP Mi1]]; last first.
  by move: MO'; rewrite Mi0 Mi1 expr0n addr0 subr0 sqr_norm_eq1.
move: MO'; rewrite -(sqr_normr (M 0 j)) (eqP M0j) expr1n.
rewrite -subr_eq opprK -addrA addrC eq_sym -subr_eq subrr eq_sym.
by rewrite paddr_eq0 ?sqr_ge0 // 2!sqrf_eq0.
Qed.

Lemma M1j_1 j : (`| M 1 j | == 1) = (M 0 j == 0) && (M 2%:R j == 0).
Proof.
move/eqP: (sqr_M2jE j) => MO'.
apply/idP/idP => [M0j|/andP[/eqP Mi0 /eqP Mi1]]; last first.
  by move: MO'; rewrite Mi0 Mi1 expr0n add0r subr0 sqr_norm_eq1.
move: MO'; rewrite -(sqr_normr (M 1 j)) (eqP M0j) expr1n.
rewrite eq_sym -subr_eq addrAC subrr add0r eq_sym -subr_eq0 opprK.
by rewrite paddr_eq0 ?sqr_ge0 // 2!sqrf_eq0.
Qed.

Lemma M2j_1 j :(`| M 2%:R j | == 1) = (M 0 j == 0) && (M 1 j == 0).
Proof.
move/eqP: (sqr_M2jE j) => MO'.
apply/idP/idP => [Mi2|/andP[/eqP Mi0 /eqP Mi1]]; last first.
  move: MO'; by rewrite Mi0 Mi1 expr2 mulr0 addr0 eq_sym subr_eq add0r eq_sym sqr_norm_eq1.
move: MO'; rewrite -(sqr_normr (M 2%:R j)) (eqP Mi2) expr1n subrr.
by rewrite paddr_eq0 ?sqr_ge0 // => /andP[]; rewrite 2!sqrf_eq0 => /eqP -> /eqP ->; rewrite eqxx.
Qed.

End properties_of_orthogonal_matrices.

(* wip *)
Section euler_angles_existence.
Variable T : realType.
Implicit Types R : 'M[T]_3.
Local Open Scope frame_scope.

(* two orthogonal vectors belonging to the plan (y,z) projected on y and z *)
Lemma exists_rotation_angle (F : frame T) (u v : 'rV[T]_3) :
  norm u = 1 -> norm v = 1 -> u *d v = 0 -> u *v v = F|,0 ->
  { w : T | [/\ - pi < w <= pi,
            u = cos w *: (F|,1) + sin w *: (F|,2%:R) &
            v = - sin w *: (F|,1) + cos w *: (F|,2%:R)] }.
Proof.
move=> normu normv u_perp_v uva0.
have u0 : u *d F|,0 = 0 by rewrite -uva0 dot_crossmulC (@liexx _ (vec3 T)) dotmul0v.
have v0 : v *d F|,0 = 0 by rewrite -uva0 dot_crossmulCA (@liexx _ (vec3 T)) dotmulv0.
case/boolP : (u *d F|,2%:R == 0) => [/eqP|] u2.
  suff [[? ?]|[? ?]] : {u = F|,1 /\ v = F|,2%:R} +
                       {u = - F|,1 /\ v = - F|,2%:R}.
  - exists 0.
    rewrite sin0 cos0 !(scale1r,oppr0,scale0r,addr0,add0r); split=> //.
    by rewrite oppr_cp0 !(pi_gt0, pi_ge0).
  - exists pi.
    rewrite sinpi cospi !(scaleN1r,scale0r,oppr0,add0r,addr0); split => //.
    by rewrite lexx (lt_trans _ (pi_gt0 _)) // oppr_cp0 pi_gt0.
  have v1 : v *d F|,1 = 0.
    move/eqP: (frame_icrossk F); rewrite -eqr_oppLR => /eqP <-.
    rewrite dotmulvN -uva0 (@lieC _ (vec3 T)) /= dotmulvN opprK double_crossmul.
    rewrite dotmulDr dotmulvN (dotmulC _ u) u2 scale0r dotmulv0 subr0.
    by rewrite dotmulvZ (dotmulC v) u_perp_v mulr0.
  rewrite (orthogonal_expansion F u) (orthogonal_expansion F v).
  rewrite u2 u0 v0 v1 !(scale0r,addr0,add0r).
  have [/eqP u1 | /eqP u1] : {u *d F |, 1 == 1} + {u *d F|,1 == -1}.
    move: normu => /(congr1 (fun x => x ^+ 2)); rewrite (sqr_norm_frame F u).
    rewrite sum3E u0 u2 expr0n add0r addr0 expr1n => /eqP.
    by rewrite sqrf_eq1 => /Bool.orb_true_elim.
  - have v2 : v *d F|,2%:R = 1.
      move: uva0.
      rewrite {1}(orthogonal_expansion F u) u0 u1 u2 !(scale0r,add0r,scale1r,addr0).
      rewrite {1}(orthogonal_expansion F v) v0 v1 !(scale0r,add0r) linearZr_LR /=.
      rewrite (frame_jcrossk F) => /scaler_eq1; apply.
      by rewrite -norm_eq0 noframe_norm oner_eq0.
    rewrite v2 u1 !scale1r; by left.
  - have v2 : v *d F|,2%:R = -1.
      move: uva0.
      rewrite {1}(orthogonal_expansion F u) u0 u1 u2 !(scale0r,add0r,scale1r,addr0,scaleN1r).
      rewrite {1}(orthogonal_expansion F v) v0 v1 !(scale0r,add0r,scale1r,addr0,scaleN1r).
      rewrite linearNl linearZr_LR /= (frame_jcrossk F) -scaleNr => /scaler_eqN1; apply.
      by rewrite -norm_eq0 noframe_norm oner_eq0.
    rewrite v2 u1 !scaleN1r; by right.
have pi2B : - pi < (pi : T) / 2%:R <= pi.
  rewrite lter_pdivl_mulr ?ltr0n // ler_pdivrMr ?ltr0n //.
  rewrite -subr_gte0 mulNr opprK addr_gt0 ? pi_gt0 //.
    by rewrite -subr_gte0 mulr_natr mulr2n addrK pi_ge0.
  by rewrite mulr_natr mulr2n addr_gt0 // pi_gt0.
have piN2B : - pi < - ((pi : T) / 2%:R) <= pi.
  rewrite ltr_oppl opprK lter_pdivr_mulr ?ltr0n // lerNl.
  rewrite ler_pdivlMr ?ltr0n // -subr_gte0 mulNr opprK.
  rewrite mulr_natr mulr2n addr_ge0 ?pi_ge0 //.
    by rewrite -subr_gte0 addrK pi_gt0.
  by rewrite addr_ge0 ?pi_ge0.
case/boolP : (u *d F|,1 == 0) => [/eqP|] u1.
  have {u2}[/eqP u2|/eqP u2] : {u *d F|,2%:R == 1} + {u *d F|,2%:R == -1}.
    move: normu => /(congr1 (fun x => x ^+ 2)).
    rewrite (sqr_norm_frame F u) sum3E u0 u1 expr0n !add0r expr1n => /eqP.
    by rewrite sqrf_eq1 => /Bool.orb_true_elim.
  + have v1 : v *d F|,1%:R = -1.
      move: uva0.
      rewrite {1}(orthogonal_expansion F u) u0 u1 u2 !(scale0r,add0r,scale1r,scaleN1r).
      rewrite {1}(orthogonal_expansion F v) v0 !(scale0r,add0r,scale1r,addr0).
      rewrite linearDr /= linearZr_LR /= (@lieC _ (vec3 T)) /= (frame_jcrossk F).
      rewrite linearZr_LR /= (@liexx _ (vec3 T)) scaler0 addr0 scalerN -scaleNr => /scaler_eqN1; apply.
      by rewrite -norm_eq0 noframe_norm oner_eq0.
    have v2 : v *d F|,2%:R = 0.
      move: normv => /(congr1 (fun x => x ^+ 2)).
      rewrite expr1n (sqr_norm_frame F) sum3E v1 v0 expr0n add0r sqrrN expr1n => /eqP.
      by rewrite eq_sym addrC -subr_eq subrr eq_sym sqrf_eq0 => /eqP.
    exists (pi / 2%:R).
    rewrite cos_pihalf sin_pihalf !(scale0r,add0r,scale1r,scaleN1r,addr0).
    rewrite (orthogonal_expansion F u) (orthogonal_expansion F v).
    by rewrite u1 u0 u2 v1 v0 v2 !(scale0r,addr0,add0r,scale1r,scaleN1r).
  + have v1 : v *d F|,1 = 1.
      move: uva0.
      rewrite {1}(orthogonal_expansion F u) u0 u1 u2 !(scale0r,add0r,scaleN1r).
      rewrite {1}(orthogonal_expansion F v) v0 !(scale0r,add0r,scaleN1r).
      rewrite linearDr 2!linearNl 2!linearZr_LR /= (@liexx _ (vec3 T)) scaler0 subr0.
      rewrite -scalerN (@lieC _ (vec3 T)) /= opprK (frame_jcrossk F) => /scaler_eq1; apply.
      by rewrite -norm_eq0 noframe_norm oner_eq0.
    have v2 : v *d F|,2%:R = 0.
      move: normv => /(congr1 (fun x => x ^+ 2)).
      rewrite expr1n (sqr_norm_frame F) sum3E v1 v0 expr0n add0r expr1n => /eqP.
      by rewrite eq_sym addrC -subr_eq subrr eq_sym sqrf_eq0 => /eqP.
    exists (- (pi / 2%:R)).
    rewrite cosN sinN cos_pihalf sin_pihalf ?(scale0r,add0r,scale1r,scaleN1r,addr0,opprK).
    rewrite (orthogonal_expansion F u) (orthogonal_expansion F v).
    by rewrite u1 u0 u2 v1 v0 v2 !(scale0r,addr0,add0r,scale1r,scaleN1r).
move: (orthogonal_expansion F u).
rewrite -{1}uva0 dot_crossmulC (@liexx _ (vec3 T)) dotmul0v scale0r add0r => Hr2.
move: (orthogonal_expansion F v).
rewrite -{1}uva0 (@lieC _ (vec3 T)) dotmulvN dot_crossmulC (@liexx _ (vec3 T)) dotmul0v oppr0 scale0r add0r => Hr3.
have f1D0 : F|,1 != 0 by apply: contra u1 => /eqP->; rewrite dotmulv0.
have f2D0 : F|,2%:R != 0 by apply: contra u2 => /eqP->; rewrite dotmulv0.
have [w [wB Hw1 Hw2]] :
  {w : T | [/\ - pi < w <= pi, u *d F|,1 = cos w & (u *d F|,2%:R) = sin w]}.
  apply: sqrD1_cossin.
  move/(congr1 (fun x => norm x)) : Hr2.
  rewrite normu.
  move/(congr1 (fun x => x ^+ 2)).
  rewrite expr1n normD !normZ ?noframe_norm !mulr1.
  rewrite (_ : cos _ = 0); last first.
    case: (lerP 0 (u *d F|,2%:R)).
      rewrite le_eqVlt eq_sym (negbTE u2) /= => {}u2.
      case: (lerP 0 (u *d F|,1)).
        rewrite le_eqVlt eq_sym (negbTE u1) /= => {}u1.
        rewrite vec_anglevZ; last by [].
        rewrite vec_angleZv; last by [].
        rewrite /vec_angle /= noframe_jdotk mul0r acos0.
        by rewrite (negPf f1D0) (negPf f2D0) cos_pihalf.
      move=> {}u1.
        rewrite vec_angleZNv; last by [].
        rewrite vec_anglevZ; last by [].
        rewrite cos_vec_angleNv //.
        rewrite /vec_angle noframe_jdotk mul0r acos0.
        by rewrite (negPf f1D0) (negPf f2D0) cos_pihalf oppr0.
      move=> {}u2.
      case: (lerP 0 (u *d F|,1)).
        rewrite le_eqVlt eq_sym (negbTE u1) /= => {}u1.
        rewrite vec_angleZv; last by [].
        rewrite vec_anglevZN; last by [].
        rewrite cos_vec_anglevN //.
        rewrite /vec_angle noframe_jdotk mul0r acos0.
        by rewrite (negPf f1D0) (negPf f2D0) cos_pihalf oppr0.
      move=> {}u1.
      rewrite vec_anglevZN; last by [].
      rewrite vec_angleZNv; last by [].
      rewrite cos_vec_angleNv ?oppr_eq0 // cos_vec_anglevN //.
      rewrite opprK /vec_angle noframe_jdotk mul0r acos0.
      by rewrite (negPf f1D0) (negPf f2D0) cos_pihalf.
  by rewrite mulr0 mul0rn addr0 !sqr_normr.
have uRv : u *m `e^(pi / 2%:R, F|,0) = v.
  rewrite -rodriguesP /rodrigues noframe_norm ?expr1n scale1r cos_pihalf subr0.
  rewrite scale1r mul1r sin_pihalf scale1r subrr add0r -uva0 dot_crossmulC.
  rewrite (@liexx _ (vec3 T)) dotmul0v scale0r add0r (@lieC _ (vec3 T)) /= double_crossmul dotmulvv.
  by rewrite normu expr1n scale1r opprB u_perp_v scale0r subr0.
have RO : `e^(pi / 2%:R, F|,0) \in 'O[T]_3 by apply eskew_is_O; rewrite noframe_norm.
have H' : vec_angle u F|,2%:R = vec_angle v (- F|,1).
  move/orth_preserves_vec_angle : RO => /(_ u F|,2%:R) <-.
  rewrite uRv; congr (vec_angle v _).
  rewrite -rodriguesP /rodrigues noframe_norm ?expr1n scale1r cos_pihalf subr0.
  rewrite scale1r mul1r sin_pihalf scale1r subrr add0r.
  by rewrite dotmulC noframe_idotk scale0r add0r frame_icrossk.
have H : vec_angle u (F |, 1) = vec_angle v (F|,2%:R).
  move/orth_preserves_vec_angle : RO => /(_ u F|,1) <-.
  rewrite uRv; congr (vec_angle v _).
  rewrite -rodriguesP /rodrigues noframe_norm ?expr1n scale1r cos_pihalf subr0.
  rewrite scale1r mul1r sin_pihalf scale1r subrr add0r.
  by rewrite dotmulC noframe_idotj scale0r add0r frame_icrossj.
exists w; rewrite -{1}Hw1 -{1}Hw2; split => //.
have <- : v *d F|,1 = - sin w.
  rewrite -Hw2 2!dotmul_cos normu 2!noframe_norm mul1r normv mulr1.
  rewrite [in LHS]mul1r [in RHS]mul1r ?opprK H'.
  rewrite [in RHS]cos_vec_anglevN ?opprK; [by [] | | ].
  by rewrite -norm_eq0 normv oner_neq0.
  by rewrite -norm_eq0 noframe_norm oner_neq0.
have <- : v *d F|,2%:R = cos w.
  by rewrite -Hw1 2!dotmul_cos normu 2!noframe_norm mul1r normv mulr1 H.
by [].
Qed.

Lemma euler_angles_zyx_RO (a1 a2 u v : 'rV[T]_3) w1 k k' :
  norm u = 1 -> norm v = 1 -> u *d v = 0 ->
  norm a1 = 1 -> norm a2 = 1 -> a1 *d a2 = 0 ->
  u = k *: a1 + k' *: a2 ->
  v = - k' *: a1 + k *: a2 ->
  cos w1 = a1 *d u ->
  sin w1 = - a2 *d u ->
  row_mx u^T v^T = row_mx a1^T a2^T *m RO w1.
Proof.
move=> u1 v1 uv a1_1 a2_1 a1a2 Hu Hv Hcos Hsin.
move: uv.
rewrite {1}Hu {1}Hv.
rewrite dotmulDr 2!dotmulDl !(dotmulZv,dotmulvZ) (dotmulC a2 a1) a1a2.
rewrite !(mulr0,addr0,add0r) 2!dotmulvv a1_1 a2_1 expr1n 2!mulr1.
move=> kk'.
move: Hsin; rewrite {1}Hu dotmulDr !(dotmulZv,dotmulvZ) !dotmulNv dotmulC a1a2.
rewrite oppr0 mulr0 add0r mulrN dotmulvv a2_1 expr1n mulr1 => Hsin.
move: Hcos; rewrite {1}Hu dotmulDr !(dotmulZv,dotmulvZ) dotmulvv.
rewrite a1_1 expr1n mulr1 a1a2 mulr0 addr0 => Hcos.
move/eqP : Hsin; rewrite -eqr_oppLR => /eqP Hsin.
subst k k'.
move: u1 => /(congr1 (fun x => x^+2)).
rewrite {1}Hu.
rewrite -dotmulvv dotmulDr 2!dotmulDl !dotmulZv!dotmulvZ !dotmulvv a1_1 a2_1 !expr1n mulr1.
rewrite a1a2 !mulr0 add0r mulr1 dotmulC a1a2 !mulr0 addr0 => u_1.
move: v1 => /(congr1 (fun x => x^+2)).
rewrite {1}Hv.
rewrite -dotmulvv dotmulDr 2!dotmulDl !dotmulZv!dotmulvZ !dotmulvv a1_1 a2_1 !expr1n mulr1.
rewrite a1a2 !mulr0 add0r mulr1 dotmulC a1a2 !mulr0 addr0 => v_1.
rewrite -2!expr2 in v_1.
case/sqrD1_cossin : v_1 => w1' [w1'B Hcos Hsin].
rewrite opprK in Hcos.
move: kk'.
rewrite opprK mulNr => _.
by rewrite Hu Hv mul_col_mx2 !mxE /= !linearD /= !linearZ /= !mul_mx_scalar opprK.
Qed.

Lemma euler_zyx_angles R : R \is 'SO[T]_3 ->
  let w2 := asin (R 2%:R 0) in
  0 < cos w2 ->
  forall w3 w1,
    cos w3 = R 0 0 * (cos w2)^-1 ->
    sin w3 = - R 1%:R 0 * (cos w2)^-1 ->
    cos w1 = (col 1 (Rzy w3 w2))^T *d (col 1 R)^T ->
    sin w1 = - (col 2%:R (Rzy w3 w2))^T *d (col 1 R)^T ->
    R = Rz w3 * Ry w2 * Rx w1.
Proof.
move=> RSO w2 cos_w2_ge0 w3 w1 Hw3 Kw3 Hw1 Kw1.
rewrite RzyE.
set A := Rzy _ _.
set a1 := col 0 A. set a2 := col 1 A. set a3 := col 2%:R A.
have Ha1 : a1 = col 0 R.
  apply/matrixP => a b.
  rewrite !mxE /=.
  case: ifPn => [/eqP ->{a}|A0].
    by rewrite !mxE /= Hw3 -mulrA mulVr ?mulr1 // unitfE gt_eqF.
  case: ifPn => [/eqP ->|A1].
    by rewrite !mxE /= Kw3 !mulNr opprK -mulrA mulVr ?mulr1 // unitfE gt_eqF.
  rewrite -(negbK (a == 2%:R)) ifnot2 negb_or A0 A1 /= !mxE /= /w2 asinK.
    suff /eqP -> : a == 2%:R by [].
    by apply/negPn; rewrite ifnot2 negb_or A0.
  by rewrite in_itv/= -ler_norml Oij_ub // rotation_sub.
have Hw2 : sin w2 = R 2%:R 0.
  move/(congr1 (fun v : 'cV_3 => v 2%:R 0)) : Ha1; by rewrite !mxE.
rewrite -(row_mx_colE R).
transitivity (row_mx (col 0 R) (row_mx a2 a3) *m Rx w1).
  rewrite Rx_RO.
  rewrite (mul_row_block _ _ 1) mulmx0 addr0 mulmx1 mulmx0 add0r.
  congr (row_mx (col 0 R)).
  rewrite (_ : col 1 R = (row 1 R^T)^T); last by rewrite ?tr_row ?trmxK.
  rewrite (_ : col 2%:R R = (row 2%:R R^T)^T); last by rewrite ?tr_row ?trmxK.
  rewrite -(trmxK a2).
  rewrite -(trmxK a3).
  have [k [k' [Hr2 Hr3]]] : exists k k',
    col 1 R = k *: a2 + k' *: a3 /\ col 2%:R R = - k' *: a2 + k *: a3.
    set r2 := col 1 R.
    set r3 := col 2%:R R.
    have ATSO : A^T \is 'SO[T]_3 by rewrite rotationV Rzy_is_SO.
    set a := frame_of_SO ATSO.
    have a1E : a |, 1 = a2^T by rewrite frame_of_SO_j /a2 tr_col.
    have a2E : a |, 2%:R = a3^T by rewrite frame_of_SO_k /a3 tr_col.
    have : { w : T |
             [/\ - pi < w <= pi,
                 r2^T = cos w *: (a |, 1) + sin w *: (a |, 2%:R) &
                 r3^T = - sin w *: (a |, 1) + cos w *: (a |, 2%:R)] }.
      apply: exists_rotation_angle.
      by rewrite tr_col norm_row_of_O // rotation_sub // rotationV.
      by rewrite tr_col norm_row_of_O // rotation_sub // rotationV.
      rewrite 2!tr_col.
      by move: RSO; rewrite -rotationV => /rotation_sub/orthogonalP ->.
      rewrite frame_of_SO_i -tr_col -/a1 Ha1 !tr_col.
      move: RSO; rewrite -rotationV => RSO.
      set r := frame_of_SO RSO.
      rewrite -(frame_of_SO_i RSO) -(frame_of_SO_j RSO) -(frame_of_SO_k RSO).
      by rewrite frame_jcrossk.
    case => w [wB Lw1 Lw2].
    exists (cos w), (sin w).
    split.
      apply trmx_inj.
      by rewrite !linearD !linearZ /= Lw1 a1E a2E.
    apply trmx_inj.
    by rewrite !linearD !linearZ /= -a2E -a1E.
  move/(congr1 trmx) : Hr2.
  rewrite tr_col linearD /= 2!linearZ /= => Hr2.
  move/(congr1 trmx) : Hr3.
  rewrite tr_col linearD /= 2!linearZ /= => Hr3.
  apply: (euler_angles_zyx_RO _ _ _ _ _ _ Hr2 Hr3).
  by move: RSO; rewrite -rotationV => /rotation_sub/orthogonal3P/and6P[_ /eqP].
  by move: RSO; rewrite -rotationV => /rotation_sub/orthogonal3P/and6P[_ _ /eqP].
  move: RSO; by rewrite -rotationV => /rotation_sub/orthogonal3P/and6P[_ _ _ _ _ /eqP].
  by rewrite tr_col norm_row_of_O // rotation_sub // rotationV Rzy_is_SO.
  by rewrite tr_col norm_row_of_O // rotation_sub // rotationV Rzy_is_SO.
  move: (Rzy_is_SO w3 w2).
  rewrite -rotationV => /rotation_sub/orthogonal3P/and6P[_ _ _ _ _ /eqP].
  by rewrite !tr_col.
  move: Hw1; by rewrite 2!tr_col.
  move: Kw1; by rewrite 2!tr_col.
by rewrite -Ha1 row_mx_colE.
Qed.

Lemma Rz_rotation_exists (u : 'rV[T]_3) : norm u = 1 ->
  u != 'e_2%:R -> u != - 'e_2%:R ->
  let n : 'rV_3 := normalize ('e_2%:R *v u) in
  {phi | isRot phi 'e_2%:R (mx_lin1 (Rz phi)) & 'e_0 *m Rz phi = n}.
Proof.
move=> u1 H1 H2 n.
exists (if 0 <= u``_0 then vec_angle n 'e_0 else - vec_angle n 'e_0).
  by rewrite Rz_eskew isRot_eskew // ?normalizeI // ?norm_delta_mx.
rewrite {1}e0row /Rz mulmx_row3_col3 ?(scale0r,scale1r,addr0).
rewrite [in RHS]/n crossmulE.
rewrite (_ : 'e_2%:R 0 1 = 0) ?(mul0r,add0r); last by rewrite mxE.
rewrite (_ : 'e_2%:R 0 0 = 0) ?(mul0r,subrr,subr0); last by rewrite mxE.
rewrite (_ : 'e_2%:R 0 2%:R = 1) ?mul1r; last by rewrite mxE.
have ? : 'e_2%:R *v u != 0.
  apply/colinearP; case.
    by rewrite -norm_eq0 u1 // oner_eq0.
  case=> _ [k Hk]; have k1 : `|k| = 1.
    move: Hk => /(congr1 (@norm _ _)); rewrite normZ u1 mulr1 norm_delta_mx.
    by move->.
  case: (lerP k 0) => k0; move: k1 Hk.
    rewrite ler0_norm // -{2}(opprK k) => ->; rewrite scaleN1r.
    by move/(congr1 (fun x => - x)); rewrite opprK => /esym; apply/eqP.
  by rewrite gtr0_norm // => ->; rewrite scale1r => /esym; apply/eqP.
rewrite /normalize row3Z mulr0; congr row3.
- transitivity (n *d 'e_0).
    rewrite dotmul_cos norm_normalize ?mul1r ?norm_delta_mx ?mul1r //.
    case: ifP => //; by rewrite cosN.
  by rewrite -coorE /n crossmulE /normalize row3Z !mxE /= ?(mulr0,mul0r,add0r,mul1r,subr0,oppr0).
- transitivity (if 0 <= u``_0 then norm (n *v 'e_0) else - norm (n *v 'e_0)).
    rewrite norm_crossmul norm_normalize ?mul1r // norm_delta_mx mul1r.
    rewrite ger0_norm // ?sin_vec_angle_ge0 // -?norm_eq0 ?norm_normalize ?oner_neq0 //
      ?norm_delta_mx ?oner_neq0 //.
    case: ifPn => //; by rewrite sinN.
  rewrite /n /normalize crossmulE.
  rewrite (_ : 'e_0%:R 0 2%:R = 0) ?(mulr0,subr0,add0r); last by rewrite mxE.
  rewrite (_ : 'e_0%:R 0 1 = 0) ?(mulr0,oppr0,add0r); last by rewrite mxE.
  rewrite (_ : 'e_0%:R 0 0 = 1) ?(mulr1); last by rewrite mxE.
  rewrite crossmulE.
  rewrite (_ : 'e_2%:R 0 1 = 0) ?(mul0r,add0r); last by rewrite mxE.
  rewrite (_ : 'e_2%:R 0 0 = 0) ?(mul0r,subrr,subr0); last by rewrite mxE.
  rewrite (_ : 'e_2%:R 0 2%:R = 1) ?(mul1r); last by rewrite mxE.
  rewrite !mxE mulr0 /=.
  rewrite -{2 3 5 6}(oppr0) -row3N normN.
  rewrite [in LHS]mulrC -{2 3 5 6}(mulr0 (u``_0)) -row3Z.
  rewrite normZ mulrC norm_row3z ger0_norm ?invr_ge0 ?norm_ge0 //.
  case: ifPn => R20.
  - by rewrite ger0_norm.
  - by rewrite ltr0_norm ?ltNge // mulrN opprK.
Qed.

End euler_angles_existence.

Section euler_angles_ZYZ.
Variable T : realType.

Definition Rzyz (a b c : T) :=
  let ca := cos a in let cb := cos b in let cc := cos c in
  let sa := sin a in let sb := sin b in let sc := sin c in
  col_mx3
  (row3 (ca * cb * cc - sa * sc) (sa * cb * cc + ca * sc) (- sb * cc))
  (row3 (- ca * cb * sc - sa * cc) (- sa * cb * sc + ca * cc) (sb * sc))
  (row3 (ca * sb) (sa * sb) (cb)).

Lemma RzyzE a b c : Rz c * Ry b * Rz a = Rzyz a b c.
Proof.
apply/matrix3P/and9P; split;
  rewrite /Rz /Ry /Rz /Rzyz;
  move: (cos a) => ca;
  move: (sin a) => sa;
  move: (cos b) => cb;
  move: (sin b) => sb;
  move: (cos c) => cc;
  move: (sin c) => sc;
  rewrite !mxE /= sum3E !mxE /= !sum3E !mxE /=; Simp.r => //=.

- by apply/eqP; nsatz.
- by apply/eqP; nsatz.
- by apply/eqP; nsatz.
- by apply/eqP; nsatz.
- by apply/eqP; nsatz.
- by apply/eqP; nsatz.
- by apply/eqP; nsatz.
by apply/eqP; nsatz.
by apply/eqP; nsatz.
Qed.

Definition zyz_a (M : 'M[T]_3) : T :=
  atan2 (M 2%:R 1) (M 2%:R 0).

Definition zyz_b (M : 'M[T]_3) : T :=
  atan2 (Num.sqrt (M 2%:R 0 ^+ 2 + M 2%:R 1 ^+ 2)) (M 2%:R 2%:R).

Definition zyz_c (M : 'M[T]_3) : T :=
  atan2 (M 1 2%:R) (- M 0 2%:R).

Lemma Rzyz_reduced_constraints M a b c : M \is 'SO[T]_3 ->
  sin b != 0 ->
  M 0 2%:R = - sin b * cos c ->
  M 1 2%:R = sin b * sin c ->
  M 2%:R 0 = cos a * sin b ->
  M 2%:R 1 = sin a * sin b ->
  M 2%:R 2%:R = cos b ->
  M = (Rz c * Ry b * Rz a).
Proof.
move=> MSO sbNZ M02 M12 M20 M21 M22.
have MO : M \is 'O[T]_3 by case/andP: MSO.
have := det_mx33 M; case/andP: MSO => _ /eqP-> => Fd.
have /eqP/matrixP/(_ 0 0) := MO => F00.
have /eqP/matrixP/(_ 0 1) := MO => F01;
have /eqP/matrixP/(_ 0 2%:R) := MO => F02;
have /eqP/matrixP/(_ 1 0) := MO => F10;
have /eqP/matrixP/(_ 1 1) := MO => F11;
have /eqP/matrixP/(_ 1 2%:R) := MO => F12;
have /eqP/matrixP/(_ 2%:R 0) := MO => F20;
have /eqP/matrixP/(_ 2%:R 1) := MO => F21;
have /eqP/matrixP/(_ 2%:R 2%:R) := MO => F22.
rewrite !mxE !sum3E !mxE /= in Fd F00 F01 F02 F10 F11 F12 F20 F21 F22.
rewrite RzyzE.
have sbN2Z : sin b ^+2 != 0 by rewrite sqrf_eq0.
apply/matrix3P/and9P; split; apply/eqP; rewrite !mxE //=.
- apply: (mulIf sbN2Z).
  apply: etrans (_ : M 2%:R 0 * M 0 2%:R * (- M 2%:R 2%:R) -
                       M 1 2%:R * M 2%:R 1 = _); last first.
    rewrite expr2.
    by nsatz.
  by rewrite sin2cos2 -sqrrN -M22 expr2; nsatz.
- apply: (mulIf sbN2Z).
  apply: etrans (_ : M 0 2%:R * M 2%:R 1 * (- M 2%:R 2%:R) +
                     M 1 2%:R * M 2%:R 0 = _); last by rewrite expr2; nsatz.
  by rewrite sin2cos2 -sqrrN -M22 expr2; nsatz.
- apply: (mulIf sbN2Z).
  apply: etrans (_ : M 2%:R 0 * M 1 2%:R * (- M 2%:R 2%:R) +
                     M 0 2%:R * M 2%:R 1 = _); last by rewrite expr2; nsatz.
  by rewrite sin2cos2 -sqrrN -M22 expr2; nsatz.
apply: (mulIf sbN2Z).
apply: etrans (_ : M 2%:R 1 * M 1 2%:R * (- M 2%:R 2%:R) -
                   M 2%:R 0 * M 0 2%:R = _); last first.
  by rewrite expr2; nsatz.
by rewrite sin2cos2 -sqrrN -M22 expr2; nsatz.
Qed.

Lemma zyz_solution M : M \is 'SO[T]_3 ->
  0 < sin (zyz_b M) ->
  M = Rz (zyz_c M) * Ry (zyz_b M) * Rz (zyz_a M).
Proof.
move=> MSO Hb.
have MO : M \is 'O[T]_3 by apply: rotation_sub.
have M12 : `|M 2%:R 2%:R| < 1.
  rewrite lt_neqAle Oij_ub ?rotation_sub // andbT.
  apply/negP => abs.
  move: (abs) Hb; rewrite Mi2_1 // => /andP[/eqP M20 /eqP M21].
  rewrite /zyz_b M20 M21 expr0n add0r sqrtr0.
  by rewrite sin_atan20x ltxx.
apply: Rzyz_reduced_constraints => //.
- by apply/eqP=> Hc; rewrite Hc ltxx in Hb.
- rewrite /zyz_b /zyz_c sqr_Mi2E // -/(yarc _).
  rewrite sin_atan2_yarcx //.
  have [/eqP M02|M02] := boolP (M 0 2%:R == 0).
    rewrite M02 oppr0 cos_atan2_0.
    have M120: M 1 2%:R != 0.
      apply/negPn => /eqP M120.
      move: (M2j_1  MO 2%:R).
      by rewrite M02 M120 eqxx /= lt_eqF.
    by rewrite (negbTE M120) mulr0.
  rewrite cos_atan2 ?oppr_eq0//.
  rewrite sqrrN sqr_M2jE // -/(yarc _).
  by rewrite mulrC mulrN -mulrA mulVf ?mulr1 ?opprK // yarc_neq0.
- rewrite /zyz_b /zyz_c sqr_Mi2E; last by rewrite rotation_sub.
  rewrite -/(yarc _) sin_atan2_yarcx //.
  have [/eqP M02|M02] := boolP (M 0 2%:R == 0).
    rewrite M02 oppr0 sin_atan2_0.
    rewrite /yarc -sqr_M2jE // M02 expr0n add0r sqrtr_sqr.
    by rewrite mulrC mulr_sg_norm.
  rewrite sin_atan2 ?oppr_eq0// sqrrN sqr_M2jE // -/(yarc _).
  by rewrite mulrCA divff ?mulr1// yarc_neq0.
- rewrite /zyz_a /zyz_b sqr_Mi2E // -/(yarc _) sin_atan2_yarcx //.
  have [/eqP M20|M20] := boolP (M 2%:R 0 == 0).
    rewrite M20 cos_atan2_0.
    have M21 : M 2%:R 1 != 0.
      apply/negPn => /eqP M21.
      move: (Mi2_1 MO 2%:R).
      by rewrite M20 M21 !eqxx /= lt_eqF.
    by rewrite (negbTE M21) mul0r.
  rewrite cos_atan2 // sqr_Mi2E // -/(yarc _).
  by rewrite -mulrA mulVf ?mulr1// yarc_neq0.
- rewrite /zyz_a /zyz_b sqr_Mi2E // -/(yarc _).
  rewrite sin_atan2_yarcx //.
  have [/eqP M20|M20] := boolP (M 2%:R 0 == 0).
    rewrite M20 sin_atan2_0.
    rewrite /yarc -sqr_Mi2E // M20 expr0n add0r sqrtr_sqr.
    by rewrite mulr_sg_norm.
  rewrite sin_atan2// sqr_Mi2E // -/(yarc _).
  by rewrite -mulrA mulVf ?mulr1// yarc_neq0.
- rewrite /zyz_b.
  rewrite sqr_Mi2E //.
  rewrite -/(yarc _).
  by rewrite cos_atan2_yarcx.
Qed.

End euler_angles_ZYZ.

Section euler_angles_ZYX.
Variable T : realType.

Definition Rxyz (a b c : T) :=
  let ca := cos a in let cb := cos b in let cc := cos c in
  let sa := sin a in let sb := sin b in let sc := sin c in
  col_mx3
  (row3 (ca * cb) (sa * cb) (- sb))
  (row3 (ca * sb * sc - sa * cc) (sa * sb * sc + ca * cc) (cb * sc))
  (row3 (ca * sb * cc + sa * sc) (sa * sb * cc - ca * sc) (cb * cc)).

Lemma RxyzE c b a : Rx c * Ry b * Rz a = Rxyz a b c.
Proof.
apply/matrix3P/and9P; split;
   rewrite !mxE /=  sum3E !mxE /=; Simp.r; rewrite !sum3E !{1}mxE /=;
   Simp.r => //.
by rewrite mulrC.
by rewrite mulrC.
by rewrite mulrAC -mulrA mulrC (mulrC (cos c)).
by rewrite mulrC (mulrC (sin c)) mulrA (mulrC (cos c)).
by rewrite mulrC.
by rewrite mulrC (mulrC (cos c)) mulrA (mulrC (sin c)).
by rewrite mulrC (mulrC (cos c)) mulrA (mulrC (sin c)).
by rewrite mulrC.
Qed.

Definition rpy_a (M : 'M[T]_3) : T := atan2 (M 0 1) (M 0 0).

Definition rpy_b (M : 'M[T]_3) : T :=
  atan2 (- M 0 2%:R) (Num.sqrt (M 1 2%:R ^+ 2 + M 2%:R 2%:R ^+ 2)).

Definition rpy_c (M : 'M[T]_3) : T := atan2 (M 1 2%:R) (M 2%:R 2%:R).

Lemma RxyzE_M02D1 M a b c : M \is 'SO[T]_3 ->
  cos b != 0 ->
  M 0 0 = cos a * cos b ->
  M 0 1 = sin a * cos b ->
  M 0 2%:R = - sin b ->
  M 1 2%:R = cos b * sin c ->
  M 2%:R 2%:R = cos b * cos c ->
  M = (Rx c * Ry b * Rz a).
Proof.
move=> MSO cbNZ M00 M01 M02 M12 M22.
have MO : M \is 'O[T]_3 by case/andP: MSO.
have := det_mx33 M; case/andP: MSO => _ /eqP-> => Fd.
have /eqP/matrixP/(_ 0 0) := MO => F00.
have /eqP/matrixP/(_ 0 1) := MO => F01;
have /eqP/matrixP/(_ 0 2%:R) := MO => F02;
have /eqP/matrixP/(_ 1 0) := MO => F10;
have /eqP/matrixP/(_ 1 1) := MO => F11;
have /eqP/matrixP/(_ 1 2%:R) := MO => F12;
have /eqP/matrixP/(_ 2%:R 0) := MO => F20;
have /eqP/matrixP/(_ 2%:R 1) := MO => F21;
have /eqP/matrixP/(_ 2%:R 2%:R) := MO => F22.
rewrite !mxE !sum3E !mxE /= in Fd F00 F01 F02 F10 F11 F12 F20 F21 F22.
rewrite RxyzE.
have cbN2Z : cos b ^+2 != 0 by rewrite sqrf_eq0.
apply/matrix3P/and9P; split; apply/eqP; rewrite !mxE //=.
- apply: (mulIf cbN2Z).
  apply: etrans (_ : M 0 0 * M 1 2%:R * (- M 0 2%:R) -
                       M 0 1 * M 2%:R 2%:R = _); last by rewrite expr2; nsatz.
  rewrite cos2sin2 -sqrrN -M02 expr2; nsatz.
- apply: (mulIf cbN2Z).
  apply: etrans (_ : M 0 1 * M 1%:R 2%:R * (- M 0 2%:R) +
                     M 0 0 * M 2%:R 2%:R = _); last by rewrite expr2; nsatz.
  by rewrite cos2sin2 -sqrrN -M02 expr2; nsatz.
- apply: (mulIf cbN2Z).
  apply: etrans (_ : M 0 0 * M 2%:R 2%:R * (- M 0 2%:R) +
                     M 0 1 * M 1 2%:R = _); last by rewrite expr2; nsatz.
  by rewrite cos2sin2 -sqrrN -M02 expr2; nsatz.
apply: (mulIf cbN2Z).
apply: etrans (_ : M 0 1 * M 2%:R 2%:R * (- M 0 2%:R) -
                   M 0 0 * M 1 2%:R = _); last first.
  by rewrite expr2; nsatz.
by rewrite cos2sin2 -sqrrN -M02 expr2; nsatz.
Qed.

Lemma rpy_solution M : M \is 'SO[T]_3 ->
  0 < cos (rpy_b M) -> (* -pi/2 < b < pi/2 *)
  M = (Rx (rpy_c M) * Ry (rpy_b M) * Rz (rpy_a M)).
Proof.
move=> MSO Hb.
have MO : M \is 'O[T]_3 by apply: rotation_sub.
have M02 : `|M 0 2%:R| < 1.
  rewrite lt_neqAle Oij_ub ?rotation_sub // andbT.
  apply/negP => abs.
  move: (abs) Hb; rewrite M0j_1 // => /andP[/eqP M12 /eqP M22].
  rewrite /rpy_b M12 M22 expr0n add0r sqrtr0 cos_atan2_0 oppr_eq0.
  by rewrite -normr_eq0 (eqP abs) oner_eq0 ltxx.
apply: RxyzE_M02D1 => //.
- by apply/eqP=> Hc; rewrite Hc ltxx in Hb.
- rewrite /rpy_a /rpy_b sqr_M0jE // -/(yarc _).
  rewrite cos_atan2_xyarc //.
  have [/eqP M00|M00] := boolP (M 0 0 == 0).
    rewrite M00 cos_atan2_0.
    have M01 : M 0 1 != 0.
      apply/negPn => /eqP M01.
      move: (Mi2_1  MO 0).
      by rewrite M00 M01 !eqxx /= lt_eqF.
    by rewrite (negbTE M01) mul0r.
  rewrite cos_atan2 // sqr_Mi2E // -/(yarc _) -mulrA.
  by rewrite mulVr ?mulr1 // unitfE yarc_neq0.
- rewrite /rpy_a /rpy_b sqr_M0jE; last by rewrite rotation_sub.
  rewrite -/(yarc _) cos_atan2_xyarc //.
  have [/eqP M00|M00] := boolP (M 0 0 == 0).
    rewrite M00 sin_atan2_0.
    rewrite /yarc -sqr_Mi2E // M00 expr0n add0r sqrtr_sqr.
    by rewrite mulr_sg_norm.
  rewrite sin_atan2 // sqr_Mi2E // -/(yarc _).
  by rewrite -mulrA mulVr ?mulr1 // unitfE yarc_neq0.
- rewrite /rpy_b sqr_M0jE // -/(yarc _) -sinN.
  have [->|/eqP mo2D0] := M 0 2%:R =P 0.
    by rewrite yarc0 oppr0 atan2_0P // sinN sin0 oppr0.
  rewrite atan2N // opprK.
  by rewrite sin_atan2_xyarc.
- rewrite /rpy_b /rpy_c sqr_M0jE // -/(yarc _) cos_atan2_xyarc //.
  have [/eqP M22|M22] := boolP (M 2%:R 2%:R == 0).
    rewrite M22 sin_atan2_0 /yarc -sqr_M0jE //.
    rewrite M22 expr0n addr0 sqrtr_sqr mulrC.
    by rewrite mulr_sg_norm.
  rewrite sin_atan2 // addrC sqr_M0jE // -/(yarc _).
  by rewrite mulrCA mulfV ?mulr1 // yarc_neq0.
rewrite /rpy_b /rpy_c sqr_M0jE // -/(yarc _).
rewrite cos_atan2_xyarc //.
have [/eqP M22|M22] := boolP (M 2%:R 2%:R == 0).
  rewrite M22 cos_atan2_0.
  have M12 : M 1 2%:R != 0.
    apply/negPn => /eqP M12.
    move: (M0j_1  MO 2%:R).
    by rewrite M22 M12 !eqxx /= lt_eqF.
  by rewrite (negbTE M12) mulr0.
rewrite cos_atan2 // addrC sqr_M0jE // -/(yarc _).
by rewrite mulrCA mulfV ?mulr1 // yarc_neq0.
Qed.

End euler_angles_ZYX.

Section euler_angles.
Variable T : realType.

Definition euler_b (M : 'M[T]_3) : T :=
  if `| M 0 2%:R | != 1 then
    - asin (M 0 2%:R)
  else if M 0 2%:R == 1 then
    - (pi / 2%:R)
  else (* M 0 2%:R == - 1*) pi / 2%:R.

Definition euler_c (M : 'M[T]_3) : T :=
  if `| M 0 2%:R | != 1 then
    atan2 (M 1 2%:R / cos (euler_b M)) (M 2%:R 2%:R / cos (euler_b M))
  else 0.

Definition euler_a (M : 'M[T]_3) : T :=
  if `| M 0 2%:R | != 1 then
    atan2 (M 0 1 / cos (euler_b M)) (M 0 0 / cos (euler_b M))
  else if M 0 2%:R == 1 then
    atan2 (- M 2%:R 1) (- M 2%:R 0)
  else
    atan2 (M 2%:R 1) (M 2%:R 0).

Lemma rot_euler_anglesE M : M \is 'SO[T]_3 ->
  M = Rx (euler_c M) * Ry (euler_b M) * Rz (euler_a M).
Proof.
move=> MSO.
have MO : M \is 'O[T]_3 by apply: rotation_sub.
have [/eqP NM02E1|NM02D1] := boolP (`|M 0 2%:R| == 1); last first.
  have NM02L1 : `|M 0 2%:R| < 1.
    by rewrite lt_neqAle NM02D1 andTb Oij_ub // rotation_sub.
  have NM02L1N1 : -1 <= M 0 2%:R <= 1.
    by rewrite -real_lter_norml ?ltW ?num_real.
  apply: RxyzE_M02D1 => //.
  - by rewrite /euler_b NM02D1 cosN cos_asin // yarc_neq0.
  - rewrite /euler_a /euler_b NM02D1 cosN cos_asin //.
    have [/eqP M00|M00] := boolP (M 0 0 == 0).
      rewrite M00 mul0r cos_atan2_0.
      have M01 : M 0 1 != 0.
        apply/negPn => /eqP M01.
        move: (Mi2_1 MO 0).
        by rewrite M00 M01 !eqxx /= lt_eqF.
      rewrite mulf_eq0 (negbTE M01) orFb invr_eq0.
      move H : (_ == 0) => h; case: h H => H.
        by rewrite mul1r (eqP H).
      by rewrite mul0r.
    rewrite cos_atan2; last first.
      by rewrite mulf_neq0 // invr_eq0 -/(yarc _) yarc_neq0.
    rewrite -/(yarc _).
    rewrite mulrAC -(mulrA (M 0 0)) mulVr ?unitfE ?yarc_neq0 // mulr1.
    rewrite 2!expr_div_n -mulrDl sqr_Mi2E // sqr_yarc //.
    by rewrite divrr ?sqrtr1 ?divr1 // unitfE subr_eq0 eq_sym sqr_norm_eq1 lt_eqF.
  - rewrite /euler_a /euler_b NM02D1 // cosN cos_asin //.
    have [/eqP M00|M00] := boolP (M 0 0 == 0).
      rewrite M00 mul0r sin_atan2_0 sgrM sgrV -mulrA -normrEsg.
      by rewrite -sqr_Mi2E // M00 expr0n add0r sqrtr_sqr normr_id mulr_sg_norm.
    rewrite sin_atan2; last first.
      by rewrite mulf_neq0 // -/(yarc _) invr_eq0 yarc_neq0.
    rewrite -/(yarc _).
    (* NB: same as above *)
    rewrite mulrAC -(mulrA (M 0 1)) mulVr ?unitfE ?yarc_neq0 // mulr1.
    rewrite 2!expr_div_n -mulrDl sqr_Mi2E // sqr_yarc //.
    by rewrite divrr ?sqrtr1 ?divr1 // unitfE subr_eq0 eq_sym sqr_norm_eq1 lt_eqF.
  - by rewrite /euler_b NM02D1 sinN opprK asinK // -ler_norml ltW.
  - rewrite /euler_c /euler_b NM02D1 cosN cos_asin //.
    have [/eqP M22|M22] := boolP (M 2%:R 2%:R == 0).
      rewrite M22 mul0r sin_atan2_0 sgrM sgrV mulrCA -[_ * Num.sg _]mulrC.
      rewrite -normrEsg -sqr_M0jE //.
      by rewrite M22 expr0n addr0 sqrtr_sqr normr_id mulr_sg_norm.
    rewrite sin_atan2; last first.
      by rewrite mulf_neq0 // -/(yarc _) invr_eq0 yarc_neq0.
    rewrite -/(yarc _).
    (* NB: same as above *)
    rewrite mulrA [yarc _ * _]mulrC divfK  ?yarc_neq0 //.
    rewrite 2!expr_div_n -mulrDl addrC sqr_M0jE // sqr_yarc //.
    by rewrite divrr ?sqrtr1 ?divr1 // unitfE subr_eq0
               eq_sym sqr_norm_eq1 lt_eqF.
  rewrite /euler_c /euler_b NM02D1 cosN cos_asin //.
  have [/eqP M22|M22] := boolP (M 2%:R 2%:R == 0).
    rewrite M22 mul0r cos_atan2_0 -sqr_M0jE // M22 expr0n addr0.
    rewrite mulf_eq0 invr_eq0 sqrtr_eq0 le_eqVlt sqrf_eq0.
    rewrite ltNge sqr_ge0 orbF.
    by case: eqP => [->|] /=; rewrite ?(mul0r, mulr0, expr0n, sqrtr0).
  rewrite cos_atan2; last first.
    by rewrite mulf_neq0 // -/(yarc _) invr_eq0 yarc_neq0.
  rewrite -/(yarc _).
  (* NB: same as above *)
  rewrite mulrA [yarc _ * _]mulrC divfK  ?yarc_neq0 //.
  rewrite 2!expr_div_n -mulrDl addrC sqr_M0jE // sqr_yarc //.
  by rewrite divrr ?sqrtr1 ?divr1 // unitfE subr_eq0
              eq_sym sqr_norm_eq1 lt_eqF.
rewrite RxyzE.
have := det_mx33 M; case/andP: MSO => _ /eqP-> => Fd.
have /eqP/matrixP/(_ 0 0) := MO => F00.
have /eqP/matrixP/(_ 0 1) := MO => F01;
have /eqP/matrixP/(_ 0 2%:R) := MO => F02;
have /eqP/matrixP/(_ 1 0) := MO => F10;
have /eqP/matrixP/(_ 1 1) := MO => F11;
have /eqP/matrixP/(_ 1 2%:R) := MO => F12;
have /eqP/matrixP/(_ 2%:R 0) := MO => F20;
have /eqP/matrixP/(_ 2%:R 1) := MO => F21;
have /eqP/matrixP/(_ 2%:R 2%:R) := MO => F22.
rewrite !mxE !sum3E !mxE /= in Fd F00 F01 F02 F10 F11 F12 F20 F21 F22.
have [M00 M01] : M 0 0 = 0 /\ M 0 1 = 0.
  by move/eqP : NM02E1; rewrite Mi2_1 // => /andP[/eqP ? /eqP].
rewrite /euler_a /euler_b /euler_c NM02E1 eqxx /=.
rewrite M00 M01 !(mul0r, mulr0, add0r)
  in Fd F00 F01 F02 F10 F11 F12 F20 F21 F22.
have M12 :  M 1 2%:R = 0%:R by nsatz.
have M22 :  M 2%:R 2%:R = 0%:R by nsatz.
rewrite M12 M22 !(mul0r, mulr0, add0r, addr0)
   in Fd F00 F01 F02 F10 F11 F12 F20 F21 F22.
case: eqP => [M02E1|/eqP M02ED1].
  case: (M 2%:R 0 =P 0) => [M20|/eqP M20D].
    have M11 :  M 1 1%:R = 0%:R by nsatz.
    rewrite M20 M11 !(mul0r, mulr0, add0r, addr0, oppr0)
      in Fd F00 F01 F02 F10 F11 F12 F20 F21 F22 *.
    apply/matrix3P/and9P; split; apply/eqP;
      rewrite !mxE //= ?(cosN, sinN, cos_pihalf, sin_pihalf, cos0, sin0);
      rewrite ?(mul0r, mulr0, oppr0, add0r, addr0, mul1r, mulN1r, opprK) //;
      rewrite ?(sin_atan2_0, cos_atan2_0) //.
    - have/eqP := F11; rewrite -subr_eq0 -expr2 subr_sqr_1 mulf_eq0.
      case/orP=> /eqP H.
        have -> : M 1 0 = 1 by nsatz.
        have -> : M 2%:R 1 = 1 by nsatz.
        by rewrite sgrN sgr1 mulN1r opprK.
      have -> : M 1 0 = -1 by nsatz.
      have -> : M 2%:R 1 = -1 by nsatz.
      by rewrite opprK sgr1 mul1r.
    - by case: eqP => //=; nsatz.
    - by case: eqP => /=; nsatz.
    have/eqP := F11; rewrite -subr_eq0 -expr2 subr_sqr_1 mulf_eq0.
    case/orP=> /eqP H.
      have -> : M 2%:R 1 = 1 by nsatz.
      by rewrite sgrN sgr1 mulN1r opprK mul1r.
    have -> : M 2%:R 1 = -1 by nsatz.
    by rewrite opprK sgr1 mulrN1 mulN1r.
  have V := mulfV M20D.
  have NM20D : - M 2%:R 0 != 0 by rewrite oppr_eq0.
  apply/matrix3P/and9P; split; apply/eqP;
      rewrite !mxE //= ?(cosN, sinN, cos_pihalf, sin_pihalf, cos0, sin0);
      rewrite ?(mul0r, mulr0, oppr0, add0r, addr0, mul1r,
                mulr1, mulN1r, mulrN1, opprK) //;
      rewrite ?(sin_atan2, cos_atan2, sqrrN) //;
      rewrite  sqr_Mi2E // M22 expr0n subr0 sqrtr1 divr1 ?opprK //.
    by nsatz.
  by nsatz.
rewrite -subr_eq0 in M02ED1; have V := mulVf M02ED1.
have M20EN1 : M 0 2%:R = -1 by nsatz.
case: (M 2%:R 0 =P 0) => [M20|/eqP M20D].
  have M11 :  M 1 1 = 0%:R by nsatz.
  rewrite M20EN1 M20 M11 !(mul0r, mulr0, add0r, addr0, oppr0)
    in Fd F00 F01 F02 F10 F11 F12 F20 F21 F22 *.
  have NM21D : M 2%:R 1 != 0.
    by apply/eqP=> M210; have/eqP := F22; rewrite M210 mul0r (eqr_nat _ 0 1).
  apply/matrix3P/and9P; split; apply/eqP;
        rewrite !mxE //= ?(cosN, sinN, cos_pihalf, sin_pihalf, cos0, sin0);
        rewrite ?(cos_atan2_0, sin_atan2_0, (negPf NM21D));
        rewrite ?(mulr0, mulr1, add0r, addr0, subr0) //.
    have/eqP := F22; rewrite -subr_eq0 -expr2 subr_sqr_1 mulf_eq0
                                => /orP[] /eqP HH.
      have -> : M 2%:R 1 = 1 by nsatz.
      by rewrite sgr1; nsatz.
    have -> : M 2%:R 1 = -1 by nsatz.
    by rewrite sgrN1 opprK; nsatz.
  have/eqP := F22; rewrite -subr_eq0 -expr2 subr_sqr_1 mulf_eq0
                                => /orP[] /eqP HH.
    have -> : M 2%:R 1 = 1 by nsatz.
    by rewrite sgr1.
  have -> : M 2%:R 1 = -1 by nsatz.
  by rewrite sgrN1.
apply/matrix3P/and9P; split; apply/eqP;
     rewrite !mxE //= ?(cosN, sinN, cos_pihalf, sin_pihalf, cos0, sin0);
        rewrite ?(mul0r, mulr0, oppr0, add0r, addr0, mul1r, mulN1r, opprK) //;
        rewrite ?(sin_atan2, cos_atan2, mul0r, oppr0, expr0n, addr0, mulr1,
                     eqxx) //;
        rewrite sqr_Mi2E // M22 expr0n subr0 sqrtr1 divr1 //.
  by nsatz.
by nsatz.
Qed.

End euler_angles.
