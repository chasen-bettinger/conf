---
name: rails-model
description: Generate Rails models with migrations, associations, validations, enums, scopes, and comprehensive tests. Use when creating new Rails ActiveRecord models or when the user requests database models, model generation, or CRUD scaffolding for Rails applications.
---

## Usage

```
/rails-model <ModelName> <field:type> [field:type...] [options]
```

## Examples

```bash
# Basic model with validations
/rails-model Role name:string description:text risk_level:enum privilege_score:integer --validates name:presence,uniqueness --enum risk_level:critical,elevated,standard

# Model with associations
/rails-model Permission action:string service:string access_level:string is_dangerous:boolean --belongs-to role --has-many role_permissions --validates action:presence,uniqueness

# Model with all features
/rails-model Recommendation role_id:bigint type:string severity:enum status:enum --belongs-to role --enum severity:critical,high,medium,low --enum status:pending,approved,rejected,applied --validates type:presence --scope pending:"where(status: 'pending')"
```

## Generated Files

1. **Model** (`app/models/<model_name>.rb`) - Associations, validations, enums, scopes
2. **Migration** (`db/migrate/<timestamp>_create_<table_name>.rb`) - Fields, foreign keys, indexes, constraints
3. **Test** (`test/models/<model_name>_test.rb`) - Tests for associations, validations, scopes, enums
4. **Fixture** (`test/fixtures/<table_name>.yml`) - Sample data

## Field Types

Supported field types:
- `string` - VARCHAR(255)
- `text` - TEXT
- `integer` - INTEGER
- `bigint` - BIGINT (use for foreign keys)
- `decimal` - DECIMAL
- `float` - FLOAT
- `boolean` - BOOLEAN
- `date` - DATE
- `datetime` - DATETIME
- `timestamp` - TIMESTAMP
- `json` - JSON
- `enum` - String with enum validation (requires --enum option)

## Options

### Associations

- `--belongs-to <model>` - Add belongs_to association (creates foreign key)
- `--has-many <model>` - Add has_many association
- `--has-one <model>` - Add has_one association
- `--has-many-through <model> through:<join_model>` - Add has_many :through

Example: `--belongs-to role --has-many permissions`

### Validations

- `--validates <field>:<rules>` - Add validations

Supported rules (comma-separated):
- `presence` - validates presence
- `uniqueness` - validates uniqueness
- `format:/regex/` - validates format with regex
- `length:min..max` - validates length
- `numericality` - validates number
- `inclusion:val1,val2,val3` - validates inclusion in list

Example: `--validates name:presence,uniqueness --validates email:presence,format:/\A[\w+\-.]+@[a-z\d\-]+(\.[a-z\d\-]+)*\.[a-z]+\z/i`

### Enums

- `--enum <field>:<value1>,<value2>,...` - Define enum values

Example: `--enum status:pending,approved,rejected --enum severity:low,medium,high,critical`

### Scopes

- `--scope <name>:"<condition>"` - Add named scope

Example: `--scope active:"where(is_active: true)" --scope recent:"order(created_at: :desc).limit(10)"`

### Indexes

- `--index <field>` - Add single column index
- `--unique-index <field>` - Add unique index
- `--composite-index <field1>,<field2>` - Add composite index

Example: `--index email --unique-index username --composite-index user_id,role_id`

### Other Options

- `--timestamps` - Add created_at/updated_at (default: true)
- `--no-timestamps` - Skip timestamps
- `--table-name <name>` - Custom table name
- `--paranoid` - Add soft delete (deleted_at column)

## Naming Conventions

Automatically applied:
- Table names: pluralized (User → users, Person → people)
- Model classes: singular CamelCase
- Files/columns: snake_case
- Foreign keys: model_id format

## Code Style

Follow Rails conventions:
- 2-space indentation
- Grouped ordering: associations, validations, enums, scopes, methods
- Models inherit from ApplicationRecord
- Tests inherit from ActiveSupport::TestCase

## After Generation

After generating files:
1. Run `rails db:migrate`
2. Run `rails test test/models/<model_name>_test.rb` to verify tests pass

Never overwrite existing files without confirmation. All generated tests should pass immediately.
