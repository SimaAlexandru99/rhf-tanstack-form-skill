# RHF ↔ TanStack Form Migration Skill

Agent skill for **migrating forms between React Hook Form and TanStack Form** (both directions).

Installable via [skills.sh](https://www.skills.sh/) / [`npx skills`](https://github.com/vercel-labs/skills).

[![skills.sh](https://skills.sh/b/SimaAlexandru99/rhf-tanstack-form-skill)](https://skills.sh/SimaAlexandru99/rhf-tanstack-form-skill)

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
├── scripts/
│   └── inventory.sh          # grep-based RHF/TSF inventory
└── references/
    ├── api-mapping.md
    ├── side-by-side-examples.md
    ├── pitfalls.md
    └── checklists.md
```

## Inventory a codebase

After install (or from this repo):

```bash
bash skills/rhf-tanstack-form-migration/scripts/inventory.sh /path/to/project
# installed skill path example:
bash ~/.claude/skills/rhf-tanstack-form-migration/scripts/inventory.sh .
```

Prints package deps, import files, pattern hit counts, and a suggested migration direction.

## Local development

```bash
# list skill from this repo
npx skills add . --list

# install into current project
npx skills add . --skill rhf-tanstack-form-migration -y

# validate
npx --yes skills-ref validate ./skills/rhf-tanstack-form-migration
```

## License

MIT
