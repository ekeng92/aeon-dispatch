# Repo Health Check

Run a weekly health check on this repository.

## Checks

1. **Dependency freshness**: Are there outdated packages? Check package.json, Cargo.toml, go.mod, requirements.txt, or equivalent. Flag anything more than 2 major versions behind or with known CVEs
2. **Test suite**: Run the test suite. Report pass/fail counts and any new failures
3. **TypeScript / lint errors**: Run the type checker or linter if configured. Report any errors
4. **TODO/FIXME/HACK audit**: Search the codebase for TODO, FIXME, and HACK comments. List any that are older than 30 days (check git blame)
5. **Dead code**: Flag any exported functions or classes with zero references in the codebase

## Output Format

```
## Repo Health — [repo name] — [date]

### Dependencies
- ✅ All up to date / ⚠️ N outdated (list)

### Tests
- ✅ N passing / ❌ N failing (list failures)

### Type Check / Lint
- ✅ Clean / ⚠️ N issues (list)

### Stale TODOs
- (list with file, line, age)

### Summary
One-paragraph overall health assessment.
```
