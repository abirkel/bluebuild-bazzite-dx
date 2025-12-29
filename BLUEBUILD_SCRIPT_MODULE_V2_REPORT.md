# BlueBuild Script Module v2 Breaking Changes Report

## Timeline
- **Commit**: `ced173ae1edbec54585073baccaf6a342c5012a0`
- **Date**: December 28, 2025 at 14:25:46 UTC (23:25 JST)
- **Working build**: Dec 28, 09:29 UTC (before the change)
- **Failing build**: Dec 29, 02:21 UTC (after the change)

## What Changed

BlueBuild converted the script module from **Bash (v1)** to **Nushell (v2)** and made it the default. When you use `type: script` (without version), it now uses v2 by default.

## Key Differences Between v1 and v2

### v1 (Bash - OLD)
```bash
#!/usr/bin/env bash
set -euo pipefail

cd "$CONFIG_DIRECTORY/scripts"
# Make every script executable
find "$PWD" -type f -exec chmod +x {} \;
for SCRIPT in "${SCRIPTS[@]}"; do
    echo "Running script $SCRIPT"
    "$PWD/$SCRIPT"
done

for SNIPPET in "${SNIPPETS[@]}"; do
    echo "Running snippet $SNIPPET"
    bash -c "$SNIPPET"
done
```

### v2 (Nushell - NEW)
```nu
#!/usr/bin/env nu

$config.scripts
  | each {|script|
    cd $'($env.CONFIG_DIRECTORY)/scripts'
    let script = $'($env.PWD)/($script)'
    chmod +x $script
    print -e $'(ansi green)Running script: (ansi cyan)($script)(ansi reset)'
    ^$script
  }

$config.snippets
  | each {|snippet|
    print -e $"(ansi green)Running snippet:\n(ansi cyan)($snippet)(ansi reset)"
    /bin/sh -c $'($snippet)'
  }
```

## Critical Changes That Broke Our Scripts

1. **Snippets now use `/bin/sh` instead of `bash`**
   - v1: `bash -c "$SNIPPET"`
   - v2: `/bin/sh -c $'($snippet)'`
   - Impact: POSIX shell compatibility required

2. **Scripts are invoked directly with their shebang**
   - v1: Made all scripts executable upfront with `find`
   - v2: Makes each script executable individually with `chmod +x`
   - Impact: Scripts must have proper shebangs

3. **Output formatting changed**
   - v1: Simple echo statements
   - v2: Fancy ANSI colored output with boxes
   - The "empty list" box is v2's way of showing "no stdout output captured"

4. **Script execution context**
   - v1: Changed to scripts directory once, then ran all scripts
   - v2: Changes to scripts directory for EACH script individually
   - Impact: `${BASH_SOURCE[0]}` behavior may differ

5. **Error handling**
   - Both use strict error handling, but v2's Nushell implementation may handle errors differently
   - Scripts with `grep` commands that return non-zero were failing silently

## Why Our Scripts Failed

1. **`${BASH_SOURCE[0]}` not set**: When Nushell invokes bash scripts, the environment may be different
2. **`grep` failures**: Commands like `grep -q "^docker:" /etc/group` return non-zero when no match is found, causing `set -oue pipefail` to exit
3. **Output capture**: v2 captures stdout differently, showing "empty list" when scripts fail before producing stdout

## Version Control

The module now supports explicit versioning:
- `type: script` or `type: script@latest` → Uses v2 (Nushell)
- `type: script@v2` → Explicitly uses v2 (Nushell)
- `type: script@v1` → Uses v1 (Bash)

## Solutions

### Option 1: Pin to v1 (temporary workaround)
```yaml
- type: script@v1
  scripts:
    - fetch-aurora-blocklist.sh
```

### Option 2: Fix scripts for v2 compatibility
- Use `$0` instead of `${BASH_SOURCE[0]}`
- Handle grep failures gracefully with `2>/dev/null` or proper conditionals
- Ensure proper error handling for all commands

## Commit Message from BlueBuild

> "This follows the new pattern in #503 for trying to be POSIX compatible or use nushell for modules. This does change the scripts module so that the snippets are executed with `sh` instead of `bash`. And it also fixes a bug where a user would create a multi-line snippet only for each line in that one multi-line snippet to be executed separately. Now the entire multi-line snippet entry will execute as one script."

## References

- Commit: https://github.com/blue-build/modules/commit/ced173ae1edbec54585073baccaf6a342c5012a0
- PR: https://github.com/blue-build/modules/pull/515

## Bottom Line

BlueBuild pushed a breaking change to their script module on Dec 28, 2025, switching from Bash to Nushell as the default. Our scripts worked fine with v1 but broke with v2 due to subtle differences in execution environment and error handling.
