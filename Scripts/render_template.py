#!/usr/bin/env python3
"""
SwiftBlock Template Pre-renderer for test_templates.sh.
Parses brick.yml default flavors and renders conditional blocks ({{#if ...}} / {{#unless ...}}).
"""

import sys
import os
import re

def parse_brick_defaults(brick_dir):
    defaults = {}
    manifest_path = os.path.join(brick_dir, "brick.yml")
    if not os.path.exists(manifest_path):
        manifest_path = os.path.join(brick_dir, "brick.yaml")
    if not os.path.exists(manifest_path):
        return defaults

    with open(manifest_path, "r", encoding="utf-8") as f:
        content = f.read()

    lines = content.split("\n")
    in_section = False
    current_flavor = None

    for line in lines:
        stripped = line.strip()
        if not stripped or stripped.startswith("#"):
            continue

        if re.match(r"^(flavors|variables):", line):
            in_section = True
            current_flavor = None
            continue
        elif re.match(r"^[a-zA-Z0-9_-]+:", line):
            in_section = False
            current_flavor = None
            continue

        if in_section:
            flavor_match = re.match(r"^  ([a-zA-Z0-9_-]+):", line)
            if flavor_match:
                current_flavor = flavor_match.group(1)
                continue

            if current_flavor:
                default_match = re.match(r"^\s+default:\s*([a-zA-Z0-9_-]+)", line)
                if default_match:
                    defaults[current_flavor] = default_match.group(1)

    return defaults

def eval_condition(expr, variables):
    expr = expr.strip()
    match_cmp = re.match(r"^([a-zA-Z0-9_-]+)\s*(==|!=)\s*['\"]([^'\"]+)['\"]$", expr)
    if match_cmp:
        var_name, op, expected = match_cmp.groups()
        actual = variables.get(var_name, "")
        return (actual == expected) if op == "==" else (actual != expected)
    
    # Bare boolean check
    val = variables.get(expr, "").lower()
    return val in ("true", "1", "yes")

def render_conditionals(text, variables):
    if_pattern = re.compile(
        r"\{\{#if\s+([^\}]+)\}\}((?:(?!\{\{#if)[\s\S])*?)(?:\{\{else\}\}((?:(?!\{\{#if)[\s\S])*?))?\{\{\/if\}\}"
    )
    unless_pattern = re.compile(
        r"\{\{#unless\s+([^\}]+)\}\}((?:(?!\{\{#unless)[\s\S])*?)(?:\{\{else\}\}((?:(?!\{\{#unless)[\s\S])*?))?\{\{\/unless\}\}"
    )

    iterations = 0
    while iterations < 50:
        iterations += 1
        m = if_pattern.search(text)
        if m:
            cond, true_part, false_part = m.group(1), m.group(2), m.group(3) or ""
            replacement = true_part if eval_condition(cond, variables) else false_part
            text = text[:m.start()] + replacement + text[m.end():]
            continue

        m_u = unless_pattern.search(text)
        if m_u:
            cond, false_part, true_part = m_u.group(1), m_u.group(2), m_u.group(3) or ""
            replacement = false_part if not eval_condition(cond, variables) else true_part
            text = text[:m_u.start()] + replacement + text[m_u.end():]
            continue

        break

    return text

def main():
    if len(sys.argv) < 5:
        print("Usage: render_template.py <src_file> <dest_file> <brick_dir> <prefix>")
        sys.exit(1)

    src_file = sys.argv[1]
    dest_file = sys.argv[2]
    brick_dir = sys.argv[3]
    prefix = sys.argv[4]

    with open(src_file, "r", encoding="utf-8") as f:
        content = f.read()

    variables = parse_brick_defaults(brick_dir)
    rendered = render_conditionals(content, variables)

    # Replace placeholders
    rendered = rendered.replace("__MODULE_NAME__", prefix)
    rendered = rendered.replace("@testable import __APP_MODULE__", "@testable import SwiftBlockTemplatesTest")
    rendered = rendered.replace("@testable import __PROJECT_NAME__", "@testable import SwiftBlockTemplatesTest")
    rendered = rendered.replace("@testable import Core", "@testable import SwiftBlockTemplatesTest")

    os.makedirs(os.path.dirname(dest_file), exist_ok=True)
    with open(dest_file, "w", encoding="utf-8") as f:
        f.write(rendered)

if __name__ == "__main__":
    main()
