#!/bin/bash

# Set path of this script
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# Define claude implementation directory
CLAUDE_DIR="$SCRIPT_DIR/../../platforms/claude"
# Define copilot implementation directories
COPILOT_DIR="$SCRIPT_DIR/../../platforms/copilot"
COPILOT_GITHUB_DIR="$COPILOT_DIR/.github"

# Remove existing copilot implementation
rm -rf "$COPILOT_DIR/"

# Create directories
mkdir -p "$COPILOT_GITHUB_DIR"

# Instructions
# Copy files
cp "$CLAUDE_DIR/CLAUDE.md" "$COPILOT_GITHUB_DIR/copilot-instructions.md"
cp -R "$CLAUDE_DIR/.claude/rules" "$COPILOT_GITHUB_DIR/instructions"
# Add .instructions.md extension to files
for file in "$COPILOT_GITHUB_DIR/instructions/"*; do
	mv "$file" "${file%.*}.instructions.md"
done

# Skills
# Copy files
cp -R "$CLAUDE_DIR/.claude/skills" "$COPILOT_GITHUB_DIR/"

