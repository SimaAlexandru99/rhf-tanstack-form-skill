# Migration checklists

Use these as agent/execution checklists. Tick every item that applies to the codebase.

---

## Pre-flight (both directions)

- [ ] Confirm React-only (this skill targets `@tanstack/react-form` and `react-hook-form`)
- [ ] Inventory all form entry points (grep packages + hooks)
- [ ] Note validation library (Zod / Valibot / Yup / hand-rolled)
- [ ] Note design-system inputs (need Controller/AppField wrappers)
- [ ] Decide: full cutover vs form-by-form
- [ ] Establish baseline: typecheck + critical form E2E/manual tests

### Inventory greps

```bash
# RHF
rg -n "from ['\"]react-hook-form['\"]|useForm\(|useFieldArray|Controller|FormProvider|useFormContext|useWatch|useController" --glob '*.{ts,tsx,js,jsx}'

# TSF
rg -n "from ['\"]@tanstack/react-form['\"]|createFormHook|form\\.Field|mode=[\"']array[\"']" --glob '*.{ts,tsx,js,jsx}'

# packages
rg -n "react-hook-form|@hookform/resolvers|@tanstack/react-form" package.json
```

---

## RHF → TanStack Form

### 1. Inventory

- [ ] List forms by complexity: simple / arrays / multi-step / shared composition
- [ ] Mark each: `register` vs `Controller` vs `useFieldArray` vs `FormProvider` depth
- [ ] Extract shared Zod (or other) schemas to a single importable module

### 2. Dependencies

- [ ] Add `@tanstack/react-form` (prefer **exact** pin)
- [ ] Keep RHF until last form migrates (dual-stack OK short-term)
- [ ] Plan removal of `@hookform/resolvers` after cutover

### 3. Defaults & types

- [ ] Write complete `defaultValues` for every form (no `undefined` holes)
- [ ] Align TypeScript types with `defaultValues` shape (TSF infers from defaults)

### 4. Composition strategy

- [ ] If ≥3 forms or shared inputs: create `createFormHook` + `AppField` kit first
- [ ] If 1–2 simple forms: raw `useForm` + `form.Field` is fine

### 5. Field rewrite

- [ ] `register` → controlled `form.Field`
- [ ] `Controller` → `form.Field` (same binding pattern)
- [ ] Nested paths: keep dots for objects; convert array indices to brackets
- [ ] Numbers/dates: transform in `handleChange` (`valueAsNumber`, etc.)

### 6. Validation

- [ ] Map `mode`/`reValidateMode` to event validators intentionally
- [ ] Move `resolver` schema into form and/or field `validators`
- [ ] Port per-field `rules` / `validate` functions
- [ ] Cross-field: `deps`/`validate` → `onChangeListenTo` or form `.refine`
- [ ] Async: port to `onChangeAsync` + `onChangeAsyncDebounceMs`
- [ ] Server errors: port `setError` flows to `onSubmitAsync` field maps

### 7. Arrays

- [ ] `useFieldArray` → `mode="array"`
- [ ] `append`/`remove`/… → `pushValue`/`removeValue`/…
- [ ] Stable React keys if reorder/swap is used

### 8. Reactivity & state UX

- [ ] `watch`/`useWatch` → `form.Subscribe` / `useSelector` with **narrow** selectors
- [ ] Submit button: prefer `canSubmit` + `isSubmitting`
- [ ] Revisit dirty UX: persistent dirty vs `!isDefaultValue`
- [ ] Error display: join `meta.errors` arrays

### 9. Submit / reset

- [ ] Wire `preventDefault` + `form.handleSubmit()`
- [ ] Move side effects into `onSubmit` / `onSubmitAsync`
- [ ] Reset buttons: `preventDefault` + `form.reset` (or `type="button"`)

### 10. Verify

- [ ] Typecheck clean on migrated files
- [ ] Manual/E2E: required fields, async errors, array add/remove/reorder
- [ ] Manual: dirty/unsaved guards, disable submit timing
- [ ] Manual: server error mapping
- [ ] Accessibility: labels, error association still valid

### 11. Cleanup

- [ ] Remove RHF imports from migrated modules
- [ ] When zero RHF usage: remove `react-hook-form` and `@hookform/resolvers`
- [ ] Update docs/AGENTS.md form conventions if project has them

---

## TanStack Form → RHF

### 1. Inventory

- [ ] List `useForm` / `createFormHook` / `withForm` / array fields
- [ ] Note event validators and Standard Schema usage

### 2. Dependencies

- [ ] Add `react-hook-form`
- [ ] If Zod/Yup/etc.: add `@hookform/resolvers` + matching resolver

### 3. Field rewrite

- [ ] Controlled Field → `register` (native) or `Controller` (design system)
- [ ] Paths: brackets → dots for array indices
- [ ] `mode="array"` → `useFieldArray` + `field.id` keys

### 4. Validation

- [ ] Collapse event validators into `mode` + `resolver` and/or rules
- [ ] `onChangeListenTo` → `deps` / `.refine` / `trigger`
- [ ] Async debounce: implement manually
- [ ] Server errors → `setError` / `root.*` / `errors` prop (stable reference)

### 5. Reactivity & composition

- [ ] `form.Subscribe` / `useSelector` → `useWatch` / `useFormState` / Proxy reads
- [ ] `createFormHook` kit → `FormProvider` + shared components
- [ ] Dirty: accept non-persistent semantics; re-test guards

### 6. Submit / reset

- [ ] `handleSubmit(onValid, onInvalid)`
- [ ] API failures: try/catch + `setError`
- [ ] `reset` options if partial keep needed

### 7. Verify + cleanup

- [ ] Typecheck + form tests
- [ ] Remove `@tanstack/react-form` when unused
- [ ] Update project conventions

---

## Post-migration QA (either direction)

Run against a representative form:

| Check | Pass criteria |
|-------|----------------|
| Empty submit | Required errors show; focus/UX acceptable |
| Fix errors | Errors clear on revalidate with expected timing |
| Async uniqueness | Debounce feels right; loading indicator optional |
| Cross-field | Changing field A revalidates field B |
| Arrays | Add/remove/reorder keeps correct values |
| Dirty banner | Matches product intent (persistent vs value-diff) |
| External load | `reset`/`values` after fetch does not wipe wrongly |
| Server 400 | Field-level messages map correctly |
| Reset button | Returns to defaults, not weird HTML state |
| Typecheck | `tsc --noEmit` / project typecheck green |

---

## Decision: should you migrate at all?

Migrate **to TSF** when:

- [ ] Complex multi-step / multi-file forms need deep TS inference
- [ ] You want per-event validation + built-in async debounce
- [ ] You need strong composition (`createFormHook`, field groups)
- [ ] Team already on TanStack ecosystem and accepts controlled verbosity

Stay on / migrate **to RHF** when:

- [ ] Forms are simple/moderate and `register` is enough
- [ ] Bundle size and maturity matter more than composition power
- [ ] Team already productive with RHF + resolvers
- [ ] TSF boilerplate/DX is the main pain (common revert reason)

**Do not migrate** “because agents default to the other library.” Migrate for product constraints.
