# 시각적 품질 가이드 (AI Slop 방지)

> **"AI Slop"**: AI가 생성하는 전형적이고 진부한 시각적 패턴. 과도한 그라데이션, 보라색 계열, 예측 가능한 레이아웃 등

---

## 1. 프로젝트 스타일 시스템

### 컬러 팔레트

| 용도 | 변수명 | 값 | 사용 예시 |
|------|--------|-----|----------|
| Primary | `primary` | `#287dff` | 주요 버튼, 링크, 강조 |
| Neutral | `neutral` | `#6b7280` | 보조 텍스트, 비활성 상태 |
| Success | `success` | `#22c55e` | 성공 메시지, 완료 상태 |
| Warning | `warning` | `#f59e0b` | 경고 메시지 |
| Error | `error` | `#ef4444` | 에러, 삭제 버튼 |

**사용법**:
```vue
<!-- NuxtUI 컴포넌트 color prop 사용 -->
<u-button color="primary">저장</u-button>
<u-button color="error">삭제</u-button>
<u-badge color="success">완료</u-badge>
```

### 타이포그래피

| 요소 | 폰트 | 크기 | 용도 |
|------|------|------|------|
| 본문 | Pretendard | 14px | 일반 텍스트, 테이블 |
| 제목 | Pretendard | 16px~18px | 페이지 제목, 섹션 헤더 |
| 라벨 | Pretendard | 12px~14px | 폼 라벨, 캡션 |

### 반응형 기준

| 브레이크포인트 | 값 | 용도 |
|---------------|-----|------|
| sm | 640px | 모바일 |
| md | 768px | 태블릿 |
| lg | 1024px | 데스크톱 (기준) |
| xl | 1280px | 와이드 스크린 |

---

## 2. AI Slop 금지 패턴 상세

### 2.1 그라데이션 금지

```vue
<!-- ❌ 금지 -->
<div class="bg-gradient-to-r from-blue-500 to-purple-600">
<div class="bg-gradient-to-br from-indigo-500 via-purple-500 to-pink-500">

<!-- ✅ 허용 -->
<div class="bg-primary">
<div class="bg-white">
<u-card>  <!-- NuxtUI 컴포넌트 사용 -->
```

**이유**: 그라데이션은 AI 생성 코드의 전형적 특징. 백오피스는 단색 배경이 적합.

### 2.2 과도한 그림자 금지

```vue
<!-- ❌ 금지 -->
<div class="shadow-xl">
<div class="shadow-2xl">
<div class="drop-shadow-lg">

<!-- ✅ 허용 -->
<div class="shadow-sm">
<div class="shadow">
<u-card>  <!-- 내장 그림자 사용 -->
```

**이유**: 과도한 그림자는 시각적 노이즈. 업무용 UI는 미니멀해야 함.

### 2.3 애니메이션 금지

```vue
<!-- ❌ 금지 -->
<div class="animate-pulse">
<div class="animate-bounce">
<div class="animate-spin">  <!-- 로딩 제외 -->
<div class="transition-all duration-500">

<!-- ✅ 허용 (NuxtUI 내장 전환만) -->
<u-modal>  <!-- 내장 전환 효과 -->
<u-button :loading="true">  <!-- 로딩 스피너 -->
```

**이유**: 업무용 UI에서 장식적 애니메이션은 방해 요소.

### 2.4 확대/변형 효과 금지

```vue
<!-- ❌ 금지 -->
<button class="hover:scale-105">
<div class="transform hover:rotate-3">
<img class="hover:scale-110">

<!-- ✅ 허용 -->
<u-button>  <!-- 내장 hover 효과 사용 -->
<button class="hover:bg-primary-600">  <!-- 색상 변경만 -->
```

**이유**: 확대 효과는 게이미피케이션 요소. 백오피스와 부적합.

### 2.5 과도한 둥근 모서리 금지

```vue
<!-- ❌ 금지 -->
<button class="rounded-full">  <!-- 아이콘 버튼 제외 -->
<div class="rounded-3xl">
<div class="rounded-[20px]">

<!-- ✅ 허용 -->
<div class="rounded-md">
<div class="rounded-lg">
<u-button>  <!-- 내장 스타일 -->
```

**이유**: 과도한 둥근 모서리는 비전문적. 적절한 라운딩이 깔끔함.

---

## 3. 허용 패턴 가이드

### 3.1 _common 래퍼 + NuxtUI 컴포넌트 우선

```vue
<!-- ✅ 권장: _common 래퍼 컴포넌트 (래퍼가 있으면 반드시 래퍼 사용) -->
<p-input-box v-model="value" placeholder="텍스트 입력" />
<p-nuxt-select v-model="selected" :options="options" />
<p-date-picker-work v-model="date" />
<p-modal :is-show-modal="isOpen" :current-comp="modalComp" />
<p-file-upload v-model="fileList" :upload-handler="store.uploadFileLocal" />

<!-- ✅ 권장: NuxtUI 직접 사용 (래퍼 없는 컴포넌트) -->
<u-button>저장</u-button>
<u-card>내용</u-card>
<u-table :rows="data" :columns="columns" />
<u-badge color="success">완료</u-badge>
<u-tabs :items="tabItems" />

<!-- ❌ 금지: 래퍼가 있는데 NuxtUI 직접 사용 -->
<!-- <u-input> → p-input-box 사용 -->
<!-- <u-select> → p-nuxt-select 사용 -->

<!-- ⚠️ 필요시만: 커스텀 스타일링 -->
<button class="px-4 py-2 bg-primary text-white rounded-md">
```

> **_common 컴포넌트 상세**: [common-component-guide.md](common-component-guide.md) 참조

### 3.2 허용 TailwindCSS 클래스

#### 레이아웃
```
flex, grid, block, inline-flex
justify-*, items-*, gap-*
w-*, h-*, min-w-*, max-w-*
```

#### 간격
```
p-2, p-4, p-6 (4px 배수)
m-2, m-4, m-6
space-x-2, space-y-2
gap-2, gap-4
```

#### 배경/테두리
```
bg-white, bg-gray-50, bg-gray-100
bg-primary, bg-error, bg-success
border, border-gray-200, border-gray-300
rounded-md, rounded-lg
```

#### 텍스트
```
text-sm, text-base, text-lg
text-gray-500, text-gray-700, text-gray-900
font-medium, font-semibold
```

#### 그림자
```
shadow-sm, shadow (최대)
```

#### Hover 상태
```
hover:bg-gray-50
hover:bg-primary-600
hover:text-primary
```

### 3.3 폼 요소 패턴

```vue
<template>
  <u-form-field label="제목" required>
    <p-input-box v-model="form.title" placeholder="제목을 입력하세요" :maxlength="200" />
  </u-form-field>

  <u-form-field label="상태">
    <p-nuxt-select
      v-model="form.status"
      :options="[
        { text: '활성', value: 'A' },
        { text: '비활성', value: 'I' }
      ]"
    />
  </u-form-field>

  <u-form-field label="금액">
    <p-input-box v-model="form.price" :is-comma="true" :is-right="true" placeholder="0" />
  </u-form-field>

  <u-form-field label="사용여부">
    <u-switch v-model="form.isUse" />  <!-- USwitch는 래퍼 없음, 직접 사용 -->
  </u-form-field>
</template>
```

### 3.4 버튼 패턴

```vue
<!-- 주요 액션 -->
<u-button color="primary">저장</u-button>

<!-- 보조 액션 -->
<u-button color="neutral" variant="outline">취소</u-button>

<!-- 위험 액션 -->
<u-button color="error">삭제</u-button>

<!-- 버튼 그룹 -->
<div class="flex gap-2">
  <u-button color="neutral" variant="outline">취소</u-button>
  <u-button color="primary">저장</u-button>
</div>
```

---

## 4. 품질 체크리스트

### 생성 코드 검증 항목

```
□ 그라데이션 클래스 미사용 (bg-gradient-*, from-*, to-*)
□ 과도한 그림자 미사용 (shadow-xl, shadow-2xl)
□ 애니메이션 미사용 (animate-pulse, animate-bounce)
□ 확대 효과 미사용 (hover:scale-*, transform)
□ 과도한 둥근 모서리 미사용 (rounded-full, rounded-3xl)
□ NuxtUI 컴포넌트 우선 사용
□ 프로젝트 컬러 팔레트 준수 (primary: #287dff)
□ 4px 배수 간격 사용 (p-2, p-4, gap-4)
□ 불필요한 장식 요소 없음
```

### 빠른 검사 명령어

```bash
# 금지 패턴 검색
grep -rn "bg-gradient\|shadow-xl\|shadow-2xl\|animate-pulse\|animate-bounce\|hover:scale" front/src/modules/[모듈명]/

# 결과가 없어야 함
```

---

## 5. 안티 패턴 vs 권장 패턴 비교

### 카드 컴포넌트

```vue
<!-- ❌ AI Slop -->
<div class="bg-gradient-to-br from-blue-500 to-purple-600 rounded-3xl shadow-2xl p-6 transform hover:scale-105 transition-all duration-300">
  <h3 class="text-white font-bold animate-pulse">제목</h3>
</div>

<!-- ✅ 권장 -->
<u-card>
  <template #header>
    <h3 class="font-semibold text-gray-900">제목</h3>
  </template>
  <p class="text-gray-600">내용</p>
</u-card>
```

### 버튼

```vue
<!-- ❌ AI Slop -->
<button class="bg-gradient-to-r from-indigo-500 to-purple-500 rounded-full px-8 py-4 shadow-xl hover:scale-110 transition-transform">
  클릭
</button>

<!-- ✅ 권장 -->
<u-button color="primary">클릭</u-button>
```

### 테이블

```vue
<!-- ❌ AI Slop -->
<div class="bg-gradient-to-b from-gray-50 to-white rounded-3xl shadow-2xl overflow-hidden">
  <table class="w-full">
    <tr class="hover:bg-gradient-to-r hover:from-blue-50 hover:to-purple-50 transition-all">
      ...
    </tr>
  </table>
</div>

<!-- ✅ 권장 -->
<u-table :rows="data" :columns="columns" />
```

---

## 참조

- **디자인 시스템 (Single Source of Truth)**: `.claude/skills/gen-design/` — 색상, 타이포, 레이아웃, 접근성 원칙
- **_common 컴포넌트 가이드**: [common-component-guide.md](common-component-guide.md) — DB 타입별 컴포넌트 매핑
- **NuxtUI 공식 문서**: https://ui.nuxt.com/
- **TailwindCSS v4 문서**: https://tailwindcss.com/
- **프로젝트 가이드 코드**: `front/src/modules/test-data/`
