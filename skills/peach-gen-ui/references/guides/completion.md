# UI 생성 완료 체크리스트

## 필수 검증

- [ ] `npx vue-tsc --noEmit` 통과
- [ ] `bun run lint:fix` 통과
- [ ] `bun run build` 성공
- [ ] Store 연결 확인 (import 및 사용)

---

## 패턴 적용 확인

### URL 동기화 패턴
- [ ] `listAction`: 검색 시 route query 업데이트 (page=1, time)
- [ ] `resetAction`: 초기화 시 기본값 복구 + 정렬 설정
- [ ] `watch(route)`: route query를 listParams에 동기화

### Selectbox 패턴
- [ ] 전체 옵션 value='' (빈 문자열)
- [ ] `@change="listAction"` 즉시 검색

### Date 검색 패턴
- [ ] 초기값: 5년 전 ~ 오늘
- [ ] `p-date-picker` + `@update:modelValue="listAction"`
- [ ] `p-day-select` + `@setDate="setDate"` (빠른 선택)

### 모달 패턴
- [ ] `isOpenInsert`, `isOpenDetail`, `isOpenUpdate` 상태 관리
- [ ] `v-model:open` 양방향 바인딩
- [ ] `@insert-ok`, `@update-ok`, `@remove-ok` 이벤트 처리

### 로딩 패턴
- [ ] `FormService.loading` 적용

---

## 완료 후 작업

1. **라우터 등록**: `front/src/router.ts`에 추가
2. **개발 서버 실행**: `cd front && bun dev`
3. **브라우저 확인**: 화면 동작 테스트

---

## 완료 메시지

```
Frontend UI 생성 완료!

다음 단계:
1. 라우터 등록
2. 개발 서버 실행
3. 브라우저에서 확인
```
