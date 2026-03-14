# 애니메이션 & 마이크로 인터랙션 가이드 (2024-2025)

## 핵심 트렌드

- **CSS Scroll-Driven Animations**: Chrome 116+, Safari 26 beta 지원
- **Reduced Motion**: 접근성 필수 대응
- **마이크로 인터랙션**: 피드백 중심의 미묘한 움직임

---

## 애니메이션 타이밍 기준

| 용도 | 시간 | 설명 |
|------|------|------|
| 마이크로 인터랙션 | 100-300ms | 버튼 호버, 토글 등 |
| 페이지 전환 | 300-500ms | 라우트 변경, 모달 열기 |
| 복잡한 애니메이션 | 500-800ms | 차트 로딩, 대규모 전환 |

### Easing 함수

```css
/* Material Design 표준 (권장) */
--ease-default: cubic-bezier(0.4, 0, 0.2, 1);

/* 빠른 시작 */
--ease-in: cubic-bezier(0.4, 0, 1, 1);

/* 빠른 끝 */
--ease-out: cubic-bezier(0, 0, 0.2, 1);

/* 탄성 */
--ease-bounce: cubic-bezier(0.34, 1.56, 0.64, 1);
```

---

## 스크롤 기반 애니메이션

Chrome 116+, Safari 26 beta 지원:

```css
/* 스크롤 기반 요소 등장 */
.scroll-reveal {
  animation: reveal linear both;
  animation-timeline: scroll();
  animation-range: entry 0% cover 40%;
}

@keyframes reveal {
  from {
    opacity: 0;
    transform: translateY(50px);
  }
  to {
    opacity: 1;
    transform: translateY(0);
  }
}

/* 스크롤 프로그레스 바 */
.progress-bar {
  animation: grow-progress linear;
  animation-timeline: scroll();
}

@keyframes grow-progress {
  from { width: 0%; }
  to { width: 100%; }
}
```

> **주의**: 백오피스에서는 제한적 사용 권장 (랜딩 페이지용)

---

## 백오피스 권장 애니메이션

### 모달 열기/닫기

```css
/* 모달 등장 */
@keyframes modal-enter {
  from {
    opacity: 0;
    transform: scale(0.95);
  }
  to {
    opacity: 1;
    transform: scale(1);
  }
}

.modal-enter {
  animation: modal-enter 200ms ease-out;
}

/* 오버레이 페이드 */
@keyframes overlay-enter {
  from { opacity: 0; }
  to { opacity: 1; }
}

.overlay-enter {
  animation: overlay-enter 200ms ease-out;
}
```

### 드롭다운 메뉴

```css
@keyframes dropdown-enter {
  from {
    opacity: 0;
    transform: translateY(-8px);
  }
  to {
    opacity: 1;
    transform: translateY(0);
  }
}

.dropdown-enter {
  animation: dropdown-enter 150ms ease-out;
}
```

### 토스트 알림

```css
@keyframes toast-enter {
  from {
    opacity: 0;
    transform: translateX(100%);
  }
  to {
    opacity: 1;
    transform: translateX(0);
  }
}

.toast-enter {
  animation: toast-enter 300ms ease-out;
}
```

---

## 버튼 인터랙션

### 호버 상태 (권장)

```vue
<template>
  <u-button
    class="transition-colors duration-150"
  >
    버튼
  </u-button>
</template>
```

### 금지 패턴

```vue
<!-- 금지: 과도한 확대 효과 -->
<button class="hover:scale-105 transform">금지</button>

<!-- 금지: 과도한 애니메이션 -->
<button class="animate-pulse">금지</button>
<button class="animate-bounce">금지</button>
```

---

## Skeleton 로딩

```css
.skeleton {
  background: linear-gradient(
    90deg,
    #eee 40%,
    #f5f5f5 50%,
    #eee 60%
  );
  background-size: 200% 100%;
  animation: shimmer 1.5s infinite;
}

@keyframes shimmer {
  0% { background-position: 100% 0; }
  100% { background-position: -100% 0; }
}
```

### Vue 컴포넌트

```vue
<template>
  <div v-if="loading" class="space-y-3">
    <div class="skeleton h-4 w-3/4 rounded"></div>
    <div class="skeleton h-4 w-1/2 rounded"></div>
    <div class="skeleton h-4 w-5/6 rounded"></div>
  </div>
</template>
```

---

## Reduced Motion 대응

**필수**: 접근성을 위해 반드시 구현

```css
@media (prefers-reduced-motion: reduce) {
  *,
  *::before,
  *::after {
    animation-duration: 0.01ms !important;
    transition-duration: 0.01ms !important;
    scroll-behavior: auto !important;
  }
}
```

### Vue에서 감지

```typescript
const prefersReducedMotion = window.matchMedia(
  '(prefers-reduced-motion: reduce)'
).matches;

// 조건부 애니메이션
const transitionDuration = computed(() =>
  prefersReducedMotion ? '0ms' : '200ms'
);
```

---

## TailwindCSS 트랜지션 유틸리티

### 기본 트랜지션

| 클래스 | 설명 |
|--------|------|
| `transition` | 기본 트랜지션 (color, bg, border, shadow, opacity, transform) |
| `transition-colors` | 색상만 |
| `transition-opacity` | 불투명도만 |
| `transition-transform` | 변환만 |
| `transition-all` | 모든 속성 |
| `transition-none` | 트랜지션 없음 |

### Duration

| 클래스 | 값 |
|--------|-----|
| `duration-75` | 75ms |
| `duration-100` | 100ms |
| `duration-150` | 150ms (권장) |
| `duration-200` | 200ms (권장) |
| `duration-300` | 300ms |

### 사용 예시

```vue
<template>
  <button
    class="
      bg-primary-500
      hover:bg-primary-600
      transition-colors
      duration-150
    "
  >
    버튼
  </button>
</template>
```

---

## 백오피스 애니메이션 원칙

### 사용해야 할 때
- 상태 변화 피드백 (로딩, 성공, 오류)
- 요소 등장/퇴장 (모달, 드롭다운, 토스트)
- 포커스 표시

### 사용하지 말아야 할 때
- 장식용 애니메이션
- 주의를 분산시키는 움직임
- 정보 인지를 방해하는 효과

### 권장 시간
- 즉각 피드백: 100-150ms
- 상태 전환: 150-200ms
- 복잡한 전환: 200-300ms
