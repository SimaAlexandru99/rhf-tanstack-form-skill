# RHF ↔ TanStack Form Migration Skill

Agent skill for **migrating forms between React Hook Form and TanStack Form** (both directions).

Installable via [skills.sh](https://www.skills.sh/) / [`npx skills`](https://github.com/vercel-labs/skills).

## Install

```bash
npx skills add SimaAlexandru99/rhf-tanstack-form-skill
# or one skill only:
npx skills add SimaAlexandru99/rhf-tanstack-form-skill --skill rhf-tanstack-form-migration
```

## Skill

| Skill | Description |
|-------|-------------|
| `rhf-tanstack-form-migration` | Procedure + API mapping + pitfalls for RHF ↔ TanStack Form rewrites |

This is a **migration/procedure** skill, not a greenfield form builder. Use it when converting existing forms, comparing APIs, or choosing which library fits.

## Structure

```
skills/rhf-tanstack-form-migration/
├── SKILL.md
└── references/
    ├── api-mapping.md
    ├── side-by-side-examples.md
    ├── pitfalls.md
    └── checklists.md
```

## Local development

```bash
# list skill from this repo
npx skills add . --list

# install into current project
npx skills add . --skill rhf-tanstack-form-migration -y
```

## License

MIT
