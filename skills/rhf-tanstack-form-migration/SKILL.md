---
name: rhf-tanstack-form-migration
description: >-
  Migrate forms between React Hook Form and TanStack Form (both directions).
  Use when converting RHF ↔ TanStack Form, rewriting form components, mapping
  register/Controller/useFieldArray to form.Field, comparing dirty/validation
  semantics, choosing which library to use, or handling field arrays, Zod
  schemas, cross-field validation, and form composition differences.
license: MIT
metadata:
  author: SimaAlexandru99
  version: "1.0.0"
---

# RHF ↔ TanStack Form Migration

Guided **rewrite** (not drop-in) between `react-hook-form` and `@tanstack/react-form`.

## When to use

- Migrating existing forms RHF → TanStack Form (or reverse)
- Mapping APIs while rewriting a form component
- Explaining dirty / validation / array / composition differences
- Deciding which library fits a codebase

## When not to use

- **Greenfield simple forms** — build with one library; do not force a migration skill
- Non-React TanStack adapters (Vue/Solid/Angular) — out of scope
- Formik, Final Form, Formisch migrations — out of scope
- Pure styling/a11y form review without library cutover

## Quick decision guide

| Prefer **React Hook Form** | Prefer **TanStack Form** |
|----------------------------|--------------------------|
| Simple/moderate forms, native inputs | Complex multi-step / multi-file forms |
| Uncontrolled `register` DX, smaller mental model | Deep TypeScript inference + controlled model |
| Mature ecosystem, team already productive | Per-event validators + built-in async debounce |
| “Dirty = differs from default” UX | Composition (`createFormHook`, field groups) |

If current forms work and pain is low: **do not migrate**.

## Mental model

| Axis | RHF | TanStack Form |
|------|-----|---------------|
| Control | Uncontrolled-first (`register`) | Controlled-first (`value` + `handleChange`) |
| Validation | Form-level `mode` + `resolver` | Per-event `validators` (`onChange` / `onBlur` / `onSubmit` + async) |
| Schema | `@hookform/resolvers` | Standard Schema (Zod etc.) **directly** |
| Arrays | `useFieldArray` | `form.Field mode="array"` |
| Paths | `users.0.name` | `users[0].name` |
| Dirty | Non-persistent (≠ default) | **Persistent** (use `!isDefaultValue` for RHF-like) |
| Composition | `FormProvider` | `createFormHook` + `AppField` / `withForm` |
| Subscribe | `watch` / `useWatch` / Proxy `formState` | `form.Subscribe` / `useSelector` |

Full tables: [references/api-mapping.md](references/api-mapping.md)

## Core API cheat sheet

```
RHF                              TSF
─────────────────────────────────────────────────────────────
useForm                          useForm (@tanstack/react-form)
register                         form.Field (controlled)
Controller                       form.Field
useFieldArray                    form.Field mode="array"
append / remove                  pushValue / removeValue
watch / useWatch                 form.Subscribe / useSelector
FormProvider                     createFormHook + withForm
errors.x.message                 field.state.meta.errors[]
isDirty                          isDirty (persistent!) or !isDefaultValue
setError                         onSubmitAsync { fields, form }
setValue                         setFieldValue
reset                            form.reset (+ preventDefault on type=reset)
handleSubmit(fn)                 onSubmit option + form.handleSubmit()
resolver: zodResolver(z)         validators: { onChange: z }
mode: 'onBlur'                   validators.onBlur (+ handleBlur)
deps: ['a']                      onChangeListenTo: ['a']
users.0.name                     users[0].name
```

## Minimal side-by-side (bootstrap)

**RHF**

```tsx
const { register, handleSubmit, formState: { errors } } = useForm({
  defaultValues: { email: '' },
  resolver: zodResolver(schema),
})
<form onSubmit={handleSubmit(onSubmit)}>
  <input {...register('email')} />
  {errors.email?.message}
</form>
```

**TSF**

```tsx
const form = useForm({
  defaultValues: { email: '' },
  validators: { onChange: schema },
  onSubmit: async ({ value }) => { /* ... */ },
})
<form onSubmit={(e) => { e.preventDefault(); form.handleSubmit() }}>
  <form.Field name="email" children={(field) => (
    <>
      <input
        value={field.state.value}
        onBlur={field.handleBlur}
        onChange={(e) => field.handleChange(e.target.value)}
      />
      {!field.state.meta.isValid && <em>{field.state.meta.errors.join(', ')}</em>}
    </>
  )} />
</form>
```

More examples: [references/side-by-side-examples.md](references/side-by-side-examples.md)

---

## Workflow: RHF → TanStack Form

Follow in order. Detailed ticks: [references/checklists.md](references/checklists.md).

### 1. Inventory

```bash
rg -n "from ['\"]react-hook-form['\"]|useFieldArray|Controller|FormProvider" --glob '*.{ts,tsx}'
```

Classify each form: simple · arrays · multi-step · shared composition.

### 2. Dependencies

- Add `@tanstack/react-form` (**pin exact** — types can change in patches)
- Keep RHF until the last form is migrated

### 3. Defaults and schemas

- Extract Zod/schema modules
- Provide **complete** `defaultValues` (no `undefined` holes) — TSF infers paths from them
- Drop `zodResolver` usage on migrated forms; pass schema into `validators`

### 4. Composition strategy

| Scale | Approach |
|-------|----------|
| 1–2 simple forms | Raw `useForm` + `form.Field` |
| App-scale / shared inputs | **`createFormHook` + AppField kit first** |

Avoid rewriting 20 forms with giant render props before shared field components exist.

### 5. Rewrite fields

1. `register` / `Controller` → controlled `form.Field`
2. Array paths: `list.${i}.x` → `` `list[${i}].x` ``
3. `useFieldArray` → `mode="array"` + `pushValue` / `removeValue` / …
4. Prefer stable keys when reordering (TSF does not give RHF-style `field.id`)

### 6. Validation and async

1. Map RHF `mode` to intentional event validators (not everything on every keystroke)
2. Cross-field: `deps` / `validate` → `onChangeListenTo` or form-level `.refine`
3. Async: `onChangeAsync` + `onChangeAsyncDebounceMs` (first-class in TSF)
4. Server errors: prefer `onSubmitAsync` returning `{ form, fields }` maps over ad-hoc `setError`

### 7. Reactivity and dirty UX

1. `watch` / `useWatch` → `form.Subscribe` / `useSelector` with **narrow** selectors
2. Submit disable: prefer `canSubmit` + `isSubmitting`
3. **Revisit dirty banners** — TSF dirty is persistent; emulate RHF with `!isDefaultValue` if product needs it
4. Errors display: join `meta.errors` arrays

### 8. Submit / reset

```tsx
onSubmit={(e) => {
  e.preventDefault()
  e.stopPropagation()
  form.handleSubmit()
}}
// reset:
<button type="button" onClick={() => form.reset()}>Reset</button>
```

### 9. Verify then remove RHF

- Typecheck migrated modules
- QA: empty submit, async, cross-field, arrays, dirty, server errors, reset
- When zero RHF imports remain: remove `react-hook-form` and `@hookform/resolvers`

---

## Workflow: TanStack Form → RHF

Shorter reverse path (same inventory discipline).

1. Add `react-hook-form` (+ `@hookform/resolvers` if using Zod)
2. `defaultValues` + `useForm<T>()` generics
3. Fields: native → `register`; design-system → `Controller`
4. Collapse event validators into `mode` + `resolver` / rules
5. Arrays: `mode="array"` → `useFieldArray` + `key={field.id}`; paths brackets → dots
6. Linked fields: `onChangeListenTo` → `deps` / refine / `trigger`
7. Async debounce: implement manually
8. Server errors → `setError` / `root.*` / stable `errors` prop
9. `form.Subscribe` → `useWatch` / `useFormState` (read Proxy keys you need)
10. Composition kit → `FormProvider` + shared components
11. Accept **non-persistent** dirty; re-test unsaved guards
12. Verify → remove `@tanstack/react-form`

---

## Top pitfalls (do not skip)

1. **Dirty semantics differ** — largest product bug after naive migrations  
2. **Path syntax** — `users.0.name` vs `users[0].name`  
3. **Errors are arrays** in TSF — not `errors.x.message`  
4. **No `register`** in TSF — always controlled (or AppField)  
5. **`preventDefault` on submit and reset** for TSF  
6. **Field validators can overwrite form-level field errors** on the same event  
7. **`canSubmit` timing ≠ RHF `isValid`** until touched  
8. **Verbose Field JSX** — introduce composition early  
9. **Pin TSF exactly** for stable types  
10. **Do not half-remove resolvers** — clean package.json after full cutover  

Full list: [references/pitfalls.md](references/pitfalls.md)

---

## Post-migration validation (minimum)

- [ ] Empty submit shows required errors with expected timing  
- [ ] Fixing a field clears its error  
- [ ] Cross-field revalidates when sibling changes  
- [ ] Array add/remove keeps correct values  
- [ ] Dirty/unsaved UX matches product intent  
- [ ] Server field errors map correctly  
- [ ] Reset returns to form defaults  
- [ ] Project typecheck green  

---

## Agent procedure (execute this)

When asked to migrate forms:

1. **Confirm direction** (RHF→TSF or TSF→RHF) and whether migration is justified  
2. **Inventory** usages (grep above) and list forms by complexity  
3. **Load** [references/api-mapping.md](references/api-mapping.md) for the APIs you will touch  
4. **Migrate one form end-to-end** as a template (prefer a medium-complexity form)  
5. **Extract shared field components** if more forms remain  
6. **Apply** [references/checklists.md](references/checklists.md) per form  
7. **QA** post-migration list  
8. **Remove** old package only when inventory is empty  
9. **Summarize** semantic risks called out (dirty, paths, errors[], canSubmit)

Prefer small, reviewable diffs. Never claim migration complete without typecheck evidence on touched files.

---

## Official docs

- React Hook Form: https://react-hook-form.com/docs/useform  
- RHF field array: https://react-hook-form.com/docs/usefieldarray  
- TanStack Form overview: https://tanstack.com/form/latest/docs/overview  
- TSF basic concepts (dirty, arrays, validation): https://tanstack.com/form/latest/docs/framework/react/guides/basic-concepts  
- TSF comparison: https://tanstack.com/form/latest/docs/comparison  
- TSF form composition: https://tanstack.com/form/latest/docs/framework/react/guides/form-composition  

## References

- [api-mapping.md](references/api-mapping.md) — complete API tables  
- [side-by-side-examples.md](references/side-by-side-examples.md) — basic, select, arrays, cross-field+async, composition  
- [pitfalls.md](references/pitfalls.md) — both directions  
- [checklists.md](references/checklists.md) — executable checklists + decision gates  
