# 인쇄 디자인 상세 가이드

## 디자인 철학

**웹 디자인과 인쇄 디자인의 근본적 차이**

웹은 동적이고 상호작용적인 반면, 인쇄물은 정적이고 영구적입니다.
인쇄 디자인은 **명확성**, **가독성**, **정보 밀도**에 집중해야 합니다.

> "인쇄물은 한 번 출력되면 수정할 수 없다. 모든 정보가 첫눈에 명확해야 한다."

---

## Context7 MCP 활용 패턴

### CSS Print 문서 참조

```javascript
// @media print 최신 사양 확인
mcp__context7__resolve-library-id({
  libraryName: "MDN Web Docs",
  query: "CSS print styles page breaks"
});

mcp__context7__query-docs({
  libraryId: "/mdn/content",
  query: "@page size margin marks CSS print media query"
});
```

### 유용한 쿼리 예시

| 목적 | 쿼리 |
|------|------|
| 페이지 브레이크 | `page-break-inside avoid orphans widows` |
| @page 규칙 | `@page size margin CSS print` |
| 테이블 헤더 반복 | `thead display table-header-group print` |
| 배경색 출력 | `print-color-adjust webkit exact` |

---

## Sequential Thinking MCP 활용 패턴

### 복잡한 인쇄 레이아웃 설계

```javascript
mcp__sequential-thinking__sequentialthinking({
  thought: "1단계: 원본 데이터 구조 분석 - 테이블 컬럼, 행 수, 데이터 타입 파악",
  thoughtNumber: 1,
  totalThoughts: 5,
  nextThoughtNeeded: true
});

mcp__sequential-thinking__sequentialthinking({
  thought: "2단계: 페이지당 최적 행 수 계산 - A4 기준 약 35-40행 (헤더/푸터 제외)",
  thoughtNumber: 2,
  totalThoughts: 5,
  nextThoughtNeeded: true
});

mcp__sequential-thinking__sequentialthinking({
  thought: "3단계: 정보 우선순위 결정 - 필수 컬럼 vs 생략 가능 컬럼",
  thoughtNumber: 3,
  totalThoughts: 5,
  nextThoughtNeeded: true
});

mcp__sequential-thinking__sequentialthinking({
  thought: "4단계: 페이지 브레이크 위치 - 그룹 경계(월별, 카테고리별)에서 분리",
  thoughtNumber: 4,
  totalThoughts: 5,
  nextThoughtNeeded: true
});

mcp__sequential-thinking__sequentialthinking({
  thought: "5단계: 최종 레이아웃 - 헤더(문서 정보), 본문(테이블), 푸터(페이지 번호)",
  thoughtNumber: 5,
  totalThoughts: 5,
  nextThoughtNeeded: false
});
```

---

## 인쇄 최적화 타이포그래피

### 폰트 선택 원칙

**웹과 다른 점:**
- 웹: 화면 렌더링 최적화 (픽셀)
- 인쇄: 잉크/토너 출력 최적화 (포인트)

```css
/* 인쇄용 폰트 스택 */
font-family:
  'Noto Sans KR',      /* 한글 가독성 최고 */
  'Malgun Gothic',     /* Windows 기본 */
  'Apple SD Gothic Neo', /* macOS 기본 */
  -apple-system,
  sans-serif;
```

### 폰트 크기 체계 (포인트 단위)

| 용도 | 크기 | 비고 |
|------|------|------|
| 문서 제목 | 16-18pt | Bold, 1줄 |
| 섹션 제목 | 12-14pt | Semi-bold |
| 본문 | 10-11pt | Regular |
| 테이블 내용 | 9-10pt | Regular |
| 캡션/푸터 | 8pt | Light gray |

### 행간 (Line Height)

```css
/* 인쇄용 행간 */
body { line-height: 1.4; }      /* 본문 */
table { line-height: 1.3; }     /* 테이블 */
h1, h2 { line-height: 1.2; }    /* 제목 */
```

---

## 인쇄용 색상 시스템

### 기본 원칙

1. **고대비**: 배경과 텍스트 대비 최소 4.5:1
2. **잉크 절약**: 불필요한 배경색 최소화
3. **CMYK 고려**: RGB 색상의 CMYK 변환 시 색상 변화 고려

### 색상 팔레트

```css
:root {
  /* 텍스트 */
  --print-black: #000000;       /* 순수 검정 (주요 텍스트) */
  --print-dark: #1a1a1a;        /* 본문 텍스트 */
  --print-gray: #666666;        /* 보조 텍스트 */
  --print-light-gray: #999999;  /* 캡션, 푸터 */

  /* 강조 */
  --print-accent: #1a56db;      /* 링크, 강조 (절제 사용) */
  --print-negative: #dc2626;    /* 음수, 경고 */
  --print-positive: #059669;    /* 양수, 성공 */

  /* 배경 */
  --print-bg-white: #ffffff;
  --print-bg-light: #f8f9fa;    /* 헤더 배경 */
  --print-bg-alt: #f1f3f4;      /* 교차 행 */

  /* 테두리 */
  --print-border-dark: #1a1a1a;
  --print-border-medium: #adb5bd;
  --print-border-light: #dee2e6;
}
```

### 색상 사용 가이드

| 요소 | 색상 | 이유 |
|------|------|------|
| 문서 제목 | #000000 | 최대 가시성 |
| 본문 텍스트 | #1a1a1a | 부드러운 검정 |
| 테이블 헤더 | 배경 #f1f3f4 + 텍스트 #1a1a1a | 구분 명확 |
| 음수 금액 | #dc2626 | 주의 환기 |
| 합계 행 | 배경 #e9ecef | 시각적 강조 |

---

## 레이아웃 시스템

### A4 용지 기준

```css
@page {
  size: A4;           /* 210mm x 297mm */
  margin: 10mm;       /* 상하좌우 여백 */
}

/* 인쇄 가능 영역: 190mm x 277mm */
```

### 콘텐츠 영역 분배

```
┌──────────────────────────────────────┐
│          문서 헤더 (15mm)            │
│  ┌────────────────────────────────┐  │
│  │    타이틀 + 메타 정보           │  │
│  └────────────────────────────────┘  │
├──────────────────────────────────────┤
│          요약 박스 (20mm)            │
│  ┌────────────────────────────────┐  │
│  │    핵심 KPI / 요약 데이터       │  │
│  └────────────────────────────────┘  │
├──────────────────────────────────────┤
│                                      │
│          본문 테이블                  │
│          (가변, ~230mm)              │
│                                      │
├──────────────────────────────────────┤
│          푸터 (10mm)                 │
│    페이지 번호 / 인쇄 일시           │
└──────────────────────────────────────┘
```

### 페이지 브레이크 제어

```css
/* 분리 금지 */
.avoid-break {
  page-break-inside: avoid;
  break-inside: avoid;
}

/* 요소 앞에서 새 페이지 */
.page-break-before {
  page-break-before: always;
  break-before: page;
}

/* 요소 뒤에서 새 페이지 */
.page-break-after {
  page-break-after: always;
  break-after: page;
}

/* 고아/과부 줄 방지 */
p, li {
  orphans: 3;  /* 페이지 끝에 최소 3줄 */
  widows: 3;   /* 페이지 시작에 최소 3줄 */
}
```

---

## 테이블 디자인

### 기본 구조

```css
.print-table {
  width: 100%;
  border-collapse: collapse;
  font-size: 9pt;
}

/* 헤더 반복 (여러 페이지) */
.print-table thead {
  display: table-header-group;
}

.print-table tfoot {
  display: table-footer-group;
}
```

### 스타일 패턴

#### 패턴 1: 클래식 (기본)

```css
.table-classic th {
  background: #f1f3f4;
  border-top: 2px solid #1a1a1a;
  border-bottom: 1px solid #1a1a1a;
  padding: 3mm 2mm;
}

.table-classic td {
  border-bottom: 1px solid #dee2e6;
  padding: 2.5mm 2mm;
}
```

#### 패턴 2: 미니멀

```css
.table-minimal th {
  border-bottom: 2px solid #1a1a1a;
  padding: 2mm;
  font-weight: 600;
}

.table-minimal td {
  border-bottom: 1px solid #e9ecef;
  padding: 2mm;
}
```

#### 패턴 3: 줄무늬

```css
.table-striped tbody tr:nth-child(even) {
  background: #f8f9fa;
}
```

---

## 숫자/금액 표시

### 포맷팅 규칙

```javascript
// 금액 포맷 (천단위 콤마)
const formatAmount = (value) => {
  return value.toLocaleString('ko-KR');
};

// 음수 표시 (빨간색 + 괄호)
const formatNegative = (value) => {
  if (value < 0) {
    return `(${Math.abs(value).toLocaleString()})`;
  }
  return value.toLocaleString();
};
```

### CSS 스타일

```css
/* 숫자 정렬 */
.number {
  text-align: right;
  font-variant-numeric: tabular-nums;  /* 고정폭 숫자 */
}

/* 음수 강조 */
.negative {
  color: #dc2626;
  font-weight: 600;
}

/* 합계 강조 */
.total {
  font-weight: 700;
  border-top: 2px solid #1a1a1a;
}
```

---

## 접근성 고려사항

### 색맹 대응

```css
/* 색상만으로 정보 전달 금지 */
/* 아이콘 또는 텍스트 라벨 병행 */

.negative {
  color: #dc2626;
}
.negative::before {
  content: "▼ ";  /* 시각적 보조 */
}

.positive {
  color: #059669;
}
.positive::before {
  content: "▲ ";
}
```

### 대비 확보

```css
/* 최소 대비 4.5:1 */
/* 배경 #ffffff 기준 */

.text-primary { color: #1a1a1a; }   /* 대비 16.1:1 ✓ */
.text-secondary { color: #666666; } /* 대비 5.7:1 ✓ */
.text-muted { color: #999999; }     /* 대비 2.8:1 ✗ (캡션만) */
```

---

## 체크리스트

### 인쇄 전 확인사항

- [ ] 모든 텍스트 가독성 확인 (9pt 이상)
- [ ] 숫자 정렬 확인 (우측 정렬, 고정폭)
- [ ] 색상 대비 확인 (4.5:1 이상)
- [ ] 페이지 브레이크 위치 확인
- [ ] 테이블 헤더 반복 확인
- [ ] 배경색 출력 설정 확인
- [ ] 여백 설정 확인 (10mm 이상)
- [ ] 불필요한 요소 숨김 처리

### @media print 필수 설정

```css
@media print {
  /* 배경색 출력 강제 */
  * {
    -webkit-print-color-adjust: exact !important;
    print-color-adjust: exact !important;
  }

  /* 링크 URL 숨김 */
  a[href]::after {
    content: none !important;
  }

  /* 그림자 제거 */
  * {
    box-shadow: none !important;
  }
}
```
