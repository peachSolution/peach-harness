# 닥터팔레트 타이포그래피 시스템

> 기준 파일: `front/src/assets/styles/theme.css`

---

## 폰트 패밀리

### 기본 폰트 (Pretendard)

```css
--font-family-base: 'Pretendard', -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
```

Pretendard는 한글과 영문 모두 최적화된 Variable Font입니다.

### 폰트 설정
```css
@theme {
  --font-sans: 'Pretendard', system-ui, sans-serif;
  --font-display: 'Pretendard', sans-serif;
  --font-mono: 'JetBrains Mono', monospace;
}
```

---

## 폰트 사이즈 스케일

| 토큰 | 크기 | Line Height | 용도 |
|------|------|-------------|------|
| `xs` | 12px | 1.4 | 캡션, 메타 정보, 타임스탬프 |
| `sm` | 13px | 1.5 | 보조 정보, 작은 본문 |
| `base` | 14px | 1.5 | **기본 본문** |
| `lg` | 16px | 1.5 | 큰 본문, 카드 헤더 |

```css
:root {
  --font-size-xs: 12px;
  --font-size-sm: 13px;
  --font-size-base: 14px;
  --font-size-lg: 16px;
}
```

---

## 텍스트 스타일

### 제목 (Headings)

| 스타일 | 크기 | Weight | Line Height | 색상 | 용도 |
|--------|------|--------|-------------|------|------|
| Heading 1 | 24px | 700 | 1.3 | neutral-900 | 페이지 제목 |
| Heading 2 | 20px | 600 | 1.4 | neutral-800 | 섹션 제목 |
| Heading 3 | 16px | 600 | 1.4 | neutral-800 | 카드 헤더 |
| Heading 4 | 14px | 600 | 1.4 | neutral-700 | 소제목 |

```vue
<!-- 페이지 제목 -->
<h1 class="text-2xl font-bold text-neutral-900">페이지 제목</h1>

<!-- 섹션 제목 -->
<h2 class="text-xl font-semibold text-neutral-800">섹션 제목</h2>

<!-- 카드 제목 -->
<h3 class="text-base font-semibold text-neutral-800">카드 제목</h3>

<!-- 소제목 -->
<h4 class="text-sm font-semibold text-neutral-700">소제목</h4>
```

### 본문 (Body)

| 스타일 | 크기 | Weight | 색상 | 용도 |
|--------|------|--------|------|------|
| Body Large | 16px | 400 | neutral-600 | 주요 콘텐츠 |
| Body | 14px | 400 | neutral-600 | **기본 본문** |
| Body Small | 13px | 400 | neutral-600 | 보조 정보 |
| Caption | 12px | 400 | neutral-500 | 메타 정보, 타임스탬프 |

```vue
<!-- 기본 본문 -->
<p class="text-sm text-neutral-600">본문 텍스트입니다.</p>

<!-- 강조 본문 -->
<p class="text-sm font-medium text-neutral-700">강조 텍스트입니다.</p>

<!-- 보조 텍스트 -->
<p class="text-xs text-neutral-500">보조 설명입니다.</p>
```

### 레이블 (Labels)

| 스타일 | 크기 | Weight | 색상 | 용도 |
|--------|------|--------|------|------|
| Label | 12px | 500 | neutral-700 | 폼 레이블, 배지 |
| Table Header | 12px | 600 | neutral-500 | 테이블 헤더 |

```vue
<!-- 폼 레이블 -->
<label class="text-xs font-medium text-neutral-700">레이블</label>

<!-- 테이블 헤더 -->
<th class="text-xs font-semibold text-neutral-500 uppercase tracking-wider">
  컬럼명
</th>
```

---

## Font Weight 가이드

| Weight | 클래스 | 값 | 용도 |
|--------|--------|-----|------|
| Regular | `font-normal` | 400 | 본문 기본 |
| Medium | `font-medium` | 500 | 레이블, 강조 |
| Semibold | `font-semibold` | 600 | 부제목, 버튼 |
| Bold | `font-bold` | 700 | 페이지 제목 |

> **주의**: 백오피스에서는 `font-bold` 이상은 페이지 제목에만 제한적으로 사용합니다.

---

## Line Height 가이드

| 용도 | Line Height | TailwindCSS |
|------|-------------|-------------|
| 제목 | 1.3 | `leading-tight` |
| 본문 | 1.5 | `leading-normal` |
| 캡션 | 1.4 | - |

---

## 실제 사용 예시

### 카드 타이포그래피

```vue
<template>
  <u-card>
    <template #header>
      <h3 class="text-base font-semibold text-neutral-800">
        카드 제목
      </h3>
    </template>

    <p class="text-sm text-neutral-600">
      카드 본문 내용입니다.
    </p>

    <p class="text-xs text-neutral-500 mt-2">
      2026-01-29 등록
    </p>
  </u-card>
</template>
```

### 폼 타이포그래피

```vue
<template>
  <u-form-field>
    <template #label>
      <span class="text-xs font-medium text-neutral-700">이메일</span>
    </template>
    <u-input v-model="email" placeholder="이메일을 입력하세요" />
    <template #hint>
      <span class="text-xs text-neutral-500">업무용 이메일을 입력하세요</span>
    </template>
  </u-form-field>
</template>
```

### 테이블 타이포그래피

```vue
<template>
  <table>
    <thead>
      <tr>
        <th class="text-xs font-semibold text-neutral-500 uppercase tracking-wider">
          이름
        </th>
      </tr>
    </thead>
    <tbody>
      <tr>
        <td class="text-sm text-neutral-900">홍길동</td>
      </tr>
    </tbody>
  </table>
</template>
```

---

## 접근성 고려사항

### 최소 폰트 크기
- 본문: 최소 14px (권장)
- 보조 텍스트: 최소 12px

### 대비
- 본문 텍스트: 4.5:1 이상
- 큰 텍스트 (18px+): 3:1 이상

### 줄 간격
- 본문: 최소 1.5
- 긴 텍스트 블록: 1.625 이상 권장

---

## 금지 패턴

```vue
<!-- 금지: 너무 작은 폰트 -->
<span class="text-[10px]">금지</span>

<!-- 금지: 너무 연한 색상 (대비 부족) -->
<p class="text-neutral-300">금지</p>

<!-- 금지: 과도한 letter-spacing -->
<p class="tracking-[0.5em]">금지</p>
```

---

## 권장 패턴

```vue
<template>
  <!-- 페이지 제목 -->
  <h1 class="text-2xl font-bold text-neutral-900">회원 관리</h1>

  <!-- 섹션 제목 -->
  <h2 class="text-xl font-semibold text-neutral-800">회원 목록</h2>

  <!-- 카드 제목 -->
  <h3 class="text-base font-semibold text-neutral-800">기본 정보</h3>

  <!-- 본문 -->
  <p class="text-sm text-neutral-600">설명 텍스트</p>

  <!-- 캡션 -->
  <span class="text-xs text-neutral-500">2026-01-29</span>

  <!-- 레이블 -->
  <label class="text-xs font-medium text-neutral-700">이름</label>
</template>
```
