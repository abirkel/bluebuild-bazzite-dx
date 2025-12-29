# BlueBuild Script Module v2 - Deep Technical Analysis

## Execution Flow Comparison

### v1 (Bash) Execution Flow

```bash
#!/usr/bin/env bash
set -euo pipefail

# Parse JSON config
get_json_array SCRIPTS 'try .["scripts"][]' "$1"
get_json_array SNIPPETS 'try .["snippets"][]' "$1"

# Process ALL scripts
if [[ ${#SCRIPTS[@]} -gt 0  ]]; then
    cd "$CONFIG_DIRECTORY/scripts"              # ← CHANGE DIR ONCE
    find "$PWD" -type f -exec chmod +x {} \;    # ← MAKE ALL EXECUTABLE
    for SCRIPT in "${SCRIPTS[@]}"; do
        echo "Running script $SCRIPT"
        "$PWD/$SCRIPT"                          # ← RUN FROM CURRENT DIR
    done
fi

# Process snippets
for SNIPPET in "${SNIPPETS[@]}"; do
    echo "Running snippet $SNIPPET"
    bash -c "$SNIPPET"                          # ← BASH SUBSHELL
done
```

**Key Points:**
- Changes to `/tmp/files/scripts` ONCE at the start
- Makes ALL scripts executable with one `find` command
- Runs all scripts from the SAME working directory
- Scripts inherit the `/tmp/files/scripts` PWD
- Snippets run in `bash` subshells

### v2 (Nushell) Execution Flow

```nu
#!/usr/bin/env nu

def main [config: string]: nothing -> nothing {
  let config = $config
    | from json
    | default [] scripts
    | default [] snippets

  # Process EACH script individually
  $config.scripts
    | each {|script|
      cd $'($env.CONFIG_DIRECTORY)/scripts'    # ← CHANGE DIR FOR EACH SCRIPT
      let script = $'($env.PWD)/($script)'     # ← BUILD FULL PATH
      chmod +x $script                         # ← MAKE THIS ONE EXECUTABLE
      print -e $'(ansi green)Running script: (ansi cyan)($script)(ansi reset)'
      ^$script                                 # ← RUN WITH SHEBANG
    }

  # Process snippets
  $config.snippets
    | each {|snippet|
      print -e $"(ansi green)Running snippet:\n(ansi cyan)($snippet)(ansi reset)"
      /bin/sh -c $'($snippet)'                 # ← POSIX SH SUBSHELL
    }
}
```

**Key Points:**
- Changes to `/tmp/files/scripts` FOR EACH SCRIPT
- Makes each script executable individually
- Runs each script with its FULL PATH
- Scripts may NOT inherit `/tmp/files/scripts` as PWD (depends on shebang)
- Snippets run in `/bin/sh` (POSIX) subshells, NOT bash

## Critical Difference: Working Directory

### v1 Behavior
```
Module starts → cd /tmp/files/scripts → run script1 → run script2 → run script3
                     ↑                      ↑             ↑             ↑
                     └──────────────────────┴─────────────┴─────────────┘
                            ALL scripts run from here
```

**Result:** All scripts have `PWD=/tmp/files/scripts`

### v2 Behavior
```
Module starts → cd /tmp/files/scripts → run /tmp/files/scripts/script1
                cd /tmp/files/scripts → run /tmp/files/scripts/script2
                cd /tmp/files/scripts → run /tmp/files/scripts/script3
                     ↑                           ↑
                     └───────────────────────────┘
                  Changes dir, then runs with full path
```

**Result:** Scripts run with full path, PWD depends on shebang interpreter behavior

## Evidence from Build Logs

### Snippet Execution (v2)
```
Running snippet: bash /tmp/files/scripts/fetch-aurora-blocklist.sh
PWD: /
```
When run via snippet with `bash`, PWD is `/` (root)

### Script Execution (v2)
```
Running script: /tmp/files/scripts/install-fonts.sh
PWD: /tmp/files/scripts
```
When run via `scripts:` array, PWD is `/tmp/files/scripts`

**Why the difference?**
- Snippets: Run with `/bin/sh -c` from wherever Nushell is
- Scripts: Nushell does `cd` first, THEN runs the script

## Impact on ${BASH_SOURCE[0]} vs $0

### ${BASH_SOURCE[0]}
- Bash-specific variable
- Contains the path to the script being executed
- May not be set when script is invoked by non-bash process
- **In v2**: Nushell invokes the script → bash starts → `${BASH_SOURCE[0]}` may be empty or incorrect

### $0
- POSIX standard variable
- Always set to the script name/path
- Works across all shells
- **In v2**: Always contains `/tmp/files/scripts/scriptname.sh`

### Test Case
```bash
# v1 execution:
cd /tmp/files/scripts
./install-fonts.sh
# Inside script: ${BASH_SOURCE[0]} = "./install-fonts.sh" or "install-fonts.sh"
# Inside script: $0 = "./install-fonts.sh" or "install-fonts.sh"

# v2 execution:
cd /tmp/files/scripts
/tmp/files/scripts/install-fonts.sh
# Inside script: ${BASH_SOURCE[0]} = may be unset or wrong
# Inside script: $0 = "/tmp/files/scripts/install-fonts.sh"
```

## Snippet Behavior Change

### v1: bash -c
```bash
bash -c "echo 'test'"
```
- Full bash features available
- Arrays, associative arrays, `[[`, etc.
- Bash-specific syntax works

### v2: /bin/sh -c
```sh
/bin/sh -c "echo 'test'"
```
- POSIX shell only
- No bash-specific features
- Must be portable

**Breaking Changes:**
- `[[` → must use `[`
- `${array[@]}` → not available
- `${var//pattern/replacement}` → not available
- Process substitution `<()` → not available

## Our Scripts Analysis

### fetch-aurora-blocklist.sh
```bash
#!/usr/bin/env bash
set -euo pipefail

echo "Fetching Aurora blocklist..."
mkdir -p /etc/bazaar
curl -fsSL https://raw.githubusercontent.com/... -o /etc/bazaar/blocklist.yaml
echo "Aurora blocklist installed successfully"
```

**v2 Compatibility:** ✅ GOOD
- No path dependencies
- No ${BASH_SOURCE[0]}
- No grep or conditional failures
- Should work as-is

### install-fonts.sh
```bash
#!/usr/bin/env bash
set -oue pipefail

echo "Installing fonts..."
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"  # ← PROBLEM
FONTS_ARCHIVE="${SCRIPT_DIR}/fonts.7z"
```

**v2 Compatibility:** ❌ BROKEN
- Uses `${BASH_SOURCE[0]}` which may not be set
- Needs to use `$0` instead
- Otherwise script is fine

**Fix:**
```bash
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
```

### cleanup-docker.sh
```bash
#!/usr/bin/env bash
set -euo pipefail

rm -f /etc/yum.repos.d/docker-ce.repo

if grep -q "^docker:" /etc/group; then  # ← PROBLEM
    sed -i '/^docker:/d' /etc/group
fi

sed -i 's/,docker//g; s/:docker,/:/g; s/:docker$/:/g' /etc/group
echo "Docker cleanup complete."
```

**v2 Compatibility:** ❌ BROKEN
- `grep -q` returns non-zero when no match
- With `set -euo pipefail`, script exits immediately
- No output produced → "empty list"

**Fix:**
```bash
if grep -q "^docker:" /etc/group 2>/dev/null; then
    sed -i '/^docker:/d' /etc/group
fi
# OR
grep -q "^docker:" /etc/group && sed -i '/^docker:/d' /etc/group || true
```

## Additional v2 Considerations

### Output Formatting
v2 uses Nushell's table formatting:
```
╭───┬─────────────────────────────────────────╮
│ 0 │ Testing snippet execution               │
│ 1 │ PWD: /                                  │
╰───┴─────────────────────────────────────────╯
```

vs v1's simple output:
```
Testing snippet execution
PWD: /
```

### Error Messages
v2 may have different error output due to Nushell's error handling

### Performance
v2 does more work per script (cd + chmod for each), but difference is negligible

## Migration Requirements

### Mandatory Changes
1. ✅ **install-fonts.sh**: Change `${BASH_SOURCE[0]}` → `$0`
2. ✅ **cleanup-docker.sh**: Add error handling for grep

### Optional Improvements
1. Add explicit error messages for debugging
2. Use `set -eu` instead of `set -euo pipefail` for POSIX compatibility
3. Test scripts with `/bin/sh` to ensure portability

### Recipe Changes
```yaml
# FROM:
- type: script@v1
  scripts:
    - fetch-aurora-blocklist.sh

# TO:
- type: script@v2  # or just 'script'
  scripts:
    - fetch-aurora-blocklist.sh
```

## Testing Strategy

### 1. Local Testing
```bash
# Test with POSIX shell
/bin/sh files/scripts/fetch-aurora-blocklist.sh
/bin/sh files/scripts/cleanup-docker.sh

# Test with bash
bash files/scripts/install-fonts.sh
```

### 2. Verify $0 behavior
```bash
# Create test script
cat > test-path.sh << 'EOF'
#!/usr/bin/env bash
echo "BASH_SOURCE[0]: ${BASH_SOURCE[0]}"
echo "\$0: $0"
echo "dirname \$0: $(dirname "$0")"
EOF

chmod +x test-path.sh

# Test different invocation methods
./test-path.sh
bash test-path.sh
/full/path/to/test-path.sh
```

### 3. Build Testing
1. Create test branch
2. Apply v2 changes
3. Monitor for "empty list" boxes
4. Verify script output appears

## Conclusion

The v2 migration requires:
1. **Minimal code changes** (2 lines across 2 files)
2. **Better error handling** (which we should have anyway)
3. **More portable code** (POSIX-compatible)

The changes we made during debugging are exactly what's needed for v2 compatibility. We're already 95% ready to migrate.
