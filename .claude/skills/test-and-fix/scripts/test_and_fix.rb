#!/usr/bin/env ruby
# frozen_string_literal: true

# Run Rails tests, identify failures, and automatically fix common issues
# Usage: ruby test_and_fix.rb [--scope path/to/tests] [--max-iterations 5]

require 'fileutils'
require 'json'
require_relative 'fixers'

class TestRunner
  include Fixers

  MAX_ITERATIONS = 5
  TEST_COMMAND = 'rails test'

  def initialize(scope: nil, max_iterations: MAX_ITERATIONS, verbose: false)
    @scope = scope
    @max_iterations = max_iterations
    @verbose = verbose
    @fixes_applied = []
    @iteration = 0
  end

  def run
    puts "🧪 Running Rails tests#{@scope ? " (scope: #{@scope})" : ''}...\n\n"

    loop do
      @iteration += 1
      break if @iteration > @max_iterations

      puts "📍 Iteration #{@iteration}/#{@max_iterations}"
      result = run_tests

      if result[:success]
        puts "\n✅ All tests passing!"
        print_summary
        return true
      end

      failures = parse_failures(result[:output])

      if failures.empty?
        puts "\n⚠️  Tests failed but no recognizable error patterns found."
        puts "Output:\n#{result[:output]}"
        print_summary
        return false
      end

      puts "Found #{failures.count} failure(s) to fix...\n"

      fixed_any = false
      failures.each do |failure|
        if fix = apply_fix(failure)
          fixed_any = true
          @fixes_applied << fix
          puts "  ✓ #{fix[:description]}"
        end
      end

      unless fixed_any
        puts "\n⚠️  No automatic fixes available for remaining failures."
        puts "Manual intervention required.\n"
        print_summary
        print_remaining_failures(failures)
        return false
      end

      puts ""
    end

    puts "\n⚠️  Max iterations (#{@max_iterations}) reached."
    puts "Some tests may still be failing.\n"
    print_summary
    false
  end

  private

  def run_tests
    command = @scope ? "#{TEST_COMMAND} #{@scope}" : TEST_COMMAND
    output = `#{command} 2>&1`
    success = $?.success?

    puts output if @verbose

    { success: success, output: output }
  end

  def parse_failures(output)
    failures = []

    # Pattern: Missing fixture
    output.scan(/ActiveRecord::RecordNotFound.*Couldn't find (\w+)/) do |match|
      failures << {
        type: :missing_fixture,
        model: match[0],
        file: extract_test_file(output)
      }
    end

    # Pattern: Missing factory
    output.scan(/Factory not registered: "?(\w+)"?/) do |match|
      failures << {
        type: :missing_factory,
        factory: match[0],
        file: extract_test_file(output)
      }
    end

    # Pattern: Undefined method (often missing associations)
    output.scan(/undefined method `(\w+)' for #<(\w+):/) do |match|
      failures << {
        type: :undefined_method,
        method: match[0],
        model: match[1],
        file: extract_test_file(output)
      }
    end

    # Pattern: Validation errors
    output.scan(/Validation failed: (.+)/) do |match|
      failures << {
        type: :validation_error,
        message: match[0],
        file: extract_test_file(output)
      }
    end

    # Pattern: Missing column
    output.scan(/unknown attribute '(\w+)' for (\w+)/) do |match|
      failures << {
        type: :missing_column,
        column: match[0],
        model: match[1]
      }
    end

    # Pattern: Syntax error
    output.scan(/syntax error.*\n.*\n.*in `([^']+)'/) do |match|
      failures << {
        type: :syntax_error,
        file: match[0]
      }
    end

    # Pattern: NameError (undefined constant)
    output.scan(/uninitialized constant (\w+::)?(\w+)/) do |match|
      failures << {
        type: :undefined_constant,
        constant: match[1],
        namespace: match[0]&.chomp('::')
      }
    end

    failures.uniq
  end

  def extract_test_file(output)
    # Try to extract the test file path from backtrace
    if match = output.match(/test\/[^:]+\.rb/)
      match[0]
    end
  end

  def apply_fix(failure)
    case failure[:type]
    when :missing_fixture
      fix_missing_fixture(failure)
    when :missing_factory
      fix_missing_factory(failure)
    when :undefined_method
      fix_undefined_method(failure)
    when :validation_error
      fix_validation_error(failure)
    when :missing_column
      fix_missing_column(failure)
    when :syntax_error
      fix_syntax_error(failure)
    when :undefined_constant
      fix_undefined_constant(failure)
    else
      nil
    end
  end

  def print_summary
    puts "\n" + "=" * 60
    puts "SUMMARY"
    puts "=" * 60
    puts "Iterations: #{@iteration}"
    puts "Fixes applied: #{@fixes_applied.count}"

    if @fixes_applied.any?
      puts "\nFixes:"
      @fixes_applied.each do |fix|
        puts "  • #{fix[:description]}"
      end
    end
    puts ""
  end

  def print_remaining_failures(failures)
    puts "Remaining failures:"
    failures.each do |failure|
      puts "  • #{failure[:type]}: #{failure.reject { |k| k == :type }.values.join(' - ')}"
    end
    puts ""
  end
end

# Main execution
if __FILE__ == $0
  require 'optparse'

  options = {}
  OptionParser.new do |opts|
    opts.banner = "Usage: test_and_fix.rb [options]"

    opts.on("--scope PATH", "Scope tests to specific path") do |path|
      options[:scope] = path
    end

    opts.on("--max-iterations N", Integer, "Max fix iterations (default: 5)") do |n|
      options[:max_iterations] = n
    end

    opts.on("-v", "--verbose", "Verbose output") do
      options[:verbose] = true
    end

    opts.on("-h", "--help", "Show this help") do
      puts opts
      exit
    end
  end.parse!

  runner = TestRunner.new(**options)
  success = runner.run
  exit(success ? 0 : 1)
end
