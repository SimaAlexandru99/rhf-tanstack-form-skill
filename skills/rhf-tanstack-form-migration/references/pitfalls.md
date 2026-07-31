# Common migration pitfalls

## RHF → TanStack Form

### 1. Expecting `register` / uncontrolled inputs

TSF is controlled-first. Every field needs `value` + `handleChange` (+ `handleBlur` when using blur validators), or a shared `AppField` wrapper. Do not leave `{...register('x')}` patterns behind.

### 2. Global `mode` does not map 1:1

RHF `mode: 'onChange' | 'onBlur' | 'onSubmit'` is form-wide. TSF uses per-field / per-form **event validators**. Decide which events each field needs; do not assume every field validates on every keystroke.

### 3. Path syntax: dots vs brackets

```
RHF:  users.0.name
TSF:  users[0].name
```

Broken paths fail silently at typecheck or produce wrong bindings. Rewrite all array indices.

### 4. `errors.field.message` vs `meta.errors[]`

RHF usually exposes one `FieldError` with `.message`. TSF stores **arrays** of errors (multi-validator). Always join/map:

```tsx
field.state.meta.errors.join(', ')
```

Schema/object errors may need normalization before display.

### 5. Dirty semantics flip

| | RHF | TSF |
|--|-----|-----|
| Dirty model | Non-persistent (≠ default) | **Persistent** (once edited, stays dirty) |

Unsaved-changes banners and disable-save logic break if you map `isDirty` 1:1.

**Emulate RHF dirty:**

```ts
const isDirtyLikeRhf = !field.state.meta.isDefaultValue
// form-level: compare values to defaultValues or use selectors
```

### 6. `useFieldArray` keys

RHF gives stable `field.id`. TSF examples often key by index — reordering then remounts wrong inputs. Prefer stable ids in array item shape when reorder/swap is required.

### 7. Dropping `@hookform/resolvers` incompletely

Passing `zodResolver` into TSF does nothing useful. Use Standard Schema directly:

```ts
validators: { onChange: zodSchema }
```

Remove `@hookform/resolvers` from package.json only after all forms migrate.

### 8. Submit wiring

```tsx
// Wrong: form.handleSubmit as onSubmit without preventDefault
// Right:
onSubmit={(e) => {
  e.preventDefault()
  e.stopPropagation()
  form.handleSubmit()
}}
```

Put the real submit side-effect in `useForm({ onSubmit })`.

### 9. Native reset button

```tsx
<button
  type="reset"
  onClick={(e) => {
    e.preventDefault()
    form.reset()
  }}
>
  Reset
</button>
// or type="button" + form.reset()
```

Without `preventDefault`, `<select>` and other native elements may reset to HTML defaults, not form defaults.

### 10. `setError` habits

Prefer `onSubmitAsync` returning `{ form, fields }` maps. Imperative meta errors are easier to fight with field validators that clear them on the next event.

### 11. `canSubmit` vs `isValid`

TSF `canSubmit` often stays true until fields are touched, even if values would fail validation. Match product UX intentionally; do not assume RHF `isValid` timing.

### 12. Verbose Field JSX fatigue

Migrating 20 forms with raw `form.Field` children is painful. Introduce `createFormHook` + shared field components early.

### 13. Field validators override form validators

On the same event, field-level validators can overwrite form-level field errors. Plan layering (shape on field, cross-field refine on form submit).

### 14. Incomplete `defaultValues`

TSF inference and dirty/meta flags rely on complete defaults. Missing keys → weak types and broken dirty UX. Avoid `undefined` holes (also bad in RHF).

### 15. Pin `@tanstack/react-form` exactly

Type-level API changes can ship as patches. Prefer exact versions (`bun add --exact @tanstack/react-form`) for stable agent/code output.

---

## TSF → React Hook Form

### 1. Reintroduce uncontrolled or Controller paths

Native inputs → `register`. Design-system controlled components → `Controller` / `useController`.

### 2. Collapse event validators

Map `onChange` / `onBlur` / `onSubmit` validators into `mode` / `reValidateMode` + `resolver` and/or per-field `rules`.

### 3. Array paths and keys

```
TSF:  cart[0].name  →  RHF: cart.0.name
```

Use `useFieldArray` and **`key={field.id}`**.

### 4. Persistent dirty → non-persistent

Guards that relied on “once touched always dirty” will free too early when values revert to defaults. Re-test unsaved UX.

### 5. `onChangeListenTo` → `deps` / refine / `trigger`

Cross-field revalidation needs `deps`, schema `.refine`, or explicit `trigger('other')`.

### 6. Standard Schema direct → resolvers

```ts
// TSF
validators: { onChange: schema }

// RHF
resolver: zodResolver(schema)
// + package: @hookform/resolvers
```

### 7. Subscribe selectors → Proxy `formState` / `useWatch`

RHF requires **reading** the `formState` keys you subscribe to. Prefer `useWatch` / `useFormState` for isolated re-renders.

### 8. Async debounce is DIY

RHF has no first-class `onChangeAsyncDebounceMs`. Implement debounce in custom validate or a small hook.

### 9. Error arrays → single FieldError

Display code that joins `errors[]` becomes `errors.field?.message` (unless `criteriaMode: 'all'`).

### 10. Composition kit → FormProvider

`createFormHook` / `withForm` maps to `FormProvider` + shared components + `useController`. Typing is usually weaker; document generics carefully.

---

## High-impact semantic diffs (both directions)

| Topic | Remember |
|-------|----------|
| Control model | RHF uncontrolled-first · TSF controlled-first |
| Dirty | RHF non-persistent · TSF persistent + `isDefaultValue` |
| Paths | Dots+index vs brackets |
| Errors | Object+message vs array |
| Validation clock | Global mode vs per-event validators |
| Arrays | `useFieldArray` ids vs mode=array helpers |
| Schema glue | resolvers package vs Standard Schema native |
| Reset | TSF needs preventDefault on native reset |
