#!/usr/bin/env python3
from __future__ import annotations

import argparse
import subprocess
import sys
from pathlib import Path
from shutil import which


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


def convert_markitdown(source: str, target: Path) -> tuple[bool, str]:
    returncode, output = run_command(["markitdown", source, "-o", str(target)])
    return returncode == 0, output


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
    returncode, output = run_command(command)
    return returncode == 0, output


def main() -> int:
    parser = argparse.ArgumentParser(description="단일 문서파일을 md로 변환")
    parser.add_argument("--source", required=True, help="입력 파일 경로")
    parser.add_argument("--output", required=True, help="출력 md 파일 경로")
    args = parser.parse_args()

    project_root = Path.cwd().resolve()
    skill_dir = Path(__file__).resolve().parent
    hwpx_extract_script = skill_dir / "extract_hwpx.py"
    output_path = Path(args.output).resolve()
    output_path.parent.mkdir(parents=True, exist_ok=True)

    ensure_tools(project_root, hwpx_extract_script)

    source_path = Path(args.source).resolve()
    if not source_path.is_file():
        print(f"입력 파일이 없습니다: {source_path}", file=sys.stderr)
        return 1

    if source_path.suffix.lower() == ".hwpx":
        ok, detail = convert_hwpx(source_path, output_path, project_root, hwpx_extract_script)
    else:
        ok, detail = convert_markitdown(str(source_path), output_path)

    print(f"ok={str(ok).lower()}")
    print(f"output={output_path}")
    if detail.strip():
        print(detail.strip())
    return 0 if ok else 2


if __name__ == "__main__":
    raise SystemExit(main())
