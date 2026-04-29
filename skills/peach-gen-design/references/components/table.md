# 테이블 디자인 가이드

> 기준 파일: `front/src/assets/styles/theme.css`, `docs/ux-design/dr-pltt-design-system.md`

---

## 테이블 스펙 (닥터팔레트)

### 크기 가이드

| 요소 | 값 | 설명 |
|------|-----|------|
| 행 높이 (편안함) | 48-56px | 기본 권장 |
| 행 높이 (밀집) | 36-40px | 데이터 밀집 필요 시 |
| 헤더 높이 | 40-48px | - |
| 셀 패딩 | 12-16px | `px-4 py-3` |

### 스타일

```css
/* 테이블 헤더 */
.table-header {
  font-size: 12px;
  font-weight: 600;
  color: #7c7d94;            /* neutral-500 */
  text-transform: uppercase;
  letter-spacing: 0.05em;
  background-color: #f9fafb; /* neutral-50 */
}

/* 테이블 셀 */
.table-cell {
  font-size: 14px;
  color: #212121;            /* neutral-900 */
  border-bottom: 1px solid #e5e5e5;  /* neutral-200 */
}

/* 호버 상태 */
.table-row:hover {
  background-color: #f9fafb; /* neutral-50 */
}
```

---

## 반응형 패턴

| 패턴 | 설명 | 용도 |
|------|------|------|
| **Horizontal scroll** | 컨테이너 내 스크롤 | 데이터 비교 (권장) |
| Card stack | 모바일에서 카드로 변환 | 단순 데이터 |
| Priority columns | 비필수 컬럼 숨김 | 복잡한 테이블 |
| Sticky column | 첫 컬럼 고정 | ID 기반 데이터 |

---

## Pagination

표준 페이지 크기: **10, 25, 50, 100 per page**

---

## NuxtUI 테이블 사용

### 기본 테이블

```vue
<script setup>
const columns = [
  { key: 'name', label: '이름' },
  { key: 'email', label: '이메일' },
  { key: 'role', label: '역할' },
  { key: 'status', label: '상태' },
  { key: 'actions', label: '' },
];

const rows = [
  { id: 1, name: '홍길동', email: 'hong@example.com', role: '관리자', status: '활성' },
  { id: 2, name: '김철수', email: 'kim@example.com', role: '편집자', status: '활성' },
];
</script>

<template>
  <u-table :rows="rows" :columns="columns">
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
```

### 정렬 기능

```vue
<script setup>
const sort = ref({ column: 'name', direction: 'asc' as const });

const columns = [
  { key: 'name', label: '이름', sortable: true },
  { key: 'email', label: '이메일', sortable: true },
  { key: 'createdAt', label: '등록일', sortable: true },
];
</script>

<template>
  <u-table
    v-model:sort="sort"
    :rows="rows"
    :columns="columns"
  />
</template>
```

### 선택 기능

```vue
<script setup>
const selected = ref<typeof rows>([]);
</script>

<template>
  <div>
    <u-table
      v-model="selected"
      :rows="rows"
      :columns="columns"
    />

    <p class="mt-4 text-sm text-neutral-500">
      {{ selected.length }}개 선택됨
    </p>
  </div>
</template>
```

---

## 빈 상태

```vue
<template>
  <u-table :rows="rows" :columns="columns">
    <template #empty>
      <div class="text-center py-12">
        <icon name="i-heroicons-inbox" class="w-12 h-12 mx-auto text-neutral-300" />
        <p class="text-sm text-neutral-500 mt-4">데이터가 없습니다</p>
        <u-button class="mt-4" size="sm" @click="refresh">
          새로고침
        </u-button>
      </div>
    </template>
  </u-table>
</template>
```

---

## 로딩 상태

```vue
<template>
  <u-table :rows="rows" :columns="columns" :loading="isLoading">
    <template #loading>
      <div class="text-center py-12">
        <div class="w-8 h-8 mx-auto border-2 border-primary-500 border-t-transparent rounded-full animate-spin" />
        <p class="text-sm text-neutral-500 mt-4">데이터 로딩 중...</p>
      </div>
    </template>
  </u-table>
</template>
```

---

## 페이지네이션

```vue
<script setup>
const page = ref(1);
const pageSize = ref(10);
const total = ref(100);
</script>

<template>
  <div>
    <u-table :rows="paginatedRows" :columns="columns" />

    <div class="flex items-center justify-between mt-4 px-2">
      <p class="text-sm text-neutral-500">
        총 {{ total }}건 중 {{ (page - 1) * pageSize + 1 }}-{{ Math.min(page * pageSize, total) }}
      </p>

      <u-pagination
        v-model="page"
        :page-count="pageSize"
        :total="total"
      />
    </div>
  </div>
</template>
```

---

## 커스텀 스타일링 (TailwindCSS)

```vue
<template>
  <div class="overflow-x-auto">
    <table class="w-full">
      <thead>
        <tr class="border-b border-neutral-200 bg-neutral-50">
          <th
            v-for="col in columns"
            :key="col.key"
            class="px-4 py-3 text-left text-xs font-semibold text-neutral-500 uppercase tracking-wider"
          >
            {{ col.label }}
          </th>
        </tr>
      </thead>
      <tbody>
        <tr
          v-for="row in rows"
          :key="row.id"
          class="border-b border-neutral-100 hover:bg-neutral-50 transition-colors duration-150"
        >
          <td
            v-for="col in columns"
            :key="col.key"
            class="px-4 py-3 text-sm text-neutral-900"
          >
            {{ row[col.key] }}
          </td>
        </tr>
      </tbody>
    </table>
  </div>
</template>
```

---

## 반응형 테이블

### Horizontal Scroll (권장)

```vue
<template>
  <div class="overflow-x-auto">
    <u-table :rows="rows" :columns="columns" class="min-w-[800px]" />
  </div>
</template>
```

### 모바일 카드 스택

```vue
<template>
  <!-- 데스크톱: 테이블 -->
  <div class="hidden md:block">
    <u-table :rows="rows" :columns="columns" />
  </div>

  <!-- 모바일: 카드 리스트 -->
  <div class="md:hidden space-y-4">
    <u-card v-for="row in rows" :key="row.id">
      <div class="space-y-2">
        <div class="flex justify-between">
          <span class="text-xs text-neutral-500">이름</span>
          <span class="text-sm font-medium text-neutral-900">{{ row.name }}</span>
        </div>
        <div class="flex justify-between">
          <span class="text-xs text-neutral-500">이메일</span>
          <span class="text-sm text-neutral-700">{{ row.email }}</span>
        </div>
        <div class="flex justify-between">
          <span class="text-xs text-neutral-500">상태</span>
          <u-badge :color="row.status === '활성' ? 'success' : 'neutral'">
            {{ row.status }}
          </u-badge>
        </div>
      </div>
    </u-card>
  </div>
</template>
```

---

## 접근성 체크리스트

- [ ] `<caption>` 테이블 제목
- [ ] `<th>` + `scope="col|row"` 헤더
- [ ] 복잡한 테이블: `headers` 속성
- [ ] 정렬 상태: `aria-sort` 속성

```vue
<template>
  <table>
    <caption class="sr-only">사용자 목록</caption>
    <thead>
      <tr>
        <th scope="col" :aria-sort="getSortDirection('name')">이름</th>
        <th scope="col">이메일</th>
        <th scope="col">상태</th>
      </tr>
    </thead>
    <tbody>
      <tr v-for="user in users" :key="user.id">
        <td>{{ user.name }}</td>
        <td>{{ user.email }}</td>
        <td>{{ user.status }}</td>
      </tr>
    </tbody>
  </table>
</template>
```

---

## 금지 패턴

```vue
<!-- 금지: 스크롤 없는 넘치는 테이블 -->
<table class="w-full">...</table>

<!-- 금지: 테이블 헤더 없음 -->
<table>
  <tbody>...</tbody>
</table>

<!-- 금지: 과도한 호버 효과 -->
<tr class="hover:scale-105 hover:shadow-xl">...</tr>

<!-- 금지: 과도한 그림자 -->
<table class="shadow-2xl">...</table>
```

---

## 권장 패턴

```vue
<template>
  <div class="overflow-x-auto">
    <u-table
      :rows="rows"
      :columns="columns"
      :loading="isLoading"
    >
      <!-- 상태 배지 -->
      <template #status-data="{ row }">
        <u-badge :color="getStatusColor(row.status)">
          {{ row.status }}
        </u-badge>
      </template>

      <!-- 액션 버튼 -->
      <template #actions-data="{ row }">
        <div class="flex gap-1">
          <u-button size="xs" variant="ghost" icon="i-heroicons-pencil" @click="edit(row)" />
          <u-button size="xs" variant="ghost" color="error" icon="i-heroicons-trash" @click="remove(row)" />
        </div>
      </template>

      <!-- 빈 상태 -->
      <template #empty>
        <div class="text-center py-12 text-neutral-500">
          데이터가 없습니다
        </div>
      </template>
    </u-table>
  </div>

  <!-- 페이지네이션 -->
  <div class="flex justify-between items-center mt-4">
    <span class="text-sm text-neutral-500">총 {{ total }}건</span>
    <u-pagination v-model="page" :total="total" />
  </div>
</template>
```

---

## 실제 사용 예시

### 회원 목록 테이블

```vue
<script setup>
const columns = [
  { key: 'seq', label: 'No.' },
  { key: 'name', label: '이름', sortable: true },
  { key: 'email', label: '이메일' },
  { key: 'phone', label: '연락처' },
  { key: 'isUse', label: '사용여부' },
  { key: 'insertDate', label: '등록일', sortable: true },
  { key: 'actions', label: '' },
];
</script>

<template>
  <div class="space-y-4">
    <!-- 검색 영역 -->
    <div class="bg-neutral-50 rounded-lg p-4">
      <div class="grid grid-cols-1 md:grid-cols-4 gap-4">
        <u-form-field label="검색어">
          <u-input v-model="params.keyword" placeholder="이름, 이메일" />
        </u-form-field>
        <u-form-field label="사용여부">
          <u-select v-model="params.isUse" :options="useOptions" />
        </u-form-field>
        <div class="md:col-span-2 flex items-end justify-end gap-2">
          <u-button variant="soft" @click="resetSearch">초기화</u-button>
          <u-button icon="i-heroicons-magnifying-glass" @click="search">검색</u-button>
        </div>
      </div>
    </div>

    <!-- 테이블 헤더 -->
    <div class="flex justify-between items-center">
      <span class="text-sm text-neutral-500">총 {{ total }}건</span>
      <u-button icon="i-heroicons-plus">회원 등록</u-button>
    </div>

    <!-- 테이블 -->
    <div class="overflow-x-auto">
      <u-table :rows="rows" :columns="columns" :loading="isLoading">
        <template #isUse-data="{ row }">
          <u-badge :color="row.isUse === 'Y' ? 'success' : 'neutral'">
            {{ row.isUse === 'Y' ? '사용' : '미사용' }}
          </u-badge>
        </template>

        <template #actions-data="{ row }">
          <div class="flex gap-1">
            <u-button size="xs" variant="ghost" @click="goDetail(row.seq)">상세</u-button>
            <u-button size="xs" variant="ghost" @click="edit(row)">수정</u-button>
          </div>
        </template>
      </u-table>
    </div>

    <!-- 페이지네이션 -->
    <div class="flex justify-center">
      <u-pagination v-model="page" :total="total" />
    </div>
  </div>
</template>
```
