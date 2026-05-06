#!/usr/bin/env bash
set -euo pipefail

# DU Skills installer for Claude Code
# Usage: curl -fsSL https://git.volcanly.me/du-v2/claude-skills/-/raw/main/install.sh | bash
# Or:    ./install.sh [target-project-dir]

SKILLS_REPO="git@git.volcanly.me:du-v2/claude-skills.git"
SKILLS_DIR="${HOME}/.local/share/du-skills"

# Skills organized by category: folder/skill-name
# Functional skills (PM, BA, Designer)
FUNCTIONAL_SKILLS=(
  "functional:functional-scaffold"
  "functional/jira-scaffold:jira-scaffold"
  "functional/jira-review:jira-review"
  "functional/wbs-export:wbs-export"
  "functional/documentation:documentation"
)

# Technical skills (Developers, QC, DevOps)
TECHNICAL_SKILLS=(
  "technical/monorepo-scaffold:monorepo-scaffold"
  "technical/implement:implement"
  "technical/audit:audit"
  "technical/review:review"
  "technical/test:test"
  "technical/housekeeping:housekeeping"
  "technical/gitflow:gitflow"
)

ALL_SKILLS=("${FUNCTIONAL_SKILLS[@]}" "${TECHNICAL_SKILLS[@]}")

echo "DU Skills installer"
echo "==================="
echo ""

# Clone or update the skills repo
if [ -d "$SKILLS_DIR/.git" ]; then
  echo "Updating existing installation at $SKILLS_DIR..."
  git -C "$SKILLS_DIR" pull --ff-only origin main 2>/dev/null || {
    echo "Warning: could not pull latest. Using existing version."
  }
else
  echo "Installing DU Skills to $SKILLS_DIR..."
  mkdir -p "$(dirname "$SKILLS_DIR")"
  git clone "$SKILLS_REPO" "$SKILLS_DIR"
fi

echo ""

# If a target project dir is provided, symlink skills into it
TARGET="${1:-.}"
if [ "$TARGET" = "." ]; then
  read -rp "Link skills into current project? ($(pwd)) [Y/n] " answer
  answer="${answer:-Y}"
  if [[ ! "$answer" =~ ^[Yy] ]]; then
    echo ""
    echo "Installation complete. Skills are at: $SKILLS_DIR"
    echo ""
    echo "To link into a project later, run:"
    echo "  cd /path/to/your/project"
    echo "  $SKILLS_DIR/install.sh ."
    echo ""
    exit 0
  fi
fi

TARGET="$(cd "$TARGET" && pwd)"
CLAUDE_SKILLS_DIR="$TARGET/.claude/skills"

echo "Linking skills into $CLAUDE_SKILLS_DIR..."
mkdir -p "$CLAUDE_SKILLS_DIR"

# Clean up old flat symlinks (pre-reorganization)
OLD_SKILLS=(scaffold jira-scaffold jira-review documentation audit review test housekeeping gitflow)
for old_skill in "${OLD_SKILLS[@]}"; do
  if [ -L "$CLAUDE_SKILLS_DIR/$old_skill" ]; then
    rm "$CLAUDE_SKILLS_DIR/$old_skill"
    echo "  Removed old link: $old_skill"
  fi
done

# Create new symlinks with folder-based naming
for entry in "${ALL_SKILLS[@]}"; do
  folder="${entry%%:*}"
  name="${entry##*:}"

  if [ -L "$CLAUDE_SKILLS_DIR/$name" ]; then
    rm "$CLAUDE_SKILLS_DIR/$name"
  fi
  ln -sf "$SKILLS_DIR/$folder" "$CLAUDE_SKILLS_DIR/$name"
  echo "  Linked: /$name -> $folder/"
done

echo ""
echo "Done. Available commands in Claude Code:"
echo ""
echo "  Functional (PM, BA, Designer):"
for entry in "${FUNCTIONAL_SKILLS[@]}"; do
  name="${entry##*:}"
  echo "    /$name"
done
echo ""
echo "  Technical (Developers, QC, DevOps):"
for entry in "${TECHNICAL_SKILLS[@]}"; do
  name="${entry##*:}"
  echo "    /$name"
done
echo ""
echo "Run any command in Claude Code to get started."
echo "Configuration will be stored in .du-skills.yaml at your project root."
