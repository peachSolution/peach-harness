# 네비게이션 디자인 가이드

> 기준 파일: 대상 프로젝트의 `theme.css`와 디자인 시스템 문서

---

## 레이아웃 스펙 (닥터팔레트)

```css
:root {
  --sidebar-width: 220px;
  --header-height: 64px;
}
```

---

## 사이드바 스펙

```css
.sidebar {
  width: 220px;
  background-color: #ffffff;
  border-right: 1px solid #e5e5e5;  /* neutral-200 */
  height: 100vh;
  padding: 16px 0;
}

.sidebar-item {
  display: flex;
  align-items: center;
  gap: 12px;
  padding: 10px 16px;
  color: #545456;               /* neutral-600 */
  font-size: 14px;
  cursor: pointer;
  transition: all 0.15s ease;
}

.sidebar-item:hover {
  background-color: #f3f4f6;    /* neutral-100 */
}

.sidebar-item.active {
  background-color: #eff6ff;    /* primary-50 */
  color: #287dff;               /* primary-500 */
  border-left: 3px solid #287dff;
}

.sidebar-item-icon {
  width: 20px;
  height: 20px;
  color: inherit;
}
```

---

## 사이드바 패턴

| 유형 | 너비 | 용도 |
|------|------|------|
| **Full** | 220px | 콘텐츠 앱, 대시보드 (닥터팔레트 기본) |
| Collapsed | 60-72px | 공간 절약 |
| Rail | 80px | 아이콘+레이블 하이브리드 |

---

## 패널 레이아웃

```css
.panel-layout {
  display: grid;
  grid-template-columns: 220px 1fr 320px;
  gap: 0;
  height: 100vh;
}

/* Sidebar: 220px fixed */
/* Main Content: flexible */
/* Right Panel: 320px fixed (선택) */
```

---

## 사이드바 구현

### 기본 사이드바

```vue
<script setup>
const isCollapsed = ref(false);

const menuItems = [
  { icon: 'i-heroicons-home', label: '대시보드', to: '/' },
  { icon: 'i-heroicons-users', label: '사용자', to: '/users' },
  { icon: 'i-heroicons-document', label: '문서', to: '/documents' },
  { icon: 'i-heroicons-cog-6-tooth', label: '설정', to: '/settings' },
];
</script>

<template>
  <aside
    :class="[
      'fixed left-0 top-0 h-screen bg-white border-r border-neutral-200',
      'transition-all duration-200',
      isCollapsed ? 'w-16' : 'w-[220px]'
    ]"
  >
    <!-- 로고 -->
    <div class="h-16 flex items-center px-4 border-b border-neutral-200">
      <img v-if="!isCollapsed" src="/logo.svg" class="h-8" alt="Logo" />
      <img v-else src="/logo-icon.svg" class="h-8 mx-auto" alt="Logo" />
    </div>

    <!-- 메뉴 -->
    <nav class="py-2">
      <ul class="space-y-1">
        <li v-for="item in menuItems" :key="item.to">
          <nuxt-link
            :to="item.to"
            :class="[
              'flex items-center gap-3 mx-2 px-3 py-2.5 rounded-md',
              'text-sm text-neutral-600 hover:bg-neutral-100 hover:text-neutral-900',
              'transition-colors duration-150',
              isCollapsed && 'justify-center'
            ]"
            active-class="!bg-primary-50 !text-primary-500 border-l-3 border-primary-500"
          >
            <icon :name="item.icon" class="w-5 h-5 flex-shrink-0" />
            <span v-if="!isCollapsed">{{ item.label }}</span>
          </nuxt-link>
        </li>
      </ul>
    </nav>

    <!-- 접기 버튼 -->
    <button
      class="absolute bottom-4 right-[-12px] w-6 h-6 bg-white border border-neutral-200 rounded-full flex items-center justify-center shadow-sm"
      @click="isCollapsed = !isCollapsed"
    >
      <icon
        :name="isCollapsed ? 'i-heroicons-chevron-right' : 'i-heroicons-chevron-left'"
        class="w-4 h-4 text-neutral-500"
      />
    </button>
  </aside>
</template>
```

### 중첩 메뉴

```vue
<script setup>
const expandedMenus = ref<string[]>([]);

const menuItems = [
  { icon: 'i-heroicons-home', label: '대시보드', to: '/' },
  {
    icon: 'i-heroicons-users',
    label: '사용자 관리',
    children: [
      { label: '사용자 목록', to: '/users' },
      { label: '권한 관리', to: '/users/permissions' },
    ],
  },
  {
    icon: 'i-heroicons-document',
    label: '콘텐츠 관리',
    children: [
      { label: '게시글', to: '/content/posts' },
      { label: '카테고리', to: '/content/categories' },
    ],
  },
];

function toggleMenu(label: string) {
  const index = expandedMenus.value.indexOf(label);
  if (index === -1) {
    expandedMenus.value.push(label);
  } else {
    expandedMenus.value.splice(index, 1);
  }
}
</script>

<template>
  <nav class="py-2">
    <ul class="space-y-1">
      <li v-for="item in menuItems" :key="item.label">
        <!-- 단일 메뉴 -->
        <nuxt-link
          v-if="!item.children"
          :to="item.to"
          class="flex items-center gap-3 mx-2 px-3 py-2.5 rounded-md text-sm text-neutral-600 hover:bg-neutral-100"
          active-class="!bg-primary-50 !text-primary-500"
        >
          <icon :name="item.icon" class="w-5 h-5" />
          <span>{{ item.label }}</span>
        </nuxt-link>

        <!-- 중첩 메뉴 -->
        <div v-else>
          <button
            class="w-full flex items-center gap-3 mx-2 px-3 py-2.5 rounded-md text-sm text-neutral-600 hover:bg-neutral-100"
            @click="toggleMenu(item.label)"
          >
            <icon :name="item.icon" class="w-5 h-5" />
            <span class="flex-1 text-left">{{ item.label }}</span>
            <icon
              :name="expandedMenus.includes(item.label) ? 'i-heroicons-chevron-up' : 'i-heroicons-chevron-down'"
              class="w-4 h-4"
            />
          </button>

          <ul v-show="expandedMenus.includes(item.label)" class="ml-10 mt-1 space-y-1">
            <li v-for="child in item.children" :key="child.to">
              <nuxt-link
                :to="child.to"
                class="block px-3 py-2 rounded-md text-sm text-neutral-500 hover:bg-neutral-100 hover:text-neutral-900"
                active-class="!text-primary-500"
              >
                {{ child.label }}
              </nuxt-link>
            </li>
          </ul>
        </div>
      </li>
    </ul>
  </nav>
</template>
```

---

## 탭 네비게이션

### NuxtUI 탭

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

### 커스텀 탭

```vue
<script setup>
const activeTab = ref('basic');
const tabs = [
  { id: 'basic', label: '기본 정보' },
  { id: 'detail', label: '상세 정보' },
  { id: 'files', label: '첨부 파일' },
];
</script>

<template>
  <div>
    <!-- 탭 헤더 -->
    <div class="border-b border-neutral-200">
      <nav class="flex gap-4 px-4">
        <button
          v-for="tab in tabs"
          :key="tab.id"
          :class="[
            'relative py-3 text-sm font-medium transition-colors duration-150',
            activeTab === tab.id
              ? 'text-primary-500'
              : 'text-neutral-500 hover:text-neutral-700'
          ]"
          @click="activeTab = tab.id"
        >
          {{ tab.label }}
          <!-- 인디케이터 -->
          <span
            v-if="activeTab === tab.id"
            class="absolute bottom-0 left-0 right-0 h-0.5 bg-primary-500"
          />
        </button>
      </nav>
    </div>

    <!-- 탭 콘텐츠 -->
    <div class="p-4">
      <div v-show="activeTab === 'basic'">기본 정보</div>
      <div v-show="activeTab === 'detail'">상세 정보</div>
      <div v-show="activeTab === 'files'">첨부 파일</div>
    </div>
  </div>
</template>
```

---

## 브레드크럼

```vue
<script setup>
const breadcrumbs = [
  { label: '홈', to: '/' },
  { label: '사용자 관리', to: '/users' },
  { label: '사용자 상세' },
];
</script>

<template>
  <nav aria-label="Breadcrumb">
    <ol class="flex items-center gap-2 text-sm">
      <li v-for="(crumb, index) in breadcrumbs" :key="index" class="flex items-center gap-2">
        <nuxt-link
          v-if="crumb.to"
          :to="crumb.to"
          class="text-neutral-500 hover:text-neutral-700"
        >
          {{ crumb.label }}
        </nuxt-link>
        <span v-else class="text-neutral-900 font-medium">{{ crumb.label }}</span>

        <icon
          v-if="index < breadcrumbs.length - 1"
          name="i-heroicons-chevron-right"
          class="w-4 h-4 text-neutral-400"
        />
      </li>
    </ol>
  </nav>
</template>
```

---

## Navbar 패턴

| 패턴 | 설명 |
|------|------|
| Static | 고정 위치 없음 |
| **Sticky** | 스크롤 시 상단 고정 (닥터팔레트 기본) |
| Hide on scroll | 아래 스크롤 시 숨김, 위로 스크롤 시 표시 |

### 헤더 구현

```vue
<template>
  <header class="h-16 bg-white border-b border-neutral-200 flex items-center justify-between px-6">
    <!-- 좌측: 브레드크럼 -->
    <nav aria-label="Breadcrumb">
      <ol class="flex items-center gap-2 text-sm">
        <li class="text-neutral-500">홈</li>
        <li class="text-neutral-400">/</li>
        <li class="text-neutral-900 font-medium">대시보드</li>
      </ol>
    </nav>

    <!-- 우측: 유저 메뉴 -->
    <div class="flex items-center gap-4">
      <u-button variant="ghost" icon="i-heroicons-bell" aria-label="알림" />
      <u-dropdown :items="userMenuItems">
        <u-button variant="ghost" class="flex items-center gap-2">
          <div class="w-8 h-8 bg-primary-100 rounded-full flex items-center justify-center">
            <span class="text-sm font-medium text-primary-600">홍</span>
          </div>
          <span class="text-sm text-neutral-700">홍길동</span>
        </u-button>
      </u-dropdown>
    </div>
  </header>
</template>
```

---

## 접근성 체크리스트

- [ ] `<nav>` + `aria-label`
- [ ] 현재 페이지: `aria-current="page"`
- [ ] 드롭다운: `aria-expanded` 사용
- [ ] 키보드 접근: Tab, Enter, Space, Arrow keys

```vue
<template>
  <nav aria-label="메인 네비게이션">
    <ul>
      <li>
        <nuxt-link
          to="/dashboard"
          :aria-current="$route.path === '/dashboard' ? 'page' : undefined"
        >
          대시보드
        </nuxt-link>
      </li>
      <li>
        <button
          :aria-expanded="isMenuOpen"
          @click="toggleMenu"
        >
          설정
        </button>
        <ul v-show="isMenuOpen" role="menu">
          <li role="menuitem"><a href="/settings/profile">프로필</a></li>
          <li role="menuitem"><a href="/settings/security">보안</a></li>
        </ul>
      </li>
    </ul>
  </nav>
</template>
```

---

## 금지 패턴

```vue
<!-- 금지: aria-current 없는 현재 페이지 표시 -->
<a href="/" class="text-primary-500">현재 페이지</a>

<!-- 금지: 키보드로 접근 불가능한 드롭다운 -->
<div @mouseenter="openMenu">메뉴</div>

<!-- 금지: 과도한 애니메이션 -->
<nav class="animate-pulse">...</nav>

<!-- 금지: 과도한 그림자 -->
<aside class="shadow-2xl">...</aside>
```

---

## 권장 패턴

```vue
<template>
  <nav aria-label="메인 네비게이션">
    <ul class="space-y-1">
      <li v-for="item in menuItems" :key="item.to">
        <nuxt-link
          :to="item.to"
          :aria-current="$route.path === item.to ? 'page' : undefined"
          :class="[
            'flex items-center gap-3 px-3 py-2.5 rounded-md',
            'text-sm font-medium transition-colors duration-150',
            $route.path === item.to
              ? 'bg-primary-50 text-primary-500'
              : 'text-neutral-600 hover:bg-neutral-100 hover:text-neutral-900'
          ]"
        >
          <icon :name="item.icon" class="w-5 h-5" />
          {{ item.label }}
        </nuxt-link>
      </li>
    </ul>
  </nav>
</template>
```

---

## 실제 사용 예시

### 전체 레이아웃

```vue
<template>
  <div class="min-h-screen bg-neutral-50">
    <!-- 사이드바 -->
    <aside class="fixed left-0 top-0 w-[220px] h-screen bg-white border-r border-neutral-200">
      <!-- 로고 -->
      <div class="h-16 flex items-center px-4 border-b border-neutral-200">
        <img src="/logo.svg" class="h-8" alt="닥터팔레트" />
      </div>

      <!-- 메뉴 -->
      <nav class="py-4">
        <ul class="space-y-1">
          <li v-for="item in menuItems" :key="item.to">
            <nuxt-link
              :to="item.to"
              class="flex items-center gap-3 mx-2 px-3 py-2.5 rounded-md text-sm text-neutral-600 hover:bg-neutral-100"
              active-class="!bg-primary-50 !text-primary-500"
            >
              <icon :name="item.icon" class="w-5 h-5" />
              {{ item.label }}
            </nuxt-link>
          </li>
        </ul>
      </nav>
    </aside>

    <!-- 메인 콘텐츠 -->
    <main class="ml-[220px]">
      <!-- 헤더 -->
      <header class="h-16 bg-white border-b border-neutral-200 flex items-center justify-between px-6 sticky top-0 z-10">
        <h1 class="text-lg font-semibold text-neutral-900">대시보드</h1>
        <div class="flex items-center gap-4">
          <u-button variant="ghost" icon="i-heroicons-bell" />
        </div>
      </header>

      <!-- 페이지 콘텐츠 -->
      <div class="p-6">
        <slot />
      </div>
    </main>
  </div>
</template>
```
