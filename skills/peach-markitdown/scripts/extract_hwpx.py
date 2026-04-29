#!/usr/bin/env python3
from __future__ import annotations

import argparse
import sys
from pathlib import Path

from hwpx import TextExtractor


def extract_plain(hwpx_path: str, *, include_tables: bool = False) -> str:
    object_behavior = "nested" if include_tables else "skip"
    with TextExtractor(hwpx_path) as ext:
        return ext.extract_text(
            include_nested=include_tables,
            object_behavior=object_behavior,
            skip_empty=True,
        )


def extract_markdown(hwpx_path: str) -> str:
    lines: list[str] = []
    with TextExtractor(hwpx_path) as ext:
        for section in ext.iter_sections():
            if lines:
                lines.extend(["", "---", ""])
            for para in ext.iter_paragraphs(section, include_nested=True):
                text = para.text(object_behavior="nested")
                if text.strip():
                    lines.append(f"  {text}" if para.is_nested else text)
    return "\n".join(lines)


def main() -> int:
    parser = argparse.ArgumentParser(description="Extract text from an HWPX document")
    parser.add_argument("input", help="Path to .hwpx file")
    parser.add_argument("--format", "-f", choices=["plain", "markdown"], default="plain")
    parser.add_argument("--include-tables", action="store_true")
    parser.add_argument("--output", "-o", help="Output file path")
    args = parser.parse_args()

    if not Path(args.input).is_file():
        print(f"Error: File not found: {args.input}", file=sys.stderr)
        return 1

    if args.format == "markdown":
        result = extract_markdown(args.input)
    else:
        result = extract_plain(args.input, include_tables=args.include_tables)

    if args.output:
        Path(args.output).write_text(result, encoding="utf-8")
    else:
        print(result)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())

