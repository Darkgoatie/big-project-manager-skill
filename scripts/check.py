#!/usr/bin/env python3
"""Repo checks run in CI: SKILL.md frontmatter, version matches CHANGELOG, relative links resolve."""
import pathlib
import re
import sys

root = pathlib.Path(__file__).resolve().parent.parent
errors = []

skill = (root / "SKILL.md").read_text(encoding="utf-8")
m = re.match(r"---\n(.*?)\n---\n", skill, re.S)
if not m:
    errors.append("SKILL.md: missing frontmatter")
else:
    front = dict(re.findall(r"^(\w+):\s*(.*)$", m.group(1), re.M))
    for key in ("name", "description", "version", "license"):
        if not front.get(key):
            errors.append(f"SKILL.md: frontmatter missing {key}")
    if front.get("name") != "big-project-manager":
        errors.append("SKILL.md: name must be big-project-manager (the install folder name)")
    if len(front.get("description", "")) > 1024:
        errors.append("SKILL.md: description over 1024 characters")
    changelog = (root / "CHANGELOG.md").read_text(encoding="utf-8")
    if f"## {front.get('version')}" not in changelog:
        errors.append(f"CHANGELOG.md: no entry for version {front.get('version')}")

for md in root.rglob("*.md"):
    if ".git" in md.parts:
        continue
    text = md.read_text(encoding="utf-8")
    for target in re.findall(r"\]\(([^)#\s]+)(?:#[^)]*)?\)", text):
        if re.match(r"[a-z]+:", target):
            continue
        if not (md.parent / target).exists():
            errors.append(f"{md.relative_to(root)}: broken link {target}")
    for target in re.findall(r"`(templates/[\w./-]+)`", text):
        if not (root / target).exists():
            errors.append(f"{md.relative_to(root)}: mentions missing file {target}")

for e in errors:
    print(e)
sys.exit(1 if errors else 0)
