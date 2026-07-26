# Task Specification Template

Use this template when assigning work to Claude workers.

## Task: [Clear, Action-Oriented Title]

**Assigned To**: [Worker ID/Name]
**Estimated Effort**: [X hours/days]
**Priority**: [Critical / High / Medium / Low]
**Status**: [Not Started / In Progress / Blocked / Review / Complete]

---

## Objective

[One-sentence description of what this task accomplishes]

## Context

[Background information the worker needs to understand the task]
- Why this task exists
- How it fits into the larger project
- Any relevant history or decisions

## Deliverables

Specific, measurable outputs:

- [ ] [Deliverable 1] - [Acceptance criteria]
- [ ] [Deliverable 2] - [Acceptance criteria]
- [ ] [Tests passing] - [Which tests]
- [ ] [Documentation updated] - [Which docs]

## Dependencies

**Requires Before Starting**:
- [Resource/Information 1] - Available: [Yes/No/When]
- [Completed task] - Status: [Complete/In Progress]

**Provides for Others**:
- [Output 1] for [Task B]
- [Output 2] for [Task C]

**Blocks**:
- [Task name] - [Why it's blocked]

## Technical Requirements

### Files to Create/Modify
```
app/models/user.rb
app/controllers/users_controller.rb
test/models/user_test.rb
```

### Interfaces/Contracts
```ruby
# API this task must expose
class User
  def authenticate(password)
    # Returns: true/false
  end
end
```

### External Dependencies
- Gems: [List required gems]
- APIs: [External services needed]
- Tools: [Special tools required]

## Implementation Approach

[Recommended approach, but worker has flexibility]

1. [Step 1]
2. [Step 2]
3. [Step 3]

**Alternatives Considered**:
- [Approach A]: [Why not chosen]
- [Approach B]: [Trade-offs]

## Success Criteria

How to know this task is complete:

- [ ] All deliverables checked off
- [ ] Tests pass: `rails test test/models/user_test.rb`
- [ ] Code review approved
- [ ] Documentation updated
- [ ] No known blockers introduced for downstream tasks

## Testing Instructions

```bash
# Run these commands to verify
rails test test/models/user_test.rb
rubocop app/models/user.rb
```

Expected results:
- All tests green
- No RuboCop offenses
- Coverage > 80%

## Integration Plan

### Merge Strategy
- [ ] Create feature branch: `feature/user-authentication`
- [ ] Open PR against: `main`
- [ ] Request review from: [Worker IDs]
- [ ] Merge after: [Conditions]

### Potential Conflicts
- **File conflicts**: `app/models/user.rb` may conflict with [Task B]
- **Resolution strategy**: [How to handle]

### Coordination Points
- Sync with [Worker X] after [milestone] to ensure [interfaces align]
- Review with [Worker Y] before [integration] to verify [contracts]

## Resources

**Documentation**:
- [Link to relevant docs]
- [Link to design decisions]

**Examples**:
- [Link to similar implementation]
- [Reference code]

**People**:
- Questions about [X]? Ask [Worker Y]
- Domain expertise: [Expert name]

## Timeline

- **Start Date**: [Date or "After Task X completes"]
- **Estimated Completion**: [Date]
- **Actual Completion**: [Fill in when done]

## Notes / Caveats

- [Important consideration 1]
- [Known limitation 2]
- [Assumption 3]

## Questions / Blockers

Use this section to track issues:

- **Q**: [Question]
  - **A**: [Answer when resolved]

- **Blocker**: [Description]
  - **Status**: [Unresolved / Escalated / Resolved]
  - **Resolution**: [How it was fixed]

---

## For the Worker

### Getting Started Checklist

- [ ] Read entire task specification
- [ ] Verify all dependencies are available
- [ ] Understand acceptance criteria
- [ ] Review related tasks for coordination needs
- [ ] Ask questions before starting if anything unclear

### While Working

- [ ] Update status to "In Progress"
- [ ] Document any blockers in Questions/Blockers section
- [ ] Commit frequently with clear messages
- [ ] Run tests continuously
- [ ] Communicate if timeline slips

### Before Marking Complete

- [ ] All deliverables checked off
- [ ] All tests passing
- [ ] Code reviewed (by another worker or self-review)
- [ ] Documentation updated
- [ ] No new blockers introduced
- [ ] Notified downstream workers that outputs are ready

---

## Sign-Off

**Assigned By**: [Planner name]
**Accepted By**: [Worker name]
**Completed By**: [Worker name]
**Reviewed By**: [Reviewer name]

**Date Assigned**: [Date]
**Date Completed**: [Date]
