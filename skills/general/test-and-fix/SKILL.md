---
name: test-and-fix
description: Automatically run Rails tests, identify failures, and fix common issues including missing fixtures, missing factories, syntax errors, and test setup problems. Use when Rails tests are failing, after writing new models or tests, when setting up test infrastructure, or when the user requests automated test fixing and debugging. Iteratively applies fixes and re-runs tests until all pass or no more automatic fixes are available.
---

# Test and Fix

Automatically run Rails tests, identify failures, parse error messages, apply common fixes, and re-run tests until they pass.

## Quick Start

Run tests and auto-fix issues:

```bash
ruby scripts/test_and_fix.rb
```

Run tests for specific scope:

```bash
ruby scripts/test_and_fix.rb --scope test/models
ruby scripts/test_and_fix.rb --scope test/models/user_test.rb
```

Verbose output:

```bash
ruby scripts/test_and_fix.rb --verbose
```

## What It Does

The script follows this workflow:

1. **Run tests** - Execute `rails test` (or scoped command)
2. **Parse failures** - Extract error patterns from test output
3. **Apply fixes** - Automatically fix recognizable issues
4. **Re-run tests** - Verify fixes worked
5. **Repeat** - Continue until all tests pass or max iterations reached

## Automatic Fixes

### ✅ Can Fix Automatically

| Issue | Fix Applied |
|-------|-------------|
| Missing fixture file | Creates `test/fixtures/model_name.yml` with template |
| Empty fixture file | Populates with basic two-record template |
| Missing factory | Creates `test/factories/model_name.rb` with FactoryBot template |
| Syntax errors | Adds missing `end` keywords, closes unmatched quotes |

### ❌ Requires Manual Intervention

| Issue | What You Need To Do |
|-------|---------------------|
| Undefined method | Add missing association or method to model |
| Validation errors | Add required attributes to fixtures/factories |
| Missing columns | Run database migrations |
| Undefined constants | Create missing model/class files |

See [references/error_patterns.md](references/error_patterns.md) for complete list of recognizable error patterns and fix strategies.

## Usage Options

### Basic Usage

```bash
ruby scripts/test_and_fix.rb
```

Runs all tests and attempts to fix failures.

### Scoped Testing

```bash
# Test only models
ruby scripts/test_and_fix.rb --scope test/models

# Test specific file
ruby scripts/test_and_fix.rb --scope test/models/user_test.rb

# Test controllers
ruby scripts/test_and_fix.rb --scope test/controllers
```

### Advanced Options

```bash
# Set max iterations (default: 5)
ruby scripts/test_and_fix.rb --max-iterations 10

# Verbose output (show test results each iteration)
ruby scripts/test_and_fix.rb --verbose

# Combine options
ruby scripts/test_and_fix.rb --scope test/models --max-iterations 3 --verbose
```

## Example Session

```bash
$ ruby scripts/test_and_fix.rb --scope test/models

🧪 Running Rails tests (scope: test/models)...

📍 Iteration 1/5
Found 3 failure(s) to fix...
  ✓ Created fixture file: test/fixtures/users.yml
  ✓ Created fixture file: test/fixtures/posts.yml
  ✓ Created factory file: test/factories/comments.rb

📍 Iteration 2/5
Found 1 failure(s) to fix...
  ✓ Fixed syntax error in: test/models/user_test.rb

📍 Iteration 3/5

✅ All tests passing!

============================================================
SUMMARY
============================================================
Iterations: 3
Fixes applied: 4

Fixes:
  • Created fixture file: test/fixtures/users.yml
  • Created fixture file: test/fixtures/posts.yml
  • Created factory file: test/factories/comments.rb
  • Fixed syntax error in: test/models/user_test.rb
```

## Generated File Templates

### Fixture Template

Created at `test/fixtures/model_name.yml`:

```yaml
# Read about fixtures at https://api.rubyonrails.org/classes/ActiveRecord/FixtureSet.html

one:
  id: 1
  # Add attributes here

two:
  id: 2
  # Add attributes here
```

**After generation**: Edit to add actual model attributes with realistic test data.

### Factory Template

Created at `test/factories/model_name.rb`:

```ruby
# frozen_string_literal: true

FactoryBot.define do
  factory :model_name do
    # Add attributes here
  end
end
```

**After generation**: Add attribute definitions with sensible defaults or sequences.

## Post-Fix Workflow

After the script completes:

1. **Review generated files** - Check `test/fixtures/` and `test/factories/`
2. **Add missing data** - Populate fixtures/factories with realistic attributes
3. **Handle manual fixes** - Address any issues that couldn't be auto-fixed
4. **Run tests manually** - Verify everything works: `rails test`
5. **Commit changes** - Add new fixtures/factories to version control

## Error Patterns Reference

For detailed information on error patterns and fix strategies, see [references/error_patterns.md](references/error_patterns.md).

This includes:
- All recognizable error patterns
- What automatic fixes are applied
- Manual fix instructions for unsupported errors
- Success rates for each error type

## Integration with CI/CD

Use in CI/CD workflows to automatically fix test setup issues:

```yaml
# .github/workflows/ci.yml
- name: Run tests with auto-fix
  run: |
    ruby scripts/test_and_fix.rb
    if [ $? -ne 0 ]; then
      git add test/fixtures test/factories
      git commit -m "Auto-fix: Add missing test fixtures/factories"
    fi
```

**Note**: Review auto-generated fixtures before committing in CI.

## Limitations

- **Focuses on structural issues** (missing files) not logical issues (wrong data)
- **Syntax fixes are heuristic** - May not work for complex syntax errors
- **Cannot fix business logic** - Test assertions and expectations need manual review
- **Limited to Rails conventions** - Assumes standard Rails project structure

## Best Practices

1. **Run early and often** - Fix issues as soon as tests fail
2. **Review generated files** - Don't blindly trust auto-generated fixtures
3. **Add realistic data** - Populate fixtures with meaningful test data after generation
4. **Use with version control** - Review changes before committing
5. **Combine with manual review** - Use as a starting point, not a complete solution

## Extending the Script

To add new error patterns and fixes:

1. Add pattern to `parse_failures` method in `test_and_fix.rb`
2. Create fix method in `fixers.rb`
3. Add case to `apply_fix` method
4. Document in `references/error_patterns.md`

Example:

```ruby
# In test_and_fix.rb
output.scan(/new error pattern (.+)/) do |match|
  failures << {
    type: :new_error_type,
    data: match[0]
  }
end

# In fixers.rb
def fix_new_error_type(failure)
  # Apply fix logic
  # Return fix description hash or nil
end
```
