## Pre-commit hook using `gitleaks`

**Script how-to:**

Installing the script:
```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/nickpimankov/gitleaks/main/pre-commit-hook.sh)"
```
Enabling the script through `git config`:
```bash
git config hooks.gitleaks true
```
Disabling the script through `git config`:
```bash
git config hooks.gitleaks false
```
Staging the changes:
```bash
git add .
```
Commiting the changes:
```bash
git commit -m "commit message"
```

**At this point if the script is enabled, it will check the code for secrets. If any of those found, the script would message an error `"gitleaks detected leaks. Please fix the issues before committing."` and abort the commit.**
