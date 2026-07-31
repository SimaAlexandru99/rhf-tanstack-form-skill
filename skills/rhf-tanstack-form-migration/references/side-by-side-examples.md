# Side-by-side examples: RHF ↔ TanStack Form

Minimal, copy-paste oriented examples. Prefer reading `api-mapping.md` for tables.

---

## 1. Basic form + Zod

### RHF

```tsx
import { useForm } from 'react-hook-form'
import { zodResolver } from '@hookform/resolvers/zod'
import { z } from 'zod'

const schema = z.object({
  firstName: z.string().min(3, 'At least 3 characters'),
  lastName: z.string().min(1, 'Required'),
})

type FormData = z.infer<typeof schema>

export function RhfBasic() {
  const {
    register,
    handleSubmit,
    formState: { errors, isSubmitting },
  } = useForm<FormData>({
    defaultValues: { firstName: '', lastName: '' },
    resolver: zodResolver(schema),
  })

  return (
    <form
      onSubmit={handleSubmit(async (data) => {
        console.log(data)
      })}
    >
      <input {...register('firstName')} />
      {errors.firstName && <p>{errors.firstName.message}</p>}

      <input {...register('lastName')} />
      {errors.lastName && <p>{errors.lastName.message}</p>}

      <button type="submit" disabled={isSubmitting}>
        {isSubmitting ? '…' : 'Submit'}
      </button>
    </form>
  )
}
```

### TSF

```tsx
import { useForm } from '@tanstack/react-form'
import { z } from 'zod'

const schema = z.object({
  firstName: z.string().min(3, 'At least 3 characters'),
  lastName: z.string().min(1, 'Required'),
})

export function TsfBasic() {
  const form = useForm({
    defaultValues: { firstName: '', lastName: '' },
    validators: { onChange: schema },
    onSubmit: async ({ value }) => {
      console.log(value)
    },
  })

  return (
    <form
      onSubmit={(e) => {
        e.preventDefault()
        e.stopPropagation()
        form.handleSubmit()
      }}
    >
      <form.Field
        name="firstName"
        children={(field) => (
          <>
            <input
              value={field.state.value}
              onBlur={field.handleBlur}
              onChange={(e) => field.handleChange(e.target.value)}
            />
            {field.state.meta.isTouched && !field.state.meta.isValid && (
              <em>{field.state.meta.errors.join(', ')}</em>
            )}
          </>
        )}
      />

      <form.Field
        name="lastName"
        children={(field) => (
          <>
            <input
              value={field.state.value}
              onBlur={field.handleBlur}
              onChange={(e) => field.handleChange(e.target.value)}
            />
            {field.state.meta.isTouched && !field.state.meta.isValid && (
              <em>{field.state.meta.errors.join(', ')}</em>
            )}
          </>
        )}
      />

      <form.Subscribe
        selector={(s) => [s.canSubmit, s.isSubmitting]}
        children={([canSubmit, isSubmitting]) => (
          <button type="submit" disabled={!canSubmit}>
            {isSubmitting ? '…' : 'Submit'}
          </button>
        )}
      />
    </form>
  )
}
```

**Migration notes**

- Drop `@hookform/resolvers`; pass Zod into `validators`.
- Every field becomes controlled.
- Prefer `canSubmit` over raw `isValid` for disable-submit UX.

---

## 2. Controlled / custom component (select)

### RHF (`Controller`)

```tsx
import { useForm, Controller } from 'react-hook-form'

type FormData = { role: 'admin' | 'user' | '' }

export function RhfSelect() {
  const { control, handleSubmit } = useForm<FormData>({
    defaultValues: { role: '' },
  })

  return (
    <form onSubmit={handleSubmit(console.log)}>
      <Controller
        name="role"
        control={control}
        rules={{ required: 'Pick a role' }}
        render={({ field, fieldState }) => (
          <>
            <select {...field}>
              <option value="">Select…</option>
              <option value="admin">Admin</option>
              <option value="user">User</option>
            </select>
            {fieldState.error && <p>{fieldState.error.message}</p>}
          </>
        )}
      />
      <button type="submit">Save</button>
    </form>
  )
}
```

### TSF (`form.Field`)

```tsx
import { useForm } from '@tanstack/react-form'

export function TsfSelect() {
  const form = useForm({
    defaultValues: { role: '' as 'admin' | 'user' | '' },
    onSubmit: async ({ value }) => console.log(value),
  })

  return (
    <form
      onSubmit={(e) => {
        e.preventDefault()
        form.handleSubmit()
      }}
    >
      <form.Field
        name="role"
        validators={{
          onChange: ({ value }) => (!value ? 'Pick a role' : undefined),
        }}
        children={(field) => (
          <>
            <select
              value={field.state.value}
              onBlur={field.handleBlur}
              onChange={(e) =>
                field.handleChange(e.target.value as typeof field.state.value)
              }
            >
              <option value="">Select…</option>
              <option value="admin">Admin</option>
              <option value="user">User</option>
            </select>
            {!field.state.meta.isValid && (
              <em>{field.state.meta.errors.join(', ')}</em>
            )}
          </>
        )}
      />
      <button type="submit">Save</button>
    </form>
  )
}
```

**Migration notes**

- `Controller` disappears; every design-system field is a render-prop `Field`.
- For app scale, wrap inputs once via `createFormHook` + `AppField`.

---

## 3. Field arrays

### RHF

```tsx
import { useForm, useFieldArray } from 'react-hook-form'

type Item = { name: string; qty: number }
type FormData = { cart: Item[] }

export function RhfArray() {
  const { control, register, handleSubmit } = useForm<FormData>({
    defaultValues: { cart: [{ name: '', qty: 1 }] },
  })
  const { fields, append, remove } = useFieldArray({ control, name: 'cart' })

  return (
    <form onSubmit={handleSubmit(console.log)}>
      {fields.map((item, i) => (
        <div key={item.id}>
          <input {...register(`cart.${i}.name` as const)} />
          <input
            type="number"
            {...register(`cart.${i}.qty` as const, { valueAsNumber: true })}
          />
          <button type="button" onClick={() => remove(i)}>
            X
          </button>
        </div>
      ))}
      <button type="button" onClick={() => append({ name: '', qty: 1 })}>
        Add
      </button>
      <button type="submit">Submit</button>
    </form>
  )
}
```

### TSF

```tsx
import { useForm } from '@tanstack/react-form'

export function TsfArray() {
  const form = useForm({
    defaultValues: { cart: [{ name: '', qty: 1 }] },
    onSubmit: async ({ value }) => console.log(value),
  })

  return (
    <form
      onSubmit={(e) => {
        e.preventDefault()
        form.handleSubmit()
      }}
    >
      <form.Field
        name="cart"
        mode="array"
        children={(cartField) => (
          <>
            {cartField.state.value.map((_, i) => (
              <div key={i}>
                <form.Field
                  name={`cart[${i}].name`}
                  children={(field) => (
                    <input
                      value={field.state.value}
                      onBlur={field.handleBlur}
                      onChange={(e) => field.handleChange(e.target.value)}
                    />
                  )}
                />
                <form.Field
                  name={`cart[${i}].qty`}
                  children={(field) => (
                    <input
                      type="number"
                      value={field.state.value}
                      onBlur={field.handleBlur}
                      onChange={(e) =>
                        field.handleChange(e.target.valueAsNumber)
                      }
                    />
                  )}
                />
                <button
                  type="button"
                  onClick={() => cartField.removeValue(i)}
                >
                  X
                </button>
              </div>
            ))}
            <button
              type="button"
              onClick={() => cartField.pushValue({ name: '', qty: 1 })}
            >
              Add
            </button>
          </>
        )}
      />
      <button type="submit">Submit</button>
    </form>
  )
}
```

**Migration notes**

- Paths: `cart.${i}.name` → `` `cart[${i}].name` ``
- `append` → `pushValue`, `remove` → `removeValue`
- Prefer stable keys when reordering (RHF gives `field.id`; TSF does not auto-generate).

---

## 4. Cross-field + async validation

### RHF

```tsx
import { useForm } from 'react-hook-form'

type FormData = { password: string; confirm: string; username: string }

async function isUsernameFree(u: string) {
  await new Promise((r) => setTimeout(r, 300))
  return u !== 'taken'
}

export function RhfCrossAsync() {
  const { register, handleSubmit, formState: { errors } } = useForm<FormData>({
    defaultValues: { password: '', confirm: '', username: '' },
  })

  return (
    <form onSubmit={handleSubmit(console.log)}>
      <input
        {...register('username', {
          validate: {
            available: async (v) =>
              (await isUsernameFree(v)) || 'Username taken',
          },
        })}
      />
      {errors.username && <p>{errors.username.message}</p>}

      <input {...register('password', { required: true })} />
      <input
        {...register('confirm', {
          deps: ['password'],
          validate: (v, values) =>
            v === values.password || 'Passwords do not match',
        })}
      />
      {errors.confirm && <p>{errors.confirm.message}</p>}
      <button type="submit">Submit</button>
    </form>
  )
}
```

### TSF

```tsx
import { useForm } from '@tanstack/react-form'

async function isUsernameFree(u: string) {
  await new Promise((r) => setTimeout(r, 300))
  return u !== 'taken'
}

export function TsfCrossAsync() {
  const form = useForm({
    defaultValues: { password: '', confirm: '', username: '' },
    onSubmit: async ({ value }) => console.log(value),
  })

  return (
    <form
      onSubmit={(e) => {
        e.preventDefault()
        form.handleSubmit()
      }}
    >
      <form.Field
        name="username"
        validators={{
          onChangeAsyncDebounceMs: 500,
          onChangeAsync: async ({ value }) => {
            const ok = await isUsernameFree(value)
            return ok ? undefined : 'Username taken'
          },
        }}
        children={(field) => (
          <>
            <input
              value={field.state.value}
              onBlur={field.handleBlur}
              onChange={(e) => field.handleChange(e.target.value)}
            />
            {field.state.meta.isValidating && <span>Checking…</span>}
            {!field.state.meta.isValid && (
              <em>{field.state.meta.errors.join(', ')}</em>
            )}
          </>
        )}
      />

      <form.Field
        name="password"
        children={(field) => (
          <input
            type="password"
            value={field.state.value}
            onBlur={field.handleBlur}
            onChange={(e) => field.handleChange(e.target.value)}
          />
        )}
      />

      <form.Field
        name="confirm"
        validators={{
          onChangeListenTo: ['password'],
          onChange: ({ value, fieldApi }) =>
            value !== fieldApi.form.getFieldValue('password')
              ? 'Passwords do not match'
              : undefined,
        }}
        children={(field) => (
          <>
            <input
              type="password"
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
      <button type="submit">Submit</button>
    </form>
  )
}
```

**Migration notes**

- `deps` → `onChangeListenTo`
- Async debounce is first-class in TSF (`onChangeAsyncDebounceMs`)
- Show `isValidating` for UX

---

## 5. Composition (shared field components)

### RHF

```tsx
import {
  useForm,
  FormProvider,
  useFormContext,
  useController,
} from 'react-hook-form'

function TextField({ name, label }: { name: string; label: string }) {
  const { control } = useFormContext()
  const { field, fieldState } = useController({ name, control })
  return (
    <label>
      {label}
      <input {...field} />
      {fieldState.error && <span>{fieldState.error.message}</span>}
    </label>
  )
}

export function RhfComposed() {
  const methods = useForm({
    defaultValues: { firstName: '', lastName: '' },
  })
  return (
    <FormProvider {...methods}>
      <form onSubmit={methods.handleSubmit(console.log)}>
        <TextField name="firstName" label="First" />
        <TextField name="lastName" label="Last" />
        <button type="submit">Save</button>
      </form>
    </FormProvider>
  )
}
```

### TSF (`createFormHook` sketch)

```tsx
import {
  createFormHook,
  createFormHookContexts,
  useForm,
} from '@tanstack/react-form'

const { fieldContext, formContext, useFieldContext } = createFormHookContexts()

function TextField({ label }: { label: string }) {
  const field = useFieldContext<string>()
  return (
    <label>
      {label}
      <input
        value={field.state.value}
        onBlur={field.handleBlur}
        onChange={(e) => field.handleChange(e.target.value)}
      />
      {!field.state.meta.isValid && (
        <span>{field.state.meta.errors.join(', ')}</span>
      )}
    </label>
  )
}

const { useAppForm } = createFormHook({
  fieldContext,
  formContext,
  fieldComponents: { TextField },
  formComponents: {},
})

export function TsfComposed() {
  const form = useAppForm({
    defaultValues: { firstName: '', lastName: '' },
    onSubmit: async ({ value }) => console.log(value),
  })

  return (
    <form
      onSubmit={(e) => {
        e.preventDefault()
        form.handleSubmit()
      }}
    >
      <form.AppField
        name="firstName"
        children={(field) => <field.TextField label="First" />}
      />
      <form.AppField
        name="lastName"
        children={(field) => <field.TextField label="Last" />}
      />
      <button type="submit">Save</button>
    </form>
  )
}
```

> Note: Exact `AppField` children typing varies slightly by `@tanstack/react-form` version. Prefer the official form-composition guide when wiring `createFormHook`.

**Migration notes**

- Invest early in `createFormHook` when migrating more than 2–3 forms.
- Typing is stronger than typical RHF context components if `defaultValues` is complete.
