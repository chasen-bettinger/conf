#!/usr/bin/env ruby
# frozen_string_literal: true

# Decompose a project into parallel work streams
# Usage: ruby decompose_project.rb --description "project description" [--workers N] [--output file.md]

require 'json'
require 'optparse'

class ProjectDecomposer
  def initialize(description, num_workers: 4, output_file: nil)
    @description = description
    @num_workers = num_workers
    @output_file = output_file
    @work_streams = []
  end

  def decompose
    puts "🔍 Analyzing project: #{@description[0..80]}#{'...' if @description.length > 80}\n\n"

    # This is a template generator - Claude will fill in the actual analysis
    plan = {
      project: @description,
      analysis: generate_analysis_template,
      work_streams: generate_work_stream_template,
      dependencies: generate_dependency_template,
      worker_assignments: generate_worker_assignment_template,
      coordination: generate_coordination_template
    }

    output = format_plan(plan)

    if @output_file
      File.write(@output_file, output)
      puts "✅ Work plan saved to: #{@output_file}"
    else
      puts output
    end

    output
  end

  private

  def generate_analysis_template
    {
      complexity: "[Low/Medium/High]",
      estimated_duration: "[X days/weeks]",
      critical_path: "[Identify blocking work]",
      parallelization_potential: "[High/Medium/Low]",
      key_challenges: [
        "[Challenge 1]",
        "[Challenge 2]"
      ]
    }
  end

  def generate_work_stream_template
    (1..@num_workers).map do |i|
      {
        id: "stream-#{i}",
        name: "[Work Stream Name]",
        description: "[Detailed description of this work stream]",
        deliverables: [
          "[Deliverable 1]",
          "[Deliverable 2]"
        ],
        estimated_effort: "[X days]",
        skills_required: ["[Skill 1]", "[Skill 2]"],
        blocks: [],
        blocked_by: []
      }
    end
  end

  def generate_dependency_template
    {
      blocking_work: [
        "stream-1 blocks stream-2,stream-3 (reason: [why])"
      ],
      critical_path: ["stream-1", "stream-2"],
      parallel_streams: [
        ["stream-3", "stream-4"]
      ]
    }
  end

  def generate_worker_assignment_template
    (1..@num_workers).map do |i|
      {
        worker: "Worker #{i}",
        assigned_streams: ["stream-#{i}"],
        start_immediately: i == 1,
        wait_for: i > 1 ? ["stream-#{i-1} completion"] : [],
        skills: ["[Required skills]"]
      }
    end
  end

  def generate_coordination_template
    {
      sync_points: [
        {
          milestone: "[Milestone name]",
          timing: "[After stream-X completes]",
          participants: ["Worker 1", "Worker 2"],
          purpose: "[Why sync is needed]"
        }
      ],
      merge_strategy: "[How to integrate parallel work]",
      conflict_resolution: "[How to handle conflicts]",
      communication_protocol: [
        "Daily: [What to communicate]",
        "Weekly: [What to review]",
        "Ad-hoc: [When to escalate]"
      ]
    }
  end

  def format_plan(plan)
    <<~MARKDOWN
      # Parallel Work Plan

      ## Project
      #{plan[:project]}

      ## Analysis

      **Complexity**: #{plan[:analysis][:complexity]}
      **Estimated Duration**: #{plan[:analysis][:estimated_duration]}
      **Critical Path**: #{plan[:analysis][:critical_path]}
      **Parallelization Potential**: #{plan[:analysis][:parallelization_potential]}

      **Key Challenges**:
      #{plan[:analysis][:key_challenges].map { |c| "- #{c}" }.join("\n")}

      ## Work Streams

      #{format_work_streams(plan[:work_streams])}

      ## Dependencies

      **Blocking Relationships**:
      #{plan[:dependencies][:blocking_work].map { |d| "- #{d}" }.join("\n")}

      **Critical Path**: #{plan[:dependencies][:critical_path].join(' → ')}

      **Parallel Streams**:
      #{plan[:dependencies][:parallel_streams].map { |streams| "- #{streams.join(', ')}" }.join("\n")}

      ## Worker Assignments

      #{format_worker_assignments(plan[:worker_assignments])}

      ## Coordination Strategy

      ### Sync Points
      #{format_sync_points(plan[:coordination][:sync_points])}

      **Merge Strategy**: #{plan[:coordination][:merge_strategy]}

      **Conflict Resolution**: #{plan[:coordination][:conflict_resolution]}

      ### Communication Protocol
      #{plan[:coordination][:communication_protocol].map { |c| "- #{c}" }.join("\n")}

      ## Execution Timeline

      ```
      Day 1-X:  [Stream 1 work]
      Day X-Y:  [Stream 2,3,4 work in parallel]
      Day Y-Z:  [Integration and testing]
      ```

      ## Success Criteria

      - [ ] All work streams completed
      - [ ] All dependencies resolved
      - [ ] Integration successful
      - [ ] Tests passing
      - [ ] Documentation complete

      ## Risk Mitigation

      | Risk | Likelihood | Impact | Mitigation |
      |------|------------|--------|------------|
      | [Risk 1] | [H/M/L] | [H/M/L] | [Strategy] |
      | [Risk 2] | [H/M/L] | [H/M/L] | [Strategy] |

    MARKDOWN
  end

  def format_work_streams(streams)
    streams.map do |stream|
      <<~STREAM
        ### #{stream[:name]} (#{stream[:id]})

        **Description**: #{stream[:description]}

        **Deliverables**:
        #{stream[:deliverables].map { |d| "- #{d}" }.join("\n")}

        **Estimated Effort**: #{stream[:estimated_effort]}
        **Required Skills**: #{stream[:skills_required].join(', ')}

        **Dependencies**:
        - Blocks: #{stream[:blocks].empty? ? 'None' : stream[:blocks].join(', ')}
        - Blocked by: #{stream[:blocked_by].empty? ? 'None' : stream[:blocked_by].join(', ')}

      STREAM
    end.join("\n")
  end

  def format_worker_assignments(assignments)
    assignments.map do |assignment|
      wait = assignment[:wait_for].empty? ? "Start immediately" : "Wait for: #{assignment[:wait_for].join(', ')}"
      <<~ASSIGNMENT
        **#{assignment[:worker]}**:
        - Assigned: #{assignment[:assigned_streams].join(', ')}
        - Timing: #{wait}
        - Skills: #{assignment[:skills].join(', ')}

      ASSIGNMENT
    end.join("\n")
  end

  def format_sync_points(sync_points)
    sync_points.map do |sp|
      <<~SYNC
        - **#{sp[:milestone]}** (#{sp[:timing]})
          - Participants: #{sp[:participants].join(', ')}
          - Purpose: #{sp[:purpose]}

      SYNC
    end.join("\n")
  end
end

# Main execution
if __FILE__ == $0
  options = {}

  OptionParser.new do |opts|
    opts.banner = "Usage: decompose_project.rb [options]"

    opts.on("-d", "--description DESC", "Project description") do |desc|
      options[:description] = desc
    end

    opts.on("-w", "--workers N", Integer, "Number of workers (default: 4)") do |n|
      options[:workers] = n
    end

    opts.on("-o", "--output FILE", "Output file path") do |file|
      options[:output] = file
    end

    opts.on("-h", "--help", "Show this help") do
      puts opts
      puts "\nExample:"
      puts "  ruby decompose_project.rb -d 'Build a web app' -w 4 -o plan.md"
      exit
    end
  end.parse!

  unless options[:description]
    puts "Error: Project description required"
    puts "Use --help for usage information"
    exit 1
  end

  decomposer = ProjectDecomposer.new(
    options[:description],
    num_workers: options[:workers] || 4,
    output_file: options[:output]
  )

  decomposer.decompose
end
