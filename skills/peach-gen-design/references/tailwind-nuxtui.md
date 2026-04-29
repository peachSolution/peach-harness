# TailwindCSS v4 + NuxtUI v3 구현 가이드

> 기준 파일: `front/src/assets/styles/theme.css`

---

## CSS 변수 매핑

### theme.css 변수 → TailwindCSS 유틸리티

theme.css에서 정의된 CSS 변수들은 Tailwind 유틸리티와 호환됩니다:

```css
/* theme.css */
:root {
  /* Primary - bg-primary-*, text-primary-* 로 사용 가능 */
  --color-primary-50: var(--ui-color-primary-50);
  --color-primary-100: var(--ui-color-primary-100);
  --color-primary-500: var(--ui-color-primary-500);
  /* ... */

  /* 커스텀 변수 */
  --color-custom-black-444: #444444;
  --color-custom-input-border: var(--ui-border);
  --color-custom-border: var(--ui-border);
}
```

### UI 시맨틱 변수

```css
:root {
  /* 시맨틱 컬러 */
  --ui-primary: var(--ui-color-primary-500);     /* #287dff */
  --ui-secondary: var(--ui-color-secondary-500); /* #10b981 */
  --ui-success: var(--ui-color-success-500);     /* #10b981 */
  --ui-info: var(--ui-color-info-500);           /* #3b82f6 */
  --ui-warning: var(--ui-color-warning-500);     /* #f59e0b */
  --ui-error: var(--ui-color-error-500);         /* #ef4444 */

  /* 텍스트 */
  --ui-text-dimmed: var(--ui-color-neutral-400);
  --ui-text-muted: var(--ui-color-neutral-500);
  --ui-text-toned: var(--ui-color-neutral-600);
  --ui-text: var(--ui-color-neutral-700);
  --ui-text-highlighted: var(--ui-color-neutral-900);

  /* 배경 */
  --ui-bg: #ffffff;
  --ui-bg-muted: var(--ui-color-neutral-50);
  --ui-bg-elevated: var(--ui-color-neutral-100);
  --ui-bg-accented: var(--ui-color-neutral-200);

  /* 테두리 */
  --ui-border: var(--ui-color-neutral-200);
  --ui-border-muted: var(--ui-color-neutral-200);
  --ui-border-accented: var(--ui-color-neutral-300);
}
```

---

## 스페이싱 시스템

### 기본 단위: 4px

```css
:root {
  --spacing-1: 4px;
  --spacing-2: 8px;
  --spacing-3: 12px;
  --spacing-4: 16px;
  --spacing-5: 20px;
  --spacing-6: 24px;
}
```

### TailwindCSS 매핑

| CSS 변수 | Tailwind | 값 |
|----------|----------|-----|
| `--spacing-1` | `p-1`, `m-1`, `gap-1` | 4px |
| `--spacing-2` | `p-2`, `m-2`, `gap-2` | 8px |
| `--spacing-3` | `p-3`, `m-3`, `gap-3` | 12px |
| `--spacing-4` | `p-4`, `m-4`, `gap-4` | 16px |
| `--spacing-5` | `p-5`, `m-5`, `gap-5` | 20px |
| `--spacing-6` | `p-6`, `m-6`, `gap-6` | 24px |

---

## Border Radius

```css
:root {
  --radius-sm: 4px;   /* rounded-sm: 태그, 작은 요소 */
  --radius-md: 6px;   /* rounded-md: 버튼, 인풋 */
  --radius-lg: 8px;   /* rounded-lg: 카드, 드롭다운 */
  --radius-xl: 12px;  /* rounded-xl: 모달, 큰 카드 */
}
```

---

## Shadows

```css
:root {
  --shadow-sm: 0 1px 3px rgba(0, 0, 0, 0.1);     /* 카드 기본 */
  --shadow-md: 0 4px 6px rgba(0, 0, 0, 0.1);     /* 드롭다운 */
  --shadow-lg: 0 6px 12px rgba(0, 0, 0, 0.175);  /* 모달 */
}
```

---

## 레이아웃

```css
:root {
  --sidebar-width: 220px;
  --header-height: 64px;
}
```

---

## NuxtUI v3 컴포넌트 사용

### UButton

```vue
<template>
  <!-- Primary (CTA) -->
  <u-button color="primary">저장</u-button>

  <!-- Secondary -->
  <u-button color="neutral" variant="soft">취소</u-button>

  <!-- Outline -->
  <u-button variant="outline">더보기</u-button>

  <!-- Ghost -->
  <u-button variant="ghost">링크</u-button>

  <!-- Destructive -->
  <u-button color="error">삭제</u-button>

  <!-- 사이즈 -->
  <u-button size="xs">아주 작게</u-button>
  <u-button size="sm">작게</u-button>
  <u-button size="md">기본</u-button>
  <u-button size="lg">크게</u-button>

  <!-- 아이콘 -->
  <u-button icon="i-heroicons-plus" aria-label="추가" />
  <u-button icon="i-heroicons-plus">추가</u-button>
  <u-button trailing-icon="i-heroicons-arrow-right">다음</u-button>

  <!-- 로딩 -->
  <u-button :loading="isLoading">저장</u-button>
</template>
```

### UCard

```vue
<template>
  <u-card>
    <template #header>
      <div class="flex items-center justify-between">
        <h3 class="text-base font-semibold text-neutral-800">카드 제목</h3>
        <u-button size="xs" variant="ghost" icon="i-heroicons-ellipsis-vertical" />
      </div>
    </template>

    <p class="text-sm text-neutral-600">카드 내용</p>

    <template #footer>
      <div class="flex justify-end gap-2">
        <u-button variant="soft">취소</u-button>
        <u-button>확인</u-button>
      </div>
    </template>
  </u-card>
</template>
```

### UModal

```vue
<script setup>
const isOpen = ref(false);
</script>

<template>
  <u-button @click="isOpen = true">모달 열기</u-button>

  <u-modal v-model="isOpen">
    <template #header>
      <h2 class="text-lg font-semibold text-neutral-900">모달 제목</h2>
    </template>

    <p class="text-sm text-neutral-600">모달 내용</p>

    <template #footer>
      <div class="flex justify-end gap-2">
        <u-button variant="soft" @click="isOpen = false">취소</u-button>
        <u-button @click="handleConfirm">확인</u-button>
      </div>
    </template>
  </u-modal>
</template>
```

### UFormField + UInput

```vue
<template>
  <u-form-field label="이메일" required :error="emailError">
    <u-input
      v-model="email"
      type="email"
      placeholder="이메일 입력"
      :error="!!emailError"
    />
    <template #hint>
      업무용 이메일을 입력하세요
    </template>
  </u-form-field>
</template>
```

### USelect

```vue
<template>
  <u-form-field label="카테고리">
    <u-select
      v-model="category"
      :options="categories"
      placeholder="선택하세요"
    />
  </u-form-field>
</template>

<script setup>
const categories = [
  { label: '전체', value: '' },
  { label: '카테고리1', value: '1' },
  { label: '카테고리2', value: '2' },
];
</script>
```

### UTable

```vue
<template>
  <u-table :rows="users" :columns="columns">
    <template #status-data="{ row }">
      <u-badge :color="row.status === '활성' ? 'success' : 'neutral'">
        {{ row.status }}
      </u-badge>
    </template>

    <template #actions-data="{ row }">
      <div class="flex gap-1">
        <u-button size="xs" variant="ghost" icon="i-heroicons-pencil" @click="edit(row)" />
        <u-button size="xs" variant="ghost" color="error" icon="i-heroicons-trash" @click="remove(row)" />
      </div>
    </template>
  </u-table>
</template>

<script setup>
const columns = [
  { key: 'name', label: '이름' },
  { key: 'email', label: '이메일' },
  { key: 'status', label: '상태' },
  { key: 'actions', label: '' },
];
</script>
```

### UBadge

```vue
<template>
  <!-- 기본 -->
  <u-badge>기본</u-badge>

  <!-- 컬러 -->
  <u-badge color="primary">Primary</u-badge>
  <u-badge color="success">성공</u-badge>
  <u-badge color="warning">경고</u-badge>
  <u-badge color="error">오류</u-badge>

  <!-- Variant -->
  <u-badge variant="solid">Solid</u-badge>
  <u-badge variant="soft">Soft</u-badge>
  <u-badge variant="outline">Outline</u-badge>
</template>
```

### UTabs

```vue
<script setup>
const tabs = [
  { label: '기본 정보', slot: 'basic' },
  { label: '상세 정보', slot: 'detail' },
  { label: '첨부 파일', slot: 'files' },
];
</script>

<template>
  <u-tabs :items="tabs">
    <template #basic>
      <div class="p-4">기본 정보 내용</div>
    </template>
    <template #detail>
      <div class="p-4">상세 정보 내용</div>
    </template>
    <template #files>
      <div class="p-4">첨부 파일 내용</div>
    </template>
  </u-tabs>
</template>
```

---

## 권장 스타일 패턴

### 간격
```vue
<template>
  <!-- 4px 배수 사용 -->
  <div class="p-4 gap-4">
    <div class="space-y-4">
      <!-- 콘텐츠 -->
    </div>
  </div>
</template>
```

### 그림자
```vue
<template>
  <!-- shadow-sm: 카드 기본 -->
  <div class="shadow-sm">카드</div>

  <!-- shadow: 호버, 인터랙티브 -->
  <div class="hover:shadow">호버 효과</div>
</template>
```

### 둥근 모서리
```vue
<template>
  <!-- rounded-md: 버튼, 인풋 -->
  <button class="rounded-md">버튼</button>

  <!-- rounded-lg: 카드 -->
  <div class="rounded-lg">카드</div>
</template>
```

---

## 금지 패턴

```vue
<!-- 금지: 그라데이션 -->
<div class="bg-gradient-to-r from-blue-500 to-purple-500">금지</div>

<!-- 금지: 과도한 그림자 -->
<div class="shadow-xl shadow-2xl">금지</div>

<!-- 금지: 과도한 애니메이션 -->
<div class="animate-pulse animate-bounce">금지</div>

<!-- 금지: 확대 효과 -->
<button class="hover:scale-105 transform">금지</button>

<!-- 금지: 과도한 둥근 모서리 -->
<button class="rounded-full rounded-3xl">금지</button>
```

---

## 트랜지션 유틸리티

```css
--transition-fast: 150ms;
--transition-normal: 200ms;
--transition-slow: 300ms;
--ease-default: cubic-bezier(0.4, 0, 0.2, 1);
```

```vue
<template>
  <button class="transition-colors duration-150 ease-out">
    버튼
  </button>

  <div class="transition-shadow duration-150 hover:shadow-md">
    카드
  </div>
</template>
```

---

## 다크 모드 구현 (옵션)

```css
@import "tailwindcss";

/* 클래스 기반 다크 모드 */
@variant dark (&:where(.dark, .dark *));
```

```vue
<template>
  <div class="bg-white dark:bg-neutral-900 text-neutral-900 dark:text-neutral-100">
    다크 모드 지원
  </div>
</template>
```

---

## 빠른 참조: 핵심 수치

### 스페이싱 스케일 (4px 기준)
```
1: 4px | 2: 8px | 3: 12px | 4: 16px | 5: 20px | 6: 24px
```

### 컬러 토큰
```css
Primary: #287dff
Secondary: #10b981
Success: #10b981
Warning: #f59e0b
Error: #ef4444
Info: #3b82f6
Text: #212121 (neutral-900)
Border: #e5e5e5 (neutral-200)
```

### 레이아웃
```css
Sidebar: 220px
Header: 64px
Card padding: 16px (p-4)
Button height: 40px (h-10)
Input height: 40px
```
