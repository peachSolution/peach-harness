# 드롭다운 / 팝오버 디자인 가이드

> 기준 파일: 대상 프로젝트의 `theme.css`와 디자인 시스템 문서

---

## 드롭다운 스펙 (닥터팔레트)

```css
.dropdown {
  background-color: #ffffff;
  border: 1px solid #e5e5e5;    /* neutral-200 */
  border-radius: 8px;           /* radius-lg */
  box-shadow: 0 6px 12px rgba(0, 0, 0, 0.175);  /* shadow-lg */
  min-width: 200px;
}

.dropdown-item {
  padding: 12px 20px;
  font-size: 14px;
  color: #242424;               /* neutral-800 */
  cursor: pointer;
  transition: background-color 0.15s ease;
}

.dropdown-item:hover {
  background-color: #eff6ff;    /* primary-50 */
}
```

---

## NuxtUI 드롭다운 사용

### 기본 드롭다운

```vue
<script setup>
const items = [
  [
    { label: '프로필', icon: 'i-heroicons-user' },
    { label: '설정', icon: 'i-heroicons-cog-6-tooth' },
  ],
  [
    { label: '로그아웃', icon: 'i-heroicons-arrow-right-on-rectangle' },
  ],
];
</script>

<template>
  <u-dropdown :items="items">
    <u-button variant="soft" trailing-icon="i-heroicons-chevron-down">
      메뉴
    </u-button>
  </u-dropdown>
</template>
```

### 액션 핸들링

```vue
<script setup>
const items = [
  [
    {
      label: '수정',
      icon: 'i-heroicons-pencil',
      click: () => handleEdit(),
    },
    {
      label: '복제',
      icon: 'i-heroicons-document-duplicate',
      click: () => handleDuplicate(),
    },
  ],
  [
    {
      label: '삭제',
      icon: 'i-heroicons-trash',
      click: () => handleDelete(),
      class: 'text-error-500',
    },
  ],
];
</script>

<template>
  <u-dropdown :items="items">
    <u-button variant="ghost" icon="i-heroicons-ellipsis-vertical" />
  </u-dropdown>
</template>
```

### 링크 드롭다운

```vue
<script setup>
const items = [
  [
    { label: '대시보드', to: '/dashboard' },
    { label: '프로필', to: '/profile' },
    { label: '설정', to: '/settings' },
  ],
];
</script>

<template>
  <u-dropdown :items="items">
    <u-button variant="soft">
      이동
      <icon name="i-heroicons-chevron-down" class="w-4 h-4 ml-1" />
    </u-button>
  </u-dropdown>
</template>
```

---

## 커스텀 트리거

```vue
<template>
  <!-- 버튼 트리거 -->
  <u-dropdown :items="items">
    <u-button>드롭다운</u-button>
  </u-dropdown>

  <!-- 아이콘 버튼 트리거 -->
  <u-dropdown :items="items">
    <u-button variant="ghost" icon="i-heroicons-ellipsis-vertical" />
  </u-dropdown>

  <!-- 아바타 트리거 -->
  <u-dropdown :items="items">
    <button class="flex items-center gap-2 hover:bg-neutral-100 rounded-lg p-2">
      <div class="w-8 h-8 bg-primary-100 rounded-full flex items-center justify-center">
        <span class="text-sm font-medium text-primary-600">홍</span>
      </div>
      <span class="text-sm text-neutral-700">홍길동</span>
      <icon name="i-heroicons-chevron-down" class="w-4 h-4 text-neutral-500" />
    </button>
  </u-dropdown>
</template>
```

---

## 드롭다운 위치

```vue
<template>
  <!-- 기본 (아래) -->
  <u-dropdown :items="items">
    <u-button>아래로</u-button>
  </u-dropdown>

  <!-- 위로 -->
  <u-dropdown :items="items" :popper="{ placement: 'top' }">
    <u-button>위로</u-button>
  </u-dropdown>

  <!-- 왼쪽 -->
  <u-dropdown :items="items" :popper="{ placement: 'left' }">
    <u-button>왼쪽으로</u-button>
  </u-dropdown>

  <!-- 오른쪽 -->
  <u-dropdown :items="items" :popper="{ placement: 'right' }">
    <u-button>오른쪽으로</u-button>
  </u-dropdown>
</template>
```

---

## 커스텀 콘텐츠

```vue
<template>
  <u-dropdown>
    <u-button variant="soft">사용자 정보</u-button>

    <template #content>
      <div class="p-4 w-64">
        <div class="flex items-center gap-3 mb-4">
          <div class="w-12 h-12 bg-primary-100 rounded-full flex items-center justify-center">
            <span class="text-lg font-semibold text-primary-600">홍</span>
          </div>
          <div>
            <p class="text-sm font-medium text-neutral-900">홍길동</p>
            <p class="text-xs text-neutral-500">hong@example.com</p>
          </div>
        </div>

        <div class="border-t border-neutral-200 pt-3 space-y-1">
          <nuxt-link
            to="/profile"
            class="block px-3 py-2 text-sm text-neutral-700 hover:bg-neutral-100 rounded-md"
          >
            프로필
          </nuxt-link>
          <nuxt-link
            to="/settings"
            class="block px-3 py-2 text-sm text-neutral-700 hover:bg-neutral-100 rounded-md"
          >
            설정
          </nuxt-link>
        </div>

        <div class="border-t border-neutral-200 pt-3 mt-3">
          <button
            class="w-full px-3 py-2 text-sm text-left text-error-500 hover:bg-error-50 rounded-md"
            @click="logout"
          >
            로그아웃
          </button>
        </div>
      </div>
    </template>
  </u-dropdown>
</template>
```

---

## 팝오버 (Popover)

더 복잡한 콘텐츠를 표시할 때 사용:

```vue
<template>
  <u-popover>
    <u-button variant="soft">상세 정보</u-button>

    <template #content>
      <div class="p-4 w-80">
        <h4 class="text-sm font-semibold text-neutral-900 mb-2">상품 정보</h4>
        <dl class="space-y-2 text-sm">
          <div class="flex justify-between">
            <dt class="text-neutral-500">상품명</dt>
            <dd class="text-neutral-900">프리미엄 구독</dd>
          </div>
          <div class="flex justify-between">
            <dt class="text-neutral-500">가격</dt>
            <dd class="text-neutral-900">₩9,900/월</dd>
          </div>
          <div class="flex justify-between">
            <dt class="text-neutral-500">혜택</dt>
            <dd class="text-neutral-900">무제한 사용</dd>
          </div>
        </dl>
        <u-button class="w-full mt-4" size="sm">구독하기</u-button>
      </div>
    </template>
  </u-popover>
</template>
```

---

## 테이블 액션 드롭다운

```vue
<script setup>
function getActionItems(row: any) {
  return [
    [
      {
        label: '상세보기',
        icon: 'i-heroicons-eye',
        click: () => goDetail(row.seq),
      },
      {
        label: '수정',
        icon: 'i-heroicons-pencil',
        click: () => edit(row),
      },
    ],
    [
      {
        label: '삭제',
        icon: 'i-heroicons-trash',
        click: () => confirmDelete(row.seq),
        class: 'text-error-500',
      },
    ],
  ];
}
</script>

<template>
  <u-table :rows="rows" :columns="columns">
    <template #actions-data="{ row }">
      <u-dropdown :items="getActionItems(row)">
        <u-button size="xs" variant="ghost" icon="i-heroicons-ellipsis-vertical" />
      </u-dropdown>
    </template>
  </u-table>
</template>
```

---

## 커스텀 스타일링 (TailwindCSS)

```vue
<script setup>
const isOpen = ref(false);
</script>

<template>
  <div class="relative">
    <u-button @click="isOpen = !isOpen">
      메뉴
      <icon name="i-heroicons-chevron-down" class="w-4 h-4 ml-1" />
    </u-button>

    <div
      v-if="isOpen"
      class="
        absolute top-full left-0 mt-1 z-10
        w-48 bg-white border border-neutral-200
        rounded-lg shadow-lg
      "
    >
      <ul class="py-1">
        <li>
          <button
            class="w-full px-4 py-2 text-left text-sm text-neutral-700 hover:bg-primary-50"
            @click="handleAction"
          >
            액션 1
          </button>
        </li>
        <li>
          <button
            class="w-full px-4 py-2 text-left text-sm text-neutral-700 hover:bg-primary-50"
            @click="handleAction"
          >
            액션 2
          </button>
        </li>
        <li class="border-t border-neutral-100 mt-1 pt-1">
          <button
            class="w-full px-4 py-2 text-left text-sm text-error-500 hover:bg-error-50"
            @click="handleDelete"
          >
            삭제
          </button>
        </li>
      </ul>
    </div>
  </div>
</template>
```

---

## 접근성 체크리스트

- [ ] 트리거: `aria-haspopup="true"`
- [ ] 열림 상태: `aria-expanded`
- [ ] 메뉴: `role="menu"`
- [ ] 메뉴 아이템: `role="menuitem"`
- [ ] 키보드 접근: Escape로 닫기, 방향키로 이동

```vue
<template>
  <div>
    <button
      :aria-expanded="isOpen"
      aria-haspopup="true"
      @click="toggle"
      @keydown.escape="close"
    >
      메뉴
    </button>

    <ul v-show="isOpen" role="menu">
      <li role="menuitem">
        <button @click="action1">액션 1</button>
      </li>
      <li role="menuitem">
        <button @click="action2">액션 2</button>
      </li>
    </ul>
  </div>
</template>
```

> NuxtUI의 `UDropdown`은 기본적으로 접근성 요구사항을 충족합니다.

---

## 금지 패턴

```vue
<!-- 금지: 호버로만 열리는 드롭다운 (모바일 불가) -->
<div @mouseenter="open" @mouseleave="close">...</div>

<!-- 금지: 과도한 그림자 -->
<div class="shadow-2xl">...</div>

<!-- 금지: 과도한 애니메이션 -->
<div class="animate-bounce">...</div>

<!-- 금지: 키보드 접근 불가 -->
<div @click="toggle">...</div>
```

---

## 권장 패턴

```vue
<template>
  <!-- 기본 액션 드롭다운 -->
  <u-dropdown :items="items">
    <u-button variant="soft" trailing-icon="i-heroicons-chevron-down">
      액션
    </u-button>
  </u-dropdown>

  <!-- 테이블 더보기 메뉴 -->
  <u-dropdown :items="items">
    <u-button size="xs" variant="ghost" icon="i-heroicons-ellipsis-vertical" />
  </u-dropdown>

  <!-- 사용자 메뉴 -->
  <u-dropdown :items="userMenuItems">
    <button class="flex items-center gap-2 p-2 hover:bg-neutral-100 rounded-lg">
      <div class="w-8 h-8 bg-primary-100 rounded-full flex items-center justify-center">
        <span class="text-sm font-medium text-primary-600">홍</span>
      </div>
      <icon name="i-heroicons-chevron-down" class="w-4 h-4 text-neutral-500" />
    </button>
  </u-dropdown>
</template>
```

---

## 실제 사용 예시

### 헤더 사용자 메뉴

```vue
<script setup>
const userMenuItems = [
  [
    {
      label: '프로필',
      icon: 'i-heroicons-user',
      to: '/profile',
    },
    {
      label: '설정',
      icon: 'i-heroicons-cog-6-tooth',
      to: '/settings',
    },
  ],
  [
    {
      label: '로그아웃',
      icon: 'i-heroicons-arrow-right-on-rectangle',
      click: () => logout(),
    },
  ],
];

async function logout() {
  await authStore.logout();
  navigateTo('/login');
}
</script>

<template>
  <u-dropdown :items="userMenuItems">
    <button class="flex items-center gap-2 p-2 hover:bg-neutral-100 rounded-lg transition-colors">
      <div class="w-8 h-8 bg-primary-100 rounded-full flex items-center justify-center">
        <span class="text-sm font-medium text-primary-600">
          {{ userName.charAt(0) }}
        </span>
      </div>
      <span class="text-sm text-neutral-700 hidden sm:inline">{{ userName }}</span>
      <icon name="i-heroicons-chevron-down" class="w-4 h-4 text-neutral-500" />
    </button>
  </u-dropdown>
</template>
```

### 테이블 액션 메뉴

```vue
<script setup>
function getRowActions(row: any) {
  return [
    [
      {
        label: '상세보기',
        icon: 'i-heroicons-eye',
        click: () => navigateTo(`/members/${row.seq}`),
      },
      {
        label: '수정',
        icon: 'i-heroicons-pencil',
        click: () => openEditModal(row),
      },
      {
        label: '복제',
        icon: 'i-heroicons-document-duplicate',
        click: () => duplicate(row),
      },
    ],
    [
      {
        label: row.isUse === 'Y' ? '비활성화' : '활성화',
        icon: row.isUse === 'Y' ? 'i-heroicons-pause' : 'i-heroicons-play',
        click: () => toggleUse(row),
      },
    ],
    [
      {
        label: '삭제',
        icon: 'i-heroicons-trash',
        click: () => confirmDelete(row.seq),
        class: 'text-error-500',
      },
    ],
  ];
}
</script>

<template>
  <u-table :rows="rows" :columns="columns">
    <template #actions-data="{ row }">
      <u-dropdown :items="getRowActions(row)" :popper="{ placement: 'bottom-end' }">
        <u-button size="xs" variant="ghost" icon="i-heroicons-ellipsis-vertical" />
      </u-dropdown>
    </template>
  </u-table>
</template>
```
