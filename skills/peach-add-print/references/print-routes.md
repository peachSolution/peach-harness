# 인쇄 라우트 설정 템플릿

## 별도 라우트 파일 (필수)

```typescript
// _[모듈명]-print.routes.ts
import type { RouteRecordRaw } from 'vue-router';

// 레이아웃 없이 인쇄 전용 라우트
const printRoutes: RouteRecordRaw = {
  path: '/[모듈명]/[기능]',
  name: '[모듈명]-[기능]',
  redirect: '/[모듈명]/list',
  children: [
    {
      path: 'print',
      name: '[모듈명]-[기능]-print',
      component: () => import('./[기능]-print.vue'),
      meta: {
        hideLayout: true
      }
    }
  ]
};

export default printRoutes;
```

## router.ts 등록

```typescript
// front/src/router.ts
import printRoutes from './modules-domain/[모듈명]/pages/_[모듈명]-print.routes.ts';

const router = createRouter({
  history: createWebHistory(import.meta.env.BASE_URL),
  routes: [
    // ... 기존 모듈 라우트들
    moduleRoutes,       // 레이아웃 있는 기존 라우트
    printRoutes,        // 레이아웃 없는 인쇄 라우트 (별도)
    // ...
  ]
});
```

## 핵심 원리

### 레이아웃이 적용되는 경우 (기존 패턴)

```typescript
// 부모 라우트에 component가 있으면 레이아웃 적용
const moduleRoutes = {
  path: '/module',
  component: () => import('itax-layout.vue'),  // ← 레이아웃 컴포넌트
  children: [
    { path: 'list', component: ... },
    { path: 'detail', component: ... }
  ]
};
```

### 레이아웃이 적용되지 않는 경우 (인쇄 패턴)

```typescript
// 부모 라우트에 component가 없으면 레이아웃 미적용
const printRoutes = {
  path: '/module/feature',
  // component 없음 ← 레이아웃 없이 직접 렌더링
  children: [
    { path: 'print', component: () => import('./feature-print.vue') }
  ]
};
```

## 실제 예시

```typescript
// _unpaid-print.routes.ts
import type { RouteRecordRaw } from 'vue-router';

const unpaidPrintRoutes: RouteRecordRaw = {
  path: '/unpaid/account',
  name: 'unpaid-account',
  redirect: '/unpaid/list',
  children: [
    {
      path: 'print',
      name: 'unpaid-account-print',
      component: () => import('./account-print.vue'),
      meta: {
        hideLayout: true
      }
    }
  ]
};

export default unpaidPrintRoutes;
```

## 주의사항

1. **별도 파일 필수**: 기존 모듈 라우트 파일에 추가하면 레이아웃이 적용됨
2. **최상위 등록**: router.ts에서 다른 라우트와 동일 레벨로 등록
3. **경로 충돌 주의**: 기존 라우트와 경로가 겹치지 않도록 설계
4. **redirect 설정**: 잘못된 접근 시 목록 페이지로 리다이렉트
