# API Mapping: React Hook Form ↔ TanStack Form

Packages: `react-hook-form` + `@hookform/resolvers` · `@tanstack/react-form`  
Paths: RHF uses `users.0.name` · TSF uses `users[0].name`

---

## Form bootstrap

| Concern | RHF | TSF |
|---------|-----|-----|
| Create | `useForm({ defaultValues, resolver, mode })` | `useForm({ defaultValues, onSubmit, validators })` |
| Submit | `<form onSubmit={handleSubmit(fn)}>` | `onSubmit` in options + `form.handleSubmit()` with `e.preventDefault()` |
| Reset | `reset(values?, options?)` | `form.reset()` / `form.reset(values)` — **preventDefault** on `type="reset"` |
| Set value | `setValue(name, value, opts)` | `form.setFieldValue(name, value)` |
| Get values | `getValues()` / `getValues(name)` | `form.state.values` / `form.getFieldValue(name)` |
| Focus | `setFocus(name)` | Manual DOM focus (no 1:1 helper) |

### RHF

```tsx
const { register, handleSubmit, formState: { errors }, reset } = useForm({
  defaultValues: { email: '' },
  mode: 'onBlur',
  resolver: zodResolver(schema),
})

<form onSubmit={handleSubmit((data) => console.log(data))}>
  <input {...register('email')} />
  {errors.email?.message}
</form>
```

### TSF

```tsx
const form = useForm({
  defaultValues: { email: '' },
  validators: { onChange: schema }, // Standard Schema (Zod, etc.)
  onSubmit: async ({ value }) => console.log(value),
})

<form
  onSubmit={(e) => {
    e.preventDefault()
    e.stopPropagation()
    form.handleSubmit()
  }}
>
  <form.Field
    name="email"
    children={(field) => (
      <>
        <input
          value={field.state.value}
          onBlur={field.handleBlur}
          onChange={(e) => field.handleChange(e.target.value)}
        />
        {!field.state.meta.isValid && (
          <em>{field.state.meta.errors.join(', ')}</em>
        )}
      </>
    )}
  />
</form>
```

---

## Field binding

| RHF | TSF | Notes |
|-----|-----|-------|
| `register('name')` | `form.Field name="name"` + controlled wire | No uncontrolled path in TSF |
| `register('a.b')` | `name="a.b"` | Nested objects both OK |
| `register('list.0.name')` | `name="list[0].name"` | **Path syntax differs** |
| `Controller` / `useController` | `form.Field` | Always controlled in TSF |
| Rules: `required`, `min`, `validate` | `validators.onChange` / `onBlur` / … | Function or Standard Schema |
| `valueAsNumber` / `setValueAs` | Transform in `handleChange` | Explicit |

### RHF uncontrolled

```tsx
<input
  {...register('age', {
    valueAsNumber: true,
    min: { value: 13, message: 'Must be 13+' },
  })}
/>
```

### TSF controlled

```tsx
<form.Field
  name="age"
  validators={{
    onChange: ({ value }) => (value < 13 ? 'Must be 13+' : undefined),
  }}
  children={(field) => (
    <input
      type="number"
      value={field.state.value}
      onChange={(e) => field.handleChange(e.target.valueAsNumber)}
      onBlur={field.handleBlur}
    />
  )}
/>
```

---

## Validation timing

| RHF | TSF |
|-----|-----|
| `mode: 'onSubmit'` (default) | `validators.onSubmit` / submit-time validators |
| `mode: 'onChange'` | `validators.onChange` |
| `mode: 'onBlur'` | `validators.onBlur` + wire `handleBlur` |
| `mode: 'onTouched'` | Combine blur then change after touch (no exact flag) |
| `mode: 'all'` | Define both `onChange` and `onBlur` |
| `reValidateMode` | Per-event validators re-run themselves |
| Form `validate` | Form-level `validators: { onChange / onSubmit / … }` |
| `resolver` (whole form schema) | Form and/or field `validators` with Standard Schema |

### TSF event matrix

| Event | Role |
|-------|------|
| `onChange` | Shape while typing |
| `onBlur` | Calmer / heavier rules |
| `onChangeAsync` + `onChangeAsyncDebounceMs` | Network checks (built-in debounce) |
| `onSubmit` / `onSubmitAsync` | Final / server invariants |

Sync runs before async for the same event.

---

## formState ↔ store / meta

| RHF `formState` | TSF equivalent | Caveat |
|-----------------|----------------|--------|
| `errors` | `field.state.meta.errors` / `errorMap` | TSF errors are **arrays** |
| `isDirty` | `state.isDirty` / `field.state.meta.isDirty` | **Different dirty semantics** |
| `dirtyFields` | Derive from field meta | No identical map API |
| `touchedFields` | `field.state.meta.isTouched` | |
| `isValid` | `state.isValid` / `field.state.meta.isValid` | |
| `isValidating` | `field.state.meta.isValidating` | |
| `isSubmitting` | `state.isSubmitting` | |
| `canSubmit` | **`state.canSubmit`** | TSF first-class; false after touch when invalid |

### Subscribe

```tsx
// RHF
const { formState: { isDirty, isValid } } = useForm()
// or useFormState / useWatch

// TSF
<form.Subscribe
  selector={(s) => [s.canSubmit, s.isSubmitting]}
  children={([canSubmit, isSubmitting]) => (
    <button type="submit" disabled={!canSubmit}>
      {isSubmitting ? '…' : 'Save'}
    </button>
  )}
/>
// or: useSelector(form.store, (s) => s.values.email)
```

---

## Watch / reactivity

| RHF | TSF |
|-----|-----|
| `watch('name')` | `useSelector(form.store, s => s.values.name)` or `form.Subscribe` |
| `useWatch({ name, control })` | Same — prefer narrow selectors |
| `watch()` whole form | `useSelector(form.store, s => s.values)` (prefer narrow) |
| `deps` on register | `onChangeListenTo: ['otherField']` |

---

## Field arrays

| RHF `useFieldArray` | TSF `mode="array"` |
|---------------------|--------------------|
| `fields` (+ `id`) | `field.state.value` map; you choose keys |
| `append` | `pushValue` |
| `prepend` | `insertValue(0, …)` |
| `insert` | `insertValue` |
| `remove` | `removeValue` |
| `swap` | `swapValues` |
| `move` | `moveValue` |
| `update` / `replace` | `replaceValue` |
| `clear` | `clearValues` |
| path `cart.${i}.name` | path `` `people[${i}].name` `` |
| key: **`field.id` required** | docs often use index; use stable ids when reordering |

### RHF

```tsx
const { fields, append, remove } = useFieldArray({ control, name: 'cart' })
{fields.map((item, i) => (
  <input key={item.id} {...register(`cart.${i}.name` as const)} />
))}
<button type="button" onClick={() => append({ name: '', qty: 0 })}>
  Add
</button>
```

### TSF

```tsx
<form.Field
  name="people"
  mode="array"
  children={(field) => (
    <>
      {field.state.value.map((_, i) => (
        <form.Field
          key={i}
          name={`people[${i}].name`}
          children={(sub) => (
            <input
              value={sub.state.value}
              onChange={(e) => sub.handleChange(e.target.value)}
              onBlur={sub.handleBlur}
            />
          )}
        />
      ))}
      <button
        type="button"
        onClick={() => field.pushValue({ name: '', age: 0 })}
      >
        Add
      </button>
    </>
  )}
/>
```

---

## Composition

| RHF | TSF |
|-----|-----|
| `FormProvider` + `useFormContext` | `createFormHookContexts` + `createFormHook` |
| Pass `control` / methods | Pass `form`; `withForm({ render })` for subforms |
| Shared UI + `useController` | `fieldComponents` → `form.AppField` → `field.TextField` |
| — | `formComponents` → `form.AppForm` / subscribe buttons |
| — | `withFieldGroup` for reusable groups |

### TSF composition skeleton

```tsx
const { fieldContext, formContext, useFieldContext } = createFormHookContexts()
const { useAppForm, withForm } = createFormHook({
  fieldContext,
  formContext,
  fieldComponents: { TextField },
  formComponents: { SubscribeButton },
})
// <form.AppField name="firstName">{(f) => <f.TextField label="…" />}</form.AppField>
// const Child = withForm({ defaultValues, render({ form }) { … } })
```

---

## Schema / Zod

| RHF | TSF |
|-----|-----|
| `resolver: zodResolver(schema)` via `@hookform/resolvers` | Pass Zod (Standard Schema) **directly** into `validators` |
| Usually one form-level schema | Form-level **and/or** field-level; event-scoped |
| `useForm<Input, Ctx, Output>` for transforms | See submission-handling docs; transforms not 1:1 |

```tsx
// RHF
useForm({ resolver: zodResolver(z.object({ age: z.number().gte(13) })) })

// TSF
useForm({
  defaultValues: { age: 0 },
  validators: {
    onChange: z.object({ age: z.number().gte(13, 'Must be 13+') }),
  },
})
```

---

## Cross-field validation

### RHF

```tsx
register('confirm', {
  deps: ['password'],
  validate: (v, formValues) =>
    v === formValues.password || 'Passwords do not match',
})
// or zod .refine on object schema
```

### TSF

```tsx
<form.Field
  name="confirm_password"
  validators={{
    onChangeListenTo: ['password'],
    onChange: ({ value, fieldApi }) =>
      value !== fieldApi.form.getFieldValue('password')
        ? 'Passwords do not match'
        : undefined,
  }}
  children={(field) => /* input */}
/>
```

Also: `onBlurListenTo`. Prefer form-level Standard Schema `.refine` for multi-field submit invariants.

---

## Async validation

### RHF

```tsx
register('username', {
  validate: {
    available: async (v) => (await check(v)) || 'Taken',
  },
})
// debounce: DIY
```

### TSF

```tsx
<form.Field
  name="username"
  validators={{
    onChangeAsyncDebounceMs: 500,
    onChangeAsync: async ({ value }) => {
      const ok = await check(value)
      return ok ? undefined : 'Taken'
    },
  }}
/>
// field.state.meta.isValidating
```

---

## Server errors

### RHF

```tsx
setError('email', { type: 'server', message: 'Already used' })
setError('root.serverError', { type: '400', message: '…' })
clearErrors('email')
// or: useForm({ errors: serverErrors }) // keep reference stable
```

### TSF

```tsx
validators: {
  onSubmitAsync: async ({ value }) => {
    const res = await api(value)
    if (res.errors) {
      return {
        form: 'Invalid data',
        fields: {
          age: 'Must be 13+',
          'details.email': 'Required',
          'socials[0].url': 'URL missing',
        },
      }
    }
    return null
  },
}
```

Field validators on the same event can overwrite form-level field errors — plan layering carefully.

---

## Default values & external updates

| Concern | RHF | TSF |
|---------|-----|-----|
| Initial | `defaultValues` (sync or async) | `defaultValues` (sync; drives inference) |
| External data | `values` prop + `resetOptions` | `form.reset(newValues)` / `setFieldValue` |
| Avoid | `undefined` defaults | Missing keys in `defaultValues` |

---

## Dirty semantics

| Model | Behavior | Libraries |
|-------|----------|-----------|
| Non-persistent | dirty iff value ≠ default; revert → clean | **RHF**, Formik |
| Persistent | once edited, stays dirty even if reverted | **TanStack Form** |

TSF also has `isDefaultValue`. Emulate RHF:

```ts
const nonPersistentIsDirty = !field.state.meta.isDefaultValue
```

---

## Quick cheat sheet

```
RHF                              TSF
─────────────────────────────────────────────────────────────
useForm                          useForm (@tanstack/react-form)
register                         form.Field (controlled)
Controller / useController       form.Field
useFieldArray                    form.Field mode="array"
append / remove                  pushValue / removeValue
watch / useWatch                 form.Subscribe / useSelector
FormProvider                     createFormHook + AppForm / withForm
formState.errors.x.message       field.state.meta.errors[]
formState.isDirty                isDirty (persistent!) or !isDefaultValue
setError                         onSubmitAsync fields map
setValue                         setFieldValue
getValues                        state.values / getFieldValue
reset                            form.reset (+ preventDefault)
handleSubmit(fn)                 onSubmit option + form.handleSubmit()
resolver: zodResolver(z)         validators: { onChange: z }
mode: 'onBlur'                   validators.onBlur (+ handleBlur)
deps: ['a']                      onChangeListenTo: ['a']
users.0.name                     users[0].name
```
