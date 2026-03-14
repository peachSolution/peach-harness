# 풀스택 팀 워크플로우 상세

## 병렬화 전략

team-backend-dev 완료 후 backend-qa와 store-dev를 동시 실행하여 시간을 절약합니다.

```
[1단계] team-backend-dev (순차 - 선행 필수)
         └─ API 코드 생성 + TDD 검증

[2단계] 병렬 실행 (team-backend-dev 완료 즉시)
         ├─ team-backend-qa (독립 검증)
         └─ team-store-dev  (API 타입 기반 Store 생성)

[3단계] team-ui-dev (team-store-dev 완료 후)
         └─ Store 인터페이스 기반 UI 생성

[4단계] team-frontend-qa (team-ui-dev 완료 후)
         └─ 전체 Frontend 품질 검증
```

## 팀원별 스폰 프롬프트 구성 예시

### team-backend-dev 스폰 프롬프트

```
당신은 team-backend-dev 에이전트입니다.
역할: .claude/agents/team-backend-dev.md 참조

작업:
모듈명: [모듈명]
스키마: api/db/schema/[도메인]/[테이블].sql
옵션: file=[Y/N], excel=[Y/N], controllerTdd=[Y/N]

1. 스키마 파일 읽기
2. gen-backend 스킬 기반으로 API 코드 생성
3. bun test 실행
4. bun run lint:fixed 실행
5. bun run build 실행
6. 완료 후 SendMessage로 팀 리더에게 보고

팀: [모듈명]-fullstack-team
```

### team-store-dev 스폰 프롬프트

```
당신은 team-store-dev 에이전트입니다.
역할: .claude/agents/team-store-dev.md 참조

작업:
모듈명: [모듈명]
전제: Backend API가 완료된 상태 (api/src/modules/[모듈명]/ 존재)
옵션: file=[Y/N], storeTdd=[Y/N]

1. Backend 타입 파일 읽기: api/src/modules/[모듈명]/type/[모듈명].type.ts
2. gen-store 스킬 기반으로 Pinia Store 생성
3. vue-tsc 검증
4. 완료 후 SendMessage로 팀 리더에게 보고

팀: [모듈명]-fullstack-team
```

### team-ui-dev 스폰 프롬프트 (Figma 없음)

```
당신은 team-ui-dev 에이전트입니다.
역할: .claude/agents/team-ui-dev.md 참조

작업:
모듈명: [모듈명]
UI 패턴: [crud/page/two-depth/...]
옵션: file=[Y/N], excel=[Y/N]
전제: Store가 완료된 상태 (front/src/modules/[모듈명]/store/ 존재)

1. Store 파일 읽기
2. gen-ui 스킬 기반으로 Vue3 UI 컴포넌트 생성
3. vue-tsc + lint + build 검증
4. 완료 후 SendMessage로 팀 리더에게 보고

팀: [모듈명]-fullstack-team
```

### team-ui-dev 스폰 프롬프트 (Figma 있음)

```
당신은 team-ui-dev 에이전트입니다.
역할: .claude/agents/team-ui-dev.md 참조

작업:
모듈명: [모듈명]
Figma URL: [URL]
UI 패턴: [crud/page/two-depth/...]
옵션: file=[Y/N], excel=[Y/N]
전제: Store가 완료된 상태 (front/src/modules/[모듈명]/store/ 존재)

1. ToolSearch로 FigmaRemote MCP 도구 로드
2. Figma 데이터 추출 및 분석
3. 닥터팔레트 기준으로 NuxtUI 컴포넌트 매핑
4. gen-ui 스킬 기반으로 Vue3 UI 컴포넌트 생성
5. vue-tsc + lint + build 검증
6. 완료 후 SendMessage로 팀 리더에게 보고

팀: [모듈명]-fullstack-team
```

## Figma 통합 시 워크플로우 변형

```
[일반 워크플로우]
team-backend-dev → (병렬) team-backend-qa + team-store-dev → team-ui-dev → team-frontend-qa

[Figma 통합 워크플로우]
                    ┌─ 피그마 분석 (team-ui-dev)
team-backend-dev → ─┤
                    └─ team-store-dev (병렬)
                           │
                    team-ui-dev (Store + Figma 합산)
                           │
                    team-frontend-qa
```

Figma가 있는 경우, team-ui-dev는:
1. Store 완료 대기
2. FigmaRemote MCP로 디자인 추출
3. 디자인 + Store 인터페이스 기반으로 UI 생성

## 오류 복구 전략

### Backend TDD 실패

```
team-backend-qa 실패 감지
    │
    ├─ 에러 분석: 타입 오류 vs SQL 오류 vs 로직 오류
    │
    └─ team-backend-dev에게 SendMessage:
       "다음 TDD 케이스 실패: [케이스명]
        오류: [에러 메시지]
        수정 후 재보고 요청"
```

### Frontend 빌드 실패

```
team-frontend-qa 실패 감지
    │
    ├─ vue-tsc 오류 → team-store-dev: 타입 수정 요청
    ├─ lint 오류 → team-ui-dev: 코드 스타일 수정 요청
    └─ build 오류 → team-ui-dev: 빌드 오류 수정 요청
```

## TaskList 활용 (팀 리더)

팀 리더는 TaskList로 팀원 진행상황을 모니터링:

```
TaskList 확인:
1. Backend API 개발    [completed] ← team-backend-dev 완료
2. Backend QA 검증     [in_progress] ← team-backend-qa 진행중
3. Frontend Store 개발 [in_progress] ← team-store-dev 진행중 (병렬)
4. Frontend UI 개발    [pending] ← 아직 대기
5. Frontend QA 검증    [pending] ← 아직 대기
```
