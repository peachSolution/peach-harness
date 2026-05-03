# 리스트 아이템 디자인 가이드

> 기준 파일: 대상 프로젝트의 `theme.css`와 디자인 시스템 문서

---

## 리스트 아이템 스펙 (닥터팔레트)

```css
.list-item {
  display: flex;
  justify-content: space-between;
  align-items: center;
  padding: 12px 16px;
  border-bottom: 1px solid #e5e5e5;  /* neutral-200 */
  cursor: pointer;
  transition: background-color 0.15s ease;
}

.list-item:hover {
  background-color: #f9fafb;         /* neutral-50 */
}

.list-item-title {
  font-size: 14px;
  font-weight: 500;
  color: #212121;                    /* neutral-900 */
}

.list-item-meta {
  font-size: 12px;
  color: #7c7d94;                    /* neutral-500 */
}
```

---

## 기본 리스트

```vue
<template>
  <ul class="divide-y divide-neutral-200">
    <li
      v-for="item in items"
      :key="item.id"
      class="px-4 py-3 hover:bg-neutral-50 cursor-pointer transition-colors"
    >
      <div class="flex items-center justify-between">
        <div>
          <p class="text-sm font-medium text-neutral-900">{{ item.title }}</p>
          <p class="text-xs text-neutral-500 mt-0.5">{{ item.description }}</p>
        </div>
        <icon name="i-heroicons-chevron-right" class="w-5 h-5 text-neutral-400" />
      </div>
    </li>
  </ul>
</template>
```

---

## 리스트 패턴

### 단순 리스트

```vue
<template>
  <ul class="divide-y divide-neutral-200 border border-neutral-200 rounded-lg overflow-hidden">
    <li
      v-for="item in items"
      :key="item.id"
      class="px-4 py-3 hover:bg-neutral-50 cursor-pointer"
      @click="selectItem(item)"
    >
      <span class="text-sm text-neutral-900">{{ item.label }}</span>
    </li>
  </ul>
</template>
```

### 아이콘 리스트

```vue
<template>
  <ul class="divide-y divide-neutral-200">
    <li
      v-for="item in items"
      :key="item.id"
      class="flex items-center gap-3 px-4 py-3 hover:bg-neutral-50 cursor-pointer"
    >
      <div class="w-10 h-10 bg-primary-50 rounded-lg flex items-center justify-center">
        <icon :name="item.icon" class="w-5 h-5 text-primary-500" />
      </div>
      <div class="flex-1">
        <p class="text-sm font-medium text-neutral-900">{{ item.title }}</p>
        <p class="text-xs text-neutral-500">{{ item.subtitle }}</p>
      </div>
      <icon name="i-heroicons-chevron-right" class="w-5 h-5 text-neutral-400" />
    </li>
  </ul>
</template>
```

### 아바타 리스트

```vue
<template>
  <ul class="divide-y divide-neutral-200">
    <li
      v-for="user in users"
      :key="user.id"
      class="flex items-center gap-3 px-4 py-3 hover:bg-neutral-50"
    >
      <!-- 아바타 -->
      <div class="w-10 h-10 bg-primary-100 rounded-full flex items-center justify-center">
        <span class="text-sm font-medium text-primary-600">
          {{ user.name.charAt(0) }}
        </span>
      </div>

      <!-- 정보 -->
      <div class="flex-1 min-w-0">
        <p class="text-sm font-medium text-neutral-900 truncate">{{ user.name }}</p>
        <p class="text-xs text-neutral-500 truncate">{{ user.email }}</p>
      </div>

      <!-- 상태 -->
      <u-badge :color="user.isActive ? 'success' : 'neutral'" size="xs">
        {{ user.isActive ? '활성' : '비활성' }}
      </u-badge>
    </li>
  </ul>
</template>
```

### 메타 정보 리스트

```vue
<template>
  <ul class="divide-y divide-neutral-200">
    <li
      v-for="item in items"
      :key="item.id"
      class="px-4 py-3 hover:bg-neutral-50 cursor-pointer"
    >
      <div class="flex items-start justify-between">
        <div class="flex-1 min-w-0">
          <p class="text-sm font-medium text-neutral-900 truncate">{{ item.title }}</p>
          <p class="text-xs text-neutral-500 mt-1 line-clamp-2">{{ item.description }}</p>
          <div class="flex items-center gap-2 mt-2">
            <span class="text-xs text-neutral-400">{{ item.date }}</span>
            <span class="text-xs text-neutral-400">·</span>
            <span class="text-xs text-neutral-400">{{ item.author }}</span>
          </div>
        </div>
        <u-badge :color="item.status === 'published' ? 'success' : 'warning'" size="xs">
          {{ item.status === 'published' ? '게시' : '대기' }}
        </u-badge>
      </div>
    </li>
  </ul>
</template>
```

---

## 선택 가능한 리스트

### 단일 선택

```vue
<script setup>
const selected = ref<string | null>(null);
</script>

<template>
  <ul class="divide-y divide-neutral-200 border border-neutral-200 rounded-lg overflow-hidden">
    <li
      v-for="item in items"
      :key="item.id"
      :class="[
        'flex items-center gap-3 px-4 py-3 cursor-pointer transition-colors',
        selected === item.id
          ? 'bg-primary-50 border-l-2 border-primary-500'
          : 'hover:bg-neutral-50'
      ]"
      @click="selected = item.id"
    >
      <div
        :class="[
          'w-5 h-5 rounded-full border-2 flex items-center justify-center',
          selected === item.id
            ? 'border-primary-500 bg-primary-500'
            : 'border-neutral-300'
        ]"
      >
        <icon
          v-if="selected === item.id"
          name="i-heroicons-check"
          class="w-3 h-3 text-white"
        />
      </div>
      <span class="text-sm text-neutral-700">{{ item.label }}</span>
    </li>
  </ul>
</template>
```

### 다중 선택

```vue
<script setup>
const selected = ref<string[]>([]);

function toggle(id: string) {
  const index = selected.value.indexOf(id);
  if (index === -1) {
    selected.value.push(id);
  } else {
    selected.value.splice(index, 1);
  }
}
</script>

<template>
  <ul class="divide-y divide-neutral-200 border border-neutral-200 rounded-lg overflow-hidden">
    <li
      v-for="item in items"
      :key="item.id"
      :class="[
        'flex items-center gap-3 px-4 py-3 cursor-pointer transition-colors',
        selected.includes(item.id)
          ? 'bg-primary-50'
          : 'hover:bg-neutral-50'
      ]"
      @click="toggle(item.id)"
    >
      <div
        :class="[
          'w-5 h-5 rounded border-2 flex items-center justify-center',
          selected.includes(item.id)
            ? 'border-primary-500 bg-primary-500'
            : 'border-neutral-300'
        ]"
      >
        <icon
          v-if="selected.includes(item.id)"
          name="i-heroicons-check"
          class="w-3 h-3 text-white"
        />
      </div>
      <span class="text-sm text-neutral-700">{{ item.label }}</span>
    </li>
  </ul>

  <p class="text-sm text-neutral-500 mt-2">
    {{ selected.length }}개 선택됨
  </p>
</template>
```

---

## 액션 리스트

```vue
<template>
  <ul class="divide-y divide-neutral-200">
    <li
      v-for="item in items"
      :key="item.id"
      class="flex items-center justify-between px-4 py-3 hover:bg-neutral-50"
    >
      <div class="flex items-center gap-3">
        <div class="w-10 h-10 bg-neutral-100 rounded-lg flex items-center justify-center">
          <icon :name="item.icon" class="w-5 h-5 text-neutral-600" />
        </div>
        <div>
          <p class="text-sm font-medium text-neutral-900">{{ item.title }}</p>
          <p class="text-xs text-neutral-500">{{ item.description }}</p>
        </div>
      </div>

      <div class="flex items-center gap-2">
        <u-button size="xs" variant="soft" @click="edit(item)">수정</u-button>
        <u-button size="xs" variant="ghost" color="error" @click="remove(item)">삭제</u-button>
      </div>
    </li>
  </ul>
</template>
```

---

## 스위치 리스트 (설정)

```vue
<script setup>
const settings = ref({
  notifications: true,
  darkMode: false,
  autoSave: true,
});
</script>

<template>
  <ul class="divide-y divide-neutral-200">
    <li class="flex items-center justify-between px-4 py-3">
      <div>
        <p class="text-sm font-medium text-neutral-900">알림 수신</p>
        <p class="text-xs text-neutral-500">새로운 소식을 알림으로 받습니다</p>
      </div>
      <u-switch v-model="settings.notifications" />
    </li>

    <li class="flex items-center justify-between px-4 py-3">
      <div>
        <p class="text-sm font-medium text-neutral-900">다크 모드</p>
        <p class="text-xs text-neutral-500">어두운 테마를 사용합니다</p>
      </div>
      <u-switch v-model="settings.darkMode" />
    </li>

    <li class="flex items-center justify-between px-4 py-3">
      <div>
        <p class="text-sm font-medium text-neutral-900">자동 저장</p>
        <p class="text-xs text-neutral-500">변경사항을 자동으로 저장합니다</p>
      </div>
      <u-switch v-model="settings.autoSave" />
    </li>
  </ul>
</template>
```

---

## 빈 상태

```vue
<template>
  <div v-if="items.length === 0" class="text-center py-12">
    <icon name="i-heroicons-inbox" class="w-12 h-12 mx-auto text-neutral-300" />
    <p class="text-sm text-neutral-500 mt-4">데이터가 없습니다</p>
    <u-button class="mt-4" size="sm" @click="refresh">새로고침</u-button>
  </div>

  <ul v-else class="divide-y divide-neutral-200">
    <!-- 리스트 아이템 -->
  </ul>
</template>
```

---

## 로딩 상태 (Skeleton)

```vue
<template>
  <ul v-if="isLoading" class="divide-y divide-neutral-200">
    <li v-for="i in 5" :key="i" class="flex items-center gap-3 px-4 py-3">
      <div class="w-10 h-10 bg-neutral-200 rounded-lg animate-pulse"></div>
      <div class="flex-1 space-y-2">
        <div class="h-4 w-3/4 bg-neutral-200 rounded animate-pulse"></div>
        <div class="h-3 w-1/2 bg-neutral-200 rounded animate-pulse"></div>
      </div>
    </li>
  </ul>
</template>
```

---

## 그룹화된 리스트

```vue
<template>
  <div v-for="group in groupedItems" :key="group.label" class="mb-6">
    <h3 class="text-xs font-semibold text-neutral-500 uppercase tracking-wider px-4 py-2">
      {{ group.label }}
    </h3>
    <ul class="divide-y divide-neutral-200">
      <li
        v-for="item in group.items"
        :key="item.id"
        class="px-4 py-3 hover:bg-neutral-50 cursor-pointer"
      >
        <span class="text-sm text-neutral-900">{{ item.title }}</span>
      </li>
    </ul>
  </div>
</template>
```

---

## 접근성 체크리스트

- [ ] `<ul>`, `<li>` 시맨틱 태그 사용
- [ ] 클릭 가능한 리스트: `role="listbox"`, `role="option"`
- [ ] 선택 상태: `aria-selected`
- [ ] 키보드 접근: 방향키로 이동, Enter/Space로 선택

```vue
<template>
  <ul role="listbox" aria-label="사용자 선택">
    <li
      v-for="item in items"
      :key="item.id"
      role="option"
      :aria-selected="selected === item.id"
      tabindex="0"
      @click="select(item)"
      @keydown.enter="select(item)"
      @keydown.space.prevent="select(item)"
    >
      {{ item.label }}
    </li>
  </ul>
</template>
```

---

## 금지 패턴

```vue
<!-- 금지: div로만 구성된 리스트 -->
<div>
  <div>아이템 1</div>
  <div>아이템 2</div>
</div>

<!-- 금지: 과도한 호버 효과 -->
<li class="hover:scale-105 hover:shadow-xl">...</li>

<!-- 금지: 키보드 접근 불가 -->
<li @click="select">...</li>
```

---

## 권장 패턴

```vue
<template>
  <!-- 기본 리스트 -->
  <ul class="divide-y divide-neutral-200">
    <li
      v-for="item in items"
      :key="item.id"
      class="px-4 py-3 hover:bg-neutral-50 cursor-pointer transition-colors"
    >
      {{ item.label }}
    </li>
  </ul>

  <!-- 선택 가능한 리스트 -->
  <ul role="listbox" class="divide-y divide-neutral-200 border border-neutral-200 rounded-lg">
    <li
      v-for="item in items"
      :key="item.id"
      role="option"
      :aria-selected="selected === item.id"
      :class="[
        'px-4 py-3 cursor-pointer transition-colors',
        selected === item.id ? 'bg-primary-50' : 'hover:bg-neutral-50'
      ]"
      @click="selected = item.id"
    >
      {{ item.label }}
    </li>
  </ul>
</template>
```

---

## 실제 사용 예시

### Two-Depth 레이아웃 목록

```vue
<template>
  <div class="h-full overflow-y-auto">
    <!-- 검색 -->
    <div class="p-4 border-b border-neutral-200">
      <u-input v-model="keyword" placeholder="검색" icon="i-heroicons-magnifying-glass" />
    </div>

    <!-- 목록 -->
    <ul class="divide-y divide-neutral-200">
      <li
        v-for="item in filteredItems"
        :key="item.seq"
        :class="[
          'px-4 py-3 cursor-pointer transition-colors',
          selectedSeq === item.seq
            ? 'bg-primary-50 border-l-2 border-primary-500'
            : 'hover:bg-neutral-50'
        ]"
        @click="selectItem(item.seq)"
      >
        <div class="flex items-center justify-between">
          <div class="min-w-0">
            <p class="text-sm font-medium text-neutral-900 truncate">{{ item.name }}</p>
            <p class="text-xs text-neutral-500 mt-0.5">{{ item.email }}</p>
          </div>
          <u-badge :color="item.isUse === 'Y' ? 'success' : 'neutral'" size="xs">
            {{ item.isUse === 'Y' ? '사용' : '미사용' }}
          </u-badge>
        </div>
      </li>
    </ul>

    <!-- 빈 상태 -->
    <div v-if="filteredItems.length === 0" class="text-center py-12">
      <p class="text-sm text-neutral-500">검색 결과가 없습니다</p>
    </div>
  </div>
</template>
```

### 알림 목록

```vue
<template>
  <div class="w-80">
    <div class="px-4 py-3 border-b border-neutral-200">
      <h3 class="text-sm font-semibold text-neutral-900">알림</h3>
    </div>

    <ul class="divide-y divide-neutral-100 max-h-80 overflow-y-auto">
      <li
        v-for="notification in notifications"
        :key="notification.id"
        :class="[
          'px-4 py-3 hover:bg-neutral-50 cursor-pointer',
          !notification.isRead && 'bg-primary-50'
        ]"
        @click="markAsRead(notification)"
      >
        <div class="flex gap-3">
          <div
            :class="[
              'w-8 h-8 rounded-full flex items-center justify-center flex-shrink-0',
              notification.type === 'success' ? 'bg-success-100' : 'bg-info-100'
            ]"
          >
            <icon
              :name="notification.type === 'success' ? 'i-heroicons-check' : 'i-heroicons-bell'"
              :class="[
                'w-4 h-4',
                notification.type === 'success' ? 'text-success-600' : 'text-info-600'
              ]"
            />
          </div>
          <div class="min-w-0 flex-1">
            <p class="text-sm text-neutral-900 line-clamp-2">{{ notification.message }}</p>
            <p class="text-xs text-neutral-500 mt-1">{{ notification.date }}</p>
          </div>
        </div>
      </li>
    </ul>

    <div class="px-4 py-2 border-t border-neutral-200">
      <u-button variant="ghost" size="sm" class="w-full">모두 보기</u-button>
    </div>
  </div>
</template>
```
