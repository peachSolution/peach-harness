# 레이아웃 트렌드 가이드 (2024-2025)

## 핵심 트렌드

- **Bento Grid**: 일본 도시락에서 영감받은 모듈식 레이아웃
- **F/Z 시선 패턴**: 좌상단에 중요 데이터 배치
- **Progressive Disclosure**: 개요 먼저, 상세는 드릴다운

---

## Bento Grid 레이아웃

Apple 키노트, Figma, WhatsApp 브랜드 가이드라인에서 활용:

```css
.bento-grid {
  display: grid;
  grid-template-columns: repeat(4, 1fr);
  grid-template-rows: repeat(3, 200px);
  gap: 16px; /* 표준 간격: 16-24px */
}

.bento-item-large {
  grid-column: span 2;
  grid-row: span 2;
}

.bento-item-wide {
  grid-column: span 2;
}

.bento-item-tall {
  grid-row: span 2;
}
```

### Vue 컴포넌트 예시

```vue
<template>
  <div class="grid grid-cols-4 gap-4">
    <!-- 큰 카드 (2x2) -->
    <u-card class="col-span-2 row-span-2">
      <template #header>주요 지표</template>
      <div class="h-full">차트 영역</div>
    </u-card>

    <!-- 일반 카드 -->
    <u-card>
      <template #header>매출</template>
      <p class="text-2xl font-semibold">₩1,234,567</p>
    </u-card>

    <!-- 가로 넓은 카드 -->
    <u-card class="col-span-2">
      <template #header>최근 활동</template>
      <ul>...</ul>
    </u-card>
  </div>
</template>
```

---

## 대시보드 레이아웃 패턴

### F/Z 시선 패턴

```
┌─────────────────────────────────────────┐
│  [1] 가장 중요한 지표    [2] 보조 지표  │
├─────────────────────────────────────────┤
│  [3] 메인 차트/테이블                   │
├─────────────────────────────────────────┤
│  [4] 상세 정보          [5] 부가 정보   │
└─────────────────────────────────────────┘
```

### Progressive Disclosure

1. **개요**: 핵심 KPI, 요약 카드
2. **드릴다운**: 클릭 시 상세 드로어/모달
3. **상세 페이지**: 전체 분석 화면

---

## 스페이싱 시스템

### 4px 기준 스케일

| 토큰 | 값 | TailwindCSS |
|------|-----|-------------|
| 0.5 | 2px | `p-0.5`, `m-0.5` |
| 1 | 4px | `p-1`, `m-1` |
| 2 | 8px | `p-2`, `m-2` |
| 3 | 12px | `p-3`, `m-3` |
| 4 | 16px | `p-4`, `m-4` |
| 5 | 20px | `p-5`, `m-5` |
| 6 | 24px | `p-6`, `m-6` |
| 8 | 32px | `p-8`, `m-8` |
| 10 | 40px | `p-10`, `m-10` |
| 12 | 48px | `p-12`, `m-12` |

### 권장 간격

| 용도 | 간격 |
|------|------|
| 카드 내부 패딩 | 16-24px (`p-4` ~ `p-6`) |
| 카드 간 갭 | 16-24px (`gap-4` ~ `gap-6`) |
| 섹션 간 간격 | 32-48px (`gap-8` ~ `gap-12`) |
| 요소 간 간격 | 8-16px (`gap-2` ~ `gap-4`) |

---

## 반응형 브레이크포인트

### TailwindCSS v4 기본값

| 이름 | 최소 너비 |
|------|----------|
| `sm` | 640px |
| `md` | 768px |
| `lg` | 1024px |
| `xl` | 1280px |
| `2xl` | 1536px |

### 커스텀 브레이크포인트

```css
@theme {
  --breakpoint-3xl: 1920px;
}
```

### 백오피스 반응형 패턴

```vue
<template>
  <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-4">
    <!-- 모바일: 1열, 태블릿: 2열, 데스크톱: 4열 -->
  </div>
</template>
```

---

## 사이드바 레이아웃

### 유형별 너비

| 유형 | 너비 | 용도 |
|------|------|------|
| Full | 240-280px | 콘텐츠 앱, 대시보드 |
| Collapsed | 60-72px | 공간 절약 |
| Rail | 80px | 아이콘+레이블 하이브리드 |

### 구현 예시

```vue
<template>
  <div class="flex min-h-screen">
    <!-- 사이드바 -->
    <aside
      :class="[
        'border-r border-neutral-200 bg-white transition-all duration-200',
        isCollapsed ? 'w-16' : 'w-64'
      ]"
    >
      <nav class="p-4">
        <!-- 메뉴 아이템 -->
      </nav>
    </aside>

    <!-- 메인 콘텐츠 -->
    <main class="flex-1 p-6">
      <slot />
    </main>
  </div>
</template>
```

---

## 컨테이너 너비

### 권장 max-width

| 용도 | 너비 | TailwindCSS |
|------|------|-------------|
| 좁은 콘텐츠 | 640px | `max-w-2xl` |
| 일반 콘텐츠 | 768px | `max-w-3xl` |
| 넓은 콘텐츠 | 1024px | `max-w-5xl` |
| 대시보드 | 1280px | `max-w-7xl` |
| 전체 너비 | 100% | `max-w-full` |

---

## 백오피스 페이지 구조

```vue
<template>
  <div class="p-6">
    <!-- 페이지 헤더 -->
    <header class="mb-6">
      <h1 class="text-2xl font-semibold">페이지 제목</h1>
      <p class="text-sm text-neutral-500 mt-1">페이지 설명</p>
    </header>

    <!-- 검색/필터 영역 -->
    <section class="mb-4">
      <u-card>
        <!-- 검색 폼 -->
      </u-card>
    </section>

    <!-- 메인 콘텐츠 -->
    <section>
      <u-card>
        <!-- 테이블 또는 콘텐츠 -->
      </u-card>
    </section>
  </div>
</template>
```
