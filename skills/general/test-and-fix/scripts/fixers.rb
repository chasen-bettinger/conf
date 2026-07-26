# frozen_string_literal: true

# Module containing automatic fix strategies for common test failures
module Fixers
  def fix_missing_fixture(failure)
    model = failure[:model]
    fixture_file = "test/fixtures/#{model.underscore.pluralize}.yml"

    # Check if fixture file exists
    unless File.exist?(fixture_file)
      # Create basic fixture file
      FileUtils.mkdir_p(File.dirname(fixture_file))
      File.write(fixture_file, generate_fixture_template(model))

      return {
        type: :missing_fixture,
        description: "Created fixture file: #{fixture_file}",
        file: fixture_file
      }
    end

    # Fixture file exists but might be empty or missing specific record
    content = File.read(fixture_file)
    if content.strip.empty? || content.strip == "# Read about fixtures at https://api.rubyonrails.org/classes/ActiveRecord/FixtureSet.html"
      File.write(fixture_file, generate_fixture_template(model))
      return {
        type: :missing_fixture,
        description: "Populated empty fixture file: #{fixture_file}",
        file: fixture_file
      }
    end

    nil
  end

  def fix_missing_factory(failure)
    factory = failure[:factory]
    factory_file = "test/factories/#{factory.pluralize}.rb"

    # Create factory file if it doesn't exist
    unless File.exist?(factory_file)
      FileUtils.mkdir_p(File.dirname(factory_file))
      File.write(factory_file, generate_factory_template(factory))

      return {
        type: :missing_factory,
        description: "Created factory file: #{factory_file}",
        file: factory_file
      }
    end

    nil
  end

  def fix_undefined_method(failure)
    # This often indicates a missing association or helper method
    # Can't automatically fix without more context, but we can suggest
    nil
  end

  def fix_validation_error(failure)
    # Validation errors often need manual intervention
    # Could potentially add required fields to fixtures/factories
    nil
  end

  def fix_missing_column(failure)
    # This indicates a schema issue - can't auto-fix
    # Need to run migrations or update schema
    nil
  end

  def fix_syntax_error(failure)
    file = failure[:file]
    return nil unless file && File.exist?(file)

    # Read the file
    content = File.read(file)

    # Common syntax fixes
    fixed = false

    # Fix: Missing 'end' keywords
    begin_count = content.scan(/\b(def|class|module|do|if|unless|case|while|until|for|begin)\b/).count
    end_count = content.scan(/\bend\b/).count

    if begin_count > end_count
      # Add missing 'end' at the end of file
      content += "\nend\n"
      fixed = true
    end

    # Fix: Unmatched quotes
    single_quotes = content.count("'")
    double_quotes = content.count('"')

    if single_quotes.odd?
      # Try to find the unmatched quote and close it
      # This is a heuristic and may not always work
      content += "'\n" if content[-1] != "'"
      fixed = true
    end

    if double_quotes.odd?
      content += "\"\n" if content[-1] != '"'
      fixed = true
    end

    if fixed
      File.write(file, content)
      return {
        type: :syntax_error,
        description: "Fixed syntax error in: #{file}",
        file: file
      }
    end

    nil
  end

  def fix_undefined_constant(failure)
    constant = failure[:constant]

    # Try to find the constant in app/models
    model_file = "app/models/#{constant.underscore}.rb"

    # If it's a model that doesn't exist, we can't auto-create it
    # This requires user intervention
    nil
  end

  private

  def generate_fixture_template(model)
    model_name = model.underscore
    <<~YAML
      # Read about fixtures at https://api.rubyonrails.org/classes/ActiveRecord/FixtureSet.html

      one:
        id: 1
        # Add attributes here

      two:
        id: 2
        # Add attributes here
    YAML
  end

  def generate_factory_template(factory)
    model = factory.classify
    <<~RUBY
      # frozen_string_literal: true

      FactoryBot.define do
        factory :#{factory} do
          # Add attributes here
        end
      end
    RUBY
  end
end

# String helpers
class String
  def underscore
    gsub(/::/, '/')
      .gsub(/([A-Z]+)([A-Z][a-z])/, '\1_\2')
      .gsub(/([a-z\d])([A-Z])/, '\1_\2')
      .tr('-', '_')
      .downcase
  end

  def classify
    split('_').map(&:capitalize).join
  end

  def pluralize
    # Simple pluralization - may not cover all cases
    if self.end_with?('s', 'x', 'z', 'ch', 'sh')
      self + 'es'
    elsif self.end_with?('y') && !self.end_with?('ay', 'ey', 'oy', 'uy')
      self[0..-2] + 'ies'
    else
      self + 's'
    end
  end
end
