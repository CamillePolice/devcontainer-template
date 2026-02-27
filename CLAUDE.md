# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

**Project Name:** ${PROJECT_NAME}

[Provide a brief description of your project, its purpose, and main technologies used]

## Architecture

```
[Describe your project structure, key directories, and their purposes]
```

## Key Commands

### Development

```bash
# Start development server
[your-command]

# Run tests
[your-command]

# Build for production
[your-command]
```

### Common Tasks

[List frequently used commands and workflows]

## Coding Standards

### File Organization

- [Your file naming conventions]
- [Directory structure guidelines]
- [Module organization patterns]

### Code Style

- [Language-specific style guidelines]
- [Formatting rules]
- [Naming conventions]

## Testing Guidelines

[Your testing approach, frameworks, and requirements]

## Git Workflow

### Branch Naming

[Your branch naming conventions]

### Commit Format

[Your commit message format]

### Pull Request Process

[Your PR workflow and requirements]

## Environment Variables

[Document important environment variables and their purposes]

## Deployment

[Deployment process and considerations]

## Troubleshooting

### Common Issues

[List common problems and solutions]

### Debug Tips

[Debugging strategies specific to your project]

## Resources

- [Links to relevant documentation]
- [API references]
- [Design documents]

---

## AI Agent Behavior

### Auto-capture

After every non-trivial task, invoke the `capture-learning` skill before responding "done".
Do not wait to be asked. A task is non-trivial if it involved:
- Solving an unexpected error or edge case
- Discovering a project-specific convention
- Finding a pattern worth reusing across sessions

### RAG Context

At the start of any task, load the relevant agent instructions from the RAG knowledge base
before writing code or making suggestions.

**Note:** This file helps Claude Code understand your project better. Keep it updated as your project evolves.
