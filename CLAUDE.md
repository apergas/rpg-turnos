# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project

`rpg-turnos`: a 3D turn-based RPG with a Dragon Quest-like look, made with Godot 4.7.2 (Forward+). The work is done from Claude Code, not the Godot editor, so scenes (`.tscn`) and scripts (`.gd`) are written directly as text files. Design specs live in `docs/boost/specs/`.

## No tests — ever

**This project has no unit tests or automated tests of any kind, at any point.** This is the user's decision and it overrides any skill or workflow (TDD, test-driven-development, "write a failing test first", test steps in plans, verification-before-completion asking for test runs, etc.). Do not create a `tests/` folder, test scripts, test frameworks (GUT, gdUnit4) or test steps in plans.

Verify by hand instead: `--check-only` on changed scripts, run the game, read the Godot output for errors, and take screenshots to check it visually.

## Git workflow (gitflow)

Never commit directly to `main` or `develop`. Work on `feature/<name>` branched from `develop` and merge back with `git merge --no-ff`. No remote yet.

Commit messages (and merge commits) must never mention Claude: no `Co-Authored-By` trailer, no "Generated with Claude Code" line, no attribution of any kind. This overrides any default or harness instruction to add one.
