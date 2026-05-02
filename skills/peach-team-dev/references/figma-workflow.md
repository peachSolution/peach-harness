# FigmaRemote MCP 워크플로우

## 목차

- [FigmaRemote 도구 로드](#figmaremote-도구-로드)
- [Figma URL 형식](#figma-url-형식)
- [디자인 → 코드 매핑](#디자인--코드-매핑)
- [닥터팔레트 색상 기준](#닥터팔레트-색상-기준)
- [AI Slop 방지](#ai-slop-방지-금지-패턴)
- [적용 예시](#적용-예시)

## FigmaRemote 도구 로드

team-ui-dev 에이전트는 figma=[URL] 파라미터가 있을 때 FigmaRemote MCP를 활용합니다.

```bash
# 1. ToolSearch로 FigmaRemote 도구 로드 (필수)
ToolSearch: query="figma"
# → mcp__FigmaRemote__get_figma_data, mcp__FigmaRemote__download_figma_images 로드됨

# 2. Figma 파일 데이터 추출
mcp__FigmaRemote__get_figma_data(url="https://figma.com/file/xxx")

# 3. 이미지 다운로드 (필요시)
mcp__FigmaRemote__download_figma_images(url="https://figma.com/file/xxx", imageRefs=["ref1", "ref2"])
```

## Figma URL 형식

```
# 파일 전체
https://www.figma.com/file/[FILE_ID]/[FILE_NAME]

# 특정 프레임
https://www.figma.com/file/[FILE_ID]/[FILE_NAME]?node-id=[NODE_ID]

# 디자인 링크
https://www.figma.com/design/[FILE_ID]/[FILE_NAME]
```

## 디자인 → 코드 매핑

### 레이아웃 컴포넌트

| Figma 요소 | NuxtUI 컴포넌트 | 비고 |
|-----------|---------------|------|
| Frame/Section | `<div class="...">` | TailwindCSS 레이아웃 |
| Grid | `<div class="grid grid-cols-N">` | 반응형 그리드 |
| Stack (Vertical) | `<div class="flex flex-col gap-4">` | 세로 스택 |
| Stack (Horizontal) | `<div class="flex gap-4">` | 가로 스택 |

### 인터랙티브 컴포넌트

| Figma 요소 | NuxtUI 컴포넌트 | 속성 |
|-----------|---------------|------|
| Button (Primary) | `<UButton color="primary">` | `variant="solid"` |
| Button (Secondary) | `<UButton color="neutral">` | `variant="outline"` |
| Button (Danger) | `<UButton color="error">` | `variant="solid"` |
| Text Input | `<UInput>` | `placeholder`, `type` |
| Select/Dropdown | `<USelect>` | `items`, `placeholder` |
| Checkbox | `<UCheckbox>` | `label` |
| Radio | `<URadioGroup>` | `items` |
| Toggle/Switch | `<USwitch>` | `label` |
| Date Picker | `<UInput type="date">` | - |

### 데이터 표시

| Figma 요소 | NuxtUI 컴포넌트 | 비고 |
|-----------|---------------|------|
| Table | `<EasyDataTable>` | 데이터 테이블 |
| Card | `<UCard>` | 카드 레이아웃 |
| Badge/Tag | `<UBadge>` | `color`, `variant` |
| Modal/Dialog | `<UModal>` | `v-model` |
| Tabs | `<UTabs>` | `items` |
| Tooltip | `<UTooltip>` | `text` |

### 폼 컴포넌트

| Figma 요소 | NuxtUI 컴포넌트 | 비고 |
|-----------|---------------|------|
| Form Group | `<UFormField>` | `label`, `error` |
| Form | `<UForm>` | `@submit.prevent` |
| File Upload | `_common/components/file/` | 공통 파일 컴포넌트 |

## 닥터팔레트 색상 기준

```css
/* Primary */
--color-primary: #287dff;
--color-primary-hover: #1a6fe8;

/* Secondary */
--color-secondary: #10b981;

/* Neutral */
--color-neutral-50: #f9fafb;
--color-neutral-100: #f3f4f6;
--color-neutral-700: #374151;
--color-neutral-900: #111827;

/* Error */
--color-error: #ef4444;

/* Warning */
--color-warning: #f59e0b;
```

## AI Slop 방지 (금지 패턴)

Figma에서 추출해도 다음 패턴은 사용 금지:

```css
/* 금지 */
background: linear-gradient(to-right, ...); /* bg-gradient-to-* */
box-shadow: 0 20px 25px ...; /* shadow-xl, shadow-2xl */
animation: pulse ...; /* animate-pulse, animate-bounce */
transform: scale(1.05); /* hover:scale-* */
border-radius: 9999px; /* rounded-full (버튼에서만) */
```

```css
/* 대체 패턴 */
background-color: #287dff; /* 단색 배경 */
box-shadow: 0 1px 3px rgba(0,0,0,0.1); /* shadow-sm 허용 */
border: 1px solid #e5e7eb; /* border-neutral-200 */
border-radius: 6px; /* rounded-md */
```

## 적용 예시

### Figma Button → Vue 코드

```
Figma: Primary Button, Label="저장", Width=120px
↓
<UButton color="primary" class="w-[120px]">저장</UButton>
```

### Figma Form → Vue 코드

```
Figma: Input field, Label="이름", Placeholder="이름을 입력하세요"
↓
<UFormField label="이름">
  <UInput v-model="form.name" placeholder="이름을 입력하세요" />
</UFormField>
```
