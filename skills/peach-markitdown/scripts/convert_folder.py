#!/usr/bin/env python3
from __future__ import annotations

import argparse
import json
import subprocess
import sys
from pathlib import Path
from shutil import which


SUPPORTED_MARKITDOWN = {
    ".pdf",
    ".pptx",
    ".docx",
    ".xlsx",
    ".xls",
    ".html",
    ".htm",
    ".csv",
    ".json",
    ".xml",
    ".zip",
    ".epub",
    ".jpg",
    ".jpeg",
    ".png",
    ".gif",
    ".bmp",
    ".tif",
    ".tiff",
    ".webp",
}
SUPPORTED_HWPX = {".hwpx"}


def run_command(command: list[str]) -> tuple[int, str]:
    proc = subprocess.run(
        command,
        stdout=subprocess.PIPE,
        stderr=subprocess.STDOUT,
        text=True,
        encoding="utf-8",
        errors="replace",
    )
    return proc.returncode, proc.stdout


def ensure_tools(project_root: Path, hwpx_extract_script: Path) -> None:
    if not which("markitdown"):
        raise RuntimeError("markitdown 명령을 찾을 수 없습니다. bootstrap.sh를 먼저 실행하세요.")

    venv_python = project_root / ".venv" / "bin" / "python"
    if not venv_python.is_file():
        raise RuntimeError(".venv Python을 찾을 수 없습니다. bootstrap.sh를 먼저 실행하세요.")

    if not hwpx_extract_script.is_file():
        raise RuntimeError(f"HWPX 추출 스크립트를 찾을 수 없습니다: {hwpx_extract_script}")


def convert_markitdown(source: Path, target: Path) -> tuple[bool, str]:
    code, output = run_command(["markitdown", str(source), "-o", str(target)])
    return code == 0, output


def convert_hwpx(source: Path, target: Path, project_root: Path, hwpx_extract_script: Path) -> tuple[bool, str]:
    venv_python = project_root / ".venv" / "bin" / "python"
    command = [
        str(venv_python),
        str(hwpx_extract_script),
        str(source),
        "--format",
        "markdown",
        "--output",
        str(target),
    ]
    code, output = run_command(command)
    return code == 0, output


def write_text(path: Path, content: str) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(content, encoding="utf-8")


def main() -> int:
    parser = argparse.ArgumentParser(description="문서파일을 md로 변환")
    parser.add_argument("--input-dir", required=True, help="입력 폴더")
    parser.add_argument("--output-dir", required=True, help="출력 폴더")
    args = parser.parse_args()

    project_root = Path.cwd().resolve()
    skill_dir = Path(__file__).resolve().parent
    input_dir = Path(args.input_dir).resolve()
    output_dir = Path(args.output_dir).resolve()
    hwpx_extract_script = skill_dir / "extract_hwpx.py"

    if not input_dir.is_dir():
        print(f"입력 폴더가 없습니다: {input_dir}", file=sys.stderr)
        return 1

    ensure_tools(project_root, hwpx_extract_script)
    output_dir.mkdir(parents=True, exist_ok=True)

    summary: list[dict[str, str]] = []
    errors: list[str] = []
    files = sorted([p for p in input_dir.rglob("*") if p.is_file()])

    for source in files:
        rel = source.relative_to(input_dir)
        target = (output_dir / rel).with_suffix(".md")
        target.parent.mkdir(parents=True, exist_ok=True)

        ext = source.suffix.lower()
        status = "skipped"
        detail = ""

        if ext in SUPPORTED_MARKITDOWN:
            ok, detail = convert_markitdown(source, target)
            status = "converted" if ok else "failed"
        elif ext in SUPPORTED_HWPX:
            ok, detail = convert_hwpx(source, target, project_root, hwpx_extract_script)
            status = "converted" if ok else "failed"
        else:
            detail = f"unsupported extension: {ext or '(none)'}"

        summary.append(
            {
                "source": str(source),
                "target": str(target),
                "extension": ext,
                "status": status,
            }
        )

        if status != "converted":
            errors.append(f"[{status}] {source} :: {detail.strip()}")

    write_text(output_dir / "conversion-errors.log", "\n".join(errors) + ("\n" if errors else ""))
    write_text(output_dir / "conversion-summary.json", json.dumps(summary, ensure_ascii=False, indent=2))

    converted = sum(1 for item in summary if item["status"] == "converted")
    failed = sum(1 for item in summary if item["status"] == "failed")
    skipped = sum(1 for item in summary if item["status"] == "skipped")

    print(f"converted={converted} failed={failed} skipped={skipped}")
    print(f"summary={output_dir / 'conversion-summary.json'}")
    print(f"errors={output_dir / 'conversion-errors.log'}")
    return 0 if failed == 0 else 2


if __name__ == "__main__":
    raise SystemExit(main())
