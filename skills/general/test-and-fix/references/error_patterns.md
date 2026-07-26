# Recognizable Error Patterns and Automatic Fixes

This document describes the error patterns the test-and-fix skill can recognize and automatically fix.

## Supported Error Patterns

### 1. Missing Fixture

**Pattern**: `ActiveRecord::RecordNotFound.*Couldn't find Model`

**Example Error**:
```
ActiveRecord::RecordNotFound: Couldn't find User with 'id'=1
```

**Automatic Fix**:
- Creates `test/fixtures/users.yml` if it doesn't exist
- Populates empty fixture files with basic template
- Adds two sample records (one, two) with IDs

**Generated Fixture**:
```yaml
one:
  id: 1
  # Add attributes here

two:
  id: 2
  # Add attributes here
```

---

### 2. Missing Factory

**Pattern**: `Factory not registered: "factory_name"`

**Example Error**:
```
Factory not registered: "user"
```

**Automatic Fix**:
- Creates `test/factories/users.rb` if it doesn't exist
- Generates FactoryBot template

**Generated Factory**:
```ruby
FactoryBot.define do
  factory :user do
    # Add attributes here
  end
end
```

---

### 3. Undefined Method

**Pattern**: `undefined method 'method_name' for #<Model:`

**Example Error**:
```
undefined method `posts' for #<User:0x00007f8b1c0a3d40>
```

**Automatic Fix**:
- **Not automatically fixable** - requires manual intervention
- Often indicates missing association or helper method
- Requires adding the association or method to the model

**Manual Fix Needed**:
```ruby
# In app/models/user.rb
has_many :posts
```

---

### 4. Validation Error

**Pattern**: `Validation failed: error_message`

**Example Error**:
```
Validation failed: Email can't be blank
```

**Automatic Fix**:
- **Not automatically fixable** - requires manual intervention
- Need to add required attributes to fixtures or factories

**Manual Fix Needed**:
```yaml
# In test/fixtures/users.yml
one:
  email: user1@example.com
```

---

### 5. Missing Column

**Pattern**: `unknown attribute 'column_name' for Model`

**Example Error**:
```
unknown attribute 'email' for User
```

**Automatic Fix**:
- **Not automatically fixable** - indicates schema issue
- Need to run migrations or update database schema

**Manual Fix Needed**:
```bash
rails db:migrate
# or
rails db:schema:load
```

---

### 6. Syntax Error

**Pattern**: `syntax error.*in 'file_path'`

**Example Error**:
```
syntax error, unexpected end-of-input, expecting keyword_end
```

**Automatic Fixes Attempted**:
- Add missing `end` keywords (count begin/end keywords)
- Close unmatched quotes (single or double)
- Add missing closing brackets

**Note**: Syntax fixes are heuristic-based and may not always work. Manual review recommended.

---

### 7. Undefined Constant

**Pattern**: `uninitialized constant ConstantName`

**Example Error**:
```
uninitialized constant User
```

**Automatic Fix**:
- **Not automatically fixable** - requires model/class creation
- Indicates missing model, controller, or class file

**Manual Fix Needed**:
```bash
rails generate model User name:string email:string
```

---

## Fix Success Rates

| Error Type | Auto-Fixable | Success Rate | Notes |
|------------|--------------|--------------|-------|
| Missing Fixture | ✅ Yes | 90% | Creates basic template |
| Missing Factory | ✅ Yes | 90% | Creates basic template |
| Undefined Method | ❌ No | 0% | Requires manual code changes |
| Validation Error | ❌ No | 0% | Requires data updates |
| Missing Column | ❌ No | 0% | Requires migration |
| Syntax Error | ⚠️ Partial | 40% | Heuristic-based fixes |
| Undefined Constant | ❌ No | 0% | Requires class creation |

## Workflow After Auto-Fix

After the script applies automatic fixes:

1. **Review the changes** - Check generated fixtures/factories
2. **Add missing data** - Populate fixtures with realistic data
3. **Run tests manually** - Verify fixes worked: `rails test`
4. **Commit changes** - Add generated files to git

## Limitations

The test-and-fix skill focuses on **structural issues** (missing files, templates) rather than **logical issues** (wrong data, incorrect logic).

**Can fix**:
- Missing fixture files
- Missing factory files
- Some syntax errors (missing end, unmatched quotes)

**Cannot fix**:
- Missing associations in models
- Validation requirements
- Database schema issues
- Test logic errors
- Incorrect data in existing fixtures

## Example Usage Session

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

## Advanced Patterns

For complex scenarios, the script can be extended to recognize:
- Database connection errors
- Gem dependency issues
- Configuration problems
- Missing test helpers
- Circular dependencies

These patterns can be added to the `parse_failures` method in `test_and_fix.rb`.
