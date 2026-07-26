# Rails Migration Field Types and Modifiers

## Supported Field Types

| Type | Description | Example Usage |
|------|-------------|---------------|
| `string` | Short text (VARCHAR) | `name:string` |
| `text` | Long text (TEXT) | `description:text` |
| `integer` | 32-bit integer | `age:integer` |
| `bigint` | 64-bit integer (for IDs) | `user_id:bigint` |
| `float` | Floating point number | `rating:float` |
| `decimal` | Precise decimal number | `price:decimal` |
| `datetime` | Date and time | `published_at:datetime` |
| `timestamp` | Unix timestamp | `event_time:timestamp` |
| `time` | Time only | `opens_at:time` |
| `date` | Date only | `birth_date:date` |
| `binary` | Binary data | `file_data:binary` |
| `boolean` | True/false | `is_active:boolean` |
| `references` | Foreign key | `user:references` |
| `json` | JSON data (PostgreSQL) | `metadata:json` |
| `jsonb` | Binary JSON (PostgreSQL) | `settings:jsonb` |

## Supported Modifiers

| Modifier | Description | Example Usage |
|----------|-------------|---------------|
| `index` | Add database index | `email:string:index` |
| `unique` | Unique constraint (use with index) | `email:string:index:unique` |
| `null` | Allow NULL values | `middle_name:string:null` |
| `default:<value>` | Default value | `status:string:default:pending` |
| `limit:<size>` | Column size limit | `code:string:limit:10` |
| `precision:<num>` | Decimal precision | `price:decimal:precision:10` |
| `scale:<num>` | Decimal scale | `price:decimal:scale:2` |

## Common Patterns

### Foreign Keys
```
user_id:bigint:index:null:false
```
Creates a foreign key column with index and NOT NULL constraint.

### Unique Email
```
email:string:index:unique:null:false
```
Creates an indexed email column with unique constraint.

### Enum-style Status
```
status:string:index:default:pending:null:false
```
Creates an indexed status column with default value.

### Money Fields
```
amount:decimal:precision:10:scale:2:default:0.0
```
Creates a decimal column suitable for currency.

### JSON Configuration
```
settings:jsonb:default:{}
```
Creates a JSONB column with empty object default.

## Default Behavior

- **NOT NULL**: Applied by default to most columns (except those with names like `description`, `notes`, `comment`)
- **Indexes**: Foreign keys (columns ending in `_id`) should always have `:index` modifier
- **Comments**: Automatically added for JSON/JSONB columns
- **Timestamps**: Always added to `create_table` migrations

## Examples

### Create Table Migration
```bash
create_users name:string:null:false email:string:index:unique age:integer:null
```

### Add Columns Migration
```bash
add_fields_to_products sku:string:index:unique price:decimal:precision:10:scale:2
```

### Join Table Migration
```bash
create_user_roles user_id:bigint:index role_id:bigint:index
```
