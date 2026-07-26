---
name: rails-migration-with-rollback
description: Generate Rails database migrations with explicit up/down methods for safe rollback, automatic index creation for foreign keys and commonly queried fields, NOT NULL constraints where appropriate, and validation that migrations run cleanly in both directions. Use when creating Rails migrations, database schema changes, adding tables, adding columns, modifying database structure, or when the user requests database migrations with proper rollback support.
---

# Rails Migration with Rollback Generator

Generate Rails migrations with explicit `up` and `down` methods instead of the standard `change` method, ensuring safe rollback capability.

## Quick Start

Generate a create table migration:

```bash
ruby scripts/generate_migration.rb create_users name:string email:string:index:unique age:integer
```

Generate an add columns migration:

```bash
ruby scripts/generate_migration.rb add_status_to_orders status:string:index:default:pending
```

## Usage Pattern

```bash
ruby scripts/generate_migration.rb <migration_name> [field:type:modifier...]
```

### Arguments

- `migration_name`: Name of the migration (e.g., `create_users`, `add_fields_to_products`)
- `field:type:modifier`: One or more field definitions with optional modifiers

### Field Definition Format

```
field_name:field_type[:modifier1][:modifier2]...
```

Examples:
- `name:string` - Simple string field
- `email:string:index:unique` - Indexed unique string
- `user_id:bigint:index` - Foreign key with index
- `status:string:default:pending` - String with default value
- `price:decimal:precision:10:scale:2` - Decimal with precision

## What the Script Does

1. **Creates migrations with explicit up/down methods** - No `change` method, ensuring reversibility
2. **Adds appropriate indexes** - Automatically indexes fields marked with `:index` modifier
3. **Applies NOT NULL constraints** - By default unless `:null` modifier specified
4. **Adds helpful comments** - Especially for JSON/JSONB columns
5. **Validates field types and modifiers** - Catches errors before creating the file
6. **Creates properly timestamped files** - Uses Rails migration timestamp format

## Common Examples

### Create a users table
```bash
ruby scripts/generate_migration.rb create_users \
  name:string \
  email:string:index:unique \
  age:integer:null \
  role:string:default:member
```

### Create a join table
```bash
ruby scripts/generate_migration.rb create_user_roles \
  user_id:bigint:index \
  role_id:bigint:index
```

### Add columns to existing table
```bash
ruby scripts/generate_migration.rb add_metadata_to_products \
  sku:string:index:unique \
  price:decimal:precision:10:scale:2 \
  settings:jsonb
```

### Create table with foreign keys
```bash
ruby scripts/generate_migration.rb create_posts \
  title:string \
  body:text \
  user_id:bigint:index \
  published_at:datetime:null
```

## Field Types and Modifiers

See [references/field_types.md](references/field_types.md) for complete documentation of:
- All supported field types (string, text, integer, bigint, decimal, datetime, json, etc.)
- All supported modifiers (index, unique, null, default, limit, precision, scale)
- Common patterns and examples

## Generated Migration Structure

### Create Table Migration

```ruby
class CreateUsers < ActiveRecord::Migration[7.0]
  def up
    create_table :users do |t|
      t.string :name, null: false
      t.string :email, null: false
      t.integer :age

      t.timestamps
    end

    add_index :users, :email, unique: true
  end

  def down
    drop_table :users
  end
end
```

### Add Columns Migration

```ruby
class AddStatusToOrders < ActiveRecord::Migration[7.0]
  def up
    add_column :orders, :status, :string, default: 'pending', null: false
    add_index :orders, :status
  end

  def down
    remove_index :orders, :status
    remove_column :orders, :status, :string
  end
end
```

## Best Practices

1. **Always add indexes to foreign keys**: `user_id:bigint:index`
2. **Use bigint for foreign keys**: `user_id:bigint` not `user_id:integer`
3. **Add indexes to frequently queried columns**: `status:string:index`
4. **Use explicit null constraints**: Add `:null` only when NULL values are allowed
5. **Set sensible defaults**: `status:string:default:pending`
6. **Use decimal for money**: `price:decimal:precision:10:scale:2`
7. **Prefer jsonb over json**: `settings:jsonb` for better performance

## Testing Migrations

After generating a migration:

```bash
# Run the migration
rails db:migrate

# Test the rollback
rails db:rollback

# Run it again to ensure it's repeatable
rails db:migrate

# Check the schema
rails db:schema:dump
```

## Error Handling

The script validates:
- Field types are in the allowed list
- Modifiers are valid
- Migration name format is correct

Invalid input will produce clear error messages:
```
❌ Error: Invalid type 'varchar' for field 'name'. Valid types: string, text, integer, bigint, ...
```

## Integration with Rails

Place generated migrations in your Rails project's `db/migrate/` directory. The script automatically:
- Creates the directory if it doesn't exist
- Uses proper timestamp format (YYYYMMDDHHMMSS)
- Follows Rails migration naming conventions
- Uses Rails 7.0 migration syntax

## Workflow

1. Run the script to generate migration file
2. Review the generated migration in `db/migrate/`
3. Adjust if needed (add custom logic, modify constraints)
4. Run `rails db:migrate`
5. Test rollback with `rails db:rollback`
6. Commit the migration file to version control
