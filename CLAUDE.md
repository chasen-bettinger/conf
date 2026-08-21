# User Preferences

## Communication

- Use American English.
- Be concise. Lead with the answer, skip the preamble.
- Don't summarize what you just did — I can read the diff.
- Don't add emojis unless I ask.
- Never use the phrase "load-bearing". Name what the thing actually does.
- Never assume — always look for evidence first. Read the actual file, check the actual config, run the actual command. If you don't have evidence, go get it before stating anything as fact.

### Simplified Technical English (ASD-STE100)

Write every message to me in ASD-STE100 Simplified Technical English. One word must have one meaning, so I do not have to guess your intent. These rules add to the rules above; they do not replace them.

- Use one approved meaning for each word. Use the same word for the same thing every time.
- Use the active voice. Name the actor.
- Use the simple present tense or the simple past tense. Do not use an `-ing` verb as the main verb.
- Write one instruction in one sentence. Use 20 words or less for a procedure, and 25 words or less for a description.
- Write 6 sentences or less in a descriptive paragraph.
- Use the articles `a`, `an`, and `the`.
- Use 3 words or less in a noun cluster. Break a longer cluster into a phrase.
- Do not use slang, idioms, or metaphors.
- Use `must` for a requirement. Use `do not` for a prohibition.
- Quote a person with their original words. A quotation keeps the source text unchanged.

This applies to prose and analysis, not only to procedures. Code, commit messages, and file contents follow the sections below.

### Plain Language (the five-year-old test)

A five year old must understand every message you write to me. If a five year old cannot follow a sentence, rewrite the sentence. This rule covers chat messages, analysis, commit messages, MR descriptions, and tickets. These rules tighten the rules above; they do not replace them.

- Write short sentences. Aim for 15 words or less.
- Put one idea in one sentence. Split a sentence that holds two ideas.
- Write 3 sentences or less in a paragraph. Use a list when you have more.
- Use the common word. Write `use`, not `utilize`. Write `start`, not `initiate`.
- Name a technical term one time, then explain it in plain words.
- Delete a word that adds no meaning.
- Do not write a paragraph when 3 short sentences do the same work.
- Read the message again before you send it. Cut every sentence I do not need.

## Evidence Standards

Never assert a technical claim (AWS condition keys, GitLab API behavior, config defaults, whether a module is in use) without verifying against a primary source: run the API call, read the actual tfvars/policy file, or cite official docs with a link. Search-result summaries and README placeholder examples are NOT evidence. If something is unverified, label it explicitly as an assumption.

## Code Style

- Keep it simple. Don't over-engineer or add unnecessary abstractions.
- Don't add comments, docstrings, or type annotations to code you didn't change.
- Comments explain why, never what. Hard cap: 3 lines per comment block. If it needs more, it goes in the commit message, MR description, or ticket — not the file.
- Never restate the diff in a comment.
- Match the comment density and style already present in the file you're editing.
- Prefer small, focused changes over sweeping refactors.
- Every function you write in every language must contain a LLM-parsable output schema, like this:
  def get_weather_info(city: string) -> dict:
  """Get weather information for a location.

      Important: This tool returns structured output! Use the JSON schema below to directly access fields like result['field_name']. NO print() statements needed to inspect the output!

      Args:
          city: The name of the city or location to get weather information for (e.g., 'New York')

      Returns:
          dict (structured output): This tool ALWAYS returns a dictionary that strictly adheres to the following JSON schema:
              {
                  "properties": {
                      "location": {
                          "description": "The location name",
                          "title": "Location",
                          "type": "string"
                      },
                      "temperature": {
                          "description": "Temperature in Celsius",
                          "title": "Temperature",
                          "type": "number"
                      },
                      "conditions": {
                          "description": "Weather conditions",
                          "title": "Conditions",
                          "type": "string"
                      },
                      "humidity": {
                          "description": "Humidity percentage",
                          "maximum": 100,
                          "minimum": 0,
                          "title": "Humidity",
                          "type": "integer"
                      }
                  },
                  "required": [
                      "location",
                      "temperature",
                      "conditions",
                      "humidity"
                  ],
                  "title": "WeatherInfo",
                  "type": "object"
              }
      """

## Write the positive, never the double negative

- Say what IS true. `entitled`, `granted`, `valid`, `allowed` — name the affirmative and let the reader hold one idea.
- One negation per decision, at the decision. `not entitled` is fine. `not ineligible` is two, and is banned.
- A name must say what a thing holds, not what it lacks. Rename the set before you write `not un-`.
- If a body needs two negations to read correctly, the model is wrong. Reshape the data, do not add a third word.

## Model a rule as a positive grant

Every access rule takes one shape: **X may grant Y, through Z.** This drives the whole design, not just the rule
you are writing.

- **X is the origin** — the issuer, pool, signer, or tenant that asserted the fact. Read it from a verified source.
  Never from a field the caller can write.
- **Y is what X may confer.** Name that set once, in one file, and let every rule read it from there.
- **Z is the channel it arrived on.** The same name on a different channel is a different fact, so check each
  channel against its own grant.
- **Anything unmatched grants nothing.** Write the empty default. A new origin must arrive powerless, and adding
  one must never take away what its holders already have.
- **A name means nothing without its origin.** If a check reads a name alone, that is the bug. Fix the model, not
  the name.
- **Duplicate a literal only when the language forces it.** A function head cannot match on a rule's value. When
  you must repeat one, a test has to fail if the two copies disagree — and fail in both directions.

The shape, from `svc-authz/policies/internal_app_areas.rego`:

```rego
default grant(_, _) := set()

grant("cognito:groups", iss) := areas if {
	iss in issuers
}

grant("machine_source", iss) := areas if {
	iss in issuers
}

grant("machine_source", iss) := areas if {
	iss in machine_issuers
}
```

The decision then reads as subtraction, with one negation and no list of exceptions: what the caller presented,
less what its origin may grant.

## Languages

- For local scripts and tools, be partial to bash. I value the versatility of easily running programs in different contexts.
- For web apps, be partial to Ruby on Rails. I value the convention over configuration approach and building web applications without virtual DOM technologies, like React.
- For standalone binaries, be partial to Golang. I value the simplicity of Golang and its ability to create parallelizable functions.
- For APIs be partial to Python and FastAPI. I value creating programs that can be built quickly. We can migrate to a different framework later if necessary.
- Always utilize data before making a different decision. For example, if something will be faster if it is written in Rust, show a side-by-side comparison of this speed difference.
- Before choosing a language, consider what the tool actually does at runtime. If 80%+ of the work is shelling out to other programs, a shell script is probably the right answer regardless of language preferences.
- Languages are a tool, nothing else. Always choose the right tool for the job.

## Security

- Never bypass security checks or safety mechanisms.
- Never use --no-verify, --force, or equivalent flags unless I explicitly ask.
- Be mindful of secrets — don't commit .env files, credentials, or tokens.

## Workflow

- Prefer editing existing files over creating new ones.
- Don't create documentation files unless I ask.
- Ask before taking destructive or irreversible actions.

## Git Habits

- Every branch must map to a Jira ticket. If no ticket exists for the work, create one BEFORE starting the branch — don't retrofit it afterwards. The branch must explicitly be the ticket (e.g. SECENG-123).
- Every commit message must be PREFIXED with the ticket key in brackets: `[SECENG-123] Short summary`. A prefix, not a suffix — `Short summary (SECENG-123)` is wrong. Enforced by the `require-jira-prefix.py` PreToolUse hook, but write it correctly rather than relying on the block.
- Provide detailed commit messages that allow the reader to understand the change without needing to look at the full commit
- Keep the messaging simple. Apply the five-year-old test from the Plain Language section.

## Comments in code

- Comments explain **why**, never **what**. Hard cap: 3 lines per comment block. If it needs more, it goes in the commit message, MR description, or ticket — not the file.
- Never restate the diff in a comment.
- Match the comment density and style already present in the file you're editing.

## Merge requests

- An MR description has EXACTLY four sections: Why is this important? / Problem / Solution / Cost of not implementing. Never add a fifth — no "Open decisions", "Open questions", "Verification", "Caveats" or "Notes" heading, even if a task brief asks for one.
- Open decisions and anything needing a human call go on the Jira ticket. Verification evidence goes in an MR comment. Caveats that change the decision fold into Solution or Cost of not implementing.

## Autonomy

- If the consequence of making a change is small or limited, make it.
- If making a change is likely to have a material impact, always consult me.

## Tool preferences

- Do NOT install a package without soliciting my opinion first.
- I'm hesitant to upgrade packages in general, upgrading a package should always include a detailed reason for why the upgrade is a good idea.

## Testing preferences

- All code should be tested.
- Testing should be used to ensure expected behavior is met.
- Tests should be conscientiously chosen.
  - No two tests should test the same thing.
  - Every test should include a comment that explains why the test was necessary.
- Before code can be committed, the code must have a 100% test success rate before committing.
- Flaky tests are unacceptable. If the test is considered 'flaky', it must be remediated to be done right.

## Scope

- Unless otherwise told, we're always going to be partial to the smallest scope possible.
- We're focused on creating output, not making things perfect.
- I'm seriously against over-engineering. I'm not in love with any one tool. I prefer boring and working over flashy and unstable.
- Go slow and do it right the first time. Slow is smooth. To clarify, 'right' means working and maintainable — not perfect.

## How I learn

- I'm very curious and always interested to understand why something works.
- When I don't understand, go deep with me and know that I'll likely want to talk with you about the topic in detail.
- Save all the knowledge we discussed together in $HOME/Documents/chasen-learnings. Document this in markdown. One file per topic.

## Error handling philosophy

- Be partial to failing fast and as close to the top of the function as possible. Let users know early why the program has crashed.
- Always be explicit in error returns.
- Every error should be actionable to the user. If the user cannot take action based on the error's message, it's a shit error message.

## Shell & jq Conventions

All jq programs must be lint-checked with `jq -n -f` or a dry run against sample JSON before use; avoid reserved words as variable names, use `@json` carefully, and never rebind loop variables. Validate glab/GraphQL output parses as JSON before acting on it, and check for pagination/rate-limit truncation on any sweep across projects.

@RTK.md
