---
name: parallel-work-planner
description: Decompose complex projects into parallelizable work streams for multiple Claude workers. Analyzes project requirements, identifies independent tasks, maps dependencies, creates actionable task specifications, and provides coordination strategies. Use when planning multi-worker projects, breaking down large features, coordinating parallel development streams, or optimizing team velocity through parallel execution. Particularly useful for rapid development sprints with 3-5 concurrent workers.
---

# Parallel Work Planner

Transform complex projects into actionable, parallelizable work streams for multiple Claude workers.

## When to Use This Skill

Use this skill when:
- You have a complex project that needs to be completed quickly
- Multiple Claude workers are available for parallel execution
- The project can be decomposed into independent work streams
- You need to optimize for calendar time (not just effort)
- Coordination between workers is critical to success

**Example scenarios**:
- "Build an IAM permission management system with 4 workers in 5 days"
- "Implement these 8 features using 5 concurrent workers"
- "Refactor the codebase across multiple modules in parallel"

## Planning Workflow

### Step 1: Analyze the Project

Start by understanding:
- **Scope**: What needs to be built?
- **Complexity**: How difficult is each component?
- **Dependencies**: What must happen first?
- **Resources**: How many workers are available?
- **Timeline**: What's the target completion date?

### Step 2: Identify Work Streams

Apply decomposition patterns from [references/decomposition_patterns.md](references/decomposition_patterns.md):

**Common patterns**:
- **Layer-based**: Frontend, Backend, Database, Testing
- **Feature-based**: Each worker owns an end-to-end feature
- **Component-based**: Core library, plugins, interfaces
- **Domain-based**: User management, billing, analytics
- **Pipeline**: Ingestion → Processing → Export

Choose the pattern that maximizes parallelization for your project.

### Step 3: Map Dependencies

Identify relationships between work streams:
- **Blocking**: Stream A must complete before Stream B can start
- **Parallel**: Streams can execute simultaneously
- **Critical Path**: Longest sequence of dependent tasks

Minimize blocking dependencies to enable maximum parallelization.

### Step 4: Assign Workers

Match workers to streams based on:
- **Skills**: Does the worker have required expertise?
- **Workload**: Is the effort balanced across workers?
- **Dependencies**: Can the worker start immediately or must wait?
- **Conflicts**: Will this worker's changes conflict with others?

### Step 5: Create Task Specifications

For each work stream, create detailed specifications using [assets/task_specification_template.md](assets/task_specification_template.md).

Include:
- Clear objective and deliverables
- Dependencies and blocking relationships
- Files to modify
- Success criteria
- Integration plan

### Step 6: Define Coordination Strategy

Establish:
- **Sync points**: When do workers need to coordinate?
- **Communication protocol**: How do workers communicate?
- **Merge strategy**: How is parallel work integrated?
- **Conflict resolution**: What happens when work overlaps?

## Quick Start Example

Decompose a project into parallel work:

```bash
ruby scripts/decompose_project.rb \
  --description "Build a task management web app with authentication" \
  --workers 4 \
  --output work-plan.md
```

This generates a template work plan with:
- 4 work streams
- Dependency analysis
- Worker assignments
- Coordination strategy

**Then**: Customize the template based on your specific project needs.

## Decomposition Patterns

### Pattern 1: Layer-Based (Full-Stack Apps)

**Best for**: Web applications, REST APIs, CRUD systems

**Work Streams**:
1. **Database & Schema** - Foundation for all other work
2. **Backend API** - Business logic and endpoints
3. **Frontend UI** - User interface and interactions
4. **Testing & CI/CD** - Quality assurance automation

**Dependencies**: Stream 1 blocks 2-4, then Streams 2-4 can parallelize

**Timeline**:
```
Day 1-2:   Worker 1 (Schema)
Day 3-7:   Workers 2-4 in parallel (API, UI, Tests)
Day 8:     Integration
```

---

### Pattern 2: Feature-Based (Microservices)

**Best for**: Feature-rich applications, microservices

**Work Streams**:
1. **Feature A** - End-to-end implementation
2. **Feature B** - End-to-end implementation
3. **Feature C** - End-to-end implementation
4. **Feature D** - End-to-end implementation

**Dependencies**: Minimal (features mostly independent)

**Timeline**:
```
Day 1-7:   All workers in parallel
Day 8:     Integration and testing
```

---

### Pattern 3: Component-Based (Libraries)

**Best for**: Frameworks, libraries, plugin systems

**Work Streams**:
1. **Core Library** - Foundation
2. **Plugin System** - Extension framework
3. **CLI Interface** - Command-line tool
4. **Web Interface** - Web dashboard

**Dependencies**: Streams 3-4 depend on Stream 1

**Timeline**:
```
Day 1-3:   Worker 1 (Core)
Day 4-7:   Workers 2-4 in parallel
Day 8:     Integration
```

For more patterns, see [references/decomposition_patterns.md](references/decomposition_patterns.md).

## Creating Task Specifications

Use the template in [assets/task_specification_template.md](assets/task_specification_template.md).

### Key Elements

**1. Clear Objective**
```markdown
## Objective
Build user authentication system with email/password login and JWT tokens.
```

**2. Measurable Deliverables**
```markdown
## Deliverables
- [ ] User model with authentication methods
- [ ] Login/logout API endpoints
- [ ] JWT token generation and validation
- [ ] Tests with >80% coverage
```

**3. Explicit Dependencies**
```markdown
## Dependencies
**Requires**: Database schema from Worker 1 (Stream 1)
**Provides**: Authentication API for Workers 3-4 (Frontend, Tests)
**Blocks**: Workers 3-4 cannot complete until auth API is ready
```

**4. Success Criteria**
```markdown
## Success Criteria
- [ ] All tests pass: `rails test test/models/user_test.rb`
- [ ] API endpoints return correct responses
- [ ] JWT tokens validate correctly
- [ ] No security vulnerabilities (run Brakeman)
```

## Coordination Strategies

### Daily Updates (Async)

Each worker posts daily:
- ✅ Completed: [What was finished]
- 🚧 Working on: [Current focus]
- 🚫 Blockers: [What's blocking progress]

### Sync Points

Trigger synchronization when:
1. **Foundation complete**: After blocking work finishes
2. **Integration needed**: When parallel work must merge
3. **Blocker discovered**: When a worker is stuck
4. **Scope clarification**: When requirements are unclear

### Merge Strategy

**Option 1: Sequential Merge**
- Worker 1 merges first
- Worker 2 merges after resolving conflicts with Worker 1
- Worker 3 merges after resolving conflicts with Workers 1-2
- Worker 4 merges last

**Option 2: Pairwise Merge**
- Workers 1-2 merge together
- Workers 3-4 merge together
- Then merge the two pairs

**Option 3: Feature Branches**
- Each worker works in isolated branch
- Integration worker merges all branches
- Resolve conflicts in integration branch

Choose based on conflict likelihood and worker availability.

## Measuring Success

### Parallelization Efficiency

**Sequential Time**: Sum of all stream durations
```
Stream 1: 3 days
Stream 2: 5 days
Stream 3: 5 days
Stream 4: 4 days
Total: 17 days sequential
```

**Parallel Time**: Longest critical path
```
Day 1-3:   Stream 1 (blocks all)
Day 4-8:   max(Stream 2, Stream 3, Stream 4) = 5 days
Day 9:     Integration
Total: 9 days parallel
```

**Speedup**: 17 / 9 = 1.89x faster (89% speedup)

**Target**: >2x speedup with 4 workers (indicates good parallelization)

### Coordination Overhead

**Conflict Count**: Number of merge conflicts
**Conflict Time**: Hours spent resolving conflicts
**Rework Rate**: % of work that had to be redone

**Targets**:
- <5 conflicts per integration
- <2 hours conflict resolution
- <10% rework rate

## Common Pitfalls

### ❌ Over-Decomposition
**Problem**: Too many tiny tasks, coordination overhead exceeds work
**Solution**: Aim for 1-3 meaningful streams per worker

### ❌ Hidden Dependencies
**Problem**: Unidentified blockers cause cascading delays
**Solution**: Map all dependencies upfront, use interface-first design

### ❌ Imbalanced Workload
**Problem**: Some workers idle while others overwhelmed
**Solution**: Balance effort, enable task handoff mid-stream

### ❌ No Integration Plan
**Problem**: Parallel work can't be merged
**Solution**: Define merge strategy and file ownership before work starts

### ❌ Unclear Ownership
**Problem**: Duplicate work or gaps in coverage
**Solution**: Explicit ownership, clear boundaries for each stream

## Best Practices

1. **Interface-First Design** - Define contracts before implementation
2. **Stub Dependencies** - Use mocks to enable parallel work
3. **Communicate Early** - Surface blockers immediately
4. **Commit Frequently** - Small commits reduce merge conflicts
5. **Test Continuously** - Catch integration issues early
6. **Document Decisions** - Keep shared context synchronized
7. **Balance Workload** - Adjust assignments if imbalance discovered
8. **Plan Integration** - Don't leave merging until the end

## Examples

### Example 1: E-commerce Site (4 Workers, 10 Days)

**Work Streams**:
- Worker 1: Product catalog (DB + API + UI) - 8 days
- Worker 2: Shopping cart (DB + API + UI) - 6 days
- Worker 3: User accounts (DB + API + UI) - 7 days
- Worker 4: Checkout flow (DB + API + UI) - 9 days

**Dependencies**: Worker 4 depends on Workers 1-3 for integrations

**Timeline**:
```
Day 1-7:   Workers 1-3 in parallel
Day 5-9:   Worker 4 starts (after Worker 2 completes cart)
Day 10:    Integration and testing
```

**Critical Path**: Worker 4 (9 days) + Integration (1 day) = 10 days

---

### Example 2: Data Pipeline (4 Workers, 6 Days)

**Work Streams**:
- Worker 1: Data ingestion - 2 days
- Worker 2: Data transformation - 3 days (waits for Worker 1)
- Worker 3: Data validation - 2 days (parallel with Worker 2)
- Worker 4: Data export - 2 days (waits for Workers 2-3)

**Dependencies**: Sequential pipeline with some parallelization

**Timeline**:
```
Day 1-2:   Worker 1 (Ingestion)
Day 3-5:   Workers 2-3 in parallel (Transform + Validate)
Day 6:     Worker 4 (Export)
```

**Critical Path**: 2 + 3 + 2 = 7 days (but overlapping work reduces to 6)

## Advanced Topics

### Dynamic Rebalancing

If a worker finishes early:
1. Identify remaining work from other streams
2. Extract separable tasks
3. Hand off to available worker
4. Update task specifications

### Skill-Based Assignment

Match worker capabilities to stream requirements:
- **Expert**: Assign critical path or complex streams
- **Competent**: Assign independent, well-defined streams
- **Learning**: Assign lower-risk streams with mentorship

### Risk Mitigation

For high-risk streams:
- Add time buffer (1.5x estimated effort)
- Assign most experienced worker
- Create backup plan
- Monitor progress more frequently

## Reference Documents

- [references/decomposition_patterns.md](references/decomposition_patterns.md) - Detailed decomposition patterns and strategies
- [assets/task_specification_template.md](assets/task_specification_template.md) - Template for creating worker task specifications

## Tools

- **decompose_project.rb** - Generate initial work plan template
- **Task board** - Track work stream progress (TODO, In Progress, Done)
- **Dependency graph** - Visualize blocking relationships
- **Daily standup doc** - Async communication for status updates
