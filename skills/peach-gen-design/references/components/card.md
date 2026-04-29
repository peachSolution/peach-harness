# 카드 (Card) 디자인 가이드

> 기준 파일: `front/src/assets/styles/theme.css`, `docs/ux-design/dr-pltt-design-system.md`

---

## 카드 스펙 (닥터팔레트)

```css
.card {
  background-color: #ffffff;
  border: 1px solid #e5e5e5;  /* neutral-200 */
  border-radius: 8px;         /* radius-lg */
  padding: 16px;              /* spacing-4 */
  box-shadow: 0 1px 3px rgba(0, 0, 0, 0.05);  /* shadow-sm 보다 미묘 */
}

.card-header {
  font-size: 16px;
  font-weight: 600;
  color: #212121;  /* neutral-900 */
  margin-bottom: 12px;
  padding-bottom: 12px;
  border-bottom: 1px solid #e5e5e5;
}
```

---

## Elevation/Shadow 시스템

| Level | 용도 | CSS |
|-------|------|-----|
| 0 | 플랫/아웃라인 | `border: 1px solid #e5e5e5` |
| 1 | 기본 카드 | `box-shadow: 0 1px 3px rgba(0, 0, 0, 0.05)` |
| 2 | 호버/인터랙티브 | `box-shadow: 0 4px 6px rgba(0, 0, 0, 0.1)` |
| 3 | 모달/다이얼로그 | `box-shadow: 0 6px 12px rgba(0, 0, 0, 0.175)` |

> 백오피스에서는 Level 0-1을 주로 사용합니다. 과도한 그림자는 금지입니다.

---

## 스페이싱 가이드

| 요소 | 값 | TailwindCSS |
|------|-----|-------------|
| 내부 패딩 | 16px | `p-4` |
| 헤더/푸터 패딩 | 12-16px | `px-4 py-3` |
| 카드 간 갭 | 16px | `gap-4` |
| 섹션 간 갭 | 12px | `space-y-3` |

---

## NuxtUI 카드 사용

### 기본 카드

```vue
<template>
  <u-card>
    <p class="text-sm text-neutral-600">카드 내용</p>
  </u-card>
</template>
```

### 헤더/푸터 있는 카드

```vue
<template>
  <u-card>
    <template #header>
      <div class="flex items-center justify-between">
        <h3 class="text-base font-semibold text-neutral-800">카드 제목</h3>
        <u-button size="xs" variant="ghost" icon="i-heroicons-ellipsis-vertical" />
      </div>
    </template>

    <p class="text-sm text-neutral-600">카드 본문 내용입니다.</p>

    <template #footer>
      <div class="flex justify-end gap-2">
        <u-button variant="soft">취소</u-button>
        <u-button>확인</u-button>
      </div>
    </template>
  </u-card>
</template>
```

---

## 카드 레이아웃 패턴

### 그리드 레이아웃

```vue
<template>
  <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
    <u-card v-for="item in items" :key="item.id">
      <h4 class="text-sm font-semibold text-neutral-800">{{ item.title }}</h4>
      <p class="text-sm text-neutral-600 mt-2">{{ item.description }}</p>
    </u-card>
  </div>
</template>
```

### 스택 레이아웃

```vue
<template>
  <div class="space-y-4">
    <u-card v-for="item in items" :key="item.id">
      <div class="flex items-center gap-4">
        <div class="flex-1">
          <h4 class="text-sm font-semibold text-neutral-800">{{ item.title }}</h4>
          <p class="text-xs text-neutral-500 mt-1">{{ item.description }}</p>
        </div>
        <u-button size="sm" variant="soft">보기</u-button>
      </div>
    </u-card>
  </div>
</template>
```

---

## 통계 카드

```vue
<template>
  <u-card>
    <div class="flex items-center justify-between">
      <div>
        <p class="text-xs text-neutral-500">총 매출</p>
        <p class="text-2xl font-semibold text-neutral-900 mt-1">₩12,345,678</p>
        <p class="text-xs text-success-600 mt-1">
          <span>+12.5%</span> 전월 대비
        </p>
      </div>
      <div class="w-10 h-10 bg-primary-50 rounded-lg flex items-center justify-center">
        <icon name="i-heroicons-currency-dollar" class="w-5 h-5 text-primary-500" />
      </div>
    </div>
  </u-card>
</template>
```

---

## 인터랙티브 카드

### 클릭 가능한 카드

```vue
<template>
  <u-card
    class="cursor-pointer hover:shadow transition-shadow duration-150"
    @click="handleClick"
  >
    <h4 class="text-sm font-semibold text-neutral-800">클릭 가능한 카드</h4>
    <p class="text-xs text-neutral-500 mt-1">클릭하면 상세 페이지로 이동</p>
  </u-card>
</template>
```

### 선택 가능한 카드

```vue
<template>
  <u-card
    :class="[
      'cursor-pointer transition-all duration-150',
      isSelected
        ? 'ring-2 ring-primary-500 border-primary-500'
        : 'hover:border-neutral-300'
    ]"
    @click="isSelected = !isSelected"
  >
    <div class="flex items-center gap-3">
      <div
        :class="[
          'w-5 h-5 rounded-full border-2 flex items-center justify-center',
          isSelected ? 'border-primary-500 bg-primary-500' : 'border-neutral-300'
        ]"
      >
        <icon v-if="isSelected" name="i-heroicons-check" class="w-3 h-3 text-white" />
      </div>
      <span class="text-sm text-neutral-700">선택 가능한 카드</span>
    </div>
  </u-card>
</template>
```

---

## Skeleton 로딩

```vue
<template>
  <u-card v-if="loading">
    <div class="space-y-3">
      <div class="h-4 w-3/4 bg-neutral-200 rounded animate-pulse"></div>
      <div class="h-4 w-1/2 bg-neutral-200 rounded animate-pulse"></div>
      <div class="h-4 w-5/6 bg-neutral-200 rounded animate-pulse"></div>
    </div>
  </u-card>
</template>
```

---

## 커스텀 스타일링 (TailwindCSS)

```vue
<template>
  <div
    class="
      bg-white
      border border-neutral-200
      rounded-lg
      p-4
      shadow-sm
    "
  >
    <h3 class="text-sm font-semibold text-neutral-800">카드 제목</h3>
    <p class="text-sm text-neutral-600 mt-2">카드 내용</p>
  </div>
</template>
```

---

## 접근성 체크리스트

- [ ] 클릭 가능한 카드: `role="button"`, `tabindex="0"`
- [ ] 키보드 접근: Enter/Space로 클릭
- [ ] 선택 상태: `aria-selected` 사용

```vue
<template>
  <u-card
    role="button"
    tabindex="0"
    :aria-selected="isSelected"
    @click="handleClick"
    @keydown.enter="handleClick"
    @keydown.space.prevent="handleClick"
  >
    인터랙티브 카드
  </u-card>
</template>
```

---

## 금지 패턴

```vue
<!-- 금지: 과도한 그림자 -->
<div class="shadow-xl shadow-2xl">금지</div>

<!-- 금지: 그라데이션 배경 -->
<div class="bg-gradient-to-r from-blue-100 to-purple-100">금지</div>

<!-- 금지: 과도한 둥근 모서리 -->
<div class="rounded-3xl">금지</div>

<!-- 금지: 확대 효과 -->
<div class="hover:scale-105 transform">금지</div>
```

---

## 권장 패턴

```vue
<template>
  <!-- 기본 카드 -->
  <u-card>내용</u-card>

  <!-- 호버 효과 (미묘하게) -->
  <u-card class="hover:shadow transition-shadow duration-150">
    클릭 가능
  </u-card>

  <!-- 선택 상태 -->
  <u-card class="ring-2 ring-primary-500 border-primary-500">
    선택됨
  </u-card>

  <!-- 패널형 카드 (테두리 없음) -->
  <div class="bg-neutral-50 rounded-lg p-4">
    배경 패널
  </div>
</template>
```

---

## 실제 사용 예시

### 대시보드 통계 카드

```vue
<template>
  <div class="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4">
    <u-card v-for="stat in stats" :key="stat.label">
      <div class="flex items-center justify-between">
        <div>
          <p class="text-xs text-neutral-500">{{ stat.label }}</p>
          <p class="text-xl font-semibold text-neutral-900 mt-1">{{ stat.value }}</p>
        </div>
        <div class="w-10 h-10 bg-primary-50 rounded-lg flex items-center justify-center">
          <icon :name="stat.icon" class="w-5 h-5 text-primary-500" />
        </div>
      </div>
    </u-card>
  </div>
</template>
```

### 상세 페이지 정보 카드

```vue
<template>
  <u-card>
    <template #header>
      <h3 class="text-base font-semibold text-neutral-800">기본 정보</h3>
    </template>

    <dl class="space-y-3">
      <div class="flex">
        <dt class="w-24 text-sm text-neutral-500">이름</dt>
        <dd class="text-sm text-neutral-900">홍길동</dd>
      </div>
      <div class="flex">
        <dt class="w-24 text-sm text-neutral-500">이메일</dt>
        <dd class="text-sm text-neutral-900">hong@example.com</dd>
      </div>
    </dl>
  </u-card>
</template>
```
