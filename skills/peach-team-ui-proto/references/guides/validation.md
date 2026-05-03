# UI 검증 가이드 (프로토타입)

## 빌드 도구 기준

```bash
# bun 프로젝트 (bun.lockb 존재)
ls bun.lockb 2>/dev/null && echo "BUILD_TOOL=bun"
```

## 검증 명령어

### bun 프로젝트 (순서대로 실행)

```bash
bunx vue-tsc --noEmit  # 타입 체크
bun run lint:fix       # 린트
bun run build          # 빌드
```

---

## 에러 티키타카 패턴

```
에러 발생 → 원인 분석 → 코드 수정 → 다시 검증 → 통과할 때까지 반복
```

### 일반적인 오류 유형

| 오류 | 원인 | 해결 |
|------|------|------|
| 타입 불일치 | DTO/인터페이스 정의 오류 | type 파일 확인 |
| import 오류 | 경로 또는 export 문제 | 상대경로/alias 확인 |
| 컴포넌트 미등록 | import 누락 | script setup에서 import |
| ref 타입 오류 | 초기값 타입 미지정 | `ref<Type>()` 형식 사용 |
| Mock 타입 오류 | Mock 함수 반환 타입 불일치 | mock 파일 타입 확인 |

---

## 중요

> 빌드 성공 없이 완료 선언 금지!

모든 검증 단계를 통과해야만 UI 프로토타입 생성 완료로 간주합니다.
