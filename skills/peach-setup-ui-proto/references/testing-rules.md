# UI Proto 검증 규칙

> peach-setup-ui-proto Source of Truth — Frontend-Only UI Proto 검증 규칙

## 검증 명령어

```bash
bun run test:run
bunx vue-tsc --noEmit
bun run lint
bun run build
```

## 원칙
- 테스트/타입/린트/빌드 명령은 bun 기준으로 표기
- 검증 섹션은 유지하되, 기획자 운영 문서와 직접 무관한 보조 설명은 최소화
