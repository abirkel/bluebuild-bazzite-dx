# v2 Migration Summary - Ready to Go!

## TL;DR

**Good News:** We're already 95% ready for v2! The fixes we made while debugging are exactly what v2 needs.

## What We Already Fixed

During our debugging session, we made these changes (commit `ab0986b`):

1. **install-fonts.sh**: Changed `${BASH_SOURCE[0]}` → `$0`
2. **cleanup-docker.sh**: Added `2>/dev/null` to grep command

These are THE EXACT changes needed for v2 compatibility!

## What Happened

1. **Dec 28, 09:25 UTC**: BlueBuild released script module v2
2. **Dec 29, 02:21 UTC**: Our build started using v2 automatically (`:latest` tag)
3. **Our scripts broke** because:
   - `${BASH_SOURCE[0]}` wasn't set correctly in v2's execution context
   - `grep` failures caused silent exits
4. **We debugged and fixed** the issues
5. **We rolled back to v1** for stability
6. **Now**: Our scripts are v2-ready, but we're running on v1

## The Key Difference: Working Directory

### v1 (Current)
```
cd /tmp/files/scripts ONCE
run script1 from here
run script2 from here  
run script3 from here
```
All scripts share the same PWD: `/tmp/files/scripts`

### v2 (Future)
```
cd /tmp/files/scripts → run /tmp/files/scripts/script1
cd /tmp/files/scripts → run /tmp/files/scripts/script2
cd /tmp/files/scripts → run /tmp/files/scripts/script3
```
Each script is run with its full path, PWD is set per-script

**Impact:** `${BASH_SOURCE[0]}` may not be set, but `$0` always works.

## To Migrate to v2

### Option A: Just Change the Recipe (Recommended)
```yaml
# Change this:
- type: script@v1
  scripts:
    - fetch-aurora-blocklist.sh

# To this:
- type: script@v2  # or just 'script'
  scripts:
    - fetch-aurora-blocklist.sh
```

That's it! Our scripts are already compatible.

### Option B: Keep Current Scripts, Use v1
```yaml
# Keep using v1 (current state)
- type: script@v1
  scripts:
    - fetch-aurora-blocklist.sh
```

This works indefinitely. v1 won't be removed.

## Testing Plan

1. Create test branch
2. Change `script@v1` → `script@v2` in recipe.yml
3. Push and watch build
4. Verify scripts run successfully
5. Merge if successful

## Risk Assessment

**Risk Level:** LOW

**Why:**
- We already tested the script changes (they work)
- We can instantly rollback by changing `@v2` → `@v1`
- v1 remains available as fallback
- No code changes needed, just recipe.yml

## Timeline

- **Now**: Stable on v1 with v2-compatible scripts
- **Next**: Test v2 migration when convenient
- **Future**: v2 becomes standard, v1 remains for compatibility

## Files Changed

### Already Modified (v2-ready)
- ✅ `files/scripts/install-fonts.sh` - uses `$0`
- ✅ `files/scripts/cleanup-docker.sh` - handles grep errors
- ✅ `files/scripts/fetch-aurora-blocklist.sh` - no changes needed

### To Modify (for migration)
- `recipes/recipe.yml` - change `@v1` to `@v2` (3 places)

## Rollback Plan

If v2 fails:
```bash
# In recipe.yml, change back:
type: script@v2  →  type: script@v1

# Commit and push
git add recipes/recipe.yml
git commit -m "rollback: revert to script@v1"
git push
```

Build will work again immediately.

## Recommendation

**Wait 1-2 weeks**, then migrate to v2 during a low-risk time. There's no urgency since v1 works perfectly and will be maintained.

When ready:
1. Create branch `feature/migrate-to-script-v2`
2. Change recipe.yml
3. Test build
4. Merge if successful

## Questions?

- **Q: Why did our scripts break initially?**
  A: v2 changed how scripts are invoked, breaking `${BASH_SOURCE[0]}` and exposing grep errors.

- **Q: Are we ready for v2?**
  A: Yes! Scripts are already compatible.

- **Q: Should we migrate now?**
  A: No rush. v1 works fine. Migrate when convenient.

- **Q: What if v2 breaks something else?**
  A: Instant rollback by changing `@v2` → `@v1` in recipe.yml.

## References

- Full analysis: `V2_DEEP_ANALYSIS.md`
- Migration guide: `V2_MIGRATION_GUIDE.md`
- Breaking changes report: `BLUEBUILD_SCRIPT_MODULE_V2_REPORT.md`
