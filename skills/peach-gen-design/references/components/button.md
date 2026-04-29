# 버튼 (Button) 디자인 가이드

> 기준 파일: `front/src/assets/styles/theme.css`, `docs/ux-design/dr-pltt-design-system.md`

---

## 버튼 스펙 (닥터팔레트)

### Primary 버튼

```css
.btn-primary {
  background-color: #287dff;
  color: #ffffff;
  border: none;
  border-radius: 6px;
  padding: 10px 20px;
  font-size: 14px;
  font-weight: 500;
  cursor: pointer;
  transition: background-color 0.15s ease;
}

.btn-primary:hover {
  background-color: #005deb;
}

.btn-primary:active {
  background-color: #0059e0;
}
```

### Secondary 버튼

```css
.btn-secondary {
  background-color: #ffffff;
  color: #545456;
  border: 1px solid #d3d3d3;
  border-radius: 6px;
  padding: 10px 20px;
  font-size: 14px;
  font-weight: 500;
  cursor: pointer;
  transition: all 0.15s ease;
}

.btn-secondary:hover {
  border-color: #287dff;
  color: #287dff;
}
```

### Ghost 버튼

```css
.btn-ghost {
  background-color: transparent;
  color: #545456;
  border: none;
  padding: 8px 12px;
  font-size: 14px;
  cursor: pointer;
}

.btn-ghost:hover {
  background-color: #f3f4f6;
}
```

---

## 사이즈 스케일

| Size | Height | Padding | Font | Radius |
|------|--------|---------|------|--------|
| xs | 24px | px-2 | 12px | 4px |
| sm | 32px | px-3 | 13px | 4px |
| md | 40px | px-4 (10px 20px) | 14px | 6px |
| lg | 44px | px-6 | 16px | 8px |

---

## 상태 디자인

| State | 처리 방식 |
|-------|----------|
| Default | 기본 색상 |
| Hover | `#005deb` (primary-600), 150ms transition |
| Active | `#0059e0` (primary-700) |
| Disabled | `opacity: 0.5`, `pointer-events: none` |
| Loading | 스피너 아이콘, 상호작용 비활성화 |
| Focus | `box-shadow: 0 0 0 3px rgba(40, 125, 255, 0.1)` |

---

## NuxtUI 버튼 사용

### 기본 사용

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
</template>
```

### 사이즈

```vue
<template>
  <u-button size="xs">아주 작게</u-button>
  <u-button size="sm">작게</u-button>
  <u-button size="md">기본</u-button>
  <u-button size="lg">크게</u-button>
</template>
```

### 아이콘 버튼

```vue
<template>
  <!-- 아이콘만 -->
  <u-button icon="i-heroicons-plus" aria-label="추가" />

  <!-- 아이콘 + 텍스트 -->
  <u-button icon="i-heroicons-plus">추가</u-button>

  <!-- 텍스트 + 아이콘 (trailing) -->
  <u-button trailing-icon="i-heroicons-arrow-right">다음</u-button>
</template>
```

### 로딩 상태

```vue
<template>
  <u-button :loading="isLoading" :disabled="isLoading">
    {{ isLoading ? '저장 중...' : '저장' }}
  </u-button>
</template>
```

---

## 버튼 그룹

```vue
<template>
  <!-- 기본 그룹 -->
  <div class="flex gap-2">
    <u-button variant="soft">취소</u-button>
    <u-button>확인</u-button>
  </div>

  <!-- 오른쪽 정렬 -->
  <div class="flex justify-end gap-2">
    <u-button variant="soft">취소</u-button>
    <u-button>저장</u-button>
  </div>
</template>
```

---

## 버튼 계층 (Visual Hierarchy)

| 계층 | 용도 | NuxtUI | 스타일 |
|------|------|--------|--------|
| Primary | 주요 액션 (저장, 확인) | `<u-button>` | 채워진 배경, `#287dff` |
| Secondary | 보조 액션 (취소, 이전) | `<u-button variant="soft">` | 연한 배경 |
| Tertiary | 부가 액션 (더보기, 링크) | `<u-button variant="ghost">` | 투명 배경 |
| Outline | 보조 액션 | `<u-button variant="outline">` | 테두리만 |
| Destructive | 삭제, 위험 액션 | `<u-button color="error">` | 빨간색 계열 |

---

## 커스텀 스타일링 (TailwindCSS)

```vue
<template>
  <button
    class="
      inline-flex items-center justify-center
      h-10 px-5
      text-sm font-medium
      text-white bg-primary-500
      hover:bg-primary-600
      active:bg-primary-700
      focus-visible:outline-none
      focus-visible:ring-2
      focus-visible:ring-primary-200
      disabled:opacity-50
      disabled:pointer-events-none
      rounded-md
      transition-colors duration-150
    "
  >
    버튼
  </button>
</template>
```

---

## 접근성 체크리스트

- [ ] 아이콘만 있는 버튼: `aria-label` 필수
- [ ] 토글 버튼: `aria-pressed` 사용
- [ ] 로딩 버튼: `aria-disabled="true"` + `aria-live` 알림
- [ ] 최소 타겟 사이즈: 24×24px (WCAG 2.5.8)
- [ ] 포커스 인디케이터: ring, 4.5:1 대비

```vue
<template>
  <!-- 아이콘 버튼 -->
  <u-button icon="i-heroicons-magnifying-glass" aria-label="검색" />

  <!-- 토글 버튼 -->
  <u-button
    :aria-pressed="isActive"
    @click="isActive = !isActive"
  >
    {{ isActive ? '활성' : '비활성' }}
  </u-button>
</template>
```

---

## 금지 패턴

```vue
<!-- 금지: 확대 효과 -->
<button class="hover:scale-105 transform">금지</button>

<!-- 금지: 과도한 둥근 모서리 (버튼) -->
<button class="rounded-full">금지</button>

<!-- 금지: 그라데이션 배경 -->
<button class="bg-gradient-to-r from-blue-500 to-purple-500">금지</button>

<!-- 금지: 과도한 그림자 -->
<button class="shadow-xl">금지</button>

<!-- 금지: 애니메이션 -->
<button class="animate-pulse">금지</button>
```

---

## 권장 패턴

```vue
<template>
  <!-- 기본 CTA -->
  <u-button color="primary">저장</u-button>

  <!-- 보조 액션 -->
  <u-button color="neutral" variant="soft">취소</u-button>

  <!-- 삭제 -->
  <u-button color="error" variant="soft">삭제</u-button>

  <!-- 링크 스타일 -->
  <u-button variant="ghost">더보기</u-button>

  <!-- 폼 하단 버튼 그룹 -->
  <div class="flex justify-end gap-2 mt-6">
    <u-button variant="soft" @click="cancel">취소</u-button>
    <u-button :loading="isSubmitting" @click="submit">저장</u-button>
  </div>
</template>
```

---

## 실제 사용 예시

### 목록 페이지 상단

```vue
<template>
  <div class="flex justify-between items-center mb-4">
    <h1 class="text-2xl font-bold text-neutral-900">회원 목록</h1>
    <u-button icon="i-heroicons-plus">회원 등록</u-button>
  </div>
</template>
```

### 테이블 액션

```vue
<template>
  <div class="flex gap-1">
    <u-button size="xs" variant="ghost" icon="i-heroicons-pencil" aria-label="수정" />
    <u-button size="xs" variant="ghost" color="error" icon="i-heroicons-trash" aria-label="삭제" />
  </div>
</template>
```

### 모달 푸터

```vue
<template>
  <div class="flex justify-end gap-2">
    <u-button variant="soft" @click="close">취소</u-button>
    <u-button @click="confirm">확인</u-button>
  </div>
</template>
```
