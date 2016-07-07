Require Import mathcomp.ssreflect.ssreflect.
From mathcomp
Require Import ssrfun ssrbool eqtype ssrnat seq choice fintype tuple finfun.
From mathcomp
Require Import bigop ssralg ssrint div ssrnum rat poly closed_field polyrcf.
From mathcomp
Require Import matrix mxalgebra tuple mxpoly zmodp binomial realalg.
From mathcomp
Require Import complex.
From mathcomp
Require Import finset fingroup perm.

Require Import aux angle euclidean3 quaternion.

(*
 OUTLINE:
 1. section angle

    definition of vec_angle (restricted to [0,pi])
    (sample lemma: multiplication by a O_3[R] matrix preserves vec_angle)
 2. section colinear
    (simple definition using crossmul, but seemed clearer to me to have a dedicated definition)
 3. section normalize
    section axial_normal_decomposition.
    (easy definitions to construct frames out of already available points/vectors)
 4. section orthonormal_frame
    definition of orthonormal frames (including orientation)
 5. module about the canonical frame (1,0,0),(0,1,0),(0,0,1)
 6. module about the construction of an orthonormal frame from some non-zero vector
 7. definition of the rotation from one frame to another
     FromTo.mkT
 8. section triad
    (construction of a frame out of three non-colinear points)
 9. section transformation_given_three_points
    (construction d'une transformation (rotation + translation) etant donnes
    trois points de depart et leurs positions d'arrivee)
    sample lemma: the rotation obtained behaves like a change of coordinates from left to right
 10. definition of rotations w.r.t. axis
     definition of the Rx,Ry,Rz rotations.
     sample lemmas:
       all rotations around an axis of angle a have trace "1 + 2 * cos a"
       equivalence SO[R]_3 <-> is_around_axis
 11. section symmetric/antisymmetry/skew (properties of skew matrices)
     (sample lemma: eigenvalues of skew matrices)
     Cayley transformation
     definition of axial_vec and proof that this vector is stable by rotation (like the axis)
 12. section exponential_map_rot
     specialized exponential map
     (sample lemmas: inverse of the exponential map,
       exponential map of a skew matrix is a rotation)
     (Rodrigues formula:
       u * e^(phi,w) can be expressed using a linear combination of vectors
         u, (u *d w)w, u *v w)
 13. correction of rotation using unit quaternions
 14. section isometry_def
     (contains the definition of central isometries)
 15. section sign_of_isometry (n = 3)
     (contains the definition of direct isometries)
 16. section tangent vectors
 17. section derivative maps of isometries
     definition of what it means to preserve the cross-product by a transformation
     (sample lemma: preservation of the cross-product by derivative maps)
 18. section homogeneous_transformation
 19. section rigid_transformation_is_homogeneous_transformation
     (a direct isometry (i.e., cross-product preserving) can be expressed in homogeneous coordinates)
     (NB: converse in progress (?))
 20. section angle_axis
     sample lemmas:
       any rotation matrix M around an axis has angle acos (tr M - 1)/2
       any rotation matrix M around an axis has axis antip_vec
     (sample lemmas: specialized exponential map <-> Rodrigues' formula)
 21. section kinematics chains
 22. section exponential_map
     tentative definition of e^M (as a series up to k)
 23. section exponential_coordinates_rigid
     tentative definition of a twist
     (NB: in progress)
*)

Set Implicit Arguments.
Unset Strict Implicit.
Unset Printing Implicit Defensive.

Import GRing.Theory.
Import Num.Theory.

Local Open Scope ring_scope.

Section angle.

Variable (R : rcfType).

Definition vec_angle v w : angle R := arg (v *d w +i* norm (v *v w)).

Lemma vec_anglev0 v : vec_angle v 0 = vec_angle 0 0.
Proof. by rewrite /vec_angle 2!dotmulv0 2!crossmulv0. Qed.

Lemma vec_angle0v v : vec_angle 0 v = vec_angle 0 0.
Proof. by rewrite /vec_angle 2!dotmul0v 2!crossmul0v. Qed.

Definition vec_angle0 := (vec_anglev0, vec_angle0v).

Lemma cos_vec_angleNv v w : v != 0 -> w != 0 ->
  cos (vec_angle (- v) w) = - cos (vec_angle v w).
Proof.
move=> a0 b0.
rewrite /vec_angle /cos crossmulNv normN expi_arg; last first.
  rewrite eq_complex /= negb_and.
  case/boolP : (v *d w == 0) => ab; last by rewrite dotmulNv oppr_eq0 ab.
  by rewrite dotmulNv (eqP ab) oppr0 eqxx /= norm_eq0 dotmul_eq0_crossmul_neq0.
rewrite expi_arg; last first.
  rewrite eq_complex /= negb_and.
  by case/boolP : (_ == 0) => ab //=; rewrite norm_eq0 dotmul_eq0_crossmul_neq0.
rewrite (_ : `|- v *d w +i* _| = `|v *d w +i* norm (v *v w)|); last first.
  by rewrite 2!normc_def /= dotmulNv sqrrN.
by rewrite /= mul0r oppr0 mulr0 subr0 expr0n /= addr0 subr0 dotmulNv mulNr.
Qed.

Lemma cos_vec_anglevN v w : v != 0 -> w != 0 ->
  cos (vec_angle v (- w)) = - cos (vec_angle v w).
Proof.
move=> a0 b0.
rewrite /vec_angle /cos crossmulC crossmulNv opprK dotmulvN.
rewrite [in LHS]expi_arg; last first.
  rewrite eq_complex /= negb_and.
  case/boolP : (v *d w == 0) => vw; rewrite oppr_eq0 vw //=.
  by rewrite norm_eq0 dotmul_eq0_crossmul_neq0 // dotmulC.
rewrite expi_arg; last first.
  rewrite eq_complex /= negb_and.
  by case/boolP : (_ == 0) => ab //=; rewrite norm_eq0 dotmul_eq0_crossmul_neq0.
rewrite (_ : `| _ +i* norm (w *v _)| = `|v *d w +i* norm (v *v w)|); last first.
  by rewrite 2!normc_def /= sqrrN crossmulC normN.
by rewrite /= mul0r oppr0 mulr0 expr0n /= addr0 subr0 mulr0 subr0 mulNr.
Qed.

Lemma vec_angleC v w : vec_angle v w = vec_angle w v.
Proof. by rewrite /vec_angle dotmulC crossmulC normN. Qed.

Lemma vec_angleZ u v k : 0 < k -> vec_angle u (k *: v) = vec_angle u v.
Proof.
case/boolP : (u == 0) => [/eqP ->|u0]; first by rewrite !vec_angle0.
case/boolP : (v == 0) => [/eqP ->|v0 k0]; first by rewrite scaler0 !vec_angle0.
by rewrite /vec_angle dotmulvZ linearZ normZ ger0_norm ?ltrW // complexZ argZ.
Qed.

Lemma vec_angleZ_neg u v k : k < 0 -> vec_angle u (k *: v) = vec_angle (- u) v.
Proof.
case/boolP : (u == 0) => [/eqP ->|u0]; first by rewrite oppr0 !vec_angle0.
case/boolP : (v == 0) => [/eqP ->|v0 k0]; first by rewrite scaler0 !vec_angle0.
rewrite /vec_angle dotmulvZ linearZ /= normZ ltr0_norm //.
by rewrite mulNr complexZ argZ_neg // opp_conjc dotmulNv crossmulNv normN.
Qed.

Lemma vec_anglevv u : u != 0 -> vec_angle u u = 0.
Proof.
move=> u0.
rewrite /vec_angle /= crossmulvv norm0 complexr0 dotmulvv arg_Re ?arg1 //.
by rewrite ltr_neqAle sqr_ge0 andbT eq_sym sqrf_eq0 norm_eq0.
Qed.

Lemma polarization_identity (v w : 'rV[R]_3) :
  v *d w = 1 / 4%:R * (norm (v + w) ^+ 2 - norm (v - w) ^+ 2).
Proof.
apply: (@mulrI _ 4%:R); first exact: pnatf_unit.
rewrite [in RHS]mulrA div1r divrr ?pnatf_unit // mul1r.
rewrite -2!dotmulvv dotmulD dotmulD mulr_natl (addrC (v *d v)).
rewrite (_ : 4 = 2 + 2)%N // mulrnDr -3![in RHS]addrA; congr (_ + _).
rewrite opprD addrCA 2!addrA -(addrC (v *d v)) subrr add0r.
by rewrite addrC opprD 2!dotmulvN dotmulNv opprK subrK -mulNrn opprK.
Qed.

Lemma dotmul_cos u v : u *d v = norm u * norm v * cos (vec_angle u v).
Proof.
wlog /andP[u0 v0] : u v / (u != 0) && (v != 0).
  case/boolP : (u == 0) => [/eqP ->{u}|u0]; first by rewrite dotmul0v norm0 !mul0r.
  case/boolP : (v == 0) => [/eqP ->{v}|v0]; first by rewrite dotmulv0 norm0 !(mulr0,mul0r).
  apply; by rewrite u0.
rewrite /vec_angle /cos. set x := _ +i* _.
case/boolP  : (x == 0) => [|x0].
  rewrite eq_complex /= => /andP[/eqP H1 H2].
  exfalso.
  move: H2; rewrite norm_eq0 => /crossmul0_dotmul/esym.
  rewrite H1 expr0n (_ : (_ == _)%:R = 0) // => /eqP.
  by rewrite 2!dotmulvv mulf_eq0 2!expf_eq0 /= 2!norm_eq0 (negbTE u0) (negbTE v0).
case/boolP : (u *d v == 0) => uv0.
  by rewrite (eqP uv0) expi_arg //= (eqP uv0) !mul0r -mulrN opprK mulr0 addr0 mulr0.
rewrite expi_arg //.
rewrite normc_def Re_scale; last first.
  rewrite sqrtr_eq0 -ltrNge -(addr0 0) ltr_le_add //.
    by rewrite exprnP /= ltr_neqAle sqr_ge0 andbT eq_sym -exprnP sqrf_eq0.
  by rewrite /= sqr_ge0.
rewrite /=.
rewrite norm_crossmul' addrC subrK sqrtr_sqr ger0_norm; last first.
  by rewrite mulr_ge0 // norm_ge0.
rewrite mulrA mulrC mulrA mulVr ?mul1r //.
by rewrite unitrMl // unitfE norm_eq0.
Qed.

Lemma dotmul0_vec_angle u v : u != 0 -> v != 0 ->
  u *d v = 0 -> `| sin (vec_angle u v) | = 1.
Proof.
move=> u0 v0 /eqP.
rewrite dotmul_cos mulf_eq0 => /orP [ | /eqP/cos0sin1 //].
by rewrite mulf_eq0 2!norm_eq0 (negbTE u0) (negbTE v0).
Qed.

Lemma normD a b : norm (a + b) =
  Num.sqrt (norm a ^+ 2 + norm a * norm b * cos (vec_angle a b) *+ 2 + norm b ^+ 2).
Proof.
rewrite /norm dotmulD {1}dotmulvv sqr_sqrtr ?le0dotmul //.
by rewrite sqr_sqrtr ?le0dotmul // (dotmul_cos a b).
Qed.

Lemma normB a b : norm (a - b) =
  Num.sqrt (norm a ^+ 2 + norm a * norm b * cos (vec_angle a b) *- 2 + norm b ^+ 2).
Proof.
rewrite /norm dotmulD {1}dotmulvv sqr_sqrtr ?le0dotmul //.
rewrite sqr_sqrtr ?le0dotmul // !dotmulvv !sqrtr_sqr normN dotmulvN dotmul_cos.
by rewrite ger0_norm ?norm_ge0 // ger0_norm ?norm_ge0 // mulNrn.
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
rewrite -mulNrn -mulr_natr mulNr -mulrA -(mulrC 2%:R) mulrA.
rewrite -mulNrn -[in X in _ = - _ / X]mulr_natr 2!mulNr invrN mulrN opprK.
rewrite mulrC mulrA mulVr ?mul1r // unitfE mulf_eq0 negb_or pnatr_eq0 andbT.
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
rewrite real_normK; first by rewrite addrC cos2Dsin2 mulr1.
rewrite /sin; case: (expi _) => a b /=; rewrite realE //.
case: (lerP 0 b) => //= b0; by rewrite ltrW.
Qed.

Lemma norm_dotmul_crossmul (u v : 'rV[R]_3) : u != 0 -> v != 0 ->
  `|u *d v +i* norm (u *v v)| = (norm u * norm v)%:C.
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
move=> u1 v1; rewrite /vec_angle => uv.
move: (norm_dotmul_crossmul u1 v1) => /arg0_inv/(_ uv)/eqP.
rewrite eq_complex {1}rmorphM /= mulf_eq0 negb_or.
rewrite eq_complex /= eqxx norm_eq0 andbT u1 eq_complex eqxx norm_eq0 andbT v1.
move/(_ isT) => /andP[].
rewrite dotmul_cos -{2}(mulr1 (norm u * norm v)); move/eqP/mulrI.
rewrite unitfE mulf_eq0 negb_or 2!norm_eq0 u1 v1 => /(_ isT) => uv1 ?.
apply/eqP; rewrite -subr_eq0 -norm_eq0 normB vec_angleZ; last first.
  by rewrite divr_gt0 // lt0r norm_ge0 norm_eq0 ?u1 ?v1.
rewrite uv1 mulr1 !normZ ger0_norm; last by rewrite divr_ge0 // norm_ge0.
by rewrite -!mulrA mulVr ?unitfE // ?norm_eq0 // mulr1 -expr2 addrAC -mulr2n subrr sqrtr0.
Qed.

Lemma vec_anglepi_inv u v : u != 0 -> v != 0 ->
  vec_angle u v = pi -> u = - (norm u / norm v) *: v.
Proof.
move=> u1 v1; rewrite /vec_angle => uv.
move: (norm_dotmul_crossmul u1 v1) => /argpi_inv/(_ uv)/eqP.
rewrite eq_complex {1}rmorphM /= mulf_eq0 negb_or.
rewrite eq_complex /= eqxx andbT norm_eq0 u1 eq_complex /= eqxx andbT norm_eq0 v1.
move/(_ isT) => /andP[].
rewrite dotmul_cos -{1}(mulrN1 (norm u * norm v)).
move/eqP/mulrI; rewrite unitfE mulf_eq0 negb_or 2!norm_eq0 u1 v1.
move/(_ isT) => uv1 ?.
apply/eqP; rewrite -subr_eq0 -norm_eq0 normB vec_angleZ_neg; last first.
  by rewrite oppr_lt0 divr_gt0 // lt0r norm_ge0 norm_eq0 ?u1 ?v1.
rewrite scaleNr normN cos_vec_angleNv // uv1 opprK.
rewrite mulr1 !normZ ger0_norm; last by rewrite divr_ge0 // norm_ge0.
by rewrite -!mulrA mulVr ?unitfE // ?norm_eq0 // mulr1 -expr2 addrAC -mulr2n subrr sqrtr0.
Qed.

Lemma dotmul1_inv (u v : 'rV[R]_3) : norm u = 1 -> norm v = 1 -> u *d v = 1 -> u = v.
Proof.
move=> u1 v1; rewrite dotmul_cos u1 v1 2!mul1r => /cos1_angle0/vec_angle0_inv.
rewrite -2!norm_eq0 u1 v1 oner_neq0 div1r invr1 scale1r; by apply.
Qed.

Lemma dotmulN1_inv (u v : 'rV[R]_3) : norm u = 1 -> norm v = 1 -> u *d v = - 1 -> u = - v.
Proof.
move=> u1 v1; rewrite dotmul_cos u1 v1 2!mul1r => /cosN1_angle0/vec_anglepi_inv.
rewrite -2!norm_eq0 u1 v1 oner_neq0 div1r invr1 scaleN1r; by apply.
Qed.

Lemma cos_vec_angle a b : a != 0 -> b != 0 ->
  `| cos (vec_angle a b) | = Num.sqrt (1 - (norm (a *v b) / (norm a * norm b)) ^+ 2).
Proof.
move=> Ha Hb.
rewrite norm_crossmul mulrAC divrr // ?mul1r.
  by rewrite sqr_normr -cos2sin2 sqrtr_sqr.
by rewrite unitfE mulf_neq0 // norm_eq0.
Qed.

Lemma orth_preserves_vec_angle M : M \is 'O[R]_3 ->
  {mono (fun u => u *m M) : v w / vec_angle v w}.
Proof.
move=> MO v w; move/(proj2 (orth_preserves_dotmul _))/(_ v w) : (MO).
by rewrite /vec_angle => ->; rewrite orth_preserves_norm_crossmul.
Qed.

End angle.

Lemma sqr_normr_cossin (R : rcfType) (v :'rV[R]_2) :
  norm v = 1 -> exists a, v 0 0 = cos a /\ v 0 1 = sin a.
Proof.
move=> v1.
have {v1}v1 : `| v 0 0 +i* v 0 1 | = 1 by rewrite normc_def /= -sqr_norm2 sqrtr_sqr v1 normr1.
exists (arg (v 0 0 +i* v 0 1)).
rewrite /cos /sin expi_arg //; last by rewrite -normr_eq0 v1 oner_neq0.
by rewrite v1 divr1.
Qed.

Definition RO {R : rcfType} (a : angle R) :=
  col_mx2 (row2 (cos a) (sin a)) (row2 (- sin a) (cos a)).

Lemma tr_RO {R : rcfType} (a : angle R) : \tr (RO a) = (cos a) *+ 2.
Proof. by rewrite /mxtrace sum2E !mxE /= mulr2n. Qed.

Lemma orthogonal2P {T : rcfType} (M : 'M[T]_2) :
  (row 0 M *d row 0 M = 1) -> (row 0 M *d row 1 M = 0) ->
  (row 1 M *d row 0 M = 0) -> (row 1 M *d row 1 M = 1) ->
  M \is 'O[T]_2.
Proof.
move=> H *; apply/orthogonalP => i j.
case/boolP : (i == 0) => [/eqP ->|].
  case/boolP : (j == 0) => [/eqP -> //|]; by rewrite ifnot01 => /eqP ->.
rewrite ifnot01 => /eqP ->; case/boolP : (j == 0) => [/eqP -> //|].
by rewrite ifnot01 => /eqP ->; rewrite eqxx.
Qed.

Lemma RO_is_O {R : rcfType} (a : angle R) : RO a \is 'O[R]_2.
Proof.
by apply/orthogonal2P; rewrite dotmulE sum2E !mxE /= -?expr2 ?sqrrN ?cos2Dsin2 //
   ?(mulrC (cos a)) ?mulNr addrC ?subrr // ?cos2Dsin2.
Qed.

Lemma RO_is_SO R (a : angle R) : RO a \is 'SO[R]_2.
Proof.
by rewrite rotationE RO_is_O /= det_mx22 !mxE /= mulrN opprK -!expr2 cos2Dsin2.
Qed.

Lemma rot2d_helper {R : rcfType} (M : 'M[R]_2) a b :
  a - b = - pihalf R ->
  M = col_mx2 (row2 (cos a) (sin a)) (row2 (cos b) (sin b)) ->
  exists a0 : angle R, M = RO a0.
Proof.
move=> abpi.
have -> : sin b = cos a.
  by move/eqP : (abpi); rewrite subr_eq => /eqP ->; rewrite addrC cosBpihalf.
have -> : cos b = - sin a.
  by move/eqP : (abpi); rewrite subr_eq => /eqP ->; rewrite addrC sinBpihalf opprK.
move=> ->; by exists a.
Qed.

Lemma rot2d {R : rcfType} (M : 'M[R]_2) : M \is 'SO[R]_2 ->
  exists a, M = RO a.
Proof.
move=> MSO.
move: (MSO); rewrite rotationE => /andP[MO _].
case: (sqr_normr_cossin (norm_row_of_O MO 0)); rewrite !mxE => a [a1 a2].
case: (sqr_normr_cossin (norm_row_of_O MO 1)); rewrite !mxE => b [b1 b2].
move/orthogonalP : (MO) => /(_ 0 1) /=.
rewrite dotmulE sum2E !mxE a1 a2 b1 b2 -cosB.
case/cos0_inv => [abpi|].
  exfalso.
  move/rotation_det : MSO.
  rewrite det_mx22 a1 a2 b1 b2 mulrC -(mulrC (cos b)) -sinB => /esym/eqP.
  rewrite -eqr_opp -sinN opprB abpi sin_pihalf -subr_eq0.
  by rewrite -opprD eqr_oppLR oppr0 -(natrD _ 1 1) pnatr_eq0.
move/(@rot2d_helper _ M a b); apply.
by rewrite -a1 -a2 -b1 -b2 [in LHS](col_mx2_rowE M) 2!row2_of_row.
Qed.

Definition RO' {R : rcfType} (a : angle R) :=
  col_mx2 (row2 (cos a) (sin a)) (row2 (sin a) (- cos a)).

Lemma rot2d_helper' {R : rcfType} (M : 'M[R]_2) a b :
  a - b = pihalf R ->
  M = col_mx2 (row2 (cos a) (sin a)) (row2 (cos b) (sin b)) ->
  exists a0, M = RO' a0.
Proof.
move=> /eqP abpi.
have -> : sin b = - cos a.
  by move: (abpi); rewrite subr_eq => /eqP ->; rewrite addrC cosDpihalf opprK.
have -> : cos b = sin a.
  by move : (abpi); rewrite subr_eq => /eqP ->; rewrite addrC sinDpihalf.
move=> ->; by exists a.
Qed.

Lemma rot2d' (R : rcfType) (M : 'M[R]_2) : M \is 'O[R]_2 ->
  exists a : angle R, (M = RO a \/ M = RO' a).
Proof.
move=> MO.
case: (sqr_normr_cossin (norm_row_of_O MO 0)); rewrite !mxE => a [a1 a2].
case: (sqr_normr_cossin (norm_row_of_O MO 1)); rewrite !mxE => b [b1 b2].
move/orthogonalP : (MO) => /(_ 0 1) /=.
rewrite dotmulE sum2E !mxE a1 a2 b1 b2 -cosB.
have HM : M = col_mx2 (row2 (cos a) (sin a)) (row2 (cos b) (sin b)).
  by rewrite -a1 -a2 -b1 -b2 [in LHS](col_mx2_rowE M) 2!row2_of_row.
case/cos0_inv => [|abpi].
  case/(@rot2d_helper' _ M)/(_ HM) => a0.
  exists a0; by right.
case: (rot2d_helper abpi HM) => a0 KM.
exists a0; by left.
Qed.

Lemma tr_SO2 {R : rcfType} (P : 'M[R]_2) : P \is 'SO[R]_2 -> `|\tr P| <= 2%:R.
Proof.
case/rot2d => a PRO; move: (cos_max a) => ca.
rewrite PRO tr_RO -(mulr_natr (cos a)) normrM normr_nat.
by rewrite -[in X in _ <= X]mulr_natr ler_pmul.
Qed.

Section colinear.

Variable R : rcfType.
Implicit Type u v : 'rV[R]_3.

Lemma colinearP u v :
  reflect (v == 0 \/
           (v != 0 /\ exists k, `| k | = norm u / norm v /\ u = k *: v))
          (colinear u v).
Proof.
apply: (iffP idP); last first.
  case => [/eqP ->|]; first by rewrite colinear_sym colinear0.
  case => v0 [k [k0 ukv]].
  by rewrite /colinear ukv crossmulC linearZ /= crossmulvv scaler0 oppr0.
rewrite /colinear => uv.
case/boolP : (v == 0) => v0; [by left | right; split; first by done].
case/boolP : (u == 0) => u0.
  by exists (norm u / norm v); rewrite (eqP u0) norm0 mul0r normr0 scale0r.
have : vec_angle u v = 0 \/ vec_angle u v = pi.
  rewrite /vec_angle (eqP uv) norm0.
  case: (lerP 0 (u *d v)) => udv; [left | right].
    rewrite arg_Re // ltr_neqAle udv andbT.
    apply/eqP => /esym/eqP/dotmul_eq0_crossmul_neq0.
    by rewrite u0 v0 uv => /(_ isT isT).
  by rewrite arg_Re_neg.
case => [ /(vec_angle0_inv u0 v0) | /(vec_anglepi_inv u0 v0)] ukv.
  exists (norm u / norm v); split => //.
  by rewrite ger0_norm // divr_ge0 // norm_ge0.
exists (- (norm u / norm v)); split => //.
by rewrite normrN ger0_norm // divr_ge0 // norm_ge0.
Qed.

End colinear.

Section non_oriented_frame.

Variable R : rcfType.
Implicit Type p : 'rV[R]_3.
Variables i j k : 'rV[R]_3.

CoInductive oframe := mkOFrame of
  norm i = 1 & norm j = 1 & norm k = 1 &
  i *d j = 0 & j *d k = 0 & i *d k = 0.

Lemma orthogonal_expansion_helper : oframe ->
  forall p, p *d i = 0 -> p *d j = 0 -> p *d k = 0 -> p = 0.
Proof.
case=> ni nj nk ij jk ik p.
do 3 rewrite dotmulE sum3E.
move=> H1 H2 H3.
have /eqP : p *m (col_mx3 i j k) ^T = 0.
  by rewrite col_mx3_mul dotmulE sum3E H1 dotmulE sum3E H2 dotmulE sum3E H3 row30.
rewrite mul_mx_rowfree_eq0; first by move/eqP.
apply/row_freeP; exists (col_mx3 i j k).
apply/eqP; rewrite -orthogonalEC.
apply matrix_is_orthogonal; by rewrite !rowK.
Qed.

Lemma orthogonal_expansion p : oframe ->
  p = (p *d i) *: i + (p *d j) *: j + (p *d k) *: k.
Proof.
case=> x1 y1 z1 xy xz yz.
set y : 'rV[R]_3 := (p *d i) *: i + (p *d j) *: j + (p *d k) *: k.
suff /eqP : p - y = 0; first by rewrite subr_eq0 => /eqP.
apply orthogonal_expansion_helper.
- by apply mkOFrame.
- rewrite dotmulDl dotmulNv /y 2!dotmulDl dotmulZv dotmulvv x1 expr1n mulr1.
  rewrite 2!opprD 2!addrA subrr add0r dotmulZv (dotmulC j) xy mulr0 oppr0.
  by rewrite dotmulZv (dotmulC k) yz mulr0 subrr.
- rewrite dotmulDl dotmulNv /y 2!dotmulDl dotmulZv xy mulr0 add0r.
  rewrite dotmulZv dotmulvv y1 expr1n mulr1 opprD addrA subrr.
  by rewrite dotmulZv (dotmulC k) xz mulr0 subrr.
- rewrite dotmulDl dotmulNv /y 2!dotmulDl dotmulZv yz mulr0 add0r dotmulZv.
  by rewrite xz mulr0 add0r dotmulZv dotmulvv z1 expr1n mulr1 subrr.
Qed.

Definition frame_sgn (_ : oframe) := i *d (j *v k).

Lemma normi (f : oframe) : norm i = 1. Proof. by case: f. Qed.
Lemma normj (f : oframe) : norm j = 1. Proof. by case: f. Qed.
Lemma normk (f : oframe) : norm k = 1. Proof. by case: f. Qed.

Lemma idotj (f : oframe) : i *d j = 0. Proof. by case: f. Qed.
Lemma jdotk (f : oframe) : j *d k = 0. Proof. by case: f. Qed.
Lemma idotk (f : oframe) : i *d k = 0. Proof. by case: f. Qed.

Lemma frame_sgn1 (f : oframe) : `| frame_sgn f | = 1.
Proof.
case: f => x1 y1 z1 xy yz xz; rewrite /frame_sgn crossmul_triple.
apply/orthogonal_det/matrix_is_orthogonal; by rewrite !rowK.
Qed.

Lemma oframek (f : oframe) : k = i *v j \/ k = - i *v j.
Proof.
move: (frame_sgn1 f).
case: (lerP 0 (i *d (j *v k))) => H.
  rewrite ger0_norm // => {H}.
  rewrite /frame_sgn dotmul_crossmulA.
  move/dotmul1_inv => H; left; rewrite H //.
  case: f => He1 He2 ? e1e2 *.
  rewrite norm_crossmul He1 He2 2!mul1r cos0sin1 //.
  do 2 rewrite -[LHS](mul1r).
  rewrite -{1}He1 -He2 mulrA.
  by rewrite -dotmul_cos.
  by case: f.
rewrite ltr0_norm // => {H} /eqP.
rewrite eqr_oppLR => /eqP.
rewrite /frame_sgn dotmul_crossmulA.
move/dotmulN1_inv => H; right. rewrite crossmulNv H // ?opprK //.
case: f => He1 He2 ? e1e2 *.
rewrite norm_crossmul He1 He2 2!mul1r cos0sin1 //.
do 2 rewrite -[LHS](mul1r).
rewrite -{1}He1 -He2 mulrA.
by rewrite -dotmul_cos.
by case: f.
Qed.

Lemma oframe_pos (f : oframe) : k = i *v j -> frame_sgn f = 1.
Proof.
move=> H.
rewrite /frame_sgn H double_crossmul dotmulvv (dotmulC j).
case: f => normu1 -> _ -> _ _.
by rewrite scale0r subr0 expr1n scale1r dotmulvv normu1 expr1n.
Qed.

Lemma oframe_neg (f : oframe) : k = - i *v j -> frame_sgn f = - 1.
Proof.
move=> H.
rewrite /frame_sgn H double_crossmul dotmulvv dotmulvN scaleNr opprK (dotmulC j).
case: f => normu1 -> _ -> _ _.
by rewrite scale0r addr0 expr1n scale1r dotmulvN dotmulvv normu1 expr1n.
Qed.

Lemma frame_pos_crossmul (f : oframe) : frame_sgn f = 1 -> k = i *v j.
Proof.
case: (oframek f) => // /(oframe_neg f) -> /esym/eqP.
by rewrite -subr_eq0 opprK -mulr2n pnatr_eq0.
Qed.

Lemma oframe_posP (f : oframe) : k = i *v j -> j = k *v i /\ i = j *v k.
Proof.
move=> H; split.
  rewrite H crossmulC double_crossmul.
  case: f => x1 ? ? K *.
  by rewrite K scale0r add0r opprK dotmulvv x1 expr1n scale1r.
rewrite H double_crossmul.
case: f => ? y1 ? K *.
by rewrite dotmulvv y1 expr1n scale1r dotmulC K scale0r subr0.
Qed.

Lemma oframe_negP (f : oframe) : k = - i *v j -> j = i *v k /\ i = k *v j.
Proof.
move=> H; split.
  rewrite H crossmulNv crossmulvN double_crossmul.
  case: f => x1 ? ? K *.
  by rewrite dotmulvv x1 expr1n scale1r K scale0r add0r opprK.
rewrite H crossmulNv crossmulC crossmulvN opprK double_crossmul.
case: f => ? y1 ? K *.
by rewrite dotmulvv y1 expr1n scale1r dotmulC K scale0r subr0.
Qed.

(* lemma 3.5, p.110, o'neill *)
Lemma crossmul_oframe_sgn (f : oframe) v v1 v2 v3 w w1 w2 w3 :
  v = v1 *: i + v2 *: j + v3 *: k ->
  w = w1 *: i + w2 *: j + w3 *: k ->
  v *v w = frame_sgn f *: ((v2 * w3 - v3 * w2) *: i -
                           (v1 * w3 - v3 * w1) *: j +
                           (v1 * w2 - v2 * w1) *: k).
Proof.
move=> -> ->.
rewrite !linearD /=.
rewrite !linearZ /=.
rewrite (crossmulC _ i).
rewrite (crossmulC _ j).
rewrite (crossmulC _ k).
rewrite !linearD /=.
rewrite (_ : _ *v _ = 0); last by rewrite linearZ /= crossmulvv scaler0.
rewrite oppr0 scaler0 add0r.
case: (oframek f) => e3e1e2.
  case: (oframe_posP f e3e1e2) => H1 H2.
  rewrite (_ : _ *v _ = v2 *: k); last by rewrite linearZ /= -e3e1e2.
  rewrite scalerN (_ : _ *v _ = - v3 *: j); last first.
    by rewrite linearZ /= crossmulC -H1 scalerN scaleNr.
  rewrite scaleNr opprK (_ : _ *v _ = - v1 *: k); last first.
    by rewrite linearZ /= crossmulC e3e1e2 scalerN scaleNr.
  rewrite scaleNr opprK (_ : _ *v _ = 0); last by rewrite linearZ /= crossmulvv scaler0.
  rewrite scalerN scaler0 subr0.
  rewrite (_ : _ *v _ = v3 *: i); last by rewrite linearZ /= -H2.
  rewrite scalerN (_ : _ *v _ = v1 *: j); last by rewrite linearZ /= H1.
  rewrite scalerN (_ : _ *v _ = - v2 *: i); last first.
    by rewrite linearZ /= crossmulC -H2 scaleNr scalerN.
  rewrite scaleNr opprK (_ : _ *v _ = 0); last first.
    by rewrite linearZ /= crossmulvv scaler0.
  rewrite scalerN scaler0 subr0.
  rewrite (oframe_pos f e3e1e2).
  rewrite !scale1r -![in LHS]addrA addrC.
  rewrite -![in LHS]addrA.
  rewrite addrCA.
  rewrite addrC.
  rewrite ![in LHS]addrA.
  rewrite -addrA; congr (_ + _); last first.
    by rewrite !scalerA -scaleNr -scalerDl /= addrC mulrC (mulrC w1).
  rewrite -addrA addrACA addrC; congr (_ + _).
    by rewrite -scaleNr !scalerA -scalerDl addrC mulrC mulNr (mulrC w2).
  by rewrite !scalerA -scalerBl scalerN -scaleNr opprB mulrC (mulrC w3).
case: (oframe_negP f e3e1e2) => H1 H2.
rewrite (_ : _ *v _ = - v2 *: k); last first.
  by rewrite linearZ /= e3e1e2 crossmulNv scalerN scaleNr opprK.
rewrite scaleNr opprK.
rewrite (_ : _ *v _ = v3 *: j); last first.
  by rewrite linearZ /= -H1.
rewrite scalerN.
rewrite (_ : _ *v _ = v1 *: k); last first.
  by rewrite linearZ /= crossmulC -crossmulNv -e3e1e2.
rewrite scalerN.
rewrite (_ : _ *v _ = 0); last first.
  by rewrite linearZ /= crossmulvv scaler0.
rewrite oppr0 scaler0 addr0.
rewrite (_ : _ *v _ = - v3 *: i); last first.
  by rewrite linearZ /= crossmulC -H2 scalerN scaleNr.
rewrite scaleNr opprK.
rewrite (_ : _ *v _ = - v1 *: j); last first.
  by rewrite linearZ /= crossmulC -H1 scalerN scaleNr.
rewrite scaleNr opprK.
rewrite (_ : _ *v _ = v2 *: i); last first.
  by rewrite linearZ /= -H2.
rewrite scalerN.
rewrite (_ : _ *v _ = 0); last first.
  by rewrite linearZ /= crossmulvv scaler0.
rewrite oppr0 scaler0 addr0.
rewrite (oframe_neg f e3e1e2).
rewrite -![in LHS]addrA addrC -addrA.
rewrite addrCA -addrA addrC ![in LHS]addrA -addrA; congr (_ + _); last first.
  by rewrite !scalerA -scalerBl mulrN1 opprB mulrC (mulrC w2).
rewrite -addrA addrACA; congr (_ + _).
  by rewrite !scalerA -scalerBl mulrN1 opprB mulrC (mulrC w3).
by rewrite !scalerA -scalerBl scalerN mulrN1 scaleNr opprK mulrC (mulrC w1).
Qed.

End non_oriented_frame.

Coercion matrix_of_oframe (R : rcfType) (i j k : 'rV[R]_3) (f : oframe i j k) :=
  col_mx3 i j k.

Section orthonormal_frame.

Variable R : rcfType.
Let vector := 'rV[R]_3.
Let coordinate := 'rV[R]_3.
Implicit Types p : coordinate.
Implicit Types i j k : vector.

Record pframe i j k := mkPFrame {
  oframe_of_pframe :> oframe i j k ;
  pframeP : frame_sgn oframe_of_pframe = 1}.

Record nframe i j k := mkNFrame {
  oframe_of_nframe :> oframe i j k ;
  nframeP : frame_sgn oframe_of_nframe = -1}.

(*Definition matrix_of_pframe i j k (f : pframe i j k) := col_mx3 i j k.*)

Lemma icrossj i j k (f : pframe i j k) : k = i *v j.
Proof. exact: (frame_pos_crossmul (pframeP f)). Qed.
Lemma icrossk i j k (f : pframe i j k) : i *v k = - j.
Proof. by rewrite (proj1 (oframe_posP f (icrossj f))) crossmulC. Qed.
Lemma jcrossk i j k (f : pframe i j k) : j *v k = i.
Proof. by rewrite -(proj2 (oframe_posP f (icrossj f))). Qed.

Lemma pframe_swap01 i j k : pframe i j k -> pframe j (- i) k.
Proof.
case => -[] i1 j1 k1 ij jk ik Hsgn.
apply: mkPFrame.
  apply: mkOFrame => //.
  by rewrite normN.
  by rewrite dotmulvN dotmulC ij oppr0.
  by rewrite dotmulNv ik oppr0.
move=> f.
rewrite /frame_sgn dotmul_crossmulA linearN /= crossmulC -(icrossj (mkPFrame Hsgn)).
by rewrite opprK dotmulvv k1 expr1n.
Qed.

Lemma pframe_is_rot i j k (f : pframe i j k) : col_mx3 i j k \in 'SO[R]_3.
Proof.
move: (icrossj f) => Hk.
case: f => -[? ? ? ? ? ?] sgn.
by apply matrix_is_rotation; rewrite !rowK.
Qed.

Record frame := mkFrame {
  framei : vector ;
  framej : vector ;
  framek : vector ;
  frameP :> pframe framei framej framek }.

(*Coercion matrix_of_frame (f : frame) := col_mx3 (framei f) (framej f) (framek f).*)

Lemma row0_frame (f : frame) : row 0 f = framei f.
Proof. case: f => x y z xyz /=; apply/rowP => i; by rewrite 2!mxE. Qed.
Lemma row1_frame (f : frame) : row 1 f = framej f.
Proof. case: f => x y z xyz /=; apply/rowP => i; by rewrite 2!mxE. Qed.
Lemma row2_frame (f : frame) : row 2%:R f = framek f.
Proof. case: f => x y z xyz /=; apply/rowP => i; by rewrite !mxE. Qed.

Lemma norm_row (f : frame) (i : 'I_3) : norm (row i f) = 1.
Proof.
case: f => a b c [] [] a1 b1 c1 H1 H2 H3 Hsgn.
case/boolP : (i == 0) => [/eqP ->|]; first by rewrite row0_frame /=.
rewrite ifnot0 => /orP [] /eqP ->; by [rewrite row1_frame | rewrite row2_frame].
Qed.

(* frame with an origin (tangent frame ?) *)
CoInductive tframe (p : coordinate) (i j k : vector) :=
  TFrame : oframe i j k -> tframe p i j k.
Definition oframe_of_tframe p i j k (f : tframe p i j k) :=
  let: TFrame f := f in f.

Lemma tframe_trans p i j k (f : tframe p i j k) t : tframe (p + t) i j k.
Proof. by case: f => -[] x1 y1 z1 xy yz xz. Qed.

End orthonormal_frame.

Module canonical_frame.
Section canonical_frame.
Variable R : rcfType.
Let vector := 'rV[R]_3.
Let coordinate := 'rV[R]_3.
Implicit Type p : coordinate.
(* TODO: turn V.i, V.j, V.k into e0, e1, e2 *)
Definition i : vector := row3 1 0 0.
Definition j : vector := row3 0 1 0.
Definition k : vector := row3 0 0 1.

Lemma idotj : i *d j = 0. Proof. by rewrite dotmulE sum3E !mxE /=; Simp.r. Qed.
Lemma jdotk : j *d k = 0. Proof. by rewrite dotmulE sum3E !mxE /=; Simp.r. Qed.
Lemma idotk : i *d k = 0. Proof. by rewrite dotmulE sum3E !mxE /=; Simp.r. Qed.

Lemma normi : norm i = 1.
Proof. by rewrite /norm dotmulE sum3E !mxE /=; Simp.r; rewrite sqrtr1. Qed.
Lemma normj : norm j = 1.
Proof. by rewrite /norm dotmulE sum3E !mxE /=; Simp.r; rewrite sqrtr1. Qed.
Lemma normk : norm k = 1.
Proof. by rewrite /norm dotmulE sum3E !mxE /=; Simp.r; rewrite sqrtr1. Qed.

Lemma icoor p : p 0 0 = p *d i.
Proof. by rewrite /dotmul mxE sum3E !mxE /=; Simp.r. Qed.
Lemma jcoor p : p 0 1 = p *d j.
Proof. by rewrite /dotmul mxE sum3E !mxE /=; Simp.r. Qed.
Lemma kcoor p : p 0 2%:R = p *d k.
Proof. by rewrite /dotmul mxE sum3E !mxE /=; Simp.r. Qed.

Definition oframe := mkOFrame normi normj normk idotj jdotk idotk.
Lemma pframeP : frame_sgn oframe = 1.
Proof. rewrite /frame_sgn crossmulE dotmulE sum3E !mxE /=. by Simp.r. Qed.
Definition pframe := mkPFrame pframeP.
Definition frame := mkFrame pframe.

Lemma framei a : frame 0 a = i 0 a.
Proof. by rewrite mxE. Qed.
Lemma framej a : frame 1 a = j 0 a.
Proof. by rewrite mxE. Qed.
Lemma framek a : frame 2%:R a = k 0 a.
Proof. by rewrite mxE. Qed.

End canonical_frame.
End canonical_frame.

Module V := canonical_frame.
Arguments V.i [_].
Arguments V.j [_].
Arguments V.k [_].

Module frame_of_vector.
Section frame_of_vector.
Variable R : rcfType.
Variable u : 'rV[R]_3.
Hypothesis u0 : u != 0.

(* TODO: useful? *)
Lemma j_of_i_colinear (uVi : colinear u V.i) :
  normalcomp V.j (normalize u) = V.j.
Proof.
rewrite ortho_normalcomp // dotmulvZ.
case/colinearP : uVi => [|[_ [k [Hk uki]]]].
  by rewrite -norm_eq0 V.normi (negbTE (@oner_neq0 _)).
by rewrite {2}uki dotmulvZ dotmulC V.idotj 2!mulr0.
Qed.

Definition j :=
  if colinear u V.i then V.j else normalize (normalcomp V.i (normalize u)).
Definition k := normalize u *v j.

Lemma idotj : u *d j = 0.
Proof.
rewrite /j; case: ifPn => iVi.
  case/colinearP : iVi => [| [_ [k [Hk ->]]]].
    by rewrite -norm_eq0 V.normi (negbTE (oner_neq0 _)).
  by rewrite dotmulZv V.idotj mulr0.
by rewrite dotmulvZ normalcompP mulr0.
Qed.
Lemma idotk : u *d k = 0.
Proof. by rewrite /k dotmul_crossmulA linearZ /= crossmulvv scaler0 dotmul0v. Qed.
Lemma jdotk : j *d k = 0.
Proof. by rewrite /k dotmul_crossmulCA crossmulvv dotmulv0. Qed.

Lemma normj : norm j = 1.
Proof.
rewrite /j; case: ifPn => iVi; first by rewrite V.normj.
rewrite norm_normalize //; apply: contra iVi => /eqP/normalcomp_colinear.
by rewrite /normalize colinear_sym colinearZv invr_eq0 norm_eq0 (negPf u0).
Qed.

Lemma normk : norm k = 1.
Proof.
rewrite /k norm_crossmul_normal // ?norm_normalize // ?normj //.
by rewrite /normalize dotmulZv idotj // mulr0.
Qed.

Lemma oframe_of : oframe (normalize u) j k.
Proof.
apply: mkOFrame.
by rewrite norm_normalize.
by rewrite normj.
by rewrite normk.
by rewrite /normalize dotmulZv idotj mulr0.
by rewrite jdotk.
by rewrite dotmulZv idotk mulr0.
Qed.

Lemma sgn_oframe_of : frame_sgn oframe_of = 1.
Proof.
case: oframe_of => /= ? ? H ? ? ?.
by rewrite /frame_sgn /= dotmul_crossmulA dotmulvv H expr1n.
Qed.

Definition pframe_of: pframe (normalize u) j k := mkPFrame sgn_oframe_of.

Lemma pframe_of_is_unit : matrix_of_oframe pframe_of \is a GRing.unit.
Proof. by apply/orthogonal_unit/rotation_sub/pframe_is_rot/pframe_of. Qed.

End frame_of_vector.

Section frame_of_vector_lemmas.

Variable (R : rcfType).

Lemma je0 : j (@V.i R) = V.j.
Proof. by rewrite /j colinear_refl. Qed.

Lemma ke0 : k (@V.i R) = V.k.
Proof. by rewrite /k (normalizeI (V.normi _)) je0 -(icrossj (V.frame _)). Qed.

Variable u : 'rV[R]_3.
Hypothesis u0 : u != 0.

Lemma jZ k (k0 : 0 < k) : j (k *: u) = j u.
Proof.
rewrite /j; case: ifPn; rewrite colinearZv ?(gtr_eqF k0) /=; first by move-> .
by move/negPf->; rewrite normalizeZ.
Qed.

Lemma jN : j (- u) = j u.
Proof.
rewrite /j colinearNv; case: ifPn => //; by rewrite normalizeN normalcompvN.
Qed.

Lemma kZ p (p0 : 0 < p) : k (p *: u) = k u.
Proof. by rewrite /k jZ // normalizeZ. Qed.

Lemma kN : k (- u) = - k u.
Proof. by rewrite /k normalizeN jN // crossmulNv. Qed.

End frame_of_vector_lemmas.

End frame_of_vector.

Module W := frame_of_vector.


(*Module Frame.
Section frame_section.
Variable R : rcfType.
Local Notation coordinate := 'rV[R]_3.
Local Notation basisType := 'M[R]_3.
Definition x_ax : basisType -> 'rV[R]_3 := row 0.
Definition y_ax : basisType -> 'rV[R]_3 := row 1%R.
Definition z_ax : basisType -> 'rV[R]_3 := row 2%:R.

Record t := mkT {
  origin : coordinate ;
  basis :> basisType ;
  _ : unitmx basis }.

Lemma unit (f : t) : basis f \in GRing.unit. Proof. by case: f. Qed.
End frame_section.
End Frame.

Coercion Framebasis R (f : Frame.t R) : 'M[R]_3 := Frame.basis f.
*)
(*Hint Immediate Frame.unit.*)

Inductive vec {R} (f : frame R) : Type := Vec of 'rV[R]_3.

Definition vec_of {R} (f : frame R) (x : vec f) := let: Vec v := x in v.

(* consider "frame" to be w.r.t. the canonical frame *)
(* x *m f : *rotate* a vector in the canonical frame according to the frame
  (we obtain a new vector but still in the canonical frame after rotation)
 rotational operator *)
Definition rotate_wrt_frame R (f : frame R) (x : vec (V.frame R)) : vec (V.frame R) :=
  Vec _ (vec_of x *m f).

(* TODO: move *)
Lemma mulmx_can_frame {R : rcfType} (x : 'rV[R]_3) : x *m V.frame R = x.
Proof.
apply/rowP => i.
case/boolP : (i == 0) => [/eqP -> |].
  rewrite mxE sum3E V.framei V.framej V.framek !mxE /=; by Simp.r.
rewrite ifnot0 => /orP [] /eqP ->;
  rewrite mxE sum3E V.framei V.framej V.framek !mxE /=; by Simp.r.
Qed.

Lemma rotate_wrt_canonical_frame {R} (x : vec (V.frame R)) :
  rotate_wrt_frame (V.frame R) x = x.
Proof. case: x => x; congr Vec => /=; by rewrite mulmx_can_frame. Qed.

(* change of coordinates: same vector but with coord in the canonical frame *)
(* "mapping" from frame f to canonical frame *)
Definition can_of_rel_coord {R} (f : frame R) (x : vec f) : vec (V.frame R) :=
  Vec _ (vec_of x *m f).

(* change of coordinates: same vector but with coord given in f *)
Definition rel_of_can_coord {R} (f : frame R) (x : vec (V.frame R)) : vec f :=
  Vec _ (vec_of x *m f^T).

Lemma can_of_rel_coordK {R} (f : frame R) (x : vec f) :
  rel_of_can_coord _ (can_of_rel_coord x) = x.
Proof.
rewrite /rel_of_can_coord /can_of_rel_coord /=; case: x => x; congr Vec => /=.
rewrite -mulmxA -(rotation_inv (pframe_is_rot f)) mulmxV ?mulmx1 // unitmxE.
by rewrite (rotation_det (pframe_is_rot f)) unitr1.
Qed.

Lemma rel_of_can_coordK {R} (f : frame R) (x : vec _) :
  can_of_rel_coord (rel_of_can_coord f x) = x.
Proof.
rewrite /rel_of_can_coord /can_of_rel_coord /=; case: x => x; congr Vec => /=.
rewrite -mulmxA -(rotation_inv (pframe_is_rot f)) mulVmx ?mulmx1 // unitmxE.
by rewrite (rotation_det (pframe_is_rot f)) unitr1.
Qed.

(*Section about_frame.

Variable R : rcfType.
Let coordinate := 'rV[R]_3.
Let vector := 'rV[R]_3.
Let frame := Frame.t R.

(* coordinate in frame f *)
Inductive coor (f : frame) : Type := Coor of 'rV[R]_3.

Definition absolute_coor (f : frame) (x : coor f) : 'rV[R]_3 :=
  match x with Coor v => Frame.origin f + v *m Frame.basis f end.

Definition relative_coor f (x : coordinate) : coor f :=
  Coor _ ((x - Frame.origin f) *m (Frame.basis f)^-1).

Lemma absolute_coorK f (x : coor f) : relative_coor f (absolute_coor x) = x.
Proof.
case: x => /= v.
by rewrite /relative_coor addrC addKr -mulmxA mulmxV // ?mulmx1 // Frame.unit.
Qed.

Lemma relative_coorK f (x : coordinate) : absolute_coor (relative_coor f x) = x.
Proof. by rewrite /= -mulmxA mulVmx // ?Frame.unit // mulmx1 addrC addrNK. Qed.

(* vector in frame f *)
Inductive vec (f : frame) : Type := Vec of 'rV[R]_3.

Definition absolute_vec f (x : vec f) : 'rV[R]_3 :=
  match x with Vec v => v *m Frame.basis f end.

Definition relative_vec f (x : vector) : vec f :=
  Vec _ (x *m (Frame.basis f)^-1).

Lemma absolute_vecK f (x : vec f) : relative_vec f (absolute_vec x) = x.
Proof. case: x => /= v. by rewrite /relative_vec -mulmxA mulmxV // ?Frame.unit // mulmx1. Qed.

Lemma relative_vecK f (x : vector) : absolute_vec (relative_vec f x) = x.
Proof. by rewrite /= -mulmxA mulVmx // ?Frame.unit // mulmx1. Qed.

End about_frame.*)

(* TODO: useful? *)
Lemma abs {R:rcfType} (f : frame R) i j : f i j = row j (V.frame R) *d row i f.
Proof.
case/boolP : (i == 0) => [/eqP ->|].
  case/boolP : (j == 0) => [/eqP ->|].
    rewrite row0_frame /= dotmulE sum3E ![(row3 _ _ _) _ _]mxE /=.
    by rewrite !(mul1r,mul0r,addr0,add0r) [in RHS]mxE.
  rewrite ifnot0 => /orP [] /eqP ->.
    rewrite row1_frame /= dotmulE sum3E ![(row3 _ _ _) _ _]mxE /=.
    by rewrite !(mul1r,mul0r,addr0,add0r) [in RHS]mxE.
  rewrite row2_frame /= dotmulE sum3E ![(row3 _ _ _) _ _]mxE /=.
  by rewrite !(mul1r,mul0r,addr0,add0r) [in RHS]mxE.
rewrite ifnot0 => /orP [] /eqP ->.
  case/boolP : (j == 0) => [/eqP ->|].
    rewrite row0_frame /= dotmulE sum3E ![(row3 _ _ _) _ _]mxE /=.
    by rewrite !(mul1r,mul0r,addr0,add0r) [in RHS]mxE.
  rewrite ifnot0 => /orP [] /eqP ->.
    rewrite row1_frame /= dotmulE sum3E ![(row3 _ _ _) _ _]mxE /=.
    by rewrite !(mul1r,mul0r,addr0,add0r) [in RHS]mxE.
  rewrite row2_frame /= dotmulE sum3E ![(row3 _ _ _) _ _]mxE /=.
  by rewrite !(mul1r,mul0r,addr0,add0r) [in RHS]mxE.
case/boolP : (j == 0) => [/eqP ->|].
  rewrite row0_frame /= dotmulE sum3E ![(row3 _ _ _) _ _]mxE /=.
  by rewrite !(mul1r,mul0r,addr0,add0r) [in RHS]mxE.
rewrite ifnot0 => /orP [] /eqP ->.
  rewrite row1_frame /= dotmulE sum3E ![(row3 _ _ _) _ _]mxE /=.
  by rewrite !(mul1r,mul0r,addr0,add0r) [in RHS]mxE.
rewrite row2_frame /= dotmulE sum3E ![(row3 _ _ _) _ _]mxE /=.
by rewrite !(mul1r,mul0r,addr0,add0r) [in RHS]mxE.
Qed.

Module FromTo.
Section tmp.
Variable R : rcfType.
Variables A B : frame R.
Record t := mkT {
  M :> 'M[R]_3 ;
  HM : M == \matrix_(i, j) (row i A^T *d row j B^T)
  (* transpose of def 1.1 of handbook ->
     "orientation of coor frame B related to coor frame A" (A ^R_ B) *)
}.
End tmp.
End FromTo.
Coercion RotM {R} (A B : frame R) := @FromTo.M _ A B.

Notation "A %> B" := (@FromTo.t _ A B) (at level 5).

Lemma FromToE R (A B : frame R) (M : A %> B) :
  M = (matrix_of_oframe A)^-1 *m B :> 'M[R]_3.
Proof.
case: M => /= M /eqP ->; apply/matrixP => i j.
rewrite mxE dotmulE /= mxE; apply eq_bigr => /= k _.
by rewrite mxE [row _ _ _ _]mxE mxE (rotation_inv (pframe_is_rot A)) 2![_^T _ _]mxE.
Qed.

Lemma FromToCan R (A : frame R) (M : A %> (V.frame R)) (x : vec A) :
  [fun x : 'rV_3 => x *m M] =1 [fun x => x *m A^T].
Proof.
move=> i /=.
by rewrite (FromToE M) mulmxA mulmx_can_frame (rotation_inv (pframe_is_rot A)).
Qed.


Lemma FromToPi R (A B : frame R) (M : A %> B) : framei A *m M = framei B.
Proof.
rewrite (FromToE M) mulmxA (_ : (matrix_of_oframe A)^-1 = A^T); last first.
  by apply/rotation_inv/(pframe_is_rot A).
rewrite /matrix_of_oframe.
rewrite col_mx3_mul dotmulvv (normi A) expr1n (idotj A) (idotk A).
rewrite row3_row_mx col_mx3E.
rewrite (mul_row_col 1%:M) mul1mx (mul_row_col 0%:M).
by rewrite !mul_scalar_mx scale0r scale0r 2!addr0.
Qed.

Lemma FromTo_is_SO R (A B : frame R) (M : A %> B) : FromTo.M M \is 'SO[R]_3.
Proof.
move: (FromToE M).
case: M => /= M _ ->.
by rewrite rpredM // ?(pframe_is_rot B) // rotation_inv // ?rotationV // (pframe_is_rot A).
Qed.

Lemma FromToComp_proof R (A B C : frame R) (M1 : A %> B) (M2 : B %> C) :
  (M1 *m M2) == \matrix_(i, j) (row i A^T *d row j C^T).
Proof.
rewrite (FromToE M1) (FromToE M2) -mulmxA (mulmxA B).
rewrite mulmxV; last first.
  by rewrite unitmxE (rotation_det (pframe_is_rot B)) unitr1.
rewrite mul1mx; apply/eqP/matrixP => i j.
rewrite !mxE dotmulE; apply/eq_bigr => k _.
by rewrite 2![row _ _ _ _]mxE (rotation_inv (pframe_is_rot A)) 2![_^T _ _]mxE mulrC.
Qed.

Definition FromToComp R (A B C : frame R) (M1 : A %> B) (M2 : B %> C) : A %> C :=
  FromTo.mkT (FromToComp_proof M1 M2).

Lemma FromToCompE R (A B : frame R) (M : A %> B) (u : 'rV[R]_3) :
  u *m M = u *m A^T *m B.
Proof. by rewrite -mulmxA (FromToE M) (rotation_inv (pframe_is_rot A)). Qed.

Module triad.
Section triad.
Variable R : rcfType.
Let coordinate := 'rV[R]_3.

Variables a b c : coordinate.
Hypothesis ab : a != b.
Hypothesis abc : ~~ colinear (b - a) (c - a).

Definition i := normalize (b - a).

Definition j := normalize (normalcomp (c - a) i).

Definition k := i *v j.

Definition t := (i, j, k).

Let ac : a != c.
Proof. by apply: contra abc => /eqP ->; rewrite subrr /colinear crossmulv0. Qed.

Lemma normi : norm i = 1.
Proof. by rewrite /i norm_normalize // subr_eq0 eq_sym. Qed.

Lemma i_neq0 : i != 0.
Proof. by rewrite -norm_eq0 normi oner_neq0. Qed.

Lemma normj : norm j = 1.
Proof.
rewrite /j norm_normalize //.
apply/eqP => /normalcomp_colinear; apply/negP; rewrite /i /normalize.
apply: contra (abc); rewrite colinear_sym colinearZv.
by rewrite invr_eq0 norm_eq0 subr_eq0 eq_sym (negPf ab).
Qed.

Lemma j_neq0 : j != 0.
Proof. by rewrite -norm_eq0 normj oner_neq0. Qed.

Lemma idotj : i *d j = 0.
Proof. by rewrite /= /i /j dotmulZv dotmulvZ normalcompP 2!mulr0. Qed.

Lemma jdotk : j *d k = 0.
Proof. by rewrite /k dotmul_crossmulCA crossmulvv dotmulv0. Qed.

Lemma idotk : i *d k = 0.
Proof. by rewrite /k dotmul_crossmulA crossmulvv dotmul0v. Qed.

Lemma normk : norm k = 1.
Proof. by rewrite norm_crossmul_normal // ?normi // ?normj // idotj. Qed.

Lemma k_neq0 : k != 0.
Proof. by rewrite -norm_eq0 normk oner_neq0. Qed.

Definition oframe : oframe _ _ _ := mkOFrame normi normj normk idotj jdotk idotk.

Lemma oframe_is_pos : frame_sgn oframe = 1.
Proof.
rewrite /frame_sgn /k double_crossmul dotmulvv normj expr1n scale1r (dotmulC j).
by rewrite idotj scale0r subr0 dotmulvv normi expr1n.
Qed.

Definition pframe : pframe _ _ _ := mkPFrame oframe_is_pos.
(* therefore, x * frame_triad^T turns a vector x in the canonical frame into the frame_triad *)

Lemma is_SO : col_mx3 i j k \is 'SO[R]_3.
Proof. exact: (pframe_is_rot pframe). Qed.

End triad.
End triad.

Section transformation_given_three_points.

Variable R : rcfType.
Let vector := 'rV[R]_3.
Let coordinate := 'rV[R]_3.

Variables l1 l2 l3 r1 r2 r3 : coordinate.
Hypotheses (l12 : l1 != l2) (r12 : r1 != r2).
Hypotheses (l123 : ~~ colinear (l2 - l1) (l3 - l1))
           (r123 : ~~ colinear (r2 - r1) (r3 - r1)).

Definition lframe := mkFrame (triad.pframe l12 l123).
Definition rframe := mkFrame (triad.pframe r12 r123).

Definition rot3 := lframe^T *m rframe.

Definition trans3 : vector := r1 - l1 *m rot3.

Lemma j_l_r : triad.j l1 l2 l3 *m rot3 = triad.j r1 r2 r3.
Proof.
rewrite /rot3 /= mulmxA col_mx3_mul dotmulC triad.idotj dotmulvv triad.normj //.
rewrite expr1n dotmul_crossmulCA crossmulvv dotmulv0 /matrix_of_oframe /=.
rewrite col_mx3E row3_row_mx (mul_row_col 0%:M) mul_scalar_mx scale0r add0r.
by rewrite (mul_row_col 1%:M) mul_scalar_mx scale1r mul_scalar_mx scale0r addr0.
Qed.

Lemma k_l_r : triad.k l1 l2 l3 *m rot3 = triad.k r1 r2 r3.
Proof.
rewrite /rot3 /= mulmxA col_mx3_mul {1}/triad.k dotmulC dotmul_crossmulA.
rewrite crossmulvv dotmul0v {1}/triad.k -dotmul_crossmulA crossmulvv dotmulv0.
rewrite /matrix_of_oframe /= dotmulvv triad.normk // expr1n col_mx3E row3_row_mx.
do 2 rewrite (mul_row_col 0%:M) mul_scalar_mx scale0r add0r.
by rewrite mul_scalar_mx scale1r.
Qed.

(* TODO: move? *)
Lemma mulmx_tr (M1 M2 : 'M[R]_3) : M1^T *m M2 = \matrix_(i < 3, j < 3) (row i M1^T *d row j M2^T).
Proof.
apply/matrixP => i j; rewrite /dotmul !mxE.
apply eq_bigr => /= k _; by rewrite !mxE.
Qed.

Definition FromLeftToRight : lframe %> rframe.
apply FromTo.mkT with (lframe^T *m rframe).
rewrite -(trmxK lframe) mulmx_tr.
apply/eqP/matrixP => i j; by rewrite [in LHS]mxE [in RHS]mxE dotmulC.
Qed.

Lemma FromLeftToRightE (u : 'rV[R]_3) : u *m FromLeftToRight = u *m rot3.
Proof. by rewrite FromToCompE /rot3 ?trmx_mul mulmxA. Qed.

End transformation_given_three_points.

Lemma basis_change (R : rcfType) (M : 'M[R]_3) i j k (f : oframe i j k) (A : 'M[R]_3) :
  i *m M = A 0 0 *: i + A 0 1 *: j + A 0 2%:R *: k ->
  j *m M = A 1 0 *: i + A 1 1 *: j + A 1 2%:R *: k ->
  k *m M = A 2%:R 0 *: i + A 2%:R 1 *: j + A 2%:R 2%:R *: k ->
  let P := col_mx3 i j k in
  M = P^-1 * A * P.
Proof.
move=> H1 H2 H3 P.
have : P * M = A * P.
  rewrite /P -mulmxE mulmx_col3 (col_mx3_rowE A).
  rewrite mulmx_col3 H1 H2 H3.
  congr col_mx3; apply/rowP => a; by rewrite !mxE sum3E !mxE.
rewrite -mulrA => <-.
rewrite mulrA mulVr ?mul1r // unitmxE unitfE /P det_col_mx3.
move: (frame_sgn1 f) => /=.
by rewrite /frame_sgn dotmul_crossmulA -normr_gt0 => ->; rewrite ltr01.
Qed.

Definition mx_lin1 (R : ringType) (M : 'M[R]_3) : {linear 'rV[R]_3 -> 'rV[R]_3} :=
  mulmxr_linear 1 M.

Section rot_axis_definition.

Variable R : rcfType.
Implicit Types a : angle R.

Definition Rx a := col_mx3
  (row3 1 0 0)
  (row3 0 (cos a) (sin a))
  (row3 0 (- sin a) (cos a)).

Lemma Rx_RO a : Rx a = block_mx (1 : 'M_1) (0 : 'M_(1, 2)) 0 (RO a).
Proof.
rewrite -(@submxK _ 1 2 1 2 (Rx a)).
rewrite (_ : ulsubmx _ = 1); last first.
  apply/rowP => i; by rewrite (ord1 i) !mxE /=.
rewrite (_ : ursubmx _ = 0); last first.
  apply/rowP => i; rewrite !mxE /=; case: ifPn => //; by case: ifPn.
rewrite (_ : dlsubmx _ = 0); last first.
  apply/colP => i; rewrite !mxE /=.
  case: ifPn; first by rewrite !mxE.
  by case: ifPn; rewrite !mxE.
rewrite (_ : drsubmx _ = RO a) //; by apply/matrix2P; rewrite !mxE.
Qed.

Lemma Rx_is_SO a : Rx a \is 'SO[R]_3.
Proof.
(* TODO: pove using RO_is_SO? *)
apply matrix_is_rotation.
- apply/eqP; rewrite -(@eqr_expn2 _ 2) // ?norm_ge0 // expr1n.
  rewrite -dotmulvv dotmulE sum3E !mxE /=. by Simp.r.
- apply/eqP; rewrite -(@eqr_expn2 _ 2) // ?norm_ge0 // expr1n.
- rewrite -dotmulvv dotmulE sum3E !mxE /=. Simp.r. by rewrite -!expr2 cos2Dsin2.
- rewrite 2!rowK /= dotmulE sum3E !mxE /=. by Simp.r.
- rewrite 3!rowK /= crossmulE !mxE /=. by Simp.r.
Qed.

Lemma tr_Rx a : \tr (Rx a) = 1 + cos a *+ 2.
Proof. by rewrite /Rx /mxtrace sum3E !mxE /= -addrA -mulr2n. Qed.

Lemma inv_Rx a : (Rx a)^-1 = Rx (- a).
Proof.
move/rotation_inv : (Rx_is_SO a) => ->.
rewrite /Rx cosN sinN opprK.
by apply/matrix3P; rewrite !mxE.
Qed.

Definition Rx' a := col_mx3
  (row3 1 0 0)
  (row3 0 (cos a) (sin a))
  (row3 0 (sin a) (- cos a)).

Lemma det_Rx' a : \det (Rx' a) = -1.
Proof.
rewrite det_mx33 !mxE /=. Simp.r. by rewrite -!expr2 -opprD cos2Dsin2.
Qed.

(* TODO *)
Definition Ry a := col_mx3
  (row3 (cos a) 0 (sin a))
  (row3 0 1 0)
  (row3 (- sin a) 0 (cos a)).

(* TODO *)
Definition Rz a := col_mx3
  (row3 (cos a) (- sin a) 0)
  (row3 (sin a) (cos a) 0)
  (row3 0 0 1).

CoInductive is_around_axis (i : 'rV[R]_3)
  (a : angle R)
  (f : {linear 'rV_3 -> 'rV_3}) : Prop :=
  mkIsAroundAxis of
  f i = i &
  let: j := W.j i in let: k := W.k i in
  f j = (cos a) *: j + (sin a) *: k &
  let: j := W.j i in let: k := W.k i in
  f k = (-sin a) *: j + (cos a) *: k.

Section properties_of_is_around_axis.

Variable u : 'rV[R]_3.

Lemma is_around_axis1 : is_around_axis u 0 (mx_lin1 1).
Proof.
split => /=; first by rewrite mulmx1.
by rewrite cos0 sin0 mulmx1 scale0r addr0 scale1r.
by rewrite mulmx1 sin0 cos0 scaleNr scale0r oppr0 add0r scale1r.
Qed.

Lemma is_around_axisD (a b : angle R) (f g : 'M[R]_3) :
  is_around_axis u a (mx_lin1 f) ->
  is_around_axis u b (mx_lin1 g) ->
  is_around_axis u (a + b) (mx_lin1 (f * g)).
Proof.
move=> [/= H1 H2 H3] [/= K1 K2 K3]; split => /=.
- by rewrite mulmxA H1 K1.
- rewrite mulmxA H2 mulmxDl cosD sinD -2!scalemxAl K2 K3 2!scalerDr addrACA.
  by rewrite !scalerA mulrN -2!scalerDl (addrC (cos a * sin b)).
- rewrite mulmxA H3 mulmxDl -2!scalemxAl K2 K3 2!scalerDr !scalerA sinD cosD.
  rewrite addrACA mulrN -2!scalerDl -opprB mulNr opprK (addrC (- _ * _)) mulNr.
  by rewrite (addrC (cos a * sin b)).
Qed.

Hypotheses u0 : u != 0.

Lemma is_around_axisZ a f k (k0 : 0 < k):
  is_around_axis (k *: u) a f <-> is_around_axis u a f.
Proof.
split; case; rewrite ?(W.jZ u0 k0) ?(W.kZ u0 k0) => H1 H2 H3; split;
  rewrite ?(W.jZ u0 k0) ?(W.kZ u0 k0) //.
- move: H1.
  rewrite linearZ /= => /scalerI -> //; by rewrite gtr_eqF.
- by rewrite linearZ H1.
Qed.

Lemma is_around_axisZN a f k (k0 : k < 0):
  is_around_axis (k *: u) a (mx_lin1 f) <-> is_around_axis u (- a) (mx_lin1 f).
Proof.
rewrite -oppr_gt0 in k0. move: u0 => u0'; rewrite -oppr0 -eqr_oppLR in u0'.
split; case => H1 H2 H3; split.
- move: H1 => /=.
  rewrite -scalemxAl => /scalerI; apply; by rewrite -oppr_eq0 gtr_eqF.
- move: H2; rewrite -(opprK k) scaleNr -scalerN (W.jZ u0' k0) (W.kZ u0' k0).
  by rewrite cosN sinN W.jN W.kN scalerN scaleNr.
- move/eqP: H3; rewrite -(opprK k) scaleNr -scalerN (W.jZ u0' k0) (W.kZ u0' k0).
  by rewrite cosN sinN W.jN W.kN linearN scalerN -opprB scaleNr 2!opprK addrC eqr_opp => /eqP.
- move: H1; by rewrite /= -scalemxAl => ->.
- rewrite -(opprK k) scaleNr -scalerN (W.jZ u0' k0) (W.kZ u0' k0).
  by move: H2; rewrite cosN sinN W.jN W.kN scalerN scaleNr.
- rewrite -(opprK k) scaleNr -scalerN (W.jZ u0' k0) (W.kZ u0' k0) W.jN W.kN.
  by move: H3; rewrite cosN sinN opprK scalerN linearN -opprB scaleNr opprK addrC => ->.
Qed.

Lemma tr_around_axis a M :
  is_around_axis u a (mx_lin1 M) -> \tr M = 1 + cos a *+ 2.
Proof.
case=> [/= H1 [H2 H3]].
move: (@basis_change _ M _ _ _ (W.pframe_of u0) (Rx a)).
rewrite !mxE /= !scale1r !scale0r !add0r !addr0.
rewrite {1 2}/normalize -scalemxAl H1 => /(_ erefl H2 H3) ->.
rewrite mxtrace_mulC mulmxA mulmxV ?mul1mx ?tr_Rx //.
rewrite unitmxE unitfE rotation_det ?oner_neq0 //.
exact: (pframe_is_rot (W.pframe_of u0)).
Qed.

Lemma same_rot (M P : 'M[R]_3) v k (k0 : 0 < k) a :
  u = k *: v ->
  is_around_axis u a (mx_lin1 M) ->
  is_around_axis v a (mx_lin1 P) ->
  M = P.
Proof.
move=> mkp [/= HMi HMj HMk] [/= HPi HPj HPk].
apply/eqP/mulmxP => w.
rewrite (orthogonal_expansion w (W.pframe_of u0)) !mulmxDl -!scalemxAl !scalerA.
have v0 : v != 0 by apply: contra u0; rewrite mkp => /eqP ->; rewrite scaler0.
congr (_ *: _ + _ *: _ + _ *: _).
- by rewrite HMi mkp -scalemxAl HPi.
- by rewrite HMj mkp (W.jZ v0 k0) (W.kZ v0 k0) -HPj.
- by rewrite HMk mkp (W.jZ v0 k0) (W.kZ v0 k0) -HPk.
Qed.

Lemma is_around_axis_trmx a (M : 'M[R]_3) : M \in unitmx ->
  is_around_axis u (- a) (mx_lin1 M) ->
  is_around_axis u a (mx_lin1 M^-1).
Proof.
move=> Hf H.
case: H => [/= H1 H2 H3].
have K1 : normalize u *m M = normalize u by rewrite /normalize -scalemxAl H1.
move: (@basis_change _ M _ _ _ (oframe_of_pframe (W.pframe_of u0)) (Rx (- a))).
rewrite !mxE /= K1 !scale0r 2!add0r !addr0 -H2 -H3 scale1r => /(_ erefl erefl erefl).
move=> fRx.
have HfRx : M^-1 = (col_mx3 (normalize u) (W.j u) (W.k u))^T *m
   (Rx (- a))^-1 *m col_mx3 (normalize u) (W.j u) (W.k u).
  rewrite fRx invrM /= ?W.pframe_of_is_unit //; last first.
    rewrite unitrMl ?unitrV ?W.pframe_of_is_unit //.
    by rewrite orthogonal_unit // rotation_sub // Rx_is_SO.
  rewrite invrM; last 2 first.
    by rewrite unitrV W.pframe_of_is_unit.
    by rewrite orthogonal_unit // rotation_sub // Rx_is_SO.
  by rewrite invrK (rotation_inv (pframe_is_rot (W.pframe_of u0))) mulmxE mulrA.
split => /=.
- by rewrite -{1}H1 -mulmxA mulmxV // mulmx1.
- rewrite HfRx !mulmxA.
  rewrite (_ : W.j u *m _ = row3 0 1 0); last first.
    rewrite col_mx3_mul dotmulC /normalize dotmulZv (W.idotj u).
    by rewrite mulr0 dotmulvv W.normj // expr1n W.jdotk.
  rewrite (_ : row3 _ _ _ *m _ = row3 0 (cos (- a)) (sin a)); last first.
    rewrite (rotation_inv (Rx_is_SO (- a))) /Rx col_mx3_mul.
    rewrite -/V.j -/V.i dotmulC V.idotj 2!dotmulE 2!sum3E !mxE /= cosN sinN opprK. by Simp.r.
  by rewrite mulmx_row3_col3 scale0r add0r cosN.
- rewrite HfRx !mulmxA.
  rewrite (_ : W.k u *m _ = row3 0 0 1); last first.
    rewrite col_mx3_mul dotmulC /normalize dotmulZv (W.idotk u) mulr0.
    by rewrite dotmulC W.jdotk dotmulvv W.normk // expr1n.
  rewrite (_ : row3 _ _ _ *m _ = row3 0 (- sin a) (cos a)); last first.
    rewrite (rotation_inv (Rx_is_SO (- a))) /Rx col_mx3_mul.
    rewrite -/V.k -/V.i dotmulC V.idotk 2!dotmulE 2!sum3E !mxE /= cosN sinN opprK. by Simp.r.
  by rewrite mulmx_row3_col3 scale0r add0r.
Qed.

Lemma is_around_axis_SO a f : is_around_axis u a f -> lin1_mx f \is 'SO[R]_3.
Proof.
case => H1 H2 H3.
move: (@basis_change _ (lin1_mx f) _ _ _ (W.pframe_of u0) (Rx a)).
rewrite !mxE /= !scale1r !scale0r !add0r !addr0.
rewrite 3!mul_rV_lin1.
rewrite {1 2}/normalize linearZ H1.
move/(_ erefl H2 H3) => ->.
move=> [:abs].
rewrite rpredM //; last first.
  abstract: abs.
  exact: (pframe_is_rot (W.pframe_of u0)).
by rewrite rpredM // ?Rx_is_SO // rotation_inv // rotationV.
Qed.

End properties_of_is_around_axis.

Lemma SO_is_around_axis M : M \is 'SO[R]_3 ->
  exists u a, norm u = 1 /\ is_around_axis u a (mx_lin1 M).
Proof.
move=> MSO.
case/boolP : (M == 1) => [/eqP ->|M1].
  exists V.i, 0; split.
    by rewrite V.normi.
    exact: is_around_axis1.
case: (euler MSO) => v /andP[v0 /eqP vMv].
set f := W.pframe_of v0.
set i := normalize v. rewrite /= in i. rewrite -/i in f.
set j := W.j v. set k := W.k v.
have iMi : i *m M = i by rewrite /i /normalize -scalemxAl vMv.
have iMj : i *d (j *m M) = 0.
  by rewrite -iMi (proj2 (orth_preserves_dotmul M) (rotation_sub MSO) i j) /j /i dotmulZv W.idotj mulr0.
have iMk : i *d (k *m M) = 0.
  by rewrite -iMi (proj2 (orth_preserves_dotmul M) (rotation_sub MSO) i k) /k /i dotmulZv W.idotk mulr0.
have [e [b ab]] : exists e b, j *m M = e *: j + b *: k.
  exists ((j *m M) *d j), ((j *m M) *d k).
  by rewrite {1}(orthogonal_expansion (j *m M) f) -/j -/k dotmulC iMj scale0r add0r.
have [c [d cd]] : exists c d, k *m M = c *: j + d *: k.
  exists ((k *m M) *d j), ((k *m M) *d k).
  by rewrite {1}(orthogonal_expansion (k *m M) f) -/j -/k dotmulC iMk scale0r add0r.
have H1 : e^+2 + b^+2 = 1.
  move: (W.normj v0) => /eqP.
  rewrite -(@eqr_expn2 _ 2) // ?norm_ge0 // expr1n -dotmulvv -/j.
  rewrite -(proj2 (orth_preserves_dotmul M) (rotation_sub MSO) j j) ab.
  rewrite dotmulDr 2!dotmulDl 4!dotmulvZ 4!dotmulZv 2!dotmulvv W.normj // W.normk //.
  by rewrite expr1n 2!mulr1 -2!expr2 dotmulC (jdotk f) !mulr0 addr0 add0r => /eqP.
have H2 : e * c + b * d = 0.
  move: (W.jdotk v).
  rewrite -/j -/k -(proj2 (orth_preserves_dotmul M) (rotation_sub MSO) j k) ab cd.
  rewrite dotmulDr 2!dotmulDl 4!dotmulvZ 4!dotmulZv 2!dotmulvv W.normk // W.normj //.
  by rewrite expr1n !mulr1 dotmulC (jdotk f) 4!mulr0 add0r addr0 mulrC (mulrC d).
have H3 : c^+2 + d^+2 = 1.
  move: (W.normk v0) => /eqP.
  rewrite -(@eqr_expn2 _ 2) // ?norm_ge0 // expr1n -dotmulvv -/j.
  rewrite -(proj2 (orth_preserves_dotmul M) (rotation_sub MSO) k k) cd.
  rewrite dotmulDr 2!dotmulDl 4!dotmulvZ 4!dotmulZv 2!dotmulvv W.normj // W.normk //.
  by rewrite expr1n 2!mulr1 -2!expr2 dotmulC (jdotk f) !mulr0 addr0 add0r => /eqP.
set P := col_mx2 (row2 e b) (row2 c d).
have PO : P \is 'O[R]_2.
  apply/orthogonal2P.
  by rewrite rowK /= dotmulE sum2E !mxE /= -2!expr2.
  by rewrite rowK /= dotmulE sum2E !mxE.
  by rewrite 2!rowK /= dotmulE sum2E !mxE /= mulrC (mulrC d).
  by rewrite dotmulE sum2E !mxE /= -!expr2.
case: (rot2d' PO) => phi [phiRO | phiRO'].
  case/eq_col_mx2 : phiRO => ? ? ? ?; subst e b c d.
  move: (@basis_change _ M _ _ _ f (Rx (phi))).
  rewrite !mxE /= !(addr0,add0r,scale0r,scale1r) -/i -/j -/k.
  rewrite iMi -ab -cd => /(_ erefl erefl erefl) HM.
  exists i, phi; split.
    by rewrite norm_normalize.
  apply: (proj1 (@is_around_axisZ _ _ phi (mx_lin1 M) (norm v) _)).
  by rewrite /i normalize_eq0.
  by rewrite ltr_neqAle ?norm_ge0 andbT eq_sym norm_eq0.
  by rewrite /i norm_scale_normalize.
exfalso.
case/eq_col_mx2 : phiRO' => ? ? ? ?; subst e b c d.
move: (@basis_change _ M _ _ _ f (Rx' (phi))).
rewrite !mxE /= !(addr0,add0r,scale0r,scale1r) -/i -/j -/k.
rewrite -ab iMi -cd => /(_ erefl erefl erefl) => HM.
move: (rotation_det MSO).
rewrite HM 2!det_mulmx det_Rx' detV -crossmul_triple.
move: (pframeP f); rewrite /frame_sgn -/j -/k => -> /eqP.
by rewrite invr1 mulr1 mul1r -subr_eq0 -opprD eqr_oppLR oppr0 -(natrD _ 1 1) pnatr_eq0.
Qed.

End rot_axis_definition.

Section anti_sym_def.

Variables (n : nat) (R : rcfType).

Definition anti := [qualify M : 'M[R]_n | M == - M^T].
Fact anti_key : pred_key anti. Proof. by []. Qed.
Canonical anti_keyed := KeyedQualifier anti_key.

Definition sym := [qualify M : 'M[R]_n | M == M^T].
Fact sym_key : pred_key sym. Proof. by []. Qed.
Canonical sym_keyed := KeyedQualifier sym_key.

End anti_sym_def.

Local Notation "''so[' R ]_ n" := (anti n R)
  (at level 8, n at level 2, format "''so[' R ]_ n").

Section skew.

Variable R : rcfType.
Let vector := 'rV[R]_3.

Lemma antiE {n} M : (M \is 'so[R]_n) = (M == - M^T). Proof. by []. Qed.

Lemma symE {n} M : (M \is sym n R) = (M == M^T). Proof. by []. Qed.

Lemma anti_diag {n} M (i : 'I_n) : M \is 'so[R]_n -> M i i = 0.
Proof.
rewrite antiE -addr_eq0 => /eqP/matrixP/(_ i i); rewrite !mxE.
by rewrite -mulr2n -mulr_natr => /eqP; rewrite mulf_eq0 pnatr_eq0 orbF => /eqP.
Qed.

Lemma antiP {n} (A B : 'M[R]_n) : A \is 'so[R]_n -> B \is 'so[R]_n ->
  (forall i j : 'I_n, (i < j)%N -> A i j = - B j i) -> A = B.
Proof.
move=> soA soB AB; apply/matrixP => i j.
case/boolP : (i == j) => [/eqP ->|ij]; first by do 2 rewrite anti_diag //.
wlog : i j ij / (i < j)%N.
  move=> wlo; move: ij; rewrite neq_ltn => /orP [] ij.
    rewrite wlo //; by apply: contraL ij => /eqP ->; by rewrite ltnn.
  move: (soA); by rewrite antiE => /eqP ->; rewrite 2!mxE AB // opprK.
move=> {ij}ij; rewrite AB //.
move: (soB); rewrite antiE -eqr_oppLR => /eqP/matrixP/(_ i j).
rewrite !mxE => <-; by rewrite opprK.
Qed.

Lemma symP {n} (A B : 'M[R]_n) : A \in sym n R -> B \in sym n R ->
  (forall i j : 'I_n, (i <= j)%N -> A i j = B i j) -> A = B.
Proof.
move=> symA symB AB; apply/matrixP => i j.
case/boolP : (i == j) => [/eqP ->|ij]; first by rewrite AB.
wlog : i j ij / (i < j)%N.
  move=> wlo; move: ij; rewrite neq_ltn => /orP [] ij.
    rewrite wlo //; by apply: contraL ij => /eqP ->; by rewrite ltnn.
  move: (symA) (symB) => /eqP -> /eqP ->; by rewrite 2!mxE AB // leq_eqVlt ij orbC.
by move=> {ij}ij; rewrite AB // leq_eqVlt ij orbC.
Qed.

(* (anti)symmetric parts of a matrix *)
Definition symp {n} (A : 'M[R]_n) := 1/2%:R *: (A + A^T).
Definition antip {n} (A : 'M[R]_n) := 1/2%:R *: (A - A^T).

Lemma symp_antip {n} (A : 'M[R]_n) : A = symp A + antip A.
Proof.
rewrite /symp /antip -scalerDr addrCA addrK -mulr2n- scaler_nat.
by rewrite scalerA div1r mulVr ?pnatf_unit // scale1r.
Qed.

Lemma antip_is_so {n} (M : 'M[R]_n) : antip M \is 'so[R]_n.
Proof.
rewrite antiE /antip; apply/eqP; rewrite [in RHS]linearZ -scalerN /=.
by rewrite [in RHS]linearD /= opprD linearN /= opprK trmxK addrC.
Qed.

Lemma antip_scaler_closed {n} : GRing.scaler_closed 'so[R]_n.
Proof.
move=> ? ?; rewrite antiE => /eqP H; by rewrite antiE linearZ /= -scalerN -H.
Qed.

Lemma sym_symp {n} (M : 'M[R]_n) : symp M \in sym n R.
Proof.
by apply/eqP; rewrite /symp linearZ /= [in RHS]linearD /= trmxK addrC.
Qed.

Lemma sym_oppr_closed {n} : oppr_closed (sym n R).
Proof. move=> /= M /eqP HM; apply/eqP; by rewrite linearN /= -HM. Qed.

Lemma sym_addr_closed {n} : addr_closed (sym n R).
Proof.
split; first by rewrite symE trmx0.
move=> /= A B; rewrite 2!symE => /eqP sA /eqP sB.
by rewrite symE linearD /= -sA -sB.
Qed.

Canonical SymOpprPred n := OpprPred (@sym_oppr_closed n).
Canonical SymAddrPred n := AddrPred (@sym_addr_closed n).

Lemma sym_scaler_closed n : GRing.scaler_closed (sym n R).
Proof. move=> ? ?; rewrite 2!symE => /eqP H; by rewrite linearZ /= -H. Qed.

Lemma sym1 n : 1%:M \is sym n R.
Proof. by rewrite symE trmx1. Qed.

Lemma mul_tr_vec_sym n (u : 'rV[R]_n) : u^T *m u \is sym n R.
Proof. apply/eqP; by rewrite trmx_mul trmxK. Qed.

(* TODO: Canonical? *)

Lemma trace_anti {n} (M : 'M[R]_n) : M \is 'so[R]_n -> \tr M = 0.
Proof.
move/anti_diag => m; by rewrite /mxtrace (eq_bigr (fun=> 0)) // sumr_const mul0rn.
Qed.

Definition skew_mx (w : vector) : 'M[R]_3 := - \matrix_i (w *v 'e_i).

Lemma skew_mx0 : skew_mx 0 = 0.
Proof.
by apply/matrixP => i j; rewrite !mxE -crossmul_triple crossmul0v dotmulv0 oppr0.
Qed.

Lemma skew_mxZ k (u : vector) : skew_mx (k *: u) = k *: skew_mx u.
Proof.
rewrite /skew_mx scalerN; congr (- _); apply/matrixP => i j.
by rewrite mxE crossmulC linearZ /= -scalerN crossmulC opprK mxE 2![in RHS]mxE.
Qed.

Lemma opp_skew_mx (u : vector) : - skew_mx u = skew_mx (- u).
Proof. by rewrite -scaleN1r -skew_mxZ scaleN1r. Qed.

Lemma anti_skew u : skew_mx u \is 'so[R]_3.
Proof.
rewrite antiE; apply/eqP/matrixP => i j; rewrite !mxE -col_mx3_perm_02.
by rewrite xrowE det_mulmx det_perm odd_tperm /= expr1 mulN1r.
Qed.

Lemma skew01 u : skew_mx u 0 1 = - u``_2%:R.
Proof. by rewrite /skew_mx 2!mxE crossmulE !mxE /= !(mulr0, mulr1, addr0, subr0). Qed.

Lemma skew02 u : skew_mx u 0 2%:R = u``_1%:R.
Proof. by rewrite /skew_mx 2!mxE crossmulE !mxE /= !(mulr0, mulr1, add0r, opprK). Qed.

Lemma skew10 u : skew_mx u 1 0 = u``_2%:R.
Proof. move/eqP: (anti_skew u) => ->; by rewrite 2!mxE skew01 opprK. Qed.

Lemma skew12 u : skew_mx u 1 2%:R = - u``_0.
Proof. by rewrite /skew_mx 2!mxE crossmulE !mxE /= !(mulr0, mulr1, subr0). Qed.

Lemma skew20 u : skew_mx u 2%:R 0 = - u``_1%:R.
Proof. move/eqP: (anti_skew u) => ->; by rewrite 2!mxE skew02. Qed.

Lemma skew21 u : skew_mx u 2%:R 1 = u``_0.
Proof. move/eqP: (anti_skew u) => ->; by rewrite 2!mxE skew12 opprK. Qed.

Lemma skewii u i : skew_mx u i i = 0.
Proof. by rewrite anti_diag // anti_skew. Qed.

Definition skewij := (skew01, skew10, skew02, skew20, skew21, skew12, skewii).

Lemma skew_mxE (u w : vector) : u *m skew_mx w = u *v w.
Proof.
rewrite [RHS]crossmulC -crossmulvN [u]row_sum_delta -/(mulmxr _ _) !linear_sum.
apply: eq_bigr=> i _; by rewrite !linearZ /= -rowE linearN /= rowK crossmulvN.
Qed.

Lemma skew_mxT (w : vector) : skew_mx w *m w^T = 0.
Proof.
rewrite -(trmxK (skew_mx w)) -trmx_mul.
move: (anti_skew w); rewrite antiE -eqr_oppLR => /eqP <-.
by rewrite mulmxN skew_mxE crossmulvv oppr0 trmx0.
Qed.

(* more general result for antisymmetric matrices? *)
Lemma det_skew_mx (u : vector) : \det (skew_mx u) = 0.
Proof.
case/boolP : (u == 0) => [/eqP ->|u0]; first by rewrite skew_mx0 det0.
apply/eqP/det0P; exists u => //; by rewrite skew_mxE crossmulvv.
Qed.

Lemma sqr_antip (M : 'M[R]_3) : M \is 'so[R]_3 ->
  M ^+ 2 = col_mx3
  (row3 (- M 0 1 ^+ 2 - M 0 2%:R ^+ 2) (- M 1 2%:R * M 0 2%:R) (M 0 1 * M 1 2%:R))
  (row3 (- M 1 2%:R * M 0 2%:R) (- M 0 1 ^+ 2 - M 1 2%:R ^+ 2) (- M 0 1 * M 0 2%:R))
  (row3 (M 1 2%:R * M 0 1) (- M 0 2%:R * M 0 1) (- M 0 2%:R ^+ 2 - M 1 2%:R ^+ 2)).
Proof.
move=> a; apply/matrix3P; rewrite !mxE /= sum3E /a !anti_diag //; Simp.r => //.
- rewrite {2}(eqP a) 2!mxE mulrN -expr2; congr (_ + _).
  by rewrite {2}(eqP a) !mxE mulrN -expr2.
- by rewrite {2}(eqP a) 2!mxE mulrN mulrC.
- by rewrite {2}(eqP a) 2!mxE mulrN.
- rewrite {1}(eqP a) 2!mxE mulNr -expr2; congr (_ + _); by rewrite {2}(eqP a) 2!mxE mulrN -expr2.
- by rewrite {1}(eqP a) 2!mxE mulNr.
- by rewrite {1}(eqP a) 2!mxE {2}(eqP a) 2!mxE mulrN mulNr opprK.
- by rewrite {1}(eqP a) 2!mxE mulNr.
- rewrite {1}(eqP a) 2!mxE mulNr -expr2; congr (_ + _); by rewrite {1}(eqP a) 2!mxE mulNr -expr2.
Qed.

Lemma sqr_skewE (u : 'rV[R]_3) : let a := skew_mx u in
  a ^+ 2 = col_mx3
    (row3 (- u 0 2%:R ^+ 2 - u 0 1 ^+ 2) (u 0 0 * u 0 1) (u 0 0 * u 0 2%:R))
    (row3 (u 0 0 * u 0 1) (- u 0 2%:R ^+ 2 - u 0 0 ^+ 2) (u 0 1 * u 0 2%:R))
    (row3 (u 0 0 * u 0 2%:R) (u 0 1 * u 0 2%:R) (- u 0 1%:R ^+ 2 - u 0 0 ^+ 2)).
Proof.
move=> a; rewrite (sqr_antip (anti_skew u)); congr col_mx3.
by rewrite !skewij sqrrN; Simp.r; rewrite (mulrC (u 0 2%:R)).
by rewrite !skewij 2!sqrrN; Simp.r; rewrite (mulrC (u 0 2%:R)).
by rewrite !skewij sqrrN; Simp.r.
Qed.

Lemma sym_sqr_skew u : skew_mx u ^+ 2 \is sym 3 R.
Proof. rewrite symE sqr_skewE; by apply/eqP/matrix3P; rewrite !mxE. Qed.

Lemma mul_tr_vecij (u : 'rV[R]_3) i j : (u^T *m u) i j = u``_i * u``_j.
Proof.
by rewrite mxE (bigD1 ord0) //= big1 ?mxE ?addr0 // => i0; rewrite (ord1 i0).
Qed.

Lemma mulmx_trE {n}  (u : 'rV[R]_n) i j : (u^T *m u) i j = u 0 i * u 0 j.
Proof.
by rewrite mxE (bigD1 ord0) //= big1 ?mxE ?addr0 // => i0; rewrite (ord1 i0).
Qed.

Lemma skew_mx2 u : skew_mx u ^+ 2 = u^T *m u - (norm u ^+ 2)%:A.
Proof.
apply (symP (sym_sqr_skew u)); last move=> i j.
  rewrite rpredD //; last by rewrite rpredN sym_scaler_closed // sym1.
  by rewrite mul_tr_vec_sym.
rewrite [in X in _ -> _ = X]mxE mulmx_trE.
case/boolP : (i == 0) => [/eqP -> _|].
  case/boolP : (j == 0) => [/eqP ->|].
    rewrite sqr_skewE 5!mxE /= -expr2 mulr1; apply/eqP.
    by rewrite -eqr_opp 2!opprB opprK eq_sym subr_eq -dotmulvv dotmulE
      sum3E -!expr2 -addrA addrCA addrAC -addrA.
  rewrite ifnot0 => /orP [] /eqP ->; by rewrite sqr_skewE 5!mxE /= mulr0 subr0.
rewrite ifnot0 => /orP [] /eqP ->.
  case/boolP : (j == 0) => [/eqP -> //|].
  rewrite ifnot0 => /orP [] /eqP -> _.
    rewrite sqr_skewE 5!mxE /= -expr2 mulr1; apply/eqP.
    by rewrite -eqr_opp 2!opprB opprK eq_sym subr_eq -dotmulvv dotmulE
      sum3E -!expr2 addrAC.
    by rewrite sqr_skewE 5!mxE /= mulr0 subr0.
case/boolP : (j == 0) => [/eqP -> //|].
rewrite ifnot0 => /orP [] /eqP -> // _.
rewrite sqr_skewE 5!mxE /= -expr2 mulr1; apply/eqP.
by rewrite -eqr_opp 2!opprB opprK eq_sym subr_eq -dotmulvv dotmulE sum3E -!expr2.
Qed.

Lemma skew_mx3 (u : 'rV[R]_3) : let a := skew_mx u in a ^+ 3 = - (norm u) ^+ 2 *: a.
Proof.
move=> a.
rewrite exprS sqr_skewE.
apply/matrixP => i j.
rewrite mxE /= sum3E.
do 3 rewrite [col_mx3 _ _ _ _ _]mxE /=.
do 3 rewrite [row3 _ _ _ _ _]mxE /=.
move: (dotmulvv u).
rewrite dotmulE sum3E => /eqP H.
rewrite -{1}eqr_opp 2!opprD -!expr2 in H.
move: (H); rewrite subr_eq addrC => /eqP ->.
move: (H); rewrite addrAC subr_eq addrC => /eqP ->.
move: (H); rewrite -addrA addrC subr_eq addrC => /eqP ->.
rewrite [in RHS]mxE.
case/boolP : (i == 0) => [/eqP -> |].
  case: ifPn => [/eqP ->|].
    rewrite /a !skewij; Simp.r => /=.
    by rewrite addrC !mulNr mulrAC -mulrA mulrC subrr.
  rewrite ifnot0 => /orP [] /eqP -> /=; rewrite /a !skewij; Simp.r => /=.
    rewrite -expr2 -mulrN mulrC -mulrDl; congr (_ * _).
    by rewrite opprD opprK subrK.
  rewrite -(mulrC (u``_1)) -mulrA -mulrDr -mulNr mulrC; congr (_ * _).
  by rewrite addrC mulNr addrK.
rewrite ifnot0 => /orP [] /eqP -> /=.
  case: ifPn => [/eqP ->|].
    rewrite /a !skewij; Simp.r => /=.
    rewrite mulrC -mulrDl -[in RHS]mulNr; congr (_ * _).
    by rewrite mulNr -expr2 addrK.
  rewrite ifnot0 => /orP [] /eqP -> /=; rewrite /a !skewij; Simp.r => /=.
    by rewrite -mulrA mulrC 2!mulNr -mulrBl subrr mul0r.
  rewrite -mulrA mulrC -mulrA -mulrBr mulrC; congr (_ * _).
  by rewrite opprD opprK addrCA -expr2 subrr addr0.
case: ifPn => [/eqP ->|].
  rewrite /a !skewij; Simp.r => /=.
  rewrite -mulrN mulrC -mulrDl; congr (_ * _).
  by rewrite opprD opprK -expr2 subrK.
rewrite ifnot0 => /orP [] /eqP -> /=; rewrite /a !skewij; Simp.r => /=.
  rewrite -mulrA mulrCA -mulrDr -[in RHS]mulNr [in RHS]mulrC; congr (_ * _).
  by rewrite addrC mulNr -expr2 addrK.
by rewrite -mulrA mulrCA -mulrA -mulrDr addrC mulNr subrr mulr0.
Qed.

Lemma skew_mx4 w : norm w = 1 -> skew_mx w ^+ 4 = - skew_mx w ^+ 2.
Proof. move=> w1; by rewrite exprS skew_mx3 // w1 expr1n scaleN1r mulrN -expr2. Qed.

Lemma mxtrace_sqr_skew_mx u : \tr ((skew_mx u) ^+ 2) = - (2%:R * (norm u) ^+ 2).
Proof.
rewrite /mxtrace sum3E sqr_skewE.
do 6 rewrite mxE /=.
rewrite -opprB opprK !addrA addrC !addrA -2!addrA.
rewrite [in RHS]mulr2n [in RHS]mulrDl [in RHS]opprD mul1r; congr (_ + _).
  rewrite -opprB opprK; congr (- _).
  by rewrite addrC addrA -dotmulvv dotmulE sum3E -!expr2.
rewrite -opprB -opprD opprK; congr (- _).
by rewrite addrC -addrA addrCA addrA  -dotmulvv dotmulE sum3E -!expr2.
Qed.

(* TODO: useful? *)
Lemma row'0_triple_prod_mat tmp (XM : 'M[{poly R}]_3) :
  row' ord0 (col_mx3 tmp (row 1 XM) (row 2%:R XM)) = row' ord0 XM.
Proof.
rewrite row'_col_mx3 /=.
apply/matrixP => i j; rewrite !mxE.
case: ifPn => [/eqP ->|].
  by rewrite !mxE; Simp.ord.
case: i => [] [] // [] // i _ /=.
by rewrite !mxE; Simp.ord.
Qed.

Lemma char_poly3_coef1 (M : 'M[R]_3) :
  let Z := 1 / 2%:R * (\tr M ^+ 2 - \tr (M ^+ 2)) in
  (char_poly M)`_1 = Z.
Proof.
move=> Z.
rewrite /char_poly /char_poly_mx det_mx33 !mxE mulr1n mulr0n !add0r.
rewrite !mulNr !mulrN !opprK.
rewrite !coefD.
(* 1 *)
rewrite [X in X + _ + _](_ : _ = M 0 0 * (M 2%:R 2%:R + M 1 1) +
   (M 1 1 * M 2%:R 2%:R - M 2%:R 1 * M 1 2%:R)); last first.
  rewrite coefM sum2E coefD coefX add0r coefN coefC [- _]/=.
  rewrite subn0 coefD.
  rewrite coefM sum2E subn0 coefD coefX add0r coefN (_ : _`_0 = M 1 1); last by rewrite coefC.
  rewrite coefD coefX coefN coefC subr0 mulr1.
  rewrite coefD coefN coefX coefN coefC subr0 mul1r.
  rewrite subnn coefD coefX add0r coefN coefC [in X in - M 1 1 - X]/=.
  rewrite coefM sum2E coefC coefC mulr0 add0r coefC mul0r subr0.
  rewrite coefD coefX coefN coefC subr0 mul1r.
  rewrite coefD coefM sum1E coefD coefX add0r coefN coefC [in X in - X * _`_ _]/=.
  rewrite coefD coefX add0r coefN coefC mulrN !mulNr opprK.
  rewrite coefN coefM sum1E coefC coefC [in X in M 1 1 * _ - X]/=.
  by rewrite -opprB mulrN 2!opprK.
rewrite [X in _ + X + _](_ : _ = - M 0 1 * M 1 0); last first.
  rewrite coefN coefM sum2E coefC [in X in X * _]/= subnn.
  rewrite coefD subn0 coefM sum2E.
  rewrite subn0 subnn coefC coefC mulr0 add0r.
  rewrite coefC mul0r add0r.
  rewrite coefM sum2E subn0 subnn coefC coefD coefX coefN coefC subr0 mulr1.
  rewrite coefC mul0r addr0 coefC mul0r addr0.
  by rewrite mulNr.
rewrite [X in _ + _ + X](_ : _ = - M 0 2%:R * M 2%:R 0); last first.
  rewrite coefN coefM sum2E subn0 subnn coefC.
  rewrite [in X in X * _]/=.
  rewrite coefD coefM sum2E subn0 coefC coefC mulr0 add0r.
  rewrite coefC mul0r add0r coefM sum2E subn0 subnn coefC [in X in X * _`_1]/=.
  by rewrite coefD coefX coefN coefC subr0 mulr1 coefC mul0r addr0 coefC mul0r addr0 mulNr.
rewrite /Z.
apply/(@mulrI _ 2%:R); first exact: pnatf_unit.
rewrite mulrA div1r divrr ?pnatf_unit // mul1r.
rewrite sqr_mxtrace.
rewrite mxtrace_sqr.
rewrite 3!opprD -[in RHS]addrAC [in RHS](addrC (\sum_ _ _)) 3![in RHS]addrA addrK.
rewrite mulrDr addrC mulNr mulrN (mulrC 2%:R) mulr_natr.
rewrite -2![in RHS]addrA [in RHS]addrC -[in RHS]addrA; congr (_ + _).
rewrite mulrDr addrC mulNr mulrN (mulrC 2%:R) mulr_natr.
rewrite [in RHS]addrA [in RHS]addrC; congr (_ + _).
rewrite addrA mulrDr addrC mulrN (mulrC 2%:R) mulr_natr mulrC -addrA; congr (_ + _).
rewrite (mulrC 2%:R) mulr_natr.
rewrite mulrDr.
rewrite mulrDl.
rewrite mulr2n.
rewrite [in RHS]mulr2n.
rewrite [in X in _ = _ + X]mulr2n.
rewrite -!addrA; congr (_ + _).
rewrite addrC -!addrA; congr (_ + (_ + _)).
by rewrite addrCA.
Qed.

Lemma char_poly3 (M : 'M[R]_3) :
  let Z := 1 / 2%:R * ((\tr M) ^+ 2 - \tr (M ^+ 2)) in
  char_poly M = 'X^3 - (\tr M) *: 'X^2 + Z *: 'X - (\det M)%:P.
Proof.
move=> Z.
rewrite -(coefK (char_poly M)) (size_char_poly M).
apply/polyP.
case. (* coef0 *)
  rewrite coef_poly char_poly_det !coef_add_poly !coef_opp_poly !coefZ.
  rewrite !coefX !coefXn add0r mulr0 oppr0 mulr0 add0r add0r coefC /=.
  by rewrite exprS sqrrN expr1n mulr1 mulN1r.
case; last first.
  case. (* coef2 *)
    rewrite coef_poly !coef_add_poly !coef_opp_poly !coefZ !coefX !coefXn.
    by rewrite add0r mulr0 mulr1 addr0 coefC subr0 char_poly_trace.
  case; last first. (* coef n >= 4 *)
    move=> n.
    rewrite coef_poly !coef_add_poly !coef_opp_poly !coefZ !coefX !coefXn.
    by rewrite add0r mulr0 mulr0 coefC subr0 addr0 oppr0.
  (* coef3 *)
  rewrite coef_poly !coef_add_poly !coef_opp_poly !coefZ !coefX !coefXn.
  rewrite mulr0 subr0 mulr0 addr0 coefC subr0; apply/eqP.
  rewrite (_ : _`_3 = lead_coef (char_poly M)); last first.
    by rewrite lead_coefE size_char_poly.
  by rewrite -monicE char_poly_monic.
(* coef1 *)
rewrite coef_poly !coef_add_poly !coef_opp_poly !coefZ !coefX !coefXn.
rewrite add0r mulr1 mulr0 oppr0 add0r coefC subr0.
suff : (char_poly M)`_1 = Z by move=> ->.
by rewrite char_poly3_coef1.
Qed.

Lemma char_poly_skew_mx (u : 'rV[R]_3) : norm u = 1 ->
  char_poly (skew_mx u) = 'X^3 + 'X.
Proof.
move=> u1.
rewrite char_poly3 det_skew_mx subr0 trace_anti ?anti_skew //.
rewrite scale0r subr0 expr0n add0r mulrN mxtrace_sqr_skew_mx mulrN opprK.
by rewrite u1 expr1n mulr1 div1r mulVr ?unitfE ?pnatr_eq0 // scale1r.
Qed.

Definition skew_mx_eigenvalues : seq R[i] := [:: 0; 'i; 0 -i* 1].

Ltac eigenvalue_skew_mx_eval_poly :=
  rewrite /map_poly horner_poly size_addl; [ |by rewrite size_polyXn size_polyX] ;
  rewrite size_polyXn sum4E !coefD !coefXn !coefX !add0r !mul0r !mul1r !add0r !addr0 mul1r.

Lemma eigenvalue_skew_mx (u : 'rV[R]_3) : norm u = 1 ->
  eigenvalue (map_mx (fun x => x%:C) (skew_mx u)) =1 [pred k | k \in skew_mx_eigenvalues].
Proof.
move=> u1 /= k.
rewrite inE eigenvalue_root_char -map_char_poly (char_poly_skew_mx u1).
apply/rootP.
case: ifPn => [|Hk].
  rewrite inE => /orP [/eqP ->|]; first by rewrite /= horner_map !hornerE.
  rewrite inE => /orP [/eqP ->|].
    eigenvalue_skew_mx_eval_poly.
    by rewrite expr1 exprS sqr_i mulrN1 subrr.
  rewrite inE => /eqP ->.
  eigenvalue_skew_mx_eval_poly.
  apply/eqP. simpc. by rewrite addrC subrr eq_complex /= eqxx.
apply/eqP; apply: contra Hk.
eigenvalue_skew_mx_eval_poly.
rewrite (exprS _ 2) -{1}(mulr1 k) -mulrDr mulf_eq0 => /orP [/eqP ->|].
  by rewrite inE eqxx.
rewrite eq_sym addrC -subr_eq add0r -sqr_i eqf_sqr => /orP [/eqP <-|].
  by rewrite !inE eqxx orbC.
rewrite -eqr_oppLR => /eqP <-.
rewrite !inE orbA; apply/orP; right.
by rewrite eq_complex /= oppr0 !eqxx.
Qed.

Lemma skew_mxC (u : vector) : let a := skew_mx u in
  (1 + a) * (1 - a) = (1 - a) * (1 + a).
Proof.
move=> a.
rewrite mulrDl mul1r mulrDr mulr1 mulrN addrA subrK.
by rewrite mulrDr mulr1 mulrBl mul1r addrA subrK.
Qed.

Lemma det_skew_mx1 (u : vector) : \det (1 - skew_mx u) = 1 + norm u ^+ 2.
Proof.
set a := skew_mx u.
rewrite det_mx33 [a]lock !mxE /=. Simp.r.
rewrite -lock /a !skewij subr0. Simp.r.
rewrite mulrDr mulrBr opprB.
rewrite addrAC !addrA mulrCA subrK.
rewrite -!addrA addrC !addrA.
by rewrite -sqr_norm addrC.
Qed.

Lemma skew_mx_inv (u : vector) : 1 - skew_mx u \is a GRing.unit.
Proof.
set a := skew_mx u.
by rewrite unitmxE unitfE det_skew_mx1 paddr_eq0 // ?ler01 // ?sqr_ge0 // negb_and oner_neq0.
Qed.

Definition cayley_of_skew (u : vector) := (1 - skew_mx u)^-1 * (1 + skew_mx u).

Lemma cayley_of_skew_is_O u : cayley_of_skew u \is 'O[R]_3.
Proof.
rewrite orthogonalE /cayley_of_skew.
set a := skew_mx u.
rewrite trmx_mul trmxV.
do 2 rewrite linearD /= trmx1.
rewrite [in X in _ * _ * (_ * X) == _]linearN /=.
move: (anti_skew u); rewrite antiE eq_sym eqr_oppLR => /eqP ->.
rewrite (opprK (skew_mx u)) -/a -mulrA (mulrA (1 + a)) skew_mxC -/a.
rewrite !mulrA mulVr ?skew_mx_inv // mul1r divrr //.
by rewrite -(opprK a) opp_skew_mx skew_mx_inv.
Qed.

Lemma det_caley u : \det (cayley_of_skew u) = 1.
Proof.
rewrite /cayley_of_skew det_mulmx det_inv det_skew_mx1.
rewrite -(opprK (skew_mx u)) opp_skew_mx det_skew_mx1 normN.
by rewrite mulVr // unitfE paddr_eq0 ?ler01 // ?sqr_ge0 // oner_eq0.
Qed.

Lemma cayley_of_skew_is_SO u : cayley_of_skew u \is 'SO[R]_3.
Proof. by rewrite rotationE cayley_of_skew_is_O det_caley eqxx. Qed.

Definition skew_of_ortho (Q : 'M[R]_3) := (Q - 1) * (Q + 1)^-1.

Lemma skew_of_ortho_is_skew Q : Q \is 'O[R]_3 -> skew_of_ortho Q \is 'so[R]_3.
Proof.
move=> HQ.
rewrite antiE /skew_of_ortho.
rewrite trmx_mul trmxV.
rewrite linearD /= trmx1.
rewrite linearD /= linearN /= trmx1.
move: (HQ).
rewrite orthogonalEinv => /andP[Qinv] /eqP <-.
rewrite mulmxE -mulrN opprB idmxE; apply/eqP.
rewrite -[in RHS](mul1r (1 - Q^-1)).
rewrite -unitrV in Qinv.
rewrite -{4}(divrr Qinv).
rewrite -mulrA invrK (mulrBr Q) mulr1 divrr; last by rewrite -unitrV.
rewrite mulrA.
Abort.

Definition unskew (M : 'M[R]_3) := row3 (- M 1 2%:R) (M 0 2%:R) (- M 0 1).

Lemma skew_mxK w : unskew (skew_mx w) = w.
Proof.
apply/rowP => i; rewrite 3!mxE /=.
case: ifPn => [/eqP ->|]; first by rewrite crossmulE /= !mxE /=; Simp.r.
by rewrite ifnot0 => /orP [] /eqP -> /=; rewrite !skewij // opprK.
Qed.

Lemma unskewK (M : 'M[R]_3) : M \is 'so[R]_3 -> skew_mx (unskew M) = M.
Proof.
move=> soM.
by apply/matrix3P; rewrite skewij ?anti_diag // mxE /= ?opprK // {1}(eqP soM) !mxE opprK.
Qed.

Lemma unskewN (a : 'M[R]_ _) : unskew (- a) = - unskew a.
Proof.
rewrite /unskew !mxE !opprK; apply/rowP => i; rewrite !mxE /=.
case: ifPn => //; rewrite ?opprK // => ?; case: ifPn => // ?; case: ifPn => //; by rewrite ?opprK ?oppr0.
Qed.

Lemma unskew_mxZ k (M : 'M[R]_3) : unskew (k *: M) = k *: unskew M.
Proof.
apply/rowP => i; rewrite !mxE /=.
case: ifPn => [_|]; first by rewrite mulrN.
rewrite ifnot0 => /orP [] /eqP -> //=; by rewrite mulrN.
Qed.

Lemma unskewD (a b : 'M[R]_ _) : unskew (a + b) = unskew a + unskew b.
Proof.
apply/rowP => i; rewrite !mxE /= !opprD.
case: ifPn => // i0; case: ifPn => // i1; case: ifPn => // ?; by Simp.r.
Qed.

Lemma skew_inj (u v : 'rV[R]_3) : skew_mx u = skew_mx v -> u = v.
Proof. move=> H; by rewrite -(skew_mxK u) H skew_mxK. Qed.

Section axial_vector.

Definition axial_vec (M : 'M[R]_3) : 'rV[R]_3 :=
  row3 (M 2%:R 1 - M 1 2%:R) (M 0 2%:R - M 2%:R 0) (M 1 0 - M 0 1).

Lemma tr_axial_vec M : axial_vec M^T = - axial_vec M.
Proof. by rewrite /axial_vec !mxE row3N 3!opprB. Qed.

Lemma skew_axial_vec M : skew_mx (axial_vec M) = M - M^T.
Proof.
by apply/matrix3P; rewrite ?skewii ![in RHS]mxE ?subrr // skewij !mxE /= ?opprB.
Qed.

Lemma axial_vecE M : axial_vec M = unskew (M - M^T).
Proof.
apply/skew_inj; rewrite skew_axial_vec unskewK //.
by rewrite antiE linearD /= linearN /= trmxK opprB.
Qed.

Lemma axial_vecD (A B : 'M[R]_3) : axial_vec (A + B) = axial_vec A + axial_vec B.
Proof. by rewrite axial_vecE linearD /= opprD addrACA 2!axial_vecE unskewD. Qed.

Lemma axial_vec_sym M : M \is sym 3 R -> axial_vec M = 0.
Proof. rewrite symE => /eqP HM; by rewrite /axial_vec {2 4 6}HM !mxE !subrr row30. Qed.

Lemma row3Z (a b c : R) k : k *: row3 a b c = row3 (k * a) (k * b) (k * c).
Proof.
apply/rowP => i; rewrite !mxE /=.
case: ifPn => // ?; case: ifPn => // ?; case: ifPn => // ?; by Simp.r.
Qed.

Lemma axial_vecZ k (M : 'M[R]_3) : axial_vec (k *: M) = k *: axial_vec M.
Proof. by rewrite /axial_vec !mxE -!mulrBr row3Z. Qed.

Lemma axial_vecP (M : 'M[R]_3) u : u *v axial_vec M = u *m antip M.
Proof.
rewrite axial_vecE /antip -skew_mxE unskewK.
Abort.

Lemma is_eigenvector1_colinear r (Hr : r \is 'SO[R]_3) n :
  (n <= eigenspace r 1)%MS -> colinear n (axial_vec r).
Proof.
move=> Hn.
have HnT : n *m r^T = n.
  move/eigenspace_trmx : Hn => /(_ (rotation_sub Hr))/eigenspaceP.
  by rewrite scale1r.
set Q := r^T - r.
have nrrT : n *m Q = 0.
 rewrite mulmxDr [in LHS]mulmxN HnT.
 move/eigenspaceP : Hn; rewrite scale1r => ->.
 by rewrite subrr.
have skewrrT : skew_mx (- axial_vec r) = Q.
  rewrite axial_vecE // -scaleN1r skew_mxZ scaleN1r unskewK ?opprB //.
  by rewrite antiE linearD /= linearN /= trmxK opprB.
move/eqP: nrrT.
by rewrite -skewrrT skew_mxE crossmulvN oppr_eq0.
Qed.

Lemma axial_vec_vec_eigenspace M : M \is 'SO[R]_3 ->
  (axial_vec M <= eigenspace M 1)%MS.
Proof.
move=> MSO; apply/eigenspaceP; rewrite scale1r.
case: (euler MSO) => u /andP[u0 /eqP uMu].
have /is_eigenvector1_colinear : (u <= eigenspace M 1)%MS.
  by apply/eigenspaceP; rewrite scale1r.
move/(_ MSO) => uax.
suff [k Hk] : exists k, axial_vec M = k *: u by rewrite Hk -scalemxAl uMu.
case/colinearP : uax => [/eqP ->| [_ [k [? ukv]]]].
  exists 0; by rewrite scale0r.
exists (1 / k); rewrite ukv scalerA div1r mulVr ?scale1r // unitfE.
apply: contra u0; rewrite ukv => /eqP ->; by rewrite scale0r.
Qed.

(* NB: useful? *)
Lemma is_around_axis_axial_vec M : M \is 'SO[R]_3 ->
  forall u a, is_around_axis u a (mx_lin1 M) -> colinear u (axial_vec M).
Proof.
move=> MSO u a [/= H1 ? ?]; apply is_eigenvector1_colinear => //.
apply/eigenspaceP; by rewrite H1 scale1r.
Qed.

End axial_vector.

End skew.

Section exponential_map_rot.

Variable R : rcfType.
Let vector := 'rV[R]_3.
Implicit Type u v : vector.
Implicit Type a b : angle R.

Definition exp_rot a (M : 'M[R]_3) : 'M_3 :=
  1 + sin a *: M + (1 - cos a) *: M ^+ 2.

Local Notation "'`e^(' a ',' M ')'" := (exp_rot a M) (format "'`e^(' a ','  M ')'").

Lemma mul_exp_rot a b M : M ^+ 3 = - M -> `e^(a, M) * `e^(b, M) = `e^(a + b, M).
Proof.
move=> cube_u.
rewrite /exp_rot sinD cosD !mulrDr !mulrDl.
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

Lemma tr_exp_rot a M : `e^(a, M)^T = `e^(a, M^T).
Proof.
by rewrite /exp_rot !linearD /= !linearZ /= trmx1 expr2 trmx_mul expr2.
Qed.

Lemma inv_exp_rot a M : M ^+ 4 = - M ^+ 2 -> `e^(a, M) * `e^(a, -M) = 1.
Proof.
move=> aM.
case/boolP : (cos a == 1) => [/eqP cphi|cphi].
  by rewrite /exp_rot cphi subrr 2!scale0r !addr0 scalerN (cos1sin0 cphi) scale0r addr0 subr0 mulr1.
rewrite /exp_rot !mulrDr !mulrDl !mulr1 !mul1r -[RHS]addr0 -!addrA; congr (_ + _).
rewrite !addrA (_ : (- M) ^+ 2 = M ^+ 2); last by rewrite expr2 mulNr mulrN opprK -expr2.
rewrite -!addrA (addrCA (_ *: M ^+ 2)) !addrA scalerN subrr add0r.
rewrite (_ : (1 - _) *: _ * _ = - (sin a *: M * ((1 - cos a) *: M ^+ 2))); last first.
  rewrite mulrN; congr (- _).
  rewrite -2!scalerAr -!scalerAl -exprS -exprSr 2!scalerA; congr (_ *: _).
  by rewrite mulrC.
rewrite -!addrA (addrCA (- (sin a *: _ * _))) !addrA subrK.
rewrite mulrN -scalerAr -scalerAl -expr2 scalerA -expr2.
rewrite -[in X in _ - _ + _ + X = _]scalerAr -scalerAl -exprD scalerA -expr2.
rewrite -scalerBl -scalerDl sin2cos2.
rewrite -{2}(expr1n _ 2) subr_sqr -{1 3}(mulr1 (1 - cos a)) -mulrBr -mulrDr.
rewrite opprD addrA subrr add0r -(addrC 1) -expr2 -scalerDr.
apply/eqP; rewrite scaler_eq0 sqrf_eq0 subr_eq0 eq_sym (negbTE cphi) /=.
by rewrite aM subrr.
Qed.

Lemma trace_exp_rot_skew_mx a u : norm u = 1 ->
  \tr `e^(a, skew_mx u) = 1 + 2%:R * cos a.
Proof.
move=> w1.
rewrite 2!mxtraceD !mxtraceZ /= mxtrace1.
rewrite (trace_anti (anti_skew _)) mulr0 addr0 mxtrace_sqr_skew_mx w1.
rewrite (_ : - _ = - 2%:R); last by rewrite expr1n mulr1.
by rewrite mulrDl addrA mul1r -natrB // mulrC mulrN -mulNr opprK.
Qed.

(* see table 1.1 of handbook of robotics *)
Lemma exp_rot_skew_mxE a u : norm u = 1 ->
  let va := 1 - cos a in let ca := cos a in let sa := sin a in
  `e^(a, skew_mx u) = col_mx3
  (row3 (u``_0 ^+2 * va + ca)
        (u``_0 * u``_1 * va - u``_2%:R * sa)
        (u``_0 * u``_2%:R * va + u``_1 * sa))
  (row3 (u``_0 * u``_1 * va + u``_2%:R * sa)
        (u``_1 ^+2 * va + ca)
        (u``_1 * u``_2%:R * va - u``_0 * sa))
  (row3 (u``_0 * u``_2%:R * va - u``_1 * sa)
        (u``_1 * u``_2%:R * va + u``_0 * sa)
        (u``_2%:R ^+2 * va + ca)).
Proof.
move=> w1 va ca sa; apply/matrix3P.
- rewrite 2![in RHS]mxE /= [in LHS]mxE -/sa -/va 3!mxE /= !skewij; Simp.r => /=.
  rewrite sqr_skewE !mxE /=.
  rewrite (_ : - _ - _ = u``_0 ^+ 2 - 1); last first.
    rewrite -[in X in _ = _ - X](expr1n _ 2%N) -w1 -dotmulvv dotmulE sum3E -3!expr2.
  by rewrite !opprD !addrA subrr add0r addrC.
- rewrite mulrBr mulr1 addrCA mulrC; congr (_ + _).
  by rewrite /va opprB addrC subrK.
- rewrite 2![in RHS]mxE /= [in LHS]mxE -/sa -/va 3!mxE /= !skewij; Simp.r => /=.
  by rewrite sqr_skewE !mxE /= addrC mulrC (mulrC sa).
- rewrite 2![in RHS]mxE /= [in LHS]mxE -/sa -/va 3!mxE /= !skewij; Simp.r => /=.
  by rewrite sqr_skewE !mxE /= addrC mulrC (mulrC sa).
- rewrite 2![in RHS]mxE /= [in LHS]mxE -/sa -/va 3!mxE /= !skewij; Simp.r => /=.
  by rewrite sqr_skewE !mxE /= addrC mulrC (mulrC sa).
- rewrite 2![in RHS]mxE /= [in LHS]mxE -/sa -/va 3!mxE /= !skewij; Simp.r => /=.
  rewrite sqr_skewE !mxE /=.
  rewrite (_ : - _ - _ = u``_1 ^+ 2 - 1); last first.
    rewrite -[in X in _ = _ - X](expr1n _ 2%N) -w1 -dotmulvv dotmulE sum3E -3!expr2.
    by rewrite 2!opprD addrCA addrA subrK addrC.
  rewrite mulrBr mulr1 addrCA mulrC; congr (_ + _).
  by rewrite /va opprB addrC subrK.
- rewrite 2![in RHS]mxE /= [in LHS]mxE -/sa -/va 3!mxE /= !skewij; Simp.r => /=.
  by rewrite sqr_skewE !mxE /= addrC mulrC (mulrC sa).
- rewrite 2![in RHS]mxE /= [in LHS]mxE -/sa -/va 3!mxE /= !skewij; Simp.r => /=.
  by rewrite sqr_skewE !mxE /= addrC mulrC (mulrC sa).
- rewrite 2![in RHS]mxE /= [in LHS]mxE -/sa -/va 3!mxE /= !skewij; Simp.r => /=.
  by rewrite sqr_skewE !mxE /= addrC mulrC (mulrC sa).
- rewrite 2![in RHS]mxE /= [in LHS]mxE -/sa -/va 3!mxE /= !skewij; Simp.r => /=.
  rewrite sqr_skewE !mxE /=.
  rewrite (_ : - _ - _ = u``_2%:R ^+ 2 - 1); last first.
    rewrite -[in X in _ = _ - X](expr1n _ 2%N) -w1 -dotmulvv dotmulE sum3E -3!expr2.
    by rewrite 2!opprD [in RHS]addrC subrK addrC.
  rewrite mulrBr mulr1 addrCA mulrC; congr (_ + _).
  by rewrite /va opprB addrC subrK.
Qed.

Lemma exp_rot_is_ortho a u : norm u = 1 -> `e^(a, skew_mx u) \is 'O[R]_3.
Proof.
move=> w1.
rewrite orthogonalE tr_exp_rot.
move: (anti_skew u); rewrite antiE -eqr_oppLR => /eqP <-.
by rewrite inv_exp_rot // skew_mx4.
Qed.

Lemma rank_exp_rot a v : norm v = 1 -> \rank `e^(a, skew_mx v) = 3.
Proof.
move=> w1; by rewrite mxrank_unit // orthogonal_unit // exp_rot_is_ortho.
Qed.

Lemma det_exp_rot0 w : norm w = 1 -> \det `e^(0, skew_mx w) = 1.
Proof. move=> w1; by rewrite /exp_rot sin0 cos0 subrr 2!scale0r 2!addr0 det1. Qed.

Lemma det_exp_rot a w : norm w = 1 -> \det `e^(a, skew_mx w) = 1.
Proof.
move=> w1.
move: (exp_rot_is_ortho (half_angle a) w1).
move/orthogonal_det/eqP.
rewrite -(@eqr_expn2 _ 2%N) // expr1n sqr_normr expr2 -det_mulmx.
rewrite mulmxE mul_exp_rot; last by rewrite skew_mx3 w1 expr1n scaleN1r.
move/eqP; by rewrite halfP.
Qed.

Definition exp_rot_skew_mx_eigenvalues a : seq R[i] := [:: 1; expi a; expi (- a)].

Lemma eigenvalue_exp_rot a w : norm w = 1 ->
  eigenvalue (map_mx (fun x => x%:C) `e^(a, skew_mx w)) =1
    [pred k | k \in exp_rot_skew_mx_eigenvalues a].
Proof.
move=> u1 /= k.
rewrite inE eigenvalue_root_char -map_char_poly.
Abort.

(*Lemma trace_sqr_exp_rot_skew_mx (phi : angle R) w : norm w = 1 ->
  \tr `e^(phi, (skew_mx w) ^+ 2) = - (1 + 2%:R * cos phi) ^+ 2(*?*).
Proof.
move=> w1.
Abort.*)

Lemma Rz_exp_rot a : Rz a = `e^(a, skew_mx V.k).
Proof.
rewrite /Rz exp_rot_skew_mxE ?V.normk //.
rewrite !mxE /= expr0n /=. Simp.r. by rewrite expr1n mul1r subrK.
Qed.

(* the w vector of e(phi,w) is an axis *)
Lemma axial_vec_exp_rot a w : norm w = 1 -> axial_vec (`e^(a, skew_mx w)) = sin a *+ 2 *: w.
Proof.
move=> w1.
rewrite /axial_vec.
apply/rowP => i.
rewrite 2!mxE /=.
case: ifPn => [/eqP ->|].
  rewrite /exp_rot.
  rewrite 2!mxE 1![in RHS]mxE /= add0r mxE skewij.
  rewrite mxE {1}skew_mx2 mxE w1 expr1n mulmx_trE 3!mxE /= mulr0 subr0.
  rewrite 3!mxE /= add0r mxE skewij.
  rewrite mulrN opprD opprK.
  rewrite mxE skew_mx2 w1 expr1n mxE mulmx_trE 3!mxE /= mulr0 subr0.
  rewrite addrACA (mulrC (w``_1)) subrr addr0 -mulr2n.
  by rewrite mulrnAl.
rewrite ifnot0 => /orP [] /eqP -> /=.
  rewrite /exp_rot.
  rewrite 3!mxE /= add0r mxE skewij.
  rewrite mxE {1}skew_mx2 mxE w1 expr1n mulmx_trE 3!mxE /= mulr0 subr0.
  rewrite 3!mxE /= add0r mxE skewij.
  rewrite mulrN opprD opprK.
  rewrite mxE skew_mx2 w1 expr1n mxE mulmx_trE 3!mxE /= mulr0 subr0.
  by rewrite addrACA (mulrC (w``_0)) subrr addr0 mxE -[in LHS]mulr2n mulrnAl.
rewrite /exp_rot.
rewrite 3!mxE /= add0r mxE skewij.
rewrite mxE {1}skew_mx2 mxE w1 expr1n mulmx_trE 3!mxE /= mulr0 subr0.
rewrite 3!mxE /= add0r mxE skewij.
rewrite mulrN opprD opprK.
rewrite mxE skew_mx2 w1 expr1n mxE mulmx_trE 3!mxE /= mulr0 subr0.
by rewrite addrACA (mulrC (w``_0)) subrr addr0 mxE -[in LHS]mulr2n mulrnAl.
Qed.

Definition rodrigues (v : 'rV[R]_3) a w :=
  cos a *: v + (1 - cos a) * (v *d w) *: w + sin a *: (v *v w).

Lemma rodriguesP u a w : norm w = 1 ->
  rodrigues u a w = u *m `e^(a, skew_mx w).
Proof.
move=> w1.
rewrite /rodrigues.
rewrite addrAC !mulmxDr mulmx1 -!scalemxAr mulmxA !skew_mxE.
rewrite [in X in _ = _ + _ + X]crossmulC scalerN.
rewrite double_crossmul dotmulvv w1 [_ ^+ _]expr1n scale1r.
rewrite [in X in _ = _ + _ + X]dotmulC scalerBr opprB.
rewrite scalerA [in RHS](addrC (_ *: w)) [in RHS]addrA; congr (_ + _).
rewrite scalerDl opprD scaleNr opprK addrC addrA scale1r; congr (_ + _).
by rewrite addrAC subrr add0r.
Qed.

(* TODO: move? *)
Lemma norm1_neq0 (u : vector) : norm u = 1 -> u != 0.
Proof. rewrite -norm_eq0 => ->; exact: oner_neq0. Qed.

Lemma is_around_axis_exp_rot a u : norm u = 1 ->
  is_around_axis u (- a) (mx_lin1 (`e^(a, skew_mx u))).
Proof.
move=> u1.
pose f := W.pframe_of (norm1_neq0 u1).
split => /=.
- rewrite -rodriguesP // /rodrigues dotmulvv u1 expr1n mulr1 scalerBl.
  by rewrite scale1r addrCA subrr addr0 crossmulvv scaler0 addr0.
- rewrite -rodriguesP // /rodrigues dotmulC.
  move: (idotj f).
  rewrite {1}(normalizeI u1) => ->.
  rewrite mulr0 scale0r addr0 crossmulC.
  move: (icrossj f).
  rewrite {1}(normalizeI u1) => ->.
  by rewrite cosN sinN scalerN scaleNr.
- rewrite -rodriguesP // /rodrigues dotmulC.
  move: (idotk f).
  rewrite {1}(normalizeI u1) => ->.
  rewrite mulr0 scale0r addr0.
  move: (proj1 (oframe_posP f (frame_pos_crossmul (pframeP f)))) => /esym.
  rewrite (normalizeI u1) => ->.
  rewrite sinN opprK cosN.
  by rewrite addrC.
Qed.

(* expression alternative de exp_rot *)
Definition Rot (e : vector) (a : angle R) :=
 e^T *m e + (cos a) *: (1 - e^T *m e) + (sin a) *: skew_mx e.

Lemma Rot_is_exp_rot (e : vector) (a : angle R) : norm e = 1 ->
  Rot e a = `e^(a, skew_mx e).
Proof.
move=> e1.
rewrite /Rot /exp_rot addrAC skew_mx2 e1 expr1n.
rewrite -addrA addrCA -[in RHS]addrA [in RHS]addrCA; congr (_ + _).
rewrite scalerBr scalemx1 scalemx1 scalerBl scale1r.
rewrite -[in RHS](addrA (e^T *m e)) [in RHS](addrCA 1); congr (_ + _).
by rewrite scalerDr addrC addrA subrr add0r opprD scalerN opprK scalemx1.
Qed.

Lemma Rot_is_around_axis e (e1 : e != 0) (a : angle R) :
  is_around_axis e (- a) (mx_lin1 (Rot (normalize e) a)).
Proof.
move: (is_around_axis_exp_rot a (norm_normalize e1)).
rewrite Rot_is_exp_rot ?norm_normalize //.
apply is_around_axisZ => //.
by rewrite invr_gt0 ltr_neqAle norm_ge0 eq_sym norm_eq0 e1.
Qed.

Lemma axial_vec_Rot (e : vector) a : axial_vec (Rot e a) = sin a *: e *+ 2.
Proof.
rewrite /Rot 2!axial_vecD axial_vec_sym ?add0r; last by rewrite mul_tr_vec_sym.
rewrite axial_vec_sym ?add0r; last first.
  rewrite sym_scaler_closed (* TODO: delcare the right canonical to be able to use rpredZ *) //.
  by rewrite rpredD // ?sym1 // rpredN mul_tr_vec_sym.
rewrite axial_vecZ axial_vecE scalerMnr; congr (_ *: _).
rewrite unskewD skew_mxK unskewN.
move/esym: (antiE (skew_mx e)); rewrite (anti_skew e) => /eqP ->.
by rewrite linearN /= trmxK unskewN skew_mxK opprK -mulr2n.
Qed.

Lemma exp_rot_is_onto_SO M : M \is 'SO[R]_3 ->
  exists a u, M = `e^(a, skew_mx u).
Proof.
case/SO_is_around_axis => u [a [u1 au]].
exists (- a), u.
move: (is_around_axis_exp_rot (- a) u1).
rewrite opprK => au'.
apply (@same_rot _ u (norm1_neq0 u1) _ _ u 1 ltr01 _ (esym (scale1r _)) au au').
Qed.

End exponential_map_rot.

Notation "'`e^(' a ',' w ')'" := (exp_rot a w).

Section quaternion.

Local Open Scope quat_scope.

Variable R : rcfType.

Lemma quat_rot_is_Rot (q : quat R) : q \is uquat R -> ~~ pureq q ->
  let: (u, a) := polar_of_quat q in
  u != 0 ->
  is_around_axis u (a *+ 2) (Linear (quat_rot_is_linear q)).
Proof.
move=> q_isuqat. rewrite /pureq => q00 u0.
set a := atan _.
split.
- set u := normalize q`1.
  simpl in u.
  rewrite -/u in u0.
  by rewrite quat_rot_is_linearE quat_rot_axis.
- move: (W.pframe_of u0).
  set v := W.j _. set w := W.k _ => f.
  rewrite quat_rot_is_linearE quat_rotE /= (_ : q`1 *d v = 0); last first.
    move: (idotj f).
    rewrite normalizeI // ?norm_normalize //; last by rewrite -normalize_eq0.
   by move/eqP; rewrite dotmul_normalize => /eqP.
  rewrite scale0r mul0rn addr0.
  rewrite (_ : q`1 *v v = norm q`1 *: w); last first.
    move: (icrossj f) => /= ->.
    rewrite normalizeI ?norm_normalize //; last by rewrite -normalize_eq0.
    by rewrite [in RHS]crossmulC scalerN -linearZ /= norm_scale_normalize crossmulC.
  rewrite scalerMnl [in X in _ + X = _]scalerA; congr (_ *: _ + _ *: _).
  by rewrite polar_of_uquat_prop.
  by rewrite mulrnAl polar_of_uquat_prop2.
- move: (W.pframe_of u0).
  set v := W.j _. set w := W.k _ => f.
  rewrite quat_rot_is_linearE quat_rotE /= (_ : q`1 *d w = 0); last first.
    move: (idotk f).
    rewrite normalizeI // ?norm_normalize //; last by rewrite -normalize_eq0.
    by move/eqP; rewrite dotmul_normalize => /eqP.
  rewrite scale0r mul0rn addr0.
  rewrite (_ : q`1 *v w = - norm q`1 *: v); last first.
    move: (icrossk f) => /=.
    rewrite normalizeI ?norm_normalize //; last by rewrite -normalize_eq0.
    move/eqP; rewrite -eqr_oppLR => /eqP <-.
  by rewrite [in RHS]crossmulC opprK -linearZ /= scaleNr norm_scale_normalize linearN /= crossmulC.
rewrite addrC; congr (_ + _ *: _); last first.
  by rewrite -polar_of_uquat_prop.
rewrite scaleNr scalerN scalerA mulNrn scalerMnl -scaleNr; congr (_ *: _).
by rewrite polar_of_uquat_prop2.
Qed.

End quaternion.

Module Iso.
Section isometry.
Variables (R : rcfType) (n : nat).
Record t := mk {
  f :> 'rV[R]_n -> 'rV[R]_n ;
  P : {mono f : a b / norm (a - b)} }.
End isometry.
End Iso.

Notation "''Iso[' R ]_ n" := (Iso.t R n)
  (at level 8, n at level 2, format "''Iso[' R ]_ n").
Definition isometry_coercion := Iso.f.
Coercion isometry_coercion : Iso.t >-> Funclass.

Module CIso.
Section central_isometry.
Variable (R : rcfType) (n : nat).
Record t := mk {
  f : 'Iso[R]_n ;
  P : f 0 = 0 }.
End central_isometry.
End CIso.

Notation "''CIso[' R ]_ n" := (CIso.t R n)
  (at level 8, n at level 2, format "''CIso[' R ]_ n").
Definition cisometry_coercion := CIso.f.
Coercion cisometry_coercion : CIso.t >-> Iso.t.

Section isometry_def.

Variable (R : rcfType) (n : nat).
Let coordinate := 'rV[R]_n.

Lemma central_isometry_preserves_norm (f : 'CIso[R]_n) : {mono f : x / norm x}.
Proof. by case: f => f f0 p; rewrite -(subr0 (f p)) -f0 Iso.P subr0. Qed.

Lemma central_isometry_preserves_dotmul (f : 'CIso[R]_n) : {mono f : u v / u *d v}.
Proof.
case: f => f f0 a b.
have : norm (f a - f b) = norm (a - b) by rewrite (Iso.P f).
rewrite /norm => /eqP.
rewrite eqr_sqrt ?le0dotmul // !dotmulDl !dotmulDr !dotmulvv !normN.
rewrite !(central_isometry_preserves_norm (CIso.mk f0)) !addrA 2!(addrC _ (norm b ^+ 2)).
move/eqP/addrI.
rewrite -2!addrA => /addrI.
rewrite -(dotmulC (f a)) dotmulvN -(dotmulC a) dotmulvN -2!mulr2n.
move/eqP.
rewrite -mulr_natr -[in X in _ == X -> _]mulr_natr 2!mulNr eqr_opp.
by move/eqP/mulIr => -> //; rewrite unitfE pnatr_eq0.
Qed.

End isometry_def.

Section sign_of_isometry.

Variable R : rcfType.
Let vector := 'rV[R]_3.
Let coordinate := 'rV[R]_3.

Lemma frame_central_iso (f : 'CIso[R]_3) i j k :
  oframe i j k -> oframe (f i) (f j) (f k).
Proof.
case => *; apply mkOFrame; by
  rewrite /= central_isometry_preserves_norm ||
  rewrite /= central_isometry_preserves_dotmul.
Qed.

Lemma central_isometry_is_linear (f : 'CIso[R]_3) : linear f.
Proof.
move=> k /= a b.
have Hp : forall p, f p = p``_0 *: f V.i + p``_1 *: f V.j + p``_2%:R *: f V.k.
  move=> p.
  have -> : f p = f p *d f V.i *: f V.i + f p *d f V.j *: f V.j + f p *d f V.k *: f V.k.
    rewrite -orthogonal_expansion //.
    apply frame_central_iso => //; exact: V.oframe.
  by rewrite 3!central_isometry_preserves_dotmul // -V.icoor -V.jcoor -V.kcoor.
rewrite Hp (Hp a) (Hp b) !mxE /= !(scalerDl, scalerDr).
rewrite !scalerA -!addrA; congr (_ + _).
rewrite addrC -!addrA; congr (_ + _).
rewrite addrC -!addrA; congr (_ + _).
by rewrite addrC -!addrA.
Qed.

Definition lin1_mx' n (f : 'rV[R]_n -> 'rV[R]_n) : linear f ->
  {M : {linear 'rV[R]_n -> 'rV[R]_n} & forall x, f x = M x}.
Proof.
move=> H.
have @g : {linear 'rV[R]_n -> 'rV[R]_n}.
  exists f; exact: (GRing.Linear.class_of_axiom H).
by exists g.
Defined.

Lemma trans_ortho_of_iso (f : 'Iso[R]_3) :
  { trans : 'rV[R]_3 & { rot : 'M[R]_3 |
    (forall x : 'rV[R]_3, f x == x *m rot + trans) /\
    rot \is 'O[R]_3 /\
    trans = f 0 } }.
Proof.
set T := f 0.
set Tm1f := fun x => f x - T.
have Tm1f_is_iso : {mono Tm1f : a b / norm (a - b)}.
  move=> ? ?; by rewrite /Tm1f -addrA opprB 2!addrA subrK (Iso.P f).
have Tm1f0 : Tm1f 0 = 0 by rewrite /Tm1f subrr.
have /= linearTm1f : linear (@CIso.mk _ _ (Iso.mk Tm1f_is_iso) Tm1f0).
  by apply: central_isometry_is_linear.
have orthogonalTm1f : {mono Tm1f : u v / u *d v}.
  move=> ? ?; by rewrite (central_isometry_preserves_dotmul
    (@CIso.mk _ _ (Iso.mk Tm1f_is_iso) Tm1f0)).
exists T.
case: (lin1_mx' linearTm1f) => g Hg.
exists (lin1_mx g); split; last first.
  split; last by done.
  apply orth_preserves_dotmul => u v /=.
  by rewrite 2!mul_rV_lin1 -[in RHS]orthogonalTm1f 2!Hg.
move=> u; by rewrite mul_rV_lin1 -Hg subrK.
Qed.

Definition ortho_of_iso (f : 'Iso[R]_3) : 'M[R]_3 := projT1 (projT2 (trans_ortho_of_iso f)).

Definition trans_of_iso (f : 'Iso[R]_3) : 'rV[R]_3 := projT1 (trans_ortho_of_iso f).

Lemma trans_of_isoE (f : 'Iso[R]_3) : trans_of_iso f = f 0.
Proof.
rewrite /trans_of_iso; by case: (trans_ortho_of_iso _) => T [C [H1 [H2 H3]]] /=.
Qed.

Lemma ortho_of_iso_is_O f : ortho_of_iso f \is 'O[R]_3.
Proof.
rewrite /ortho_of_iso; by case: (trans_ortho_of_iso _) => T [C [H1 [H2 H3]]] /=.
Qed.

Lemma trans_ortho_of_isoE f u : u *m ortho_of_iso f = f u - trans_of_iso f.
Proof.
rewrite /ortho_of_iso /trans_of_iso.
case: (trans_ortho_of_iso _) => T [C [H1 [H2 H3]]] /=.
move: (H1 u) => /eqP ->; by rewrite addrK.
Qed.

Lemma img_vec_iso (f : 'Iso[R]_3) (a b : coordinate) :
  f b - f a = (b - a) *m ortho_of_iso f.
Proof.
move/esym/eqP: (trans_ortho_of_isoE f a).
move/esym/eqP: (trans_ortho_of_isoE f b).
rewrite mulmxBl => /eqP <- /eqP <-; by rewrite opprB addrA subrK.
Qed.

Lemma ortho_of_iso_eq (f1 f2 : 'Iso[R]_3) :
  (forall i, Iso.f f1 i = Iso.f f2 i) ->
  ortho_of_iso f1 = ortho_of_iso f2.
Proof.
move=> f12.
apply/eqP/mulmxP => u.
rewrite 2!trans_ortho_of_isoE /= 2!trans_of_isoE /=.
case: f1 f2 f12 => [f1 Hf1] [f2 Hf2] /= f12.
by rewrite !f12.
Qed.

Definition iso_sgn (f : 'Iso[R]_3) : R := \det (ortho_of_iso f).

End sign_of_isometry.

Module DIso.
Section direct_isometry.
Variable (R : rcfType).
Record t := mk {
  f : 'Iso[R]_3 ;
  P : iso_sgn f == 1 }.
End direct_isometry.
End DIso.

Notation "''DIso_3[' R ]" := (DIso.t R)
  (at level 8, format "''DIso_3[' R ]").
Definition disometry_coercion := DIso.f.
Coercion disometry_coercion : DIso.t >-> Iso.t.

Section tangent_vectors_and_frames.

Variable R : rcfType.
Let vector := 'rV[R]_3.
Let coordinate := 'rV[R]_3.

(* tangent vector *)
Record tvec (p : coordinate) := TVec {tvec_field :> vector}.
Definition vtvec p (v : tvec p) := let: TVec v := v in v.

Local Notation "p .-vec" := (tvec p) (at level 5).

Definition tframe_i p u1 u2 u3 (f : tframe p u1 u2 u3) : p.-vec := TVec p u1.
Definition tframe_j p u1 u2 u3 (f : tframe p u1 u2 u3) : p.-vec := TVec p u2.
Definition tframe_k p u1 u2 u3 (f : tframe p u1 u2 u3) : p.-vec := TVec p u3.

End tangent_vectors_and_frames.

Coercion vtvec_field_coercion := vtvec.
Notation "p .-vec" := (tvec p) (at level 5).

Section derivative_map.

Variable R : rcfType.
Let vector := 'rV[R]_3.
Let coordinate := 'rV[R]_3.

(* theorem 2.1, p. 104, o'neill *)
Definition dmap (f : 'Iso[R]_3) p (v : p.-vec) :=
  let C := ortho_of_iso f in
  TVec (f p) (v *m C).

Local Notation "f '`*'" := (@dmap f _) (at level 5, format "f `*").

Lemma dmap0 (f : 'Iso[R]_3) p : f `* (TVec p 0) = TVec (f p) 0.
Proof. by rewrite /dmap /= mul0mx. Qed.

Lemma derivative_map_preserves_length (f : 'Iso[R]_3) p :
  {mono (fun x : p.-vec => f`* x) : u v / norm (vtvec u - vtvec v)}.
Proof.
move=> u v; rewrite /dmap /= -(mulmxBl (vtvec u) (vtvec v) (ortho_of_iso f)).
by rewrite orth_preserves_norm // ortho_of_iso_is_O.
Qed.

Lemma dmap_iso_sgnP p e1 e2 e3 (tf : tframe p e1 e2 e3) (f : 'Iso[R]_3) :
  f`* (TVec p e1) *d (f `* (TVec p e2) *v f`* (TVec p e3)) =
  iso_sgn f * (e1 *d (e2 *v e3)).
Proof.
case: tf => fo.
move: (orthogonal_expansion e1 (V.oframe R)).
set a11 := _ *d V.i. set a12 := _ *d V.j. set a13 := _ *d V.k => He1.
move: (orthogonal_expansion e2 (V.oframe R)).
set a21 := _ *d V.i. set a22 := _ *d V.j. set a23 := _ *d V.k => He2.
move: (orthogonal_expansion e3 (V.oframe R)).
set a31 := _ *d V.i. set a32 := _ *d V.j. set a33 := _ *d V.k => He3.
have e1a : e1 = row3 a11 a12 a13.
  apply/rowP => i; rewrite !mxE /=.
  case: ifPn => [/eqP ->|]; first by rewrite /a11 V.icoor.
  rewrite ifnot0 => /orP [] /eqP -> /=; by [rewrite /a12 V.jcoor | rewrite /a13 V.kcoor].
have e2a : e2 = row3 a21 a22 a23.
  apply/rowP => i; rewrite !mxE /=.
  case: ifPn => [/eqP ->|]; first by rewrite /a21 V.icoor.
  rewrite ifnot0 => /orP [] /eqP -> /=; by [rewrite /a22 V.jcoor | rewrite /a23 V.kcoor].
have e3a : e3 = row3 a31 a32 a33.
  apply/rowP => i; rewrite !mxE /=.
  case: ifPn => [/eqP ->|]; first by rewrite /a31 V.icoor.
  rewrite ifnot0 => /orP [] /eqP -> /=; by [rewrite /a32 V.jcoor | rewrite /a33 V.kcoor].
transitivity (\det ((ortho_of_iso f)^T *m
  (col_mx3 (row3 a11 a12 a13) (row3 a21 a22 a23) (row3 a31 a32 a33))^T)).
  rewrite /= -det_tr trmx_mul trmxK mulmx_col3.
  by rewrite -crossmul_triple -e1a -e2a -e3a trmxK.
rewrite det_mulmx det_tr; congr (_ * _).
rewrite det_tr -crossmul_triple; by congr (_ *d (_ *v _)).
Qed.

Lemma dmap_preserves_crossmul p (u v : p.-vec) (f : 'Iso[R]_3) :
  f`* (TVec p (u *v v)) =
    iso_sgn f *: vtvec (TVec (f p) ((f`* u) *v (f`* v))) :> vector.
Proof.
set tf : tframe _ _ _ _ := tframe_trans (TFrame 0 (V.oframe R)) p.
set u1p := tframe_i tf. set u2p := tframe_j tf. set u3p := tframe_k tf.
move: (orthogonal_expansion u (oframe_of_tframe tf)).
set u1 := _ *d V.i. set u2 := _ *d V.j. set u3 := _ *d V.k => Hu.
move: (orthogonal_expansion v (oframe_of_tframe tf)).
set v1 := _ *d V.i. set v2 := _ *d V.j. set v3 := _ *d V.k => Hv.
set e1 := f`* (TVec p u1p). set e2 := f`* (TVec p u2p). set e3 := f`* (TVec p u3p).
have Ku : f`* u = u1 *: vtvec e1 + u2 *: vtvec e2 + u3 *: vtvec e3 :> vector.
  by rewrite /= Hu 2!mulmxDl !scalemxAl.
have Kv : f`* v = v1 *: vtvec e1 + v2 *: vtvec e2 + v3 *: vtvec e3 :> vector.
  by rewrite /= Hv 2!mulmxDl !scalemxAl.
have f' : oframe e1 e2 e3.
  split => //.
  by rewrite orth_preserves_norm ?ortho_of_iso_is_O // V.normi.
  by rewrite orth_preserves_norm ?ortho_of_iso_is_O // V.normj.
  by rewrite orth_preserves_norm ?ortho_of_iso_is_O // V.normk.
  rewrite (proj2 (orth_preserves_dotmul (ortho_of_iso f)) _) ?ortho_of_iso_is_O //.
  by case: (V.oframe R).
  rewrite (proj2 (orth_preserves_dotmul (ortho_of_iso f)) _) ?ortho_of_iso_is_O //.
  by case: (V.oframe R).
  rewrite (proj2 (orth_preserves_dotmul (ortho_of_iso f)) _) ?ortho_of_iso_is_O //.
  by case: (V.oframe R).
have -> : iso_sgn f = frame_sgn f'.
  rewrite /frame_sgn dmap_iso_sgnP /=.
    by rewrite (jcrossk (V.frame _)) dotmulvv V.normi expr1n mulr1.
  by apply (TFrame _ (V.oframe R)).
have : vtvec (TVec (f p) ((f`* u) *v (f`* v))) =
         frame_sgn f' *: vtvec (f`* (TVec p (u *v v))) :> vector.
  rewrite /=.
  rewrite (@crossmul_oframe_sgn _ e1 e2 e3 _ (f`* u) u1 u2 u3 (f`* v) v1 v2 v3) //.
  rewrite /=.
  congr (_ *: _).
  have -> : V.i *m ortho_of_iso f = vtvec e1 by done.
  have -> : V.j *m ortho_of_iso f = vtvec e2 by done.
  have -> : V.k *m ortho_of_iso f = vtvec e3 by done.
  rewrite Hu Hv.
  do 2 rewrite linearD [in RHS]/=.
  rewrite 2!mulmxDl.
  (* on fait les remplacement veci *v vecj -> veck, veci *v veci -> 0, etc. *)
  rewrite [in RHS]linearZ [in RHS]/=.
  rewrite [in RHS]linearZ [in RHS]/=.
  rewrite [in RHS]linearZ [in RHS]/=.
  rewrite crossmulC scalerN.
  rewrite linearD [in RHS]/=.
  rewrite [in X in _ = - (_ *: X) *m _ + _ + _]linearD.
  rewrite [in RHS]/=.
  rewrite (_ : V.i *v (u1 *: _) = 0); last by rewrite linearZ /= crossmulvv scaler0.
  rewrite (_ : V.i *v (u2 *: _) = u2 *: V.k); last first.
    by rewrite linearZ /= -(icrossj (V.frame _)).
  rewrite (_ : V.i *v (u3 *: _) = - u3 *: V.j); last first.
    by rewrite linearZ /= (icrossk (V.frame _)) scalerN scaleNr.
  rewrite add0r.
  rewrite mulNmx -[in RHS]scalemxAl [in RHS]mulmxDl.
  rewrite -![in RHS]scalemxAl.
  have -> : V.k *m ortho_of_iso f = vtvec e3 by done.
  have -> : V.j *m ortho_of_iso f = vtvec e2 by done.
  rewrite [in RHS]scalerDr.
  rewrite opprD.
  rewrite crossmulC [in X in _ = _ + X + _]linearD [in X in _ = _ + X + _]/=.
  rewrite opprD.
  rewrite [in X in _ = _ + X + _]linearD [in X in _ = _ + X + _]/=.
  rewrite scaleNr scalerN opprK.
  rewrite (_ : _ *v _ = - u1 *: V.k); last first.
    by rewrite linearZ /= crossmulC -(icrossj (V.frame _)) scalerN scaleNr.
  rewrite (_ : _ *v _ = 0); last first.
    by rewrite linearZ /= crossmulvv scaler0.
  rewrite addr0.
  rewrite (_ : _ *v _ = u3 *: V.i); last by rewrite linearZ /= (jcrossk (V.frame _)).
  rewrite scaleNr opprK mulmxBl.
  rewrite -![in RHS]scalemxAl.
  have -> : V.i *m ortho_of_iso f = vtvec e1 by done.
  have -> : V.k *m ortho_of_iso f = vtvec e3 by done.
  rewrite scalerDr scalerN.
  rewrite crossmulC [in X in _ = _ + _ + X]linearD [in X in _ = _ + _ + X]/=.
  rewrite opprD.
  rewrite [in X in _ = _ + _ + X]linearD [in X in _ = _ + _ + X]/=.
  rewrite opprD.
  rewrite (_ : _ *v _ = u1 *: V.j); last first.
    by rewrite linearZ /= crossmulC (icrossk (V.frame _)) opprK.
  rewrite (_ : _ *v _ = - u2 *: V.i); last first.
    by rewrite linearZ /= crossmulC (jcrossk (V.frame _)) scalerN scaleNr.
  rewrite (_ : _ *v _ = 0); last first.
    by rewrite linearZ /= crossmulvv scaler0.
  rewrite subr0 scaleNr opprK mulmxDl mulNmx.
  rewrite -![in RHS]scalemxAl.
  have -> : V.i *m ortho_of_iso f = vtvec e1 by done.
  have -> : V.j *m ortho_of_iso f = vtvec e2 by done.
  (* on a une expression uniquement avec des vtvec e1, etc. -> on identifie rhs et lhs *)
  rewrite -![in RHS]addrA [in RHS]addrC -[in RHS]addrA [in RHS]addrCA -[in RHS]addrA [in RHS]addrC.
  rewrite ![in RHS]addrA -[in RHS]addrA.
  congr (_ + _); last first.
    by rewrite !scalerA -scaleNr -scalerDl addrC mulrC (mulrC u1).
  rewrite scalerDr.
  rewrite -![in RHS]addrA [in RHS]addrCA [in RHS]addrC ![in RHS]addrA -addrA; congr (_ + _).
  by rewrite !scalerA -scaleNr -scalerDl addrC mulrC (mulrC u2).
  by rewrite scalerN !scalerA -scalerBl -scaleNr opprB mulrC (mulrC u1).
move=> ->; by rewrite scalerA -expr2 /iso_sgn -sqr_normr frame_sgn1 expr1n scale1r.
Qed.

Definition preserves_orientation (f : 'Iso[R]_3) :=
  forall p (u v : p.-vec),
  f`* (TVec p (u *v v)) = TVec (f p) ((f`* u) *v (f`* v))
  :> vector.

Lemma direct_iso_preserves_crossmul (f : 'DIso_3[R]) : preserves_orientation f.
Proof. move=> p u v; by rewrite dmap_preserves_crossmul (eqP (DIso.P f)) scale1r. Qed.

Lemma preserves_crossmul_is_direct_iso p (u v : p.-vec) (f : 'Iso[R]_3) :
  ~~ colinear u v ->
  f`* (TVec p (u *v v)) = TVec (f p) ((f`* u) *v (f`* v)) :> vector ->
  iso_sgn f == 1.
Proof.
move=> uv0.
rewrite dmap_preserves_crossmul /iso_sgn => H.
apply/eqP.
move: (orthogonal_det (ortho_of_iso_is_O f)).
case: (lerP 0 (\det (ortho_of_iso f))) => K; first by rewrite ger0_norm.
rewrite ltr0_norm // => /eqP.
rewrite eqr_oppLR => /eqP K1.
rewrite K1 scaleN1r /= in H.
move/esym/opp_self : H.
move: (mulmxr_crossmulr (vtvec u) (vtvec v) (ortho_of_iso_is_O f)).
rewrite K1 scaleN1r.
move/esym/eqP.
rewrite eqr_oppLR => /eqP -> /eqP.
rewrite oppr_eq0 mul_mx_rowfree_eq0; last first.
  apply/row_freeP.
  exists (ortho_of_iso f)^T.
  apply/eqP.
  by rewrite -orthogonalE ortho_of_iso_is_O.
move: uv0.
rewrite /colinear; by move/negbTE => ->.
Qed.

End derivative_map.

Notation "f '`*'" := (@dmap _ f _) (at level 5, format "f '`*'").

Notation "''H[' R ]" := ('M[R]_4) (at level 8, format "''H[' R ]").
Notation "''hV[' R ]" := ('rV[R]_4) (at level 8, format "''hV[' R ]").

Module SE.
Record t (R : rcfType) : Type := mk {
  trans : 'rV[R]_3;
  rot : 'M[R]_3 ;
  rotP : rot \in 'SO[R]_3 }.

Module h.
Section homogeneous_coordinates.
Variable R : rcfType.

Definition rot (T : t R) : 'H[R] := row_mx (col_mx (rot T) 0) (col_mx 0 1).

Definition trans (T : t R) : 'H[R] := row_mx (col_mx 1 0) (col_mx (trans T)^T 1).

Coercion mx R (T : t R) : 'H[R] := row_mx (col_mx (SE.rot T) 0) (col_mx (SE.trans T)^T 1).

Lemma tE (T : t R) : T = trans T *m rot T :> 'H[R].
Proof.
rewrite /mx /trans /rot.
rewrite (mul_mx_row (row_mx (col_mx 1 0) (col_mx (SE.trans T)^T 1)) (col_mx (SE.rot T) 0)).
rewrite mul_row_col mulmx0 addr0 mul_row_col mulmx0 add0r mulmx1 mul_col_mx.
by rewrite mul1mx mul0mx.
Qed.

Definition inv_trans (T : t R) : 'H[R] := row_mx (col_mx 1 0) (col_mx (- (SE.trans T)^T) 1).

Lemma inv_transP (T : t R) : trans T *m inv_trans T = 1.
Proof.
rewrite /trans /inv_trans.
rewrite (mul_mx_row (row_mx (col_mx 1 0) (col_mx (SE.trans T)^T 1)) (col_mx 1 0)).
rewrite (mul_row_col (col_mx 1 0) (col_mx (SE.trans T)^T 1)) mulmx0 addr0 mulmx1.
rewrite (mul_row_col (col_mx 1 0) (col_mx (SE.trans T)^T 1)) mulmx1.
rewrite mul_col_mx mul1mx mul0mx add_col_mx addrC subrr add0r.
rewrite -(block_mxEh 1 0 0 1).
rewrite -[in RHS](@submxK _ 3 1 3 1 (1 : 'H[R])).
congr (@block_mx _ 3 1 3 1); apply/matrixP => i j.
by rewrite !mxE -!val_eqE.
rewrite !mxE -val_eqE /= (ord1 j) addn0.
move: (ltn_ord i); by rewrite ltn_neqAle => /andP [] /negbTE ->.
rewrite !mxE -val_eqE /= (ord1 i) addn0.
by move: (ltn_ord j); rewrite ltn_neqAle eq_sym => /andP [] /negbTE ->.
by rewrite !mxE -!val_eqE.
Qed.

Let coordinate := 'rV[R]_3.
Inductive coor := Cor of coordinate.
Coercion from_coor (p : coor) : 'hV[R] := let: Cor x := p in row_mx x 1.
Definition coor_of (x : 'hV[R]) : coordinate :=
  lsubmx (castmx (erefl, esym (addn1 3)) x).
Lemma coor_ofB (a b : 'hV[R]) : coor_of (a - b) = coor_of a - coor_of b.
Proof. apply/rowP => i; by rewrite !mxE !castmxE /= esymK !cast_ord_id !mxE. Qed.

Definition ap_coor (T : t R) (x : coordinate) : 'hV[R] := Cor x *m T^T.

Lemma ap_coorE (p : coordinate) (T : t R) :
  ap_coor T p = p *m row_mx (SE.rot T)^T 0 + row_mx (SE.trans T) 1.
Proof.
rewrite /ap_coor /mx /= (tr_row_mx (col_mx (SE.rot T) 0)) (mul_row_col p 1).
by rewrite mul1mx tr_col_mx trmx0 tr_col_mx trmx1 trmxK.
Qed.

Let vector := 'rV[R]_3.
Inductive vect := Vec of vector.
Coercion from_vect (v : vect) : 'hV[R] := let: Vec x := v in row_mx x 0.
Definition vect_of (x : 'hV[R]) : vector :=
  lsubmx (castmx (erefl, esym (addn1 3)) x).

Definition ap_vect (T : t R) (x : vector) : 'hV[R] := Vec x *m T^T.

Lemma ap_vectE (u : vector) (T : t R) : ap_vect T u = u *m row_mx (SE.rot T)^T 0.
Proof.
rewrite /ap_vect /mx /= (tr_row_mx (col_mx (SE.rot T) 0)).
by rewrite (mul_row_col u 0) mul0mx addr0 tr_col_mx trmx0.
Qed.

Lemma linear_ap_vect (T : t R) : linear (ap_vect T).
Proof. move=> k u v; by rewrite 3!ap_vectE mulmxDl scalemxAl. Qed.

Lemma ap_coorB u v (T : t R) : ap_coor T u - ap_coor T v = ap_vect T (u - v).
Proof.
by rewrite 2!ap_coorE opprD -addrCA -addrA subrr addr0 addrC ap_vectE mulmxBl.
Qed.

End homogeneous_coordinates.
End h.

Section se.
Variable R : rcfType.

Let coordinate := 'rV[R]_3.
Let vector := 'rV[R]_3.

Definition ap_coor (T : t R) (x : coordinate) : coordinate :=
  h.coor_of (h.ap_coor T x).

Lemma ap_coorE u (T : t R) :
  ap_coor T u = lsubmx (castmx (erefl, esym (addn1 3)) (SE.h.ap_coor T u)).
Proof. apply/rowP => i; by rewrite !mxE castmxE /= esymK cast_ord_id !mxE. Qed.

Definition ap_vect (T : t R) (u : vector) : vector :=
  h.vect_of (h.ap_vect T u).

Lemma ap_coorB u v (T : t R) : ap_coor T u - ap_coor T v = ap_vect T (u - v).
Proof. by rewrite /ap_vect /ap_coor -h.coor_ofB h.ap_coorB. Qed.

Lemma ap_vectE u (T : t R) : ap_vect T u = u *m (SE.rot T)^T.
Proof.
rewrite /ap_vect h.ap_vectE /SE.h.vect_of mul_mx_row mulmx0.
rewrite (_ : esym (addn1 3) = erefl (1 + 3)%N); last by apply eq_irrelevance.
by rewrite (@cast_row_mx _ _ _ 3) row_mxKl.
Qed.

Lemma ap_vect_preserves_norm (T : t R) : {mono (ap_vect T) : u / norm u}.
Proof.
move=> u.
rewrite /ap_vect h.ap_vectE /h.vect_of mul_mx_row mulmx0.
rewrite (_ : esym (addn1 3) = erefl (3 + 1)%N); last by apply eq_irrelevance.
rewrite (cast_row_mx _ (u *m (SE.rot T)^T)) row_mxKl castmx_id.
rewrite orth_preserves_norm // orthogonalV rotation_sub //; by case: T.
Qed.

End se.

End SE.

Coercion hmx_coercion := SE.h.mx.
Coercion homogeneous_of_hcoor_coercion := SE.h.from_coor.
Coercion homogeneous_of_hvect_coercion := SE.h.from_vect.

Notation "''SE_3[' R ]" := (SE.t R)
  (at level 8, format "''SE_3[' R ]").

Section homogeneous_transformation.

Variable R : rcfType.
Let vector := 'rV[R]_3.
Let coordinate := 'rV[R]_3.
Implicit Types u v : vector.

Lemma coor_of_hE (x : 'hV[R]) : SE.h.coor_of x = \row_(i < 3) x 0 (inord i).
Proof.
apply/rowP => i; rewrite !mxE castmxE /= esymK !cast_ord_id; congr (x 0 _).
apply val_inj => /=; by rewrite inordK // (ltn_trans (ltn_ord i)).
Qed.

Lemma hcoor_inv_htrans u (T : 'SE_3[R]) :
  SE.h.Cor u *m (SE.h.inv_trans T)^T = SE.h.Cor (u - (SE.trans T)) :> 'hV[R].
Proof.
rewrite /SE.h.inv_trans /= (tr_row_mx (col_mx 1 0) (col_mx (- (SE.trans T)^T) 1)).
rewrite 2!tr_col_mx !trmx1 trmx0 (mul_row_col u) mul1mx (mul_mx_row u 1).
by rewrite mulmx1 mulmx0 (add_row_mx u) add0r linearN /= trmxK.
Qed.

Lemma hcoor_hrot_of_transform u (T : 'SE_3[R]) :
  (SE.h.Cor u) *m (SE.h.rot T)^T = SE.h.Cor (u *m (SE.rot T)^T) :> 'hV[R].
Proof.
rewrite /SE.h.rot /= (tr_row_mx (col_mx (SE.rot T) 0)) !tr_col_mx !trmx0 trmx1.
rewrite (mul_row_col u) mul1mx (mul_mx_row u (SE.rot T)^T) mulmx0 (add_row_mx (u *m (SE.rot T)^T)).
by rewrite addr0 add0r.
Qed.

End homogeneous_transformation.

Section rigid_transformation_is_homogeneous_transformation.

(*
Record object (A : frame) := {
  object_size : nat ;
  body : (coor A ^ object_size)%type }.
*)

Variable R : rcfType.
Let vector := 'rV[R]_3.
Let coordinate := 'rV[R]_3.

Lemma direct_iso_is_SE (f : 'DIso_3[R]) :
  exists T : 'SE_3[R], f =1 SE.ap_coor T.
Proof.
case: f => /= f r1.
rewrite /iso_sgn /ortho_of_iso.
pose t := trans_of_iso f.
pose r := ortho_of_iso f.
have tf0 := trans_of_isoE f.
have Hr : r^T \is 'SO[R]_3 by rewrite rotationV rotationE ortho_of_iso_is_O.
set T := SE.mk t Hr.
exists T => i.
rewrite SE.ap_coorE /SE.h.ap_coor.
rewrite SE.h.tE trmx_mul mulmxA.
set fromi := SE.h.Cor i *m _.
suff <- : SE.h.Cor (f i) = fromi *m (SE.h.trans T)^T :> 'hV[R].
  rewrite (_ : esym (addn1 3) = erefl (3 + 1)%N); last by apply eq_irrelevance.
  by rewrite (cast_row_mx _ (f i)) row_mxKl castmx_id.
rewrite -[LHS]mulmx1 -trmx1.
move: (SE.h.inv_transP T) => /(congr1 trmx) => <-.
rewrite trmx_mul mulmxA; congr (_ *m _).
rewrite {}/fromi.
suff : f i - t = i *m r.
  rewrite hcoor_inv_htrans => ->.
  by rewrite hcoor_hrot_of_transform trmxK.
by rewrite (trans_ortho_of_isoE f i).
Qed.

Lemma SE_preserves_length f (T : 'SE_3[R]) :
  f =1 SE.ap_coor T -> {mono f : a b / norm (a - b)}.
Proof. move=> fT m0 m1; by rewrite 2!fT SE.ap_coorB SE.ap_vect_preserves_norm. Qed.

Lemma ortho_of_isoE f (T : 'SE_3[R]) (fT : f =1 SE.ap_coor T) :
  ortho_of_iso (Iso.mk (SE_preserves_length fT)) = (SE.rot T)^T.
Proof.
have H : {mono (SE.ap_coor T) : a b / norm (a - b)}.
  move=> u v /=; by rewrite SE.ap_coorB SE.ap_vect_preserves_norm.
suff : forall x : 'rV[R]_3, x *m ortho_of_iso (Iso.mk H) = x *m (SE.rot T)^T.
  move=> Hx.
  apply/eqP/mulmxP => u.
  rewrite -Hx /=; congr (_ *m _).
  by apply ortho_of_iso_eq.
move=> x.
by rewrite trans_ortho_of_isoE /= trans_of_isoE /= SE.ap_coorB subr0 SE.ap_vectE.
Qed.

Definition preserves_angle (f : coordinate -> coordinate) :=
  forall i j k, vec_angle (j - i) (k - i) =
                vec_angle (f j - f i) (f k - f i).

Lemma SE_preserves_angle f (T : 'SE_3[R]) :
  f =1 SE.ap_coor T -> preserves_angle f.
Proof.
move=> fT /= m0 m1 k.
rewrite 3!fT 2!SE.ap_coorB 2!SE.ap_vectE orth_preserves_vec_angle //.
by rewrite orthogonalV rotation_sub // SE.rotP.
Qed.

Lemma SE_preserves_orientation f (T : 'SE_3[R])
  (fT : f =1 SE.ap_coor T) :
  preserves_orientation (Iso.mk (SE_preserves_length fT)).
Proof.
move=> p u v /=.
rewrite mulmxr_crossmulr ?ortho_of_iso_is_O // ortho_of_isoE det_tr.
rewrite rotation_det ?scale1r //; by case: T fT.
Qed.

End rigid_transformation_is_homogeneous_transformation.

Section angle_axis.

Variable R : rcfType.
Let vector := 'rV[R]_3.

Record angle_axis := AngleAxis {
  angle_axis_val : angle R * vector ;
  _ : norm (angle_axis_val.2) == 1
 }.

Canonical angle_axis_subType := [subType for angle_axis_val].

Definition aangle (a : angle_axis) := (val a).1.
Definition aaxis (a : angle_axis) := (val a).2.

Lemma norm_axis a : norm (aaxis a) = 1.
Proof. by case: a => *; apply/eqP. Qed.

Fact norm_e1_subproof : norm (@delta_mx R _ 3 0 0) == 1.
Proof. by rewrite norm_delta_mx. Qed.

Definition angle_axis_of (a : angle R) (v : vector) :=
  insubd (@AngleAxis (a,_) norm_e1_subproof) (a, (norm v)^-1 *: v).

Lemma aaxis_of (a : angle R) (v : vector) : v != 0 ->
  aaxis (angle_axis_of a v) = (norm v)^-1 *: v.
Proof.
move=> v_neq0 /=; rewrite /angle_axis_of /aaxis val_insubd /=.
by rewrite normZ normfV normr_norm mulVf ?norm_eq0 // eqxx.
Qed.

(* NB: not used *)
Lemma aaxis_of1 (a : angle R) (v : vector) : norm v = 1 ->
  aaxis (angle_axis_of a v) = v.
Proof.
move=> v1; rewrite aaxis_of; last by rewrite -norm_eq0 v1 oner_neq0.
by rewrite v1 invr1 scale1r.
Qed.

Lemma aangle_of (a : angle R) (v : vector) : aangle (angle_axis_of a v) = a.
Proof. by rewrite /angle_axis_of /aangle val_insubd /= fun_if if_same. Qed.

(* see table 1.2 of handbook of robotics *)
Definition angle_of_rot (M : 'M[R]_3) := acos ((\tr M - 1) / 2%:R).
Definition axis_of_rot (M : 'M[R]_3) : 'rV[R]_3 :=
  let a := angle_of_rot M in 1 / ((sin a) *+ 2) *: axial_vec M.

Definition log_rot (M : 'M[R]_3) : angle R * 'rV[R]_3 :=
  (angle_of_rot M, axis_of_rot M).

Lemma log_exp_rot (a : angle R) (w : 'rV[R]_3) :
  sin a != 0 -> a \in Opi_closed R -> norm w = 1 ->
  log_rot `e^(a, skew_mx w) = (a, w).
Proof.
move=> sphi Ha w1 [:Hphi].
congr pair.
  abstract: Hphi.
  rewrite /angle_of_rot trace_exp_rot_skew_mx // addrAC subrr add0r.
  by rewrite mulrC mulrA mulVr ?mul1r ?(cosK Ha) // unitfE pnatr_eq0.
apply/rowP => i.
rewrite 2!mxE /= Hphi => [:twosphi].
case: ifPn => [/eqP ->|].
  rewrite 4!mxE /= skewij mxE sqr_skewE 2!mxE /= add0r.
  rewrite 4!mxE /= skewij mxE sqr_skewE 2!mxE /= add0r opprD addrAC addrA subrK.
  rewrite mulrN opprK -mulr2n -mulrnAl div1r mulrA mulVr ?mul1r //.
  abstract: twosphi.
  by rewrite unitfE mulrn_eq0 negb_or.
rewrite ifnot0 => /orP [] /eqP -> /=.
  rewrite 4!mxE /= skewij mxE sqr_skewE 2!mxE /= add0r.
  rewrite 4!mxE /= skewij mxE sqr_skewE 2!mxE /= add0r opprD addrAC addrA subrK.
  by rewrite mulrN opprK -mulr2n -mulrnAl mulrA div1r mulVr // mul1r.
rewrite 4!mxE /= skewij mxE sqr_skewE 2!mxE /= add0r.
rewrite 4!mxE /= skewij mxE sqr_skewE 2!mxE /= add0r opprD addrAC addrA subrK.
by rewrite mulrN opprK -mulr2n -mulrnAl mulrA div1r mulVr // mul1r.
Qed.

Lemma tr_angle_of_rot M : angle_of_rot M^T = angle_of_rot M.
Proof. by rewrite /angle_of_rot mxtrace_tr. Qed.

Lemma is_around_axis_angle_of_rot M u a : 
  u != 0 -> a \in Opi_closed R ->
  is_around_axis u a (mx_lin1 M) -> a = angle_of_rot M.
Proof.
move=> u0 Ha.
move/(tr_around_axis u0); rewrite /angle_of_rot => ->.
rewrite addrAC subrr add0r -(mulr_natr (cos a)) -mulrA divrr.
  by rewrite mulr1 cosK.
by rewrite unitfE pnatr_eq0.
Qed.

Lemma is_around_axis_angle_of_rotN M u a :
  u != 0 -> a \in piO_closed R ->
  is_around_axis u a (mx_lin1 M) -> a = - angle_of_rot M.
Proof.
move=> u0 Ha.
move/(tr_around_axis u0); rewrite /angle_of_rot => ->.
rewrite addrAC subrr add0r -(mulr_natr (cos a)) -mulrA divrr.
  by rewrite mulr1 cosKN // opprK.
by rewrite unitfE pnatr_eq0.
Qed.

(* NB: useful? *)
Lemma angle_of_rot_Rx a :
  (a \in Opi_closed R -> angle_of_rot (Rx a) = a) /\
  (a \in piO_closed R -> angle_of_rot (Rx a) = - a).
Proof.
split => Ha; rewrite /angle_of_rot tr_Rx addrAC subrr add0r
  -(mulr_natr (cos a)) -mulrA divrr ?unitfE ?pnatr_eq0 // mulr1;
  by [rewrite cosK | rewrite cosKN].
Qed.

Lemma angle_of_rot_RO M a : M = block_mx (1 : 'M_1) 0 0 (RO a) ->
  (a \in Opi_closed R -> angle_of_rot M = a) /\
  (a \in piO_closed R -> angle_of_rot M = - a).
Proof.
move=> Ma.
rewrite /angle_of_rot Ma (mxtrace_block (1 : 'M_1)) tr_RO mxtrace1 addrAC.
rewrite subrr add0r -(mulr_natr (cos a)) -mulrA divrr ?unitfE ?pnatr_eq0 // mulr1.
split => Ha; by [rewrite cosK | rewrite cosKN].
Qed.

Lemma rotation_is_Rx (M : 'M[R]_3) k (k0 : 0 < k) : M \is 'SO[R]_3 ->
  axial_vec M = k *: V.i ->
  angle_of_rot M \in Opi_closed R /\
  (M = Rx (- angle_of_rot M) \/ M = Rx (angle_of_rot M)).
Proof.
move=> MSO axialVi.
have [M02 M01] : M 0 2%:R = M 2%:R 0 /\ M 0 1 = M 1 0.
  move/matrixP/(_ 0 1) : (axialVi).
  rewrite !mxE /= mulr0 => /eqP; rewrite subr_eq add0r => /eqP ->.
  move/matrixP/(_ 0 2%:R) : (axialVi).
  by rewrite !mxE /= mulr0 => /eqP; rewrite subr_eq add0r => /eqP ->.
have axial_eigen : axial_vec M *m M = axial_vec M.
  move: (axial_vec_vec_eigenspace MSO) => /eigenspaceP; by rewrite scale1r.
have [M010 [M020 M001]] : M 0 1 = 0 /\ M 0 2%:R = 0 /\ M 0 0 = 1.
  move: axial_eigen.
  rewrite axialVi -scalemxAl => /scalerI.
  rewrite gtr_eqF // => /(_ isT) ViM.
  have : V.i *m M = row 0 M.
    rewrite rowE; congr (_ *m _); apply/rowP => i.
    rewrite !mxE /=; case: ifPn => //. by rewrite ifnot0 => /orP [] /eqP ->.
  rewrite {}ViM => ViM.
  move/matrixP : (ViM) => /(_ 0 1); rewrite !mxE /= => <-.
  move/matrixP : (ViM) => /(_ 0 2%:R); rewrite !mxE /= => <-.
  by move/matrixP : (ViM) => /(_ 0 0); rewrite !mxE /= => <-.
have [P MP] : exists P : 'M[R]_2, M = block_mx (1 : 'M_1) 0 0 P.
  exists (@drsubmx _ 1 2 1 2 M).
  rewrite -{1}(@submxK _ 1 2 1 2 M).
  rewrite (_ : ulsubmx _ = 1); last first.
    apply/matrixP => i j.
    rewrite (ord1 i) (ord1 j) !mxE /= -M001 mulr1n; congr (M _ _); by apply val_inj.
  rewrite (_ : ursubmx _ = 0); last first.
    apply/rowP => i.
    case/boolP : (i == 0) => [/eqP ->|].
      rewrite !mxE -[RHS]M010; congr (M _ _); by apply val_inj.
    rewrite ifnot01 => /eqP ->; rewrite !mxE -[RHS]M020; congr (M _ _); by apply val_inj.
  rewrite (_ : dlsubmx _ = 0) //.
  apply/colP => i.
  case/boolP : (i == 0) => [/eqP ->|].
    rewrite !mxE -[RHS]M010 M01; congr (M _ _); by apply val_inj.
  rewrite ifnot01 => /eqP ->; rewrite !mxE -[RHS]M020 M02; congr (M _ _); by apply val_inj.
have PSO : P \is 'SO[R]_2 by rewrite -(SO3_SO2 MP).
move=> [: Hangle].
split.
  abstract: Hangle.
  rewrite inE /angle_of_rot MP (mxtrace_block (1 : 'M_1)) mxtrace1 addrAC.
  rewrite subrr add0r sin_acos.
    by rewrite sqrtr_ge0.
  rewrite normrM normrV ?unitfE ?pnatr_eq0 // normr_nat ler_pdivr_mulr // mul1r.
  exact: tr_SO2.
case/rot2d : PSO => a PRO; rewrite {}PRO in MP.
case: (angle_in a) => Ha.
- move: (proj1 (angle_of_rot_RO MP) Ha) => MHa.
  right; by rewrite MHa MP Rx_RO.
- move: (proj2 (angle_of_rot_RO MP) Ha) => MHa.
  left; by rewrite MHa opprK MP Rx_RO.
Qed.

Coercion rodrigues_mx r :=
  let (a, w) := (aangle r, aaxis r) in `e^(a, skew_mx w).

(*Definition rodrigues (x : vector) r :=
  let (a, w) := (aangle r, aaxis r) in
  cos a *: x + (1 - cos a) * (x *d w) *: w + sin a *: (x *v w).

(* Rodrigues formula *)
Lemma rodriguesP u r : rodrigues u r = u *m r.
Proof.
...
Qed.*)

(* NB: useful? *)
Lemma trace_rodrigues r : \tr (rodrigues_mx r) = 1 + 2%:R * cos (aangle r).
Proof. by rewrite trace_exp_rot_skew_mx // norm_axis. Qed.

(* NB: useful? *)
Lemma rodrigues_mx_is_O r : norm (aaxis r) = 1 -> rodrigues_mx r \in 'O[R]_3.
Proof.
move=> axis1.
rewrite /rodrigues_mx orthogonalE tr_exp_rot {2}(eqP (anti_skew _)) linearN /= trmxK.
by rewrite inv_exp_rot // skew_mx4.
Qed.

(* NB: useful? *)
Lemma det_rodrigues_mx r : norm (aaxis r) = 1 -> \det (rodrigues_mx r) = 1.
Proof. move=> ?; by rewrite /rodrigues_mx det_exp_rot. Qed.

Lemma angle_of_rot_exp_rot a u : norm u = 1 ->
  angle_of_rot `e^(a, skew_mx u) = a.
Proof.
move=> u1.
rewrite /angle_of_rot trace_exp_rot_skew_mx // addrAC subrr add0r.
rewrite mulrAC divrr ?mul1r ?unitfE // ?pnatr_eq0 //.
Abort.

Lemma is_around_axis_axis_of_rot (M : 'M[R]_3) u a : 
  norm u = 1 -> sin a != 0 ->
  is_around_axis u a (mx_lin1 M) ->
  u = - (1 / (sin a *+ 2)) *: axial_vec M.
Proof.
move=> u1 sina0 H.
have -> : M = `e^( - a, skew_mx u).
  apply: (@same_rot _ u _ _ _ u 1 _ a) => //.
  by rewrite -norm_eq0 u1 oner_neq0.
  by rewrite scale1r.
  rewrite -{1}(opprK a); by apply is_around_axis_exp_rot.
rewrite axial_vec_exp_rot // sinN scalerA mulNrn mulrN mulNr opprK div1r.
by rewrite mulVr ?scale1r // unitfE mulrn_eq0 negb_or.
Qed.

(* TODO: do a direct proof not depending on exp_rot and move near
the definition of is_around_axis *)
Lemma is_around_axisN u a (M : 'M[R]_3) :
  norm u = 1 -> is_around_axis u (- a) (mx_lin1 M) ->
  is_around_axis (- u) a (mx_lin1 M).
Proof.
move=> u1 H.
have K : M = `e^( a, skew_mx u).
  apply: (@same_rot _ u _ _ _ u 1 (ltr01) (- a)).
  by rewrite -norm_eq0 u1 oner_neq0.
  by rewrite scale1r.
  done.
  by apply is_around_axis_exp_rot.
have {K}K : M = `e^(- a, skew_mx (- u)).
  apply/eqP/mulmxP => u0.
  transitivity (u0 *m (`e^(a, skew_mx u))).
    by rewrite K.
  rewrite -[in RHS]rodriguesP ?normN //.
  rewrite -[in LHS]rodriguesP //.
  rewrite /rodrigues.
  by rewrite cosN dotmulvN mulrN scalerN scaleNr opprK linearN sinN scalerN scaleNr opprK.
rewrite K.
rewrite -{1}(opprK a).
apply is_around_axis_exp_rot.
by rewrite normN.
Qed.

Definition angle_axis_of_rot (M : 'M[R]_3) :=
  angle_axis_of (angle_of_rot M) (axis_of_rot M).

Lemma angle_axis_exp_rot (M : 'M[R]_3) : M \is 'SO[R]_3 ->
  let a := aangle (angle_axis_of_rot M) in
  let w := aaxis (angle_axis_of_rot M) in
  axis_of_rot M != 0 ->
  sin (angle_of_rot M) != 0 ->
  `e^(a, skew_mx (normalize w)) = M.
Proof.
move=> HM a w M0 sin0.
rewrite -rotationV in HM.
case: (SO_is_around_axis HM) => w' [a' [w'1 w'a']].
have w'0 : w' != 0 by rewrite -norm_eq0 w'1 oner_neq0.
case: (angle_in a') => Ha'.
- move: (@is_around_axis_axis_of_rot M^T _ _ w'1 sin0) => w'axial.
  move: (is_around_axis_angle_of_rot w'0 Ha' w'a') => a'angle_of_rot.
  rewrite tr_angle_of_rot in a'angle_of_rot.
  have aa' : a = a' by rewrite /a a'angle_of_rot aangle_of.
  subst a'.
  move: {w'axial}(w'axial w'a') => w'axial.
  apply/esym.
  set k := - (1 / _) in w'axial.
  have k0 : k < 0.
    rewrite /k oppr_lt0 div1r invr_gt0 pmulrn_lgt0 // ltr_neqAle eq_sym sin0 /=.
    by rewrite inE in Ha'.
  apply: (@same_rot _ _ w'0 _ _ (norm (axis_of_rot M) *: w) ((- sin a *+ 2) * k) _ (- a)).
  - rewrite nmulr_rgt0 // mulNrn oppr_lt0 pmulrn_lgt0 //.
    by rewrite ltr_neqAle aa' eq_sym sin0.
  - rewrite w'axial mulrC -scalerA; congr (_ *: _).
    rewrite mulNrn scaleNr /w aaxis_of //.
    rewrite 2!scalerA -mulrA divrr ?mulr1; last by rewrite unitfE norm_eq0.
    rewrite /axis_of_rot /a aangle_of scalerA div1r divrr ?scale1r.
    by rewrite tr_axial_vec.
    by rewrite unitfE mulrn_eq0 negb_or.
  - rewrite aa' -{2}(trmxK M).
    move: (HM); move/rotation_inv => <-.
    apply is_around_axis_trmx => //.
    by rewrite orthogonal_unit // rotation_sub // rotationV.
    by rewrite opprK.
  - have : norm (normalize w) = 1.
      by rewrite norm_normalize // /w aaxis_of // scaler_eq0 negb_or invr_eq0 norm_eq0 andbb.
    move/(is_around_axis_exp_rot a) => H.
    have w0' : 0 < (norm w)^-1 * (norm (axis_of_rot M))^-1.
      rewrite divr_gt0 // ?invr_gt0 ltr_neqAle norm_ge0 andbT eq_sym norm_eq0 //.
      by rewrite /w aaxis_of // scaler_eq0 negb_or invr_eq0 norm_eq0 andbb.
    apply: (proj1 (is_around_axisZ _ _ _ w0')).
      rewrite scaler_eq0 negb_or norm_eq0 M0 /= /w aaxis_of // scaler_eq0.
      by rewrite negb_or invr_eq0 norm_eq0 andbb.
    by rewrite !scalerA -mulrA mulVr ?mulr1 // unitfE norm_eq0.
- rewrite rotationV in HM.
  move: (@is_around_axis_axis_of_rot M _ _ w'1 sin0) => w'axial.
  rewrite -rotationV in HM.
  move: (is_around_axis_angle_of_rotN w'0 Ha' w'a') => a'angle_of_rot.
  rewrite tr_angle_of_rot in a'angle_of_rot.
  have : M^T \in unitmx by rewrite orthogonal_unit // orthogonalV rotation_sub // -rotationV.
  move/(@is_around_axis_trmx _ _ w'0 (angle_of_rot M^T) M^T).
  rewrite {1}tr_angle_of_rot -a'angle_of_rot.
  move/(_ w'a').
  rewrite (rotation_inv HM) trmxK.
  rewrite tr_angle_of_rot.
  move/w'axial => {w'axial}w'axial.
  set k := - (1 / _) in w'axial.
  have k0 : k < 0.
    rewrite /k div1r -invrN invr_lt0 -mulNrn pmulrn_llt0 //.
    by rewrite inE a'angle_of_rot sinN in Ha'.
  apply/esym.
  apply: (@same_rot _ _ w'0 _ _ (- norm (axis_of_rot M) *: w) ((- sin a *+ 2) * k) _ a).
  - rewrite nmulr_rgt0 // pmulrn_llt0 // /a aangle_of.
    by rewrite inE a'angle_of_rot sinN in Ha'.
  - rewrite w'axial mulrC -scalerA; congr (_ *: _).
    rewrite /w aaxis_of //.
    rewrite mulNrn 2!scaleNr scalerN opprK 2!scalerA -mulrA divrr ?mulr1; last first.
      by rewrite unitfE norm_eq0.
    rewrite /axis_of_rot /a aangle_of div1r scalerA divrr ?scale1r //.
    by rewrite unitfE mulrn_eq0 negb_or.
  - rewrite /a aangle_of.
    rewrite -(opprK (angle_of_rot M)).
    rewrite -{2}(trmxK M).
    move: (HM); move/rotation_inv => <-.
    rewrite -a'angle_of_rot.
    apply is_around_axis_trmx => //.
    by rewrite orthogonal_unit // rotation_sub // rotationV.
    by rewrite opprK.
  - have K : norm (normalize w) = 1.
      by rewrite norm_normalize // /w aaxis_of // scaler_eq0 negb_or invr_eq0 norm_eq0 andbb.
    move/(is_around_axis_exp_rot a) : (K) => H.
    have w0' : 0 < (norm w)^-1 * (norm (axis_of_rot M))^-1.
      rewrite divr_gt0 // ?invr_gt0 ltr_neqAle norm_ge0 andbT eq_sym norm_eq0 //.
      by rewrite /w aaxis_of // scaler_eq0 negb_or invr_eq0 norm_eq0 andbb.
    apply: (proj1 (is_around_axisZ _ _ _ w0')).
      rewrite scaler_eq0 negb_or eqr_oppLR oppr0 norm_eq0 M0 /= /w aaxis_of // scaler_eq0.
      by rewrite negb_or invr_eq0 norm_eq0 andbb.
    rewrite !scalerA -mulrA mulrN mulVr ?mulr1 //; last by rewrite unitfE norm_eq0.
    rewrite mulrN1 scaleNr -/(normalize w).
    by apply is_around_axisN.
Qed.

Lemma rodriguesE M u (HM : M^T \in 'SO[R]_3) :
  axis_of_rot M != 0 ->
  sin (angle_of_rot M) != 0 ->
  let a := aangle (angle_axis_of_rot M) in 
  let w := aaxis (angle_axis_of_rot M) in
  rodrigues u a w = SE.ap_coor (SE.mk 0 HM) u.
Proof.
move=> axis0 sin0.
transitivity (u *m M); last first.
  (* TODO: lemma? *)
  rewrite SE.ap_coorE /SE.h.ap_coor.
  rewrite (_ : (SE.mk 0 HM)^T = (SE.h.rot (SE.mk 0 HM))^T); last first.
    by rewrite /SE.h.rot /= /hmx_coercion /= /SE.h.mx /= trmx0.
  rewrite hcoor_hrot_of_transform /=.
  rewrite (_ : esym (addn1 3) = erefl (3 + 1)%N); last by apply eq_irrelevance.
  rewrite trmxK (@cast_row_mx _ _ _ _ _ _ (u *m M)) //.
  by rewrite row_mxKl /= castmx_id.
have w1 : norm w = 1 by rewrite /w aaxis_of // norm_normalize.
rewrite rodriguesP //; congr (_ *m _) => {u}.
rewrite -(normalizeI w1).
apply angle_axis_exp_rot => //.
by rewrite -rotationV.
Qed.

End angle_axis.

Section screw.

Variable R : rcfType.
Let vector := 'rV[R]_3.
Let coordinate := 'rV[R]_3.

Variable f : 'DIso_3[R].
Let Q : 'M[R]_3 := ortho_of_iso f.
Let T : vector := trans_of_iso f.
Variable e : vector.
Hypothesis ne : norm e = 1.
Variable phi : angle R.
Hypothesis Maxis : is_around_axis e phi (mx_lin1 Q).

Lemma is_around_axis_axis : e *m Q = e.
Proof. by case: Maxis. Qed.

(* p.91 *)
(* the displacements of all the points of B have the same component along e *)
Lemma thm321 (a p : coordinate) :
  let da := f a - a in let dp := f p - p in
  da *d e = dp *d e.
Proof.
move=> da dp.
have eq34 : dp = da + (p - a) *m (Q - 1).
  rewrite /da mulmxBr mulmx1 opprB addrA -(addrC a) 2!addrA subrK.
  rewrite /dp; congr (_ - _).
  apply/eqP; rewrite addrC -subr_eq.
  by rewrite img_vec_iso.
have : dp *m e^T = da *m e^T + (p - a) *m (Q - 1) *m e^T.
  by rewrite -mulmxDl -eq34.
rewrite -mulmxA (mulmxBl Q 1 e^T) mul1mx.
have -> : Q *m e^T = e^T.
  rewrite -{1}(is_around_axis_axis) trmx_mul mulmxA mulmxE.
  have : Q \is 'O[R]_3 by rewrite /Q ortho_of_iso_is_O.
  rewrite orthogonalE => /eqP ->; by rewrite mul1mx.
rewrite subrr mulmx0 addr0 /dotmul; by move=> ->.
Qed.

Definition d0 := (f 0 - 0) *d e.

Lemma d0_is_a_lb_of_a_displacement p : (d0 ^+ 2 <= norm (f p - p) ^+ 2).
Proof.
set dp := f p - p.
rewrite /d0 (thm321 0 p) -/dp.
move: (W.pframe_of (norm1_neq0 ne)) => F.
have -> : norm dp = norm (dp *m (col_mx3 (normalize e) (W.j e) (W.k e))^T).
  rewrite orth_preserves_norm // orthogonalV.
  move: (pframe_is_rot F).
  by rewrite rotationE => /andP [].
rewrite col_mx3_mul sqr_norm !mxE /= -[X in X <= _]addr0 -addrA ler_add //.
  by rewrite normalizeI.
by rewrite addr_ge0 // sqr_ge0.
Qed.

Definition parpart (p : coordinate) :=  axialcomp (f p - p) e.

Lemma parpartP (p : vector) : parpart p = d0 *: e.
Proof. by rewrite /parpart /axialcomp dotmulC (thm321 _ 0). Qed.

Definition perppart (p : coordinate) := normalcomp (f p - p) e.

Lemma perpart_colinear (p : coordinate) :
  let dp := f p - p in
  (perppart p == 0) = (colinear dp e).
Proof.
move=> dp; apply/idP/idP => [/eqP|/colinearP].
  by apply: normalcomp_colinear.
rewrite -norm_eq0 ne -(negbK (1 == 0)) oner_neq0 => -[] // [] _ [k [Hk1 Hk2]].
rewrite /perppart /normalcomp -/dp Hk2.
by rewrite dotmulvZ dotmulvv ne expr1n mulr1 subrr.
Qed.

(* d0 is the minimal norm of a displacement, all such points are along a line parallel
   to e *)
Lemma MozziChasles1 p : let dp := f p - p in
  norm dp = d0 -> colinear dp e.
Proof.
move=> dp H.
have Hp : forall p : coordinate, let dp := f p - p in
    norm dp ^+ 2 = norm (d0 *: e) ^+2 + norm (perppart p) ^+ 2.
  move=> p' dp'.
  rewrite /dp' (decomp (f p' - p') e).
  rewrite normD -dotmul_cos.
  rewrite axialnormal // mul0rn addr0 sqr_sqrtr; last first.
    by rewrite addr_ge0 // ?sqr_ge0.
  by rewrite /perppart -/(parpart p') parpartP.
move: {Hp}(Hp p) => Hp.
rewrite -perpart_colinear.
rewrite -norm_eq0.
suff : norm dp ^+2 <= norm (d0 *: e) ^+ 2.
  by rewrite Hp addrC -ler_subr_addr subrr exprn_even_le0 //= norm_eq0.
rewrite 2!expr2.
by rewrite ler_pmul // ?norm_ge0 // H normZ ne mulr1 ler_norm.
Qed.

Definition p0 (a : coordinate) :=
  let a':= f a in
  1 / (2%:R * (1 - cos phi)) *: (a *m Q - a') *m (Q - 1)^T.

(* TODO *)

End screw.

Section chains.

Variable R : rcfType.
Let coordinate := 'rV[R]_3.
Let vector := 'rV[R]_3.
Let frame := frame R.

Record joint := mkJoint {
  offset : R ;
  joint_angle : angle R }.

Record link := mkLink {
  length : R ;
  link_angle : angle R }.

Variable n' : nat.
Let n := n'.+1.
Variables chain : {ffun 'I_n -> frame * link * joint}.
Definition frames := fun i => (chain (insubd ord0 i)).1.1.
Definition links := fun i => (chain (insubd ord0 i)).1.2.
Definition joints := fun i => (chain (insubd ord0 i)).2.

(* by definition, zi = axis of joint i *)

Local Notation "u _|_ A" := (u <= kermx A^T)%MS (at level 8).
Local Notation "u _|_ A , B " := (u _|_ (col_mx A B))
 (A at next level, at level 8,
 format "u  _|_  A , B ").

Definition common_normal_xz (i : 'I_n) :=
  (framej (frames i.-1)) _|_ (framek (frames i)), (framei (frames i.-1)).

End chains.

(* more generic definition of the exponential map, in progress *)
Section exponential_map.

Variable R : rcfType.
Let vector := 'rV[R]_3.

Definition expmx n (M : 'M[R]_n.+1) k := \sum_(i < k) (i`!%:R)^-1 *: (M ^+ i).

Lemma expmx0 n (M : 'M[R]_n.+1) : expmx M 0 = 0.
Proof. by rewrite /expmx big_ord0. Qed.

Lemma expmxS n (M : 'M[R]_n.+1) k : expmx M k.+1 = expmx M k + k`!%:R^-1 *: M ^+ k.
Proof. by rewrite /expmx big_ord_recr. Qed.

Lemma expmx1 n (M : 'M[R]_n.+1) : expmx M 1 = 1.
Proof. by rewrite expmxS expmx0 expr0 add0r fact0 invr1 scale1r. Qed.

Lemma expmx2 n (M : 'M[R]_n.+1) : expmx M 2 = 1 + M.
Proof. by rewrite expmxS expmx1 invr1 expr1 scale1r. Qed.

Lemma expr_mulmulV n (M : 'M[R]_n.+1) i (g : 'M[R]_n.+1) : g \in unitmx ->
  (g * M * g^-1)^+i = g * M ^+i  *g^-1.
Proof.
move=> Hg; elim: i => [|i ih]; first by rewrite 2!expr0 mulr1 divrr.
rewrite exprS ih -!mulrA exprS -mulrA; congr (_ * (_ * _)).
by rewrite mulrA mulVr // mul1r.
Qed.

Lemma expmx_mulmulV n (M : 'M[R]_n.+1) k (g : 'M[R]_n.+1) : g \in unitmx ->
  expmx (g * M * g^-1) k = g * expmx M k * g^-1.
Proof.
move=> Hg.
rewrite /expmx big_distrr /= big_distrl /=; apply/eq_bigr => i _.
by rewrite expr_mulmulV // 2!scalerAl scalerCA.
Qed.

End exponential_map.

Section exponential_coordinates_rigid.

Variable R : rcfType.
Let vector := 'rV[R]_3.

Definition twist (w v : vector) : 'M[R]_4 :=
  row_mx (col_mx (skew_mx w) 0) (col_mx v^T 0).

(* TODO: notation 'se_3[R] for the set of twists? *)

Lemma expr_twist0v (v : vector) n : (twist 0 v) ^+ n.+2 = 0.
Proof.
elim: n => [|n ih]; last by rewrite exprS ih mulr0.
apply/eqP; rewrite expr2 /twist.
set a := col_mx (skew_mx _) _. rewrite -mulmxE (mul_mx_row (row_mx a _) a) {}/a.
set b := _ *m _. rewrite (row_mx_eq0 b) {}/b. apply/andP; split;
  by rewrite mul_row_col mulmx0 addr0 mul_col_mx skew_mx0 !(mul0mx,mulmx0) col_mx0.
Qed.

Definition exp_twist0 (* w = 0 *) (v : vector) (a : angle R) : 'M_4 :=
  row_mx (col_mx 1 0) (col_mx v^T 1).

(* closed expression for the exponential of a twist with w = 0 *)
Lemma expmx_exp_twist0 (v : vector) (a : angle R) k :
  expmx (twist 0 v) k.+2 = exp_twist0 v a.
Proof.
rewrite /expmx 2!big_ord_recl big1 ?addr0; last first.
  move=> /= i _; by rewrite expr_twist0v scaler0.
rewrite liftE0 eqxx factS fact0 expr0 expr1 invr1 2!scale1r /twist skew_mx0.
rewrite /exp_twist0 (_ : 1 = row_mx (@col_mx _ 3 1 _ 1 0) (col_mx 0 1)); last first.
  by rewrite -block_mxEh -idmxE (@scalar_mx_block _ 3 1 1).
set x1 := col_mx _ _.
by rewrite (add_row_mx x1) col_mx0 addr0 add_col_mx add0r addr0.
Qed.

Definition rigid_trans (w v : vector) : 'M_4 :=
  row_mx (col_mx 1 0) (col_mx (w *v v)^T 1).

Definition inv_rigid_trans (w v : vector) := row_mx (col_mx 1 0) (col_mx (- w *v v)^T 1).

Lemma Vrigid_trans w v : inv_rigid_trans w v * rigid_trans w v = 1.
Proof.
rewrite /inv_rigid_trans /rigid_trans.
rewrite -[in X in _ * X = _]block_mxEh.
rewrite -mulmxE (mul_row_block (col_mx 1 0) (col_mx (- w *v v)^T 1) 1).
rewrite 2!mulmx1 mulmx0 addr0 mul_col_mx mul0mx mul1mx.
by rewrite add_col_mx crossmulNv linearN subrr add0r -block_mxEh -scalar_mx_block.
Qed.

Lemma rigid_trans_unitmx w v : rigid_trans w v \in unitmx.
Proof.
by rewrite unitmxE /rigid_trans -block_mxEh (det_ublock 1 (w *v v)^T) 2!det1 mulr1 unitr1.
Qed.

Lemma inv_rigid_transE w v : (rigid_trans w v)^-1 = inv_rigid_trans w v.
Proof.
rewrite -[LHS]mul1mx -[X in X *m _ = _](Vrigid_trans w v) -mulmxA.
by rewrite mulmxV ?rigid_trans_unitmx // mulmx1.
Qed.

(* 2.34, p.41 *)
Lemma Vmulmul w v : norm w = 1 ->
  let e' := (rigid_trans w v)^-1 *m twist w v *m rigid_trans w v in
  let h := w *d v in
  e' = col_mx (row_mx (skew_mx w) (h *: w^T)) 0.
Proof.
move=> w1 e'; rewrite /e'.
rewrite inv_rigid_transE /inv_rigid_trans /rigid_trans /twist.
rewrite -[in X in _ *m X *m _ = _]block_mxEh.
rewrite (mul_row_block (col_mx 1 0) (col_mx (- w *v v)^T 1) (skew_mx w)) 2!mulmx0 2!addr0.
rewrite mul_col_mx mul1mx mul0mx mul_col_mx mul0mx mul1mx.
rewrite -[in X in _ *m X = _]block_mxEh.
rewrite (mul_row_col (col_mx (skew_mx w) 0) (col_mx v^T 0)).
rewrite mul_col_mx mul0mx mul_col_mx mul0mx add_col_mx addr0.
rewrite (mul_mx_row (skew_mx w) 1) mulmx1.
rewrite (@mul_mx_row _ _ _ 3 1 v^T 0 1) mulmx0 mulmx1.
rewrite (add_row_mx (skew_mx w)) addr0.
rewrite -{2}(trmxK (skew_mx w)) -trmx_mul.
move: (anti_skew w); rewrite antiE -eqr_oppLR => /eqP <-.
rewrite mulmxN skew_mxE crossmulC opprK double_crossmul.
by rewrite dotmulvv w1 expr1n scale1r linearD /= linearN /= subrK linearZ /=.
Qed.

(* p.42 *)
Lemma exr_Vmulmul w v : norm w = 1 ->
  let e' := (rigid_trans w v)^-1 *m twist w v *m rigid_trans w v in
  forall k, e'^+k.+2 = col_mx (row_mx ((skew_mx w)^+k.+2) 0) (0 : 'rV_4).
Proof.
move=> w1 e' k.
rewrite /e' (Vmulmul _ w1).
set h := w *d v.
elim: k => [|k ih].
  rewrite (@expr2 _ (col_mx (row_mx (skew_mx w) _) 0)).
  rewrite -{1}row_mx0 -block_mxEv -mulmxE (mul_block_col (skew_mx w)).
  rewrite 2!mulmx0 mul0mx 2!addr0 (mul_mx_row (skew_mx w) (skew_mx w)).
  by rewrite mulmxE -expr2 /h -scalemxAr skew_mxT scaler0.
rewrite exprS ih -{1}row_mx0 -block_mxEv -mulmxE (mul_block_col (skew_mx w)).
rewrite 2!mul0mx mulmx0 2!addr0 (mul_mx_row (skew_mx w) ((skew_mx w)^+k.+2)).
by rewrite mulmx0 mulmxE -exprS.
Qed.

Lemma expmx2_twist (w v : vector) : norm w = 1 ->
  let g := rigid_trans w v in
  let h := w *d v in
  expmx (twist w v) 2 =
  g *m row_mx (col_mx (expmx (skew_mx w) 2) 0) (col_mx (h *: w^T) 1) *m g^-1.
Proof.
move=> w1 g h.
rewrite {1}/expmx 2!big_ord_recl big_ord0 addr0 liftE0 eqxx factS fact0 invr1 2!scale1r.
rewrite expr0 expr1 /twist.
rewrite (_ : 1 = row_mx (@col_mx _ 3 1 _ 1 0) (col_mx 0 1)); last first.
  by rewrite -block_mxEh -idmxE (@scalar_mx_block _ 3 1 1).
rewrite (add_row_mx (col_mx 1 0) (col_mx 0 1) (col_mx (skew_mx w) 0)).
rewrite 2!add_col_mx 2!addr0 add0r.
rewrite mul_mx_row.
rewrite {1}/g {1}/rigid_trans.
rewrite (mul_row_col (col_mx 1 0) (col_mx _ 1) (expmx (skew_mx w) 2)) mulmx0 addr0.
rewrite mul_col_mx mul1mx mul0mx.
rewrite {1}/g {1}/rigid_trans.
rewrite (mul_row_col (col_mx 1 0) (col_mx _ 1) (h *: w^T)) mulmx1.
rewrite mul_col_mx mul1mx mul0mx add_col_mx add0r.
rewrite inv_rigid_transE /inv_rigid_trans.
rewrite (mul_mx_row _ (col_mx 1 0)).
f_equal.
  by rewrite mul_row_col mulmx1 mulmx0 addr0 expmx2.
rewrite mul_row_col mulmx1.
rewrite (mul_col_mx (expmx (skew_mx w) 2) 0 (- w *v v)^T) mul0mx.
rewrite (add_col_mx (expmx (skew_mx w) 2 *m (- w *v v)^T) 0 _ 1) add0r.
f_equal.
rewrite crossmulNv linearN /= mulmxN -mulNmx addrA addrAC.
rewrite -{2}(mul1mx (_ *v _)^T) -mulmxDl expmx2 (addrC _ 1%:M) opprD addrA subrr add0r.
rewrite crossmulC [in X in _ = _ *m X + _]linearN /= mulmxN mulNmx opprK.
rewrite -(trmxK (skew_mx w)) -trmx_mul.
move: (anti_skew w); rewrite antiE -eqr_oppLR => /eqP <-.
rewrite mulmxN linearN /= skew_mxE (crossmulC (_ *v _)) linearN /= opprK.
rewrite double_crossmul dotmulvv w1 expr2 mulr1 scale1r linearD /=.
by rewrite linearN /= linearZ /= subrK.
Qed.

(* see p.42 on math. foundations, p.17 of springer's handbook *)
(* closed expression for the exponential of a twist with w != 0 *)
Definition exp_twist (w v : vector) (a : angle R) : 'M_4 :=
  row_mx
  (col_mx `e^(a, skew_mx w) 0)
  (col_mx ((w *v v) *m (1 - `e^(a, (skew_mx w)^T)) + v *m (w^T *m w))^T 1).

End exponential_coordinates_rigid.

(*

  option ('rV[R]_3 (* point *) * 'rV[R]_3 (* vec *) ).
Admitted.

Definition intersection (o o' : 'rV[R]_3) (v v' : 'rV[R]_3) : option 'rV[R]_3.
Admitted.

Definition length_prop (i : 'I_n) (f f' : frame) :
  unique_common_orthogonal (origin f) (origin f') ()
  length (links i) = `| |


Definition z_vec (i : 'I_n) := zframes i



joint i is located between links i-1 and i
z_vec (frames i) "is located along the axis of joint i"

the zi axis along the axis of joint i


Definition before_after_joint (i : 'I_n) : option (link * link):=
  match ltnP O i with
    | LtnNotGeq H (* 0 < i*) => Some (links i.-1, links i)
    | GeqNotLtn H (* i <= 0*) => None
  end.

link length and twist along and about the x_i-1 axis

Hypothesis :

Check forall i, (z_ax (basis (frames i))).

x_vec (frames i.-1) _|_ plane (z_vec (frames i.-1)),(z_vec (frames i))

length (links i) = distance from (z_vec (frames i.-1)) to (z_vec (frames i)) along (x_vec)





 *)
