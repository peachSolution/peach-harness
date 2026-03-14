# 다크 모드 디자인 가이드 (2024-2025)

## 핵심 원칙

- **순수 검정 금지**: `#000` 대신 `#121212` 사용 (눈의 피로 감소)
- **Elevation 계층**: 배경 밝기로 깊이 표현
- **채도 조절**: 다크모드에서 액센트 컬러 채도 20-30% 감소

---

## Elevation 계층 시스템

Google Material Design 기반:

| Level | 배경색 | 용도 |
|-------|--------|------|
| 0 | `#121212` | 기본 배경 |
| 1 | `#1E1E1E` | 카드, 컨테이너 |
| 2 | `#252525` | 호버 상태 |
| 3 | `#2C2C2C` | 모달, 팝오버 |

---

## CSS 변수 시스템

```css
:root {
  --bg-primary: #FFFFFF;
  --bg-secondary: #F4F4F5;
  --bg-tertiary: #E4E4E7;

  --text-primary: #18181B;
  --text-secondary: #52525B;
  --text-tertiary: #A1A1AA;

  --border: #E4E4E7;
  --accent: #287DFF;
}

[data-theme="dark"] {
  --bg-primary: #121212;
  --bg-secondary: #1E1E1E;
  --bg-tertiary: #252525;

  --text-primary: #F4F4F5;
  --text-secondary: #A1A1AA;
  --text-tertiary: #71717A;

  --border: #3F3F46;
  --accent: #5C9AFF; /* 채도 20-30% 감소 */
}
```

---

## TailwindCSS v4 다크모드 설정

### 클래스 기반 (권장)

```css
@import "tailwindcss";

/* 클래스 기반 다크 모드 */
@variant dark (&:where(.dark, .dark *));
```

### Data Attribute 기반

```css
@import "tailwindcss";

/* data attribute 기반 */
@variant dark (&:where([data-theme="dark"], [data-theme="dark"] *));
```

---

## 테마 토글 구현

### JavaScript

```javascript
// 테마 토글
function toggleTheme() {
  document.documentElement.classList.toggle("dark");
  const isDark = document.documentElement.classList.contains("dark");
  localStorage.setItem("theme", isDark ? "dark" : "light");
}

// 초기 로드 시 테마 적용
function initTheme() {
  if (
    localStorage.theme === "dark" ||
    (!("theme" in localStorage) &&
      window.matchMedia("(prefers-color-scheme: dark)").matches)
  ) {
    document.documentElement.classList.add("dark");
  }
}

initTheme();
```

### Vue Composable

```typescript
// composables/useTheme.ts
export function useTheme() {
  const isDark = ref(false);

  onMounted(() => {
    isDark.value =
      localStorage.theme === "dark" ||
      (!("theme" in localStorage) &&
        window.matchMedia("(prefers-color-scheme: dark)").matches);

    if (isDark.value) {
      document.documentElement.classList.add("dark");
    }
  });

  function toggle() {
    isDark.value = !isDark.value;
    document.documentElement.classList.toggle("dark");
    localStorage.setItem("theme", isDark.value ? "dark" : "light");
  }

  return { isDark, toggle };
}
```

---

## NuxtUI v3 다크모드

NuxtUI는 자동으로 다크모드 지원:

```typescript
// nuxt.config.ts
export default defineNuxtConfig({
  modules: ['@nuxt/ui'],
  colorMode: {
    preference: 'system', // 'dark', 'light', 'system'
    fallback: 'light',
    classSuffix: ''
  }
})
```

### 컴포넌트에서 사용

```vue
<script setup>
const colorMode = useColorMode();

function toggleDark() {
  colorMode.preference = colorMode.value === 'dark' ? 'light' : 'dark';
}
</script>

<template>
  <u-button @click="toggleDark">
    {{ colorMode.value === 'dark' ? '라이트 모드' : '다크 모드' }}
  </u-button>
</template>
```

---

## 디자인 토큰 구조

```css
@import "tailwindcss";
@import "@nuxt/ui";

@theme static {
  /* 브랜드 색상 */
  --color-brand-500: oklch(0.55 0.18 250);
}

/* 시맨틱 에일리어스 */
:root {
  --ui-primary: var(--color-brand-500);
  --ui-bg: var(--color-gray-50);
  --ui-bg-elevated: var(--color-white);
  --ui-text: var(--color-gray-900);
  --ui-text-muted: var(--color-gray-500);
  --ui-border: var(--color-gray-200);
}

.dark {
  --ui-primary: var(--color-brand-400);
  --ui-bg: var(--color-gray-950);
  --ui-bg-elevated: var(--color-gray-900);
  --ui-text: var(--color-gray-100);
  --ui-text-muted: var(--color-gray-400);
  --ui-border: var(--color-gray-800);
}
```

---

## 다크모드 컴포넌트 예시

### 카드

```vue
<template>
  <div
    class="
      bg-white dark:bg-neutral-900
      border border-neutral-200 dark:border-neutral-800
      rounded-lg p-4
    "
  >
    <h3 class="text-neutral-900 dark:text-neutral-100 font-medium">
      제목
    </h3>
    <p class="text-neutral-600 dark:text-neutral-400 text-sm mt-2">
      설명 텍스트
    </p>
  </div>
</template>
```

### 버튼

```vue
<template>
  <!-- Primary -->
  <button
    class="
      bg-primary-500 dark:bg-primary-600
      hover:bg-primary-600 dark:hover:bg-primary-700
      text-white
    "
  >
    Primary
  </button>

  <!-- Secondary -->
  <button
    class="
      bg-neutral-100 dark:bg-neutral-800
      hover:bg-neutral-200 dark:hover:bg-neutral-700
      text-neutral-900 dark:text-neutral-100
    "
  >
    Secondary
  </button>
</template>
```

---

## 다크모드 체크리스트

### 필수 확인 사항

- [ ] 텍스트 대비 4.5:1 이상 유지
- [ ] 그림자 대신 테두리로 구분 (다크모드에서 그림자 안 보임)
- [ ] 이미지/아이콘 대비 확인
- [ ] 액센트 컬러 채도 조절
- [ ] 포커스 인디케이터 가시성

### 테스트 방법

```bash
# 브라우저 개발자 도구
1. Elements 탭 > Styles 패널
2. :hov 버튼 클릭
3. prefers-color-scheme: dark 강제 적용
```

---

## 접근성 고려사항

### 대비 유지

다크모드에서도 WCAG 2.2 AA 기준 충족:
- 일반 텍스트: 4.5:1
- 큰 텍스트: 3:1
- UI 컴포넌트: 3:1

### 색상만으로 정보 전달 금지

```vue
<!-- 잘못된 예 -->
<span class="text-red-500 dark:text-red-400">오류</span>

<!-- 올바른 예: 아이콘 + 텍스트 -->
<span class="text-red-500 dark:text-red-400 flex items-center gap-1">
  <icon name="error" />
  오류
</span>
```
