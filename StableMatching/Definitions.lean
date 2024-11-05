import Mathlib.Data.Real.Basic
import Mathlib.Order.Monotone.Basic
import Mathlib.Algebra.Order.Ring.Basic
import Mathlib.Tactic
set_option linter.unusedSectionVars false


#check List.argmax

namespace Finset

variable {α : Type*} [Inhabited α]

-- Code for argmax function and spec from here:
-- https://piazza.com/class/m01h6rlmn3z6vd/post/88
noncomputable def argmax (f : α → ℕ) (s : Finset α) : α :=
  if h : s.Nonempty then
    have h' : (s.image f).Nonempty := by
      rw [image_nonempty]; exact h
    have : (s.image f).max' h' ∈ s.image f := by
      exact max'_mem (image f s) h'
    have : ∃ a ∈ s, f a = (s.image f).max' h' := by
      simpa using this
    Classical.choose this
  else
    default

theorem argmax_spec (s : Finset α) (f : α → ℕ) (h : s ≠ ∅) :
    s.argmax f ∈ s ∧ ∀ x ∈ s, f x ≤ f (s.argmax f) := by
  have h : s.Nonempty := by exact nonempty_iff_ne_empty.mpr h
  have h' : (s.image f).Nonempty := by
    rw [image_nonempty]; exact h
  have : (s.image f).max' h' ∈ s.image f := by
    exact max'_mem (image f s) h'
  have : ∃ a ∈ s, f a = (s.image f).max' h' := by
    simpa using this
  have : s.argmax f ∈ s ∧ f (s.argmax f) = (s.image f).max' h' := by
    rw [argmax, dif_pos h]; dsimp
    apply Classical.choose_spec this
  use this.1
  rw [this.2]
  intro x hx
  apply le_max' _ _ (mem_image_of_mem f hx)

end Finset

section
open Function
open Finset

variable {α β : Type*} [Fintype α] [Fintype β] [DecidableEq α] [DecidableEq β]
[Inhabited α] [Inhabited β]

-- x ∈ A now becomes x : α
-- (Finset.univ : Finset α)
-- Fintype.card α

  (pa : α → β → ℕ)
  (pb : β → α → ℕ)
  (pa_linear : ∀ a, Injective (pa a))
  (pb_linear : ∀ b, Injective (pb b))
  (A_B_same_size : Fintype.card α = Fintype.card β)

def isMatching (X : Finset (α × β)) :=
  (∀ a, ∀ b₁, ∀ b₂, (a, b₁) ∈ X ∧ (a, b₂) ∈ X → b₁ = b₂) ∧
  (∀ a₁, ∀ b, ∀ a₂, (a₁, b) ∈ X ∧ (a₂, b) ∈ X → a₁ = a₂)

def UnstablePair (X : Finset (α × β)) (a : α) (b : β) :=
  ∃ (c : α) (d : β), ((c, d) ∈ X) ∧ (pa a d > pa a b) ∧ (pb d a > pb d c)

def isStableMatching (X : Finset (α × β)) := isMatching X ∧
  ¬∃ (a : α) (b : β), ((a, b) ∈ X) ∧ (UnstablePair pa pb X a b)

-- Variant score: sum over all b in the matching of how much they prefer their current partner
-- by improvement lemma, this has to increase at each iteration of the algorithm
def V (X : Finset (α × β)) := X.sum (fun (a, b) => pb b a)

variable
  (M : Finset (α × β))
  (M_partial : #M < Fintype.card α)
  (M_stable : isStableMatching pa pb M)
  (M_nonempty : M.Nonempty)

def A' : Finset α := Finset.image (Prod.fst) M
def B' : Finset β := Finset.image (Prod.snd) M
-- ∃ x : α (x ∉ A')
-- suffices ∃ x ∈ (Finset.univ : Finset α), x ∉ A'

noncomputable def choose_next (a : α) : β :=
  let unmatched : Finset β := Finset.univ \ (B' M)
  let preferred : Finset β := {b | ∃ a', (a', b) ∈ M ∧ pb b a > pb b a'}
  let choices := unmatched ∪ preferred
  choices.argmax (pa a)

-- Theorem 1: if there exists a partial stable matching M, we can find a stable matching M'
-- with a higher variant score

include pa

#check Finset.subset_univ
#check Subset.antisymm
#check card_bij

include M_partial M_stable

theorem SM0 : ∃ a, a ∉ (A' M) := by
  let A' := A' M
  have hcard : #A' ≤ #M := by
    apply card_image_le
  have hA' : A' ⊂ univ := by
      apply ssubset_univ_iff.mpr
      have : #A' < Fintype.card α := by
        exact Nat.lt_of_le_of_lt hcard M_partial
      exact (card_lt_iff_ne_univ A').mp this
  apply exists_of_ssubset at hA'
  rcases hA' with ⟨x, _, hxr⟩
  use x

#check product_image_snd

theorem SM1 : ∃ (M' : Finset (α × β)), isMatching M' ∧ V pb M' > V pb M := by
  let B' := B' M
  let A' := A' M
  have ⟨a, ha⟩ : ∃ a, a ∉ A' := by
    exact SM0 pa pb M M_partial M_stable
  let b : β := choose_next pa pb M a
  have h1 : b ∈ B' ∨ b ∉ B' := by
    exact Decidable.em (b ∈ B')
  have A'_def : A' = Finset.image (Prod.fst) M := by rfl
  have B'_def : B' = Finset.image (Prod.snd) M := by rfl
  rcases h1 with matched | unmatched
  have ⟨a', ha'⟩ : ∃ a', (a', b) ∈ M := by
    rw [B'_def] at matched
    simpa using matched
  use (M \ {(a', b)}) ∪ {(a, b)}
  constructor
  · constructor
    · sorry
    · sorry
  · sorry
  use M ∪ {(a, b)}
  constructor
  · constructor
    · intro x y₁ y₂ ⟨h1, h2⟩
      have ha : x = a ∨ x ≠ a := by
        exact eq_or_ne x a
      rcases ha with eq | ne
      have hm : ∀ y, (x, y) ∉ M := by
        rw [eq]
        rw [A'_def] at ha
        simpa using ha
      simp at h1
      simp at h2
      rcases h1 with _ | ⟨_, h1⟩
      · specialize hm y₁
        contradiction
      · rcases h2 with _ | ⟨_, h2⟩
        · specialize hm y₂
          contradiction
        rw [h1, h2]
      have h3 : (x, y₁) ∈ M := by
        simp at h1
        rcases h1 with left | ⟨right, _⟩
        · exact left
        contradiction
      have h4 : (x, y₂) ∈ M := by
        simp at h2
        rcases h2 with left | ⟨right, _⟩
        · exact left
        contradiction
      rcases M_stable with ⟨⟨left, right⟩, _⟩
      apply left x y₁ y₂
      exact ⟨h3, h4⟩
    · intro x₁ y x₂ ⟨h1, h2⟩
      have hb : y = b ∨ y ≠ b := by
        exact eq_or_ne y b
      rcases hb with eq | ne
      have hm : ∀ x, (x, y) ∉ M := by
        rw [eq]
        rw [B'_def] at unmatched
        simpa using unmatched
      simp at h1
      simp at h2
      rcases h1 with _ | ⟨h1, _⟩
      · specialize hm x₁
        contradiction
      · rcases h2 with _ | ⟨h2, _⟩
        · specialize hm x₂
          contradiction
        rw [h1, h2]
      have h3 : (x₁, y) ∈ M := by
        simp at h1
        rcases h1 with left | ⟨right, _⟩
        · exact left
        contradiction
      have h4 : (x₂, y) ∈ M := by
        simp at h2
        rcases h2 with left | ⟨right, _⟩
        · exact left
        contradiction
      rcases M_stable with ⟨⟨left, right⟩, _⟩
      apply right x₁ y x₂
      exact ⟨h3, h4⟩
  · sorry


-- Theorem 2: a stable matching with a variant score ≥ (___) implies totality
-- this works with variant based on B because if A is proposing then the resulting
-- SM is B-pessimal

-- and, the variant score of a B-pessimal total SM is a lower bound on the
-- variant score of any total SM
theorem SM2 (X : Finset (α × β)) : ∃ (v : ℕ), V pb X ≥ v → #X = #A := by
  sorry

-- Theorem 3: can apply theorem 1 inductively to prove that for every instance
-- of the SMP there exists a total stable matching ..


end
