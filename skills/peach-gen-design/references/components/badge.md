# 배지 / 태그 디자인 가이드

> 기준 파일: `front/src/assets/styles/theme.css`, `docs/ux-design/dr-pltt-design-system.md`

---

## 배지/태그 스펙 (닥터팔레트)

```css
.tag {
  display: inline-flex;
  align-items: center;
  padding: 4px 10px;
  border-radius: 4px;       /* radius-sm */
  font-size: 12px;
  font-weight: 500;
}

.tag-blue {
  background-color: #e0ecff;  /* primary-100 */
  color: #287dff;             /* primary-500 */
}

.tag-green {
  background-color: #d1fae5;  /* success-100 */
  color: #10b981;             /* success-500 */
}
```

---

## 색상 팔레트

| 용도 | 텍스트 | 배경 | NuxtUI color |
|------|--------|------|--------------|
| Primary (기본) | `#287dff` | `#e0ecff` | `primary` |
| Success (성공) | `#10b981` | `#d1fae5` | `success` |
| Warning (경고) | `#f59e0b` | `#fef3c7` | `warning` |
| Error (오류) | `#ef4444` | `#fee2e2` | `error` |
| Info (정보) | `#3b82f6` | `#dbeafe` | `info` |
| Neutral (중립) | `#545456` | `#f3f4f6` | `neutral` |

---

## NuxtUI 배지 사용

### 기본 사용

```vue
<template>
  <!-- 기본 배지 -->
  <u-badge>기본</u-badge>

  <!-- 컬러별 배지 -->
  <u-badge color="primary">Primary</u-badge>
  <u-badge color="success">성공</u-badge>
  <u-badge color="warning">경고</u-badge>
  <u-badge color="error">오류</u-badge>
  <u-badge color="info">정보</u-badge>
  <u-badge color="neutral">중립</u-badge>
</template>
```

### Variant

```vue
<template>
  <!-- Soft (기본, 연한 배경) -->
  <u-badge variant="soft" color="primary">Soft</u-badge>

  <!-- Solid (채워진 배경) -->
  <u-badge variant="solid" color="primary">Solid</u-badge>

  <!-- Outline (테두리만) -->
  <u-badge variant="outline" color="primary">Outline</u-badge>

  <!-- Subtle (더 연한 배경) -->
  <u-badge variant="subtle" color="primary">Subtle</u-badge>
</template>
```

### 사이즈

```vue
<template>
  <u-badge size="xs">XS</u-badge>
  <u-badge size="sm">SM</u-badge>
  <u-badge size="md">MD</u-badge>
  <u-badge size="lg">LG</u-badge>
</template>
```

---

## 상태 배지 패턴

### 사용/미사용

```vue
<script setup>
function getUseColor(isUse: string) {
  return isUse === 'Y' ? 'success' : 'neutral';
}

function getUseLabel(isUse: string) {
  return isUse === 'Y' ? '사용' : '미사용';
}
</script>

<template>
  <u-badge :color="getUseColor(row.isUse)">
    {{ getUseLabel(row.isUse) }}
  </u-badge>
</template>
```

### 활성/비활성

```vue
<script setup>
function getStatusColor(status: string) {
  switch (status) {
    case 'active': return 'success';
    case 'inactive': return 'neutral';
    case 'pending': return 'warning';
    case 'error': return 'error';
    default: return 'neutral';
  }
}

function getStatusLabel(status: string) {
  switch (status) {
    case 'active': return '활성';
    case 'inactive': return '비활성';
    case 'pending': return '대기';
    case 'error': return '오류';
    default: return status;
  }
}
</script>

<template>
  <u-badge :color="getStatusColor(row.status)">
    {{ getStatusLabel(row.status) }}
  </u-badge>
</template>
```

### 결제 상태

```vue
<script setup>
const paymentStatusMap = {
  completed: { color: 'success', label: '완료' },
  pending: { color: 'warning', label: '대기' },
  failed: { color: 'error', label: '실패' },
  refunded: { color: 'info', label: '환불' },
  cancelled: { color: 'neutral', label: '취소' },
};
</script>

<template>
  <u-badge :color="paymentStatusMap[status].color">
    {{ paymentStatusMap[status].label }}
  </u-badge>
</template>
```

---

## 카테고리 태그

```vue
<template>
  <!-- 단일 태그 -->
  <u-badge color="primary" variant="soft">건강보험</u-badge>

  <!-- 태그 목록 -->
  <div class="flex flex-wrap gap-1">
    <u-badge v-for="tag in tags" :key="tag" variant="soft">
      {{ tag }}
    </u-badge>
  </div>
</template>
```

---

## 아이콘 배지

```vue
<template>
  <!-- 아이콘 + 텍스트 -->
  <u-badge color="success" class="flex items-center gap-1">
    <icon name="i-heroicons-check-circle" class="w-3.5 h-3.5" />
    완료
  </u-badge>

  <!-- 경고 배지 -->
  <u-badge color="warning" class="flex items-center gap-1">
    <icon name="i-heroicons-exclamation-triangle" class="w-3.5 h-3.5" />
    주의
  </u-badge>

  <!-- 오류 배지 -->
  <u-badge color="error" class="flex items-center gap-1">
    <icon name="i-heroicons-x-circle" class="w-3.5 h-3.5" />
    실패
  </u-badge>
</template>
```

---

## 숫자 배지 (Count)

```vue
<template>
  <!-- 알림 카운트 -->
  <div class="relative">
    <u-button variant="ghost" icon="i-heroicons-bell" />
    <span class="absolute -top-1 -right-1 w-5 h-5 bg-error-500 text-white text-xs font-medium rounded-full flex items-center justify-center">
      3
    </span>
  </div>

  <!-- 메뉴 카운트 -->
  <div class="flex items-center justify-between">
    <span>미처리 요청</span>
    <u-badge color="error" variant="solid" size="xs">12</u-badge>
  </div>
</template>
```

---

## 닷 배지 (Dot)

```vue
<template>
  <!-- 온라인 상태 -->
  <div class="flex items-center gap-2">
    <span class="w-2 h-2 bg-success-500 rounded-full"></span>
    <span class="text-sm">온라인</span>
  </div>

  <!-- 오프라인 상태 -->
  <div class="flex items-center gap-2">
    <span class="w-2 h-2 bg-neutral-400 rounded-full"></span>
    <span class="text-sm">오프라인</span>
  </div>

  <!-- 작업 중 (펄스 애니메이션) -->
  <div class="flex items-center gap-2">
    <span class="w-2 h-2 bg-warning-500 rounded-full animate-pulse"></span>
    <span class="text-sm">처리 중</span>
  </div>
</template>
```

---

## 커스텀 스타일링 (TailwindCSS)

```vue
<template>
  <!-- 기본 태그 -->
  <span
    class="
      inline-flex items-center
      px-2.5 py-0.5
      text-xs font-medium
      bg-primary-100 text-primary-600
      rounded
    "
  >
    태그
  </span>

  <!-- 상태 배지 -->
  <span
    :class="[
      'inline-flex items-center px-2.5 py-0.5 text-xs font-medium rounded',
      isActive
        ? 'bg-success-100 text-success-600'
        : 'bg-neutral-100 text-neutral-600'
    ]"
  >
    {{ isActive ? '활성' : '비활성' }}
  </span>
</template>
```

---

## 테이블에서 사용

```vue
<template>
  <u-table :rows="rows" :columns="columns">
    <!-- 상태 컬럼 -->
    <template #status-data="{ row }">
      <u-badge :color="getStatusColor(row.status)">
        {{ getStatusLabel(row.status) }}
      </u-badge>
    </template>

    <!-- 사용여부 컬럼 -->
    <template #isUse-data="{ row }">
      <u-badge :color="row.isUse === 'Y' ? 'success' : 'neutral'">
        {{ row.isUse === 'Y' ? '사용' : '미사용' }}
      </u-badge>
    </template>

    <!-- 카테고리 컬럼 -->
    <template #category-data="{ row }">
      <u-badge variant="soft">{{ row.category }}</u-badge>
    </template>
  </u-table>
</template>
```

---

## 접근성 체크리스트

- [ ] 색상만으로 정보 전달 금지 (텍스트 필수)
- [ ] 충분한 대비 유지 (4.5:1)
- [ ] 의미 있는 라벨 제공

```vue
<template>
  <!-- 올바른 예: 색상 + 텍스트 -->
  <u-badge color="error">오류</u-badge>

  <!-- 잘못된 예: 색상만 사용 -->
  <span class="w-3 h-3 bg-error-500 rounded-full"></span>
</template>
```

---

## 금지 패턴

```vue
<!-- 금지: 색상만으로 상태 표현 -->
<span class="w-3 h-3 bg-green-500 rounded-full"></span>

<!-- 금지: 과도한 그림자 -->
<span class="shadow-lg">배지</span>

<!-- 금지: 과도한 애니메이션 -->
<span class="animate-bounce">배지</span>

<!-- 금지: 너무 큰 둥근 모서리 -->
<span class="rounded-full px-4">긴 텍스트 배지</span>
```

---

## 권장 패턴

```vue
<template>
  <!-- 상태 배지 -->
  <u-badge :color="getStatusColor(status)">
    {{ getStatusLabel(status) }}
  </u-badge>

  <!-- 카테고리 태그 -->
  <u-badge variant="soft">{{ category }}</u-badge>

  <!-- 숫자 배지 -->
  <u-badge color="error" variant="solid" size="xs">{{ count }}</u-badge>

  <!-- 아이콘 + 텍스트 -->
  <u-badge color="success" class="flex items-center gap-1">
    <icon name="i-heroicons-check" class="w-3 h-3" />
    완료
  </u-badge>
</template>
```

---

## 실제 사용 예시

### 상태 관리 유틸리티

```typescript
// utils/badge.ts
export const statusConfig = {
  active: { color: 'success', label: '활성' },
  inactive: { color: 'neutral', label: '비활성' },
  pending: { color: 'warning', label: '대기' },
  error: { color: 'error', label: '오류' },
  completed: { color: 'success', label: '완료' },
  cancelled: { color: 'neutral', label: '취소' },
} as const;

export function getStatusConfig(status: string) {
  return statusConfig[status as keyof typeof statusConfig] || { color: 'neutral', label: status };
}
```

```vue
<script setup>
import { getStatusConfig } from '@/utils/badge';

const { color, label } = getStatusConfig(row.status);
</script>

<template>
  <u-badge :color="color">{{ label }}</u-badge>
</template>
```

### 테이블 목록 페이지

```vue
<template>
  <u-table :rows="rows" :columns="columns">
    <template #status-data="{ row }">
      <u-badge
        :color="row.status === 'active' ? 'success' : 'neutral'"
      >
        {{ row.status === 'active' ? '활성' : '비활성' }}
      </u-badge>
    </template>

    <template #isUse-data="{ row }">
      <u-badge
        :color="row.isUse === 'Y' ? 'success' : 'neutral'"
      >
        {{ row.isUse === 'Y' ? '사용' : '미사용' }}
      </u-badge>
    </template>

    <template #tags-data="{ row }">
      <div class="flex flex-wrap gap-1">
        <u-badge
          v-for="tag in row.tags"
          :key="tag"
          variant="soft"
          size="xs"
        >
          {{ tag }}
        </u-badge>
      </div>
    </template>
  </u-table>
</template>
```
