# Contributing

## Commit Convention

This repository follows [Conventional Commits](https://www.conventionalcommits.org/), where possible:
```
fix(parser): handle empty commit messages gracefully
feat(cli): add support for --dry-run flag
refactor(core)!: change internal API to use async/await
```

## Developer Certificate of Origin

All commits must be signed off to indicate you agree to the [Developer Certificate of Origin (DCO)](https://developercertificate.org/).

Add the `-s` flag when committing:
```sh
git commit -s -m "feat(parser): handle empty commit messages gracefully"
```

This appends a `Signed-off-by` line using your git config name and email. If you forget, you can amend your last commit with:
```sh
git commit --amend -s --no-edit
```

Or sign off an entire branch with:
```sh
git rebase --signoff HEAD~<number of commits>
```

## Pull Requests

Open pull requests against the `main` branch. Ensure every commit in your PR is signed off before requesting review.
