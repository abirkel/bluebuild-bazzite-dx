# BlueBuild Script Module v2 Migration Guide

## Overview

This guide outlines the changes needed to migrate our scripts from `script@v1` (Bash) to `script@v2` (Nushell).

## Key Differences Between v1 and v2

### Execution Environment

**v1 (Bash):**
- Snippets run with: `bash -c "$SNIPPET"`
- Scripts run directly after `cd "$CONFIG_DIRECTORY/scripts"`
- All scripts made executable upfront with `find`
- Working directory: `/tmp/files/scripts` for all scripts

**v2 (Nushell):**
- Snippets run with: `/bin/sh -c $'($snippet)'` (POSIX shell, not bash!)
- Scripts run with: `^$script` (direct execution via shebang)
- Each script made executable individually with `chmod +x`
- Working directory: Changes to `/tmp/files/scripts` for EACH script

### Critical Changes

1. **Snippets use `/bin/sh` instead of `bash`**
   - Must be POSIX-compatible
   - Bash-specific features won't work

2. **Script execution context**
   - Each script runs in its own context
   - `${BASH_SOURCE[0]}` may not be set correctly
   - Use `$0` instead for portability

3. **Error handling**
   - Commands that return non-zero must be handled explicitly
   - `grep` without matches will fail the script
   - Use `|| true` or proper conditionals

## Required Changes for Our Scripts

### 1. fetch-aurora-blocklist.sh

**Current Issues:**
- None - this script should work fine with v2

**Changes Needed:**
- None required

**Status:** ✅ Ready for v2

---

### 2. install-fonts.sh

**Current Issues:**
- Uses `${BASH_SOURCE[0]}` which may not be set in v2 context

**Changes Needed:**
```bash
# BEFORE (v1):
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# AFTER (v2):
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
```

**Status:** ⚠️ Needs modification

---

### 3. cleanup-docker.sh

**Current Issues:**
- `grep -q "^docker:" /etc/group` returns non-zero when no match found
- With `set -euo pipefail`, this causes script to exit

**Changes Needed:**
```bash
# BEFORE (v1):
if grep -q "^docker:" /etc/group; then
    sed -i '/^docker:/d' /etc/group
fi

# AFTER (v2):
if grep -q "^docker:" /etc/group 2>/dev/null; then
    sed -i '/^docker:/d' /etc/group
fi
# OR
grep -q "^docker:" /etc/group && sed -i '/^docker:/d' /etc/group || true
```

**Status:** ⚠️ Needs modification

---

## Migration Checklist

### Phase 1: Script Updates (ALREADY DONE! ✅)
- [x] Update `install-fonts.sh` to use `$0` instead of `${BASH_SOURCE[0]}` - **DONE in commit ab0986b**
- [x] Update `cleanup-docker.sh` to handle grep failures gracefully - **DONE in commit ab0986b**
- [ ] Test scripts locally with `/bin/sh` to ensure POSIX compatibility
- [x] Verify all scripts have proper shebangs - **CONFIRMED**

**Note:** We already made these changes while debugging the v2 issues! The current scripts in the repo are v2-compatible.

### Phase 2: Recipe Updates
- [ ] Change `type: script@v1` to `type: script@v2` (or just `type: script`)
- [ ] Test build with v2 module
- [ ] Verify all scripts execute successfully
- [ ] Check output formatting (v2 uses fancy ANSI boxes)

### Phase 3: Validation
- [ ] Confirm fetch-aurora-blocklist.sh works
- [ ] Confirm install-fonts.sh installs fonts correctly
- [ ] Confirm cleanup-docker.sh removes docker artifacts
- [ ] Verify final image has expected files in place

## Testing Strategy

### Local Testing
```bash
# Test with POSIX shell
/bin/sh -c "set -eu; ./files/scripts/fetch-aurora-blocklist.sh"
/bin/sh -c "set -eu; ./files/scripts/cleanup-docker.sh"

# Test with bash (should still work)
bash -c "set -euo pipefail; ./files/scripts/install-fonts.sh"
```

### Build Testing
1. Create a test branch
2. Apply v2 changes
3. Trigger build
4. Monitor logs for "empty list" boxes
5. Verify scripts produce expected output

## Rollback Plan

If v2 migration fails:
1. Revert recipe.yml changes (`script@v2` → `script@v1`)
2. Revert script modifications
3. Push changes
4. Build should work with v1 again

## Benefits of v2

1. **POSIX Compatibility**: Scripts work with any POSIX shell
2. **Better Multi-line Snippets**: Fixed bug where multi-line snippets were split
3. **Cleaner Output**: Fancy ANSI formatting with colored boxes
4. **Future-proof**: v2 is now the default and will receive updates

## Timeline

- **Current**: Using v1 (stable, working)
- **Target**: Migrate to v2 within 1-2 weeks
- **Deadline**: None, but v1 may be deprecated eventually

## Notes

- v1 will likely be maintained for backward compatibility
- No rush to migrate, but v2 is the future
- Test thoroughly before switching in production
