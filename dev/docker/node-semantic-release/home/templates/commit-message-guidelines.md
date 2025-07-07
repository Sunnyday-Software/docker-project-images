# Commit Message Format

We have very precise rules over how our Git commit messages must be formatted.
This format leads to **easier to read commit history** and makes it analyzable for changelog generation.

Each commit message consists of a **header**, a **body**, and a **footer**.


```
<header>
<BLANK LINE>
<body>
<BLANK LINE>
<footer>
```

The `header` is mandatory and must conform to the [Commit Message Header](#commit-header) format.

The `body` is mandatory for all commits except for those of type "docs".
When the body is present it must be at least 20 characters long and must conform to the [Commit Message Body](#commit-body) format.

The `footer` is optional. The [Commit Message Footer](#commit-footer) format describes what the footer is used for and the structure it must have.


## <a name="commit-header"></a>Commit Message Header

```
{{asciiDiagram types scopes}}

```

The `<type>` and `<summary>` fields are mandatory.

### Type (Mandatory)

Must be one of the following:

| Type | Description |
|------|-------------|
{{#each types}}
| `{{type}}` | {{description}} |
{{/each}}


{{#if scopes.hasScopes}}

### <a name="scope"></a> Scope ({{#if scopes.required}}Mandatory{{else}}Optional but recommended{{/if}})
The scope should be the name of the package affected (as perceived by the person reading the changelog generated from commit messages).

The following is the list of supported scopes:


| Scope | Description |
|-------|-------------|
{{#each scopes.list}}
|`{{scope}}`|{{description}} |
  {{/each}}
  {{else}}
  **Scope is optional** for this project.

You can use any meaningful scope that describes the area of change (e.g., `api`, `ui`, `docs`).
{{/if}}



## Rules

### Length Requirements
{{#if rules.length}}
{{#each rules.length}}
- **{{label}}**: {{rule}}
  {{/each}}
  {{else}}
  No specific length requirements configured.
  {{/if}}

### Formatting Rules
{{#if rules.formatting}}
{{#each rules.formatting}}
- **{{label}}**: {{rule}}
  {{/each}}
  {{else}}
  No specific formatting requirements configured.
  {{/if}}

### Structural Rules
{{#if rules.structural}}
{{#each rules.structural}}
- **{{this}}**
  {{/each}}
  {{else}}
  No specific structural requirements configured.
  {{/if}}


### Summary

Use the summary field to provide a succinct description of the change:

* use the imperative, present tense: "change" not "changed" nor "changes"
* don't capitalize the first letter
* no dot (.) at the end


## <a name="commit-body"></a>Commit Message Body

Just as in the summary, use the imperative, present tense: "fix" not "fixed" nor "fixes".

Explain the motivation for the change in the commit message body. This commit message should explain _why_ you are making the change.
You can include a comparison of the previous behavior with the new behavior in order to illustrate the impact of the change.


## <a name="commit-footer"></a>Commit Message Footer

The footer can contain information about breaking changes and deprecations and is also the place to reference GitHub issues and other PRs that this commit closes or is related to.
For example:

```
BREAKING CHANGE: <breaking change summary>
<BLANK LINE>
<breaking change description + migration instructions>
<BLANK LINE>
<BLANK LINE>
Fixes #<issue number>
```

or

```
DEPRECATED: <what is deprecated>
<BLANK LINE>
<deprecation description + recommended update path>
<BLANK LINE>
<BLANK LINE>
Closes #<pr number>
```

Breaking Change section should start with the phrase `BREAKING CHANGE: ` followed by a *brief* summary of the breaking change, a blank line, and a detailed description of the breaking change that also includes migration instructions.

Similarly, a Deprecation section should start with `DEPRECATED: ` followed by a short description of what is deprecated, a blank line, and a detailed description of the deprecation that also mentions the recommended update path.

## Revert commits

If the commit reverts a previous commit, it should begin with `revert: `, followed by the header of the reverted commit.

The content of the commit message body should contain:

- information about the SHA of the commit being reverted in the following format: `This reverts commit <SHA>`,
- a clear description of the reason for reverting the commit message.




[angularjs-commit-message-format]: https://docs.google.com/document/d/1QrDFcIiPjSLDn3EL15IJygNPiHORgU1_OOAqWjiDU5Y/edit#