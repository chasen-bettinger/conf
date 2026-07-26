#!/usr/bin/env ruby
# frozen_string_literal: true

# Generate Rails migration with explicit up/down methods
# Usage: ruby generate_migration.rb <migration_name> <field:type:modifier...>
# Example: ruby generate_migration.rb create_users name:string email:string:index:unique age:integer

require 'fileutils'

class MigrationGenerator
  VALID_TYPES = %w[string text integer bigint float decimal datetime timestamp time date binary boolean references json jsonb].freeze
  VALID_MODIFIERS = %w[index unique null default limit precision scale].freeze

  def initialize(migration_name, fields)
    @migration_name = migration_name
    @fields = parse_fields(fields)
    @timestamp = Time.now.utc.strftime('%Y%m%d%H%M%S')
    @class_name = migration_name.split('_').map(&:capitalize).join
  end

  def generate
    validate_fields!
    content = build_migration_content
    filename = "db/migrate/#{@timestamp}_#{@migration_name}.rb"

    FileUtils.mkdir_p('db/migrate')
    File.write(filename, content)

    puts "✅ Migration created: #{filename}"
    puts "\nNext steps:"
    puts "  1. Review the migration"
    puts "  2. Run: rails db:migrate"
    puts "  3. Test rollback: rails db:rollback"

    filename
  end

  private

  def parse_fields(field_strings)
    field_strings.map do |field_str|
      parts = field_str.split(':')
      {
        name: parts[0],
        type: parts[1] || 'string',
        modifiers: parts[2..-1] || []
      }
    end
  end

  def validate_fields!
    @fields.each do |field|
      unless VALID_TYPES.include?(field[:type])
        raise "Invalid type '#{field[:type]}' for field '#{field[:name]}'. Valid types: #{VALID_TYPES.join(', ')}"
      end

      invalid_modifiers = field[:modifiers] - VALID_MODIFIERS
      unless invalid_modifiers.empty?
        raise "Invalid modifiers #{invalid_modifiers} for field '#{field[:name]}'. Valid: #{VALID_MODIFIERS.join(', ')}"
      end
    end
  end

  def build_migration_content
    table_name = extract_table_name
    is_create = @migration_name.start_with?('create_')

    if is_create
      build_create_table_migration(table_name)
    else
      build_change_table_migration(table_name)
    end
  end

  def extract_table_name
    if @migration_name.start_with?('create_')
      @migration_name.sub('create_', '')
    elsif @migration_name.start_with?('add_')
      # Extract table name from patterns like add_column_to_table
      parts = @migration_name.split('_to_')
      parts.last if parts.length > 1
    else
      @migration_name.split('_').last
    end
  end

  def build_create_table_migration(table_name)
    up_columns = @fields.map { |f| column_definition(f, indent: 3) }.join("\n")
    down_statement = "    drop_table :#{table_name}"

    indexes = build_indexes(table_name, indent: 2)

    <<~RUBY
      # frozen_string_literal: true

      class #{@class_name} < ActiveRecord::Migration[7.0]
        def up
          create_table :#{table_name} do |t|
      #{up_columns}

            t.timestamps
          end
      #{indexes}
        end

        def down
      #{down_statement}
        end
      end
    RUBY
  end

  def build_change_table_migration(table_name)
    up_columns = @fields.map { |f| "    add_column :#{table_name}, #{column_args(f)}" }.join("\n")
    down_columns = @fields.map { |f| "    remove_column :#{table_name}, :#{f[:name]}, :#{f[:type]}" }.join("\n")

    up_indexes = build_add_indexes(table_name, indent: 2)
    down_indexes = build_remove_indexes(table_name, indent: 2)

    <<~RUBY
      # frozen_string_literal: true

      class #{@class_name} < ActiveRecord::Migration[7.0]
        def up
      #{up_columns}
      #{up_indexes}
        end

        def down
      #{down_indexes}
      #{down_columns}
        end
      end
    RUBY
  end

  def column_definition(field, indent: 0)
    spaces = '  ' * indent
    args = column_args(field)
    "#{spaces}t.#{field[:type]} #{args}"
  end

  def column_args(field)
    args = [":#{field[:name]}"]
    options = []

    # Handle modifiers
    if field[:modifiers].include?('null')
      options << 'null: true'
    elsif field[:type] != 'timestamps' && !field[:modifiers].include?('null')
      # Default to NOT NULL unless explicitly specified
      options << 'null: false' if field[:name] !~ /description|notes|comment/
    end

    if field[:modifiers].include?('unique')
      options << 'unique: true'
    end

    if limit = field[:modifiers].find { |m| m.start_with?('limit:') }
      options << limit.sub(':', ': ')
    end

    if default = field[:modifiers].find { |m| m.start_with?('default:') }
      options << default.sub(':', ': ')
    end

    if precision = field[:modifiers].find { |m| m.start_with?('precision:') }
      options << precision.sub(':', ': ')
    end

    if scale = field[:modifiers].find { |m| m.start_with?('scale:') }
      options << scale.sub(':', ': ')
    end

    # Add comment for complex types
    if %w[json jsonb].include?(field[:type])
      options << "comment: 'JSON data for #{field[:name]}'"
    end

    args << options.join(', ') unless options.empty?
    args.join(', ')
  end

  def build_indexes(table_name, indent: 0)
    spaces = '  ' * indent
    indexed_fields = @fields.select { |f| f[:modifiers].include?('index') }

    return '' if indexed_fields.empty?

    "\n" + indexed_fields.map do |field|
      unique = field[:modifiers].include?('unique') ? ', unique: true' : ''
      "#{spaces}add_index :#{table_name}, :#{field[:name]}#{unique}"
    end.join("\n")
  end

  def build_add_indexes(table_name, indent: 0)
    spaces = '  ' * indent
    indexed_fields = @fields.select { |f| f[:modifiers].include?('index') }

    return '' if indexed_fields.empty?

    "\n" + indexed_fields.map do |field|
      unique = field[:modifiers].include?('unique') ? ', unique: true' : ''
      "#{spaces}add_index :#{table_name}, :#{field[:name]}#{unique}"
    end.join("\n")
  end

  def build_remove_indexes(table_name, indent: 0)
    spaces = '  ' * indent
    indexed_fields = @fields.select { |f| f[:modifiers].include?('index') }

    return '' if indexed_fields.empty?

    "\n" + indexed_fields.map do |field|
      "#{spaces}remove_index :#{table_name}, :#{field[:name]}"
    end.join("\n")
  end
end

# Main execution
if __FILE__ == $0
  if ARGV.length < 1
    puts "Usage: #{$0} <migration_name> [field:type:modifier...]"
    puts "\nExample:"
    puts "  #{$0} create_users name:string email:string:index:unique age:integer"
    puts "  #{$0} add_status_to_orders status:string:index:default:pending"
    puts "\nSupported types: #{MigrationGenerator::VALID_TYPES.join(', ')}"
    puts "Supported modifiers: #{MigrationGenerator::VALID_MODIFIERS.join(', ')}"
    exit 1
  end

  migration_name = ARGV[0]
  fields = ARGV[1..-1]

  begin
    generator = MigrationGenerator.new(migration_name, fields)
    generator.generate
  rescue => e
    puts "❌ Error: #{e.message}"
    exit 1
  end
end
