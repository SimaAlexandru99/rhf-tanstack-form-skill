#!/usr/bin/env bash
# Inventory React Hook Form vs TanStack Form usage in a codebase.
# Usage:
#   ./inventory.sh [root-dir]
#   bash scripts/inventory.sh ~/projects/dialyx
set -euo pipefail

ROOT="${1:-.}"
if [[ ! -d "$ROOT" ]]; then
  echo "error: not a directory: $ROOT" >&2
  exit 1
fi

# Prefer rg; fall back to grep -R
if command -v rg >/dev/null 2>&1; then
  search() {
    local pattern="$1"
    shift
    rg -n --glob '*.{ts,tsx,js,jsx}' --glob '!node_modules/**' --glob '!.next/**' \
      --glob '!dist/**' --glob '!build/**' "$pattern" "$ROOT" "$@" 2>/dev/null || true
  }
  search_files() {
    local pattern="$1"
    rg -l --glob '*.{ts,tsx,js,jsx}' --glob '!node_modules/**' --glob '!.next/**' \
      --glob '!dist/**' --glob '!build/**' "$pattern" "$ROOT" 2>/dev/null || true
  }
  pkg_search() {
    rg -n --glob 'package.json' --glob '!node_modules/**' "$1" "$ROOT" 2>/dev/null || true
  }
else
  search() {
    local pattern="$1"
    grep -Rn --include='*.ts' --include='*.tsx' --include='*.js' --include='*.jsx' \
      --exclude-dir=node_modules --exclude-dir=.next --exclude-dir=dist --exclude-dir=build \
      -E "$pattern" "$ROOT" 2>/dev/null || true
  }
  search_files() {
    local pattern="$1"
    grep -Rl --include='*.ts' --include='*.tsx' --include='*.js' --include='*.jsx' \
      --exclude-dir=node_modules --exclude-dir=.next --exclude-dir=dist --exclude-dir=build \
      -E "$pattern" "$ROOT" 2>/dev/null || true
  }
  pkg_search() {
    grep -Rn --include='package.json' --exclude-dir=node_modules -E "$1" "$ROOT" 2>/dev/null || true
  }
fi

count_lines() {
  local n
  n=$(printf '%s' "$1" | grep -c . || true)
  echo "${n:-0}"
}

echo "=== Form library inventory ==="
echo "root: $(cd "$ROOT" && pwd)"
echo

echo "--- package.json deps ---"
pkgs=$(pkg_search 'react-hook-form|@hookform/resolvers|@tanstack/react-form')
if [[ -z "$pkgs" ]]; then
  echo "(none found)"
else
  echo "$pkgs"
fi
echo

RHF_IMPORT_RE="from ['\"]react-hook-form['\"]|require\(['\"]react-hook-form['\"]\)"
TSF_IMPORT_RE="from ['\"]@tanstack/react-form['\"]|require\(['\"]@tanstack/react-form['\"]\)"

rhf_files=$(search_files "$RHF_IMPORT_RE")
tsf_files=$(search_files "$TSF_IMPORT_RE")

rhf_file_count=$(count_lines "$rhf_files")
tsf_file_count=$(count_lines "$tsf_files")

echo "--- RHF import files ($rhf_file_count) ---"
if [[ -z "$rhf_files" ]]; then
  echo "(none)"
else
  echo "$rhf_files"
fi
echo

echo "--- TanStack Form import files ($tsf_file_count) ---"
if [[ -z "$tsf_files" ]]; then
  echo "(none)"
else
  echo "$tsf_files"
fi
echo

count_pattern() {
  # Count matching lines without loading huge output into memory twice.
  local pattern="$1"
  if command -v rg >/dev/null 2>&1; then
    rg -n --glob '*.{ts,tsx,js,jsx}' --glob '!node_modules/**' --glob '!.next/**' \
      --glob '!dist/**' --glob '!build/**' -c "$pattern" "$ROOT" 2>/dev/null \
      | awk -F: '{s+=$NF} END {print s+0}'
  else
    search "$pattern" | count_lines "$(cat)"
  fi
}

# Portable total line count for a pattern
total_hits() {
  local pattern="$1"
  local out
  out=$(search "$pattern")
  count_lines "$out"
}

echo "--- RHF pattern hits ---"
for label_pat in \
  "useForm\\(" \
  "useFieldArray" \
  "Controller|useController" \
  "FormProvider|useFormContext" \
  "useWatch|useFormState" \
  "zodResolver|@hookform/resolvers"
do
  n=$(total_hits "$label_pat")
  printf "  %-32s %s\n" "$label_pat:" "$n"
done
echo

echo "--- TanStack Form pattern hits ---"
for label_pat in \
  "createFormHook|createFormHookContexts" \
  "form\\.Field|AppField" \
  "mode=[\"']array[\"']" \
  "pushValue|removeValue|insertValue" \
  "form\\.Subscribe|useSelector" \
  "withForm|withFieldGroup"
do
  n=$(total_hits "$label_pat")
  printf "  %-40s %s\n" "$label_pat:" "$n"
done
# TSF useForm is package-scoped — count import files only (already above)
echo

echo "--- Complexity signals (RHF) ---"
printf "  useFieldArray hits:        %s\n" "$(total_hits 'useFieldArray')"
printf "  Controller hits:           %s\n" "$(total_hits 'Controller|useController')"
printf "  FormProvider/context hits: %s\n" "$(total_hits 'FormProvider|useFormContext')"
printf "  useWatch/useFormState:     %s\n" "$(total_hits 'useWatch|useFormState')"
echo

echo "--- Suggested migration order ---"
if [[ "$rhf_file_count" -eq 0 && "$tsf_file_count" -eq 0 ]]; then
  echo "No form-library imports found. Nothing to migrate."
elif [[ "$rhf_file_count" -gt 0 && "$tsf_file_count" -eq 0 ]]; then
  echo "Direction: RHF → TanStack Form (if justified)."
  echo "Start with a medium form (Controller + Zod, no arrays), then arrays, then FormProvider trees."
elif [[ "$tsf_file_count" -gt 0 && "$rhf_file_count" -eq 0 ]]; then
  echo "Direction: TanStack Form → RHF (if justified), or stay on TSF."
elif [[ "$rhf_file_count" -gt 0 && "$tsf_file_count" -gt 0 ]]; then
  echo "Mixed stack: both libraries present."
  echo "Finish one direction per form; avoid dual patterns in the same feature."
  echo "RHF files: $rhf_file_count · TSF files: $tsf_file_count"
fi
echo
echo "Done. Use rhf-tanstack-form-migration skill checklists next."
