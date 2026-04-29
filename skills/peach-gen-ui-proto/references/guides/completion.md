# UI 프로토타입 생성 완료 체크리스트

## 필수 검증

- [ ] 타입 체크 통과 (`bunx vue-tsc --noEmit`)
- [ ] lint 통과
- [ ] build 성공
- [ ] Mock 데이터 생성 확인 (mock/[모듈명].mock.ts)
- [ ] Store 연결 확인 (Mock 함수 import 및 사용)

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

### 모달 패턴
- [ ] `isOpenInsert`, `isOpenDetail`, `isOpenUpdate` 상태 관리
- [ ] `v-model:open` 양방향 바인딩
- [ ] `@insert-ok`, `@update-ok`, `@remove-ok` 이벤트 처리

### Mock 특화 확인
- [ ] Mock 데이터가 UI에 정상 표시
- [ ] Mock CRUD (등록/수정/삭제) 동작 확인
- [ ] `[Mock]` 로그가 콘솔에 출력

---

## 완료 후 작업

1. **라우터 등록**: `front/src/router.ts`에 추가
2. **개발 서버 실행**: `cd front && bun run dev`
3. **브라우저 확인**: 화면 동작 테스트

---

## 완료 메시지

```
Frontend UI 프로토타입 생성 완료!

생성된 파일:
- mock/[모듈명].mock.ts     ← Mock 데이터
- store/[모듈명].store.ts   ← Mock Store
- pages/                     ← UI 페이지
- modals/                    ← 모달 컴포넌트

다음 단계:
1. 라우터 등록
2. 개발 서버 실행 (`bun run dev`)
3. 브라우저에서 확인

프로덕션 전환 시:
1. mock/ 디렉토리 삭제
2. Store에서 mock import를 useApi()로 교체
3. 나머지 코드는 그대로 유지
```
