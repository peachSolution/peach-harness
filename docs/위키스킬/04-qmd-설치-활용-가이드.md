# qmd 설치·활용 가이드

> `peach-wiki`에서 qmd를 어떻게 쓰는지에 집중한 운영 문서다.
> 관련 문서: [패턴 분석](02-LLM위키-패턴-분석.md), [종합 분석](05-qmd-LLM위키-종합분석.md)
> 출처: 초기 분석 문서를 현재 기준으로 재작성

## qmd가 필요한 이유

`peach-wiki`는 위키 자체를 누적하지만, 소스 탐색은 여전히 효율적이어야 한다. qmd는 코드와 마크다운을 하이브리드 검색해서 다음 두 가지를 해결한다.

- 토큰을 아끼면서 관련 소스를 먼저 좁힌다.
- 단순 키워드와 의미 기반 검색을 함께 써서 누락을 줄인다.

## 설치

```bash
npm install -g @tobilu/qmd
qmd --version
```

권장 전제:

- Node.js 22 이상
- 로컬 디스크 여유 공간 약 3GB
- Apple Silicon 또는 GPU 가속 환경이면 더 빠름

## 컬렉션 등록

**반드시 `--index 프로젝트명` 패턴을 사용한다.** plain `qmd update/embed`는 전역 컬렉션을 모두 처리하므로 다른 프로젝트·옵시디언 컬렉션을 건드릴 수 있다.

### 코드 프로젝트

```bash
QMD_INDEX=$(basename $(pwd))
qmd --index "$QMD_INDEX" collection add . --name "$QMD_INDEX" --mask "**/*.{ts,vue,md,sql,py,go,js}"
qmd --index "$QMD_INDEX" context add "qmd://$QMD_INDEX/" "프로젝트 한 줄 설명"
qmd --index "$QMD_INDEX" update && qmd --index "$QMD_INDEX" embed
```

### 옵시디언 노트

```bash
QMD_INDEX=$(basename $(pwd))
qmd --index "$QMD_INDEX" collection add . --name para --mask "**/*.md"
qmd --index "$QMD_INDEX" context add "qmd://para/" "옵시디언 노트 컬렉션"
qmd --index "$QMD_INDEX" update && qmd --index "$QMD_INDEX" embed
```

## `peach-wiki`에서의 기본 사용 순서

```bash
QMD_INDEX=$(basename $(pwd))
qmd --index "$QMD_INDEX" status
qmd --index "$QMD_INDEX" collection list
qmd --index "$QMD_INDEX" query "키워드" -c "$QMD_INDEX"
qmd --index "$QMD_INDEX" get "qmd://$QMD_INDEX/경로/파일"
```

## 자주 쓰는 명령

```bash
qmd --index "$QMD_INDEX" status
qmd --index "$QMD_INDEX" collection list
qmd --index "$QMD_INDEX" query "키워드" -c "$QMD_INDEX"
qmd --index "$QMD_INDEX" search "키워드" -c "$QMD_INDEX"
qmd --index "$QMD_INDEX" query "키워드" -c "$QMD_INDEX" --files
qmd --index "$QMD_INDEX" get "qmd://$QMD_INDEX/경로/파일.md"
qmd --index "$QMD_INDEX" update && qmd --index "$QMD_INDEX" embed
```

## 언제 `embed`까지 돌릴까

| 상황 | 명령 |
|---|---|
| 새 파일 추가, 파일 이동, 대량 수정 | `qmd --index "$QMD_INDEX" update && qmd --index "$QMD_INDEX" embed` |
| 소규모 텍스트 수정 | `qmd --index "$QMD_INDEX" update` |
| 변경 없음 | 실행하지 않음 |

## 주의: CloudStorage/동기화 폴더

`~/Library/CloudStorage/*`, Synology Drive, OneDrive, iCloud Drive 아래의 컬렉션은 `qmd embed` 시 `fileproviderd`/동기화 재색인을 유발할 수 있다. 특히 background 실행(`qmd embed &`)은 체감 성능 저하를 크게 만들 수 있으므로, 해당 컬렉션은 별도 타이밍에만 임베딩하거나 사용자 확인을 받는다.

## `peach-wiki`와의 관계

- qmd는 검색 레이어다.
- `docs/wiki/`는 지식 레이어다.
- `AGENTS.md`, `SKILL.md`, `WIKI-AGENTS.md`는 운영 규칙 레이어다.

즉, qmd는 위키를 대체하지 않는다. 소스를 더 잘 찾게 도와줄 뿐이다.

## 문제 해결

| 증상 | 원인 | 해결 |
|---|---|---|
| `qmd: command not found` | 미설치 또는 PATH 문제 | `npm install -g @tobilu/qmd` |
| 새 파일 검색 안 됨 | 인덱스 미갱신 | `qmd --index "$QMD_INDEX" update` |
| 벡터 검색 품질이 낮음 | 임베딩 미생성 | `qmd --index "$QMD_INDEX" embed` |
| 검색이 느림 | CPU only 환경 | `--no-rerank`로 임시 완화 후 환경 개선 |

## 참고

- 스킬 본체: `skills/peach-wiki/SKILL.md`
- AI 참조 레퍼런스: `skills/peach-wiki/references/qmd-가이드.md`
