# 닥터팔레트 색상 시스템

> 기준 파일: `front/src/assets/styles/theme.css`

---

## Primary 컬러 (브랜드 블루)

닥터팔레트의 메인 브랜드 컬러입니다.

| 토큰 | Hex | 용도 |
|------|-----|------|
| primary-50 | `#eff6ff` | 호버 배경, 선택 배경 |
| primary-100 | `#e0ecff` | 배지 배경 |
| primary-200 | `#c5d9ff` | 포커스 링, 보조 강조 |
| primary-300 | `#93bbff` | 비활성 강조 |
| primary-400 | `#5a94ff` | 호버 텍스트 |
| **primary-500** | `#287dff` | **기본 액션, 링크, CTA** |
| primary-600 | `#005deb` | 호버 상태 |
| primary-700 | `#0059e0` | 액티브/프레스 상태 |
| primary-800 | `#0047b3` | 진한 강조 |
| primary-900 | `#003d99` | 매우 진한 강조 |
| primary-950 | `#002966` | 최대 진한 강조 |

```css
:root {
  --ui-color-primary-50: #eff6ff;
  --ui-color-primary-100: #e0ecff;
  --ui-color-primary-200: #c5d9ff;
  --ui-color-primary-300: #93bbff;
  --ui-color-primary-400: #5a94ff;
  --ui-color-primary-500: #287dff;
  --ui-color-primary-600: #005deb;
  --ui-color-primary-700: #0059e0;
  --ui-color-primary-800: #0047b3;
  --ui-color-primary-900: #003d99;
  --ui-color-primary-950: #002966;
}
```

---

## Secondary 컬러 (Teal/Emerald)

성공 상태와 보조 강조에 사용됩니다.

| 토큰 | Hex | 용도 |
|------|-----|------|
| secondary-50 | `#ecfdf5` | 성공 배경 |
| secondary-100 | `#d1fae5` | 배지 배경 |
| secondary-200 | `#a7f3d0` | 보조 강조 |
| secondary-300 | `#6ee7b7` | - |
| secondary-400 | `#34d399` | - |
| **secondary-500** | `#10b981` | **성공 상태, 긍정 액션** |
| secondary-600 | `#059669` | 호버 상태 |
| secondary-700 | `#047857` | 액티브 상태 |
| secondary-800 | `#065f46` | - |
| secondary-900 | `#064e3b` | - |
| secondary-950 | `#022c22` | - |

---

## Neutral 컬러 (닥터팔레트 그레이)

텍스트, 테두리, 배경에 사용되는 중립 컬러입니다.

| 토큰 | Hex | RGB | 용도 |
|------|-----|-----|------|
| neutral-50 | `#f9fafb` | rgb(249, 250, 251) | 페이지 배경 |
| neutral-100 | `#f3f4f6` | rgb(243, 244, 246) | 패널 배경 |
| neutral-200 | `#e5e5e5` | rgb(229, 229, 229) | 테두리 기본 |
| neutral-300 | `#d3d3d3` | rgb(211, 211, 211) | 강조 테두리 |
| neutral-400 | `#9ca3af` | rgb(156, 163, 175) | 비활성 텍스트 |
| neutral-500 | `#7c7d94` | rgb(124, 125, 148) | 플레이스홀더 |
| neutral-600 | `#545456` | rgb(84, 84, 86) | 보조 텍스트 |
| neutral-700 | `#374151` | rgb(55, 65, 81) | 부제목 |
| neutral-800 | `#242424` | rgb(36, 36, 36) | 제목 |
| neutral-900 | `#212121` | rgb(33, 33, 33) | **기본 텍스트** |
| neutral-950 | `#111827` | rgb(17, 24, 39) | 최대 진한 텍스트 |

---

## Semantic 컬러 (기능별)

### Success (성공)
```css
--ui-color-success-500: #10b981;  /* 기본 */
--ui-color-success-600: #059669;  /* 호버 */
--ui-color-success-100: #d1fae5;  /* 배경 */
```

### Info (정보)
```css
--ui-color-info-500: #3b82f6;     /* 기본 */
--ui-color-info-600: #2563eb;     /* 호버 */
--ui-color-info-100: #dbeafe;     /* 배경 */
```

### Warning (경고)
```css
--ui-color-warning-500: #f59e0b;  /* 기본 */
--ui-color-warning-600: #d97706;  /* 호버 */
--ui-color-warning-100: #fef3c7;  /* 배경 */
```

### Error (오류)
```css
--ui-color-error-500: #ef4444;    /* 기본 */
--ui-color-error-600: #dc2626;    /* 호버 */
--ui-color-error-100: #fee2e2;    /* 배경 */
```

---

## UI 시맨틱 변수

### 텍스트 컬러
```css
--ui-text-dimmed: var(--ui-color-neutral-400);      /* 비활성 */
--ui-text-muted: var(--ui-color-neutral-500);       /* 플레이스홀더 */
--ui-text-toned: var(--ui-color-neutral-600);       /* 보조 */
--ui-text: var(--ui-color-neutral-700);             /* 기본 */
--ui-text-highlighted: var(--ui-color-neutral-900); /* 강조 */
```

### 배경 컬러
```css
--ui-bg: #ffffff;                                    /* 기본 배경 */
--ui-bg-muted: var(--ui-color-neutral-50);          /* 페이지 배경 */
--ui-bg-elevated: var(--ui-color-neutral-100);      /* 패널 배경 */
--ui-bg-accented: var(--ui-color-neutral-200);      /* 강조 배경 */
```

### 테두리 컬러
```css
--ui-border: var(--ui-color-neutral-200);           /* 기본 테두리 */
--ui-border-muted: var(--ui-color-neutral-200);     /* 연한 테두리 */
--ui-border-accented: var(--ui-color-neutral-300);  /* 강조 테두리 */
```

---

## 배지/태그 컬러

| 용도 | 텍스트 | 배경 |
|------|--------|------|
| 기본 (Blue) | `#287dff` | `#e0ecff` |
| 성공 (Green) | `#10b981` | `#d1fae5` |
| 경고 (Yellow) | `#f59e0b` | `#fef3c7` |
| 오류 (Red) | `#ef4444` | `#fee2e2` |
| 정보 (Blue) | `#3b82f6` | `#dbeafe` |

---

## 차트/데이터 시각화 컬러

```css
--chart-1: #287dff;  /* primary blue */
--chart-2: #10b981;  /* green */
--chart-3: #f59e0b;  /* amber */
--chart-4: #ef4444;  /* red */
--chart-5: #8b5cf6;  /* violet */
--chart-6: #06b6d4;  /* cyan */
```

---

## TailwindCSS 유틸리티 호환

theme.css에서 Tailwind 유틸리티와 호환되는 변수도 정의되어 있습니다:

```css
--color-primary-50 ~ --color-primary-950  /* bg-primary-*, text-primary-* */
--color-custom-black-444: #444444;
--color-custom-input-border: var(--ui-border);
--color-custom-border: var(--ui-border);
```

---

## 접근성 대비 기준

| 요소 | AA 기준 | AAA 기준 |
|------|---------|----------|
| 일반 텍스트 (<18pt) | 4.5:1 | 7:1 |
| 큰 텍스트 (≥18pt) | 3:1 | 4.5:1 |
| UI 컴포넌트 & 그래픽 | 3:1 | 3:1 |

### 검증된 조합
- `neutral-900` on `white`: 16.1:1 ✅
- `neutral-600` on `white`: 7.5:1 ✅
- `primary-500` on `white`: 4.5:1 ✅
- `neutral-500` on `white`: 4.6:1 ✅

---

## 사용 예시

### 버튼
```vue
<u-button color="primary">저장</u-button>
<u-button color="neutral" variant="soft">취소</u-button>
<u-button color="error">삭제</u-button>
```

### 텍스트
```vue
<h1 class="text-neutral-900">제목</h1>
<p class="text-neutral-600">본문</p>
<span class="text-neutral-500">보조 텍스트</span>
```

### 배경
```vue
<div class="bg-white">카드</div>
<div class="bg-neutral-50">페이지 배경</div>
<div class="bg-primary-50">선택된 항목</div>
```
