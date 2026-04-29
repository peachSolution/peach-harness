# 접근성(a11y) 가이드 - WCAG 2.2 (2024-2025)

## WCAG 2.2 핵심 요구사항

2023년 10월 발표, Level AA 신규 기준:

| 기준 | 요구사항 |
|------|----------|
| 2.4.11 Focus Not Obscured | 포커스된 요소가 sticky 헤더/푸터에 완전히 가려지면 안 됨 |
| 2.5.7 Dragging Movements | 드래그 액션에 단일 포인터 대안 필수 (예: 위/아래 버튼) |
| 2.5.8 Target Size | 인터랙티브 타겟 최소 24×24 CSS 픽셀 |
| 3.3.8 Accessible Auth | 로그인에 인지 기능 테스트 금지, 비밀번호 매니저 허용 |

---

## 색상 대비 기준

| 요소 | AA | AAA |
|------|-----|-----|
| 일반 텍스트 (<18pt) | 4.5:1 | 7:1 |
| 큰 텍스트 (≥18pt) | 3:1 | 4.5:1 |
| UI 컴포넌트 & 그래픽 | 3:1 | 3:1 |
| 포커스 인디케이터 | 3:1 | 3:1 |

### 검증 도구
- WebAIM Contrast Checker
- axe DevTools
- Figma Contrast 플러그인

---

## 키보드 네비게이션

### Focus Visible 스타일링

```css
*:focus-visible {
  outline: 3px solid #005fcc;
  outline-offset: 0.25rem;
  border-radius: 0.125rem;
}

/* 마우스 클릭 시 outline 숨김 */
*:focus:not(:focus-visible) {
  outline: none;
}
```

### TailwindCSS 적용

```vue
<template>
  <button
    class="
      focus-visible:outline-none
      focus-visible:ring-2
      focus-visible:ring-primary-500
      focus-visible:ring-offset-2
    "
  >
    버튼
  </button>
</template>
```

---

## Skip Links 구현

페이지 최상단에 필수 구현:

```html
<a href="#main-content" class="skip-link">본문으로 건너뛰기</a>
<nav>...</nav>
<main id="main-content" tabindex="-1">...</main>
```

```css
.skip-link {
  position: absolute;
  top: -40px;
  left: 0;
  padding: 8px 16px;
  background: #005fcc;
  color: white;
  z-index: 100;
}

.skip-link:focus {
  top: 0;
}
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

---

## 컴포넌트별 접근성 체크리스트

### 모달 (Dialog)

- [ ] `role="dialog"`, `aria-modal="true"`
- [ ] `aria-labelledby`로 제목 연결
- [ ] 포커스 트랩 (Tab이 모달 내부만 순환)
- [ ] Escape 키로 닫기
- [ ] 닫힐 때 트리거 요소로 포커스 복귀

```vue
<template>
  <div
    role="dialog"
    aria-modal="true"
    aria-labelledby="modal-title"
    @keydown.esc="close"
  >
    <h2 id="modal-title">모달 제목</h2>
    <div>내용</div>
    <button @click="close">닫기</button>
  </div>
</template>
```

### 폼 (Form)

- [ ] 모든 인풋에 `<label>` 연결 (for/id 매칭)
- [ ] 필수 필드: `aria-required="true"`
- [ ] 에러 메시지: `aria-describedby` 연결
- [ ] 유효하지 않은 필드: `aria-invalid="true"`
- [ ] 관련 인풋: `<fieldset>`, `<legend>` 그룹화

```vue
<template>
  <div>
    <label for="email">이메일 *</label>
    <input
      id="email"
      type="email"
      aria-required="true"
      :aria-invalid="hasError"
      :aria-describedby="hasError ? 'email-error' : undefined"
    />
    <p v-if="hasError" id="email-error" class="text-red-500">
      유효한 이메일을 입력하세요
    </p>
  </div>
</template>
```

### 테이블 (Table)

- [ ] `<caption>` 테이블 제목
- [ ] `<th>` + `scope="col|row"` 헤더
- [ ] 복잡한 테이블: `headers` 속성

```vue
<template>
  <table>
    <caption>사용자 목록</caption>
    <thead>
      <tr>
        <th scope="col">이름</th>
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

### 네비게이션 (Navigation)

- [ ] `<nav>` + `aria-label`
- [ ] 현재 페이지: `aria-current="page"`
- [ ] 드롭다운: `aria-expanded` 사용

```vue
<template>
  <nav aria-label="메인 네비게이션">
    <ul>
      <li>
        <a
          href="/dashboard"
          :aria-current="isCurrentPage('/dashboard') ? 'page' : undefined"
        >
          대시보드
        </a>
      </li>
      <li>
        <button
          :aria-expanded="isMenuOpen"
          @click="toggleMenu"
        >
          설정
        </button>
        <ul v-show="isMenuOpen">
          <li><a href="/settings/profile">프로필</a></li>
          <li><a href="/settings/security">보안</a></li>
        </ul>
      </li>
    </ul>
  </nav>
</template>
```

### 버튼 (Button)

- [ ] 아이콘만 있는 버튼: `aria-label` 필수
- [ ] 토글 버튼: `aria-pressed` 사용
- [ ] 로딩 버튼: `aria-disabled="true"` + 로딩 상태 알림

```vue
<template>
  <!-- 아이콘 버튼 -->
  <button aria-label="검색">
    <icon name="search" />
  </button>

  <!-- 토글 버튼 -->
  <button
    :aria-pressed="isToggled"
    @click="toggle"
  >
    {{ isToggled ? '활성화됨' : '비활성화됨' }}
  </button>

  <!-- 로딩 버튼 -->
  <button
    :disabled="isLoading"
    :aria-disabled="isLoading"
  >
    <span v-if="isLoading" aria-live="polite">처리 중...</span>
    <span v-else>저장</span>
  </button>
</template>
```

---

## 핵심 수치 요약

| 요구사항 | 값 |
|----------|-----|
| 텍스트 대비 (AA) | 4.5:1 |
| UI 대비 | 3:1 |
| 최소 타겟 사이즈 | 24×24px |
| 권장 타겟 사이즈 (AAA) | 44×44px |
| 포커스 인디케이터 두께 | ≥2px |

---

## ARIA Live Regions

동적 콘텐츠 알림:

```vue
<template>
  <!-- 중요하지 않은 업데이트 -->
  <div aria-live="polite">
    {{ message }}
  </div>

  <!-- 긴급 알림 (에러 등) -->
  <div aria-live="assertive" role="alert">
    {{ errorMessage }}
  </div>

  <!-- 로딩 상태 -->
  <div aria-live="polite" aria-busy="true">
    데이터 로딩 중...
  </div>
</template>
```

---

## 접근성 테스트 체크리스트

### 자동 테스트
- [ ] axe DevTools 검사 통과
- [ ] Lighthouse Accessibility 점수 90+

### 수동 테스트
- [ ] 키보드만으로 모든 기능 사용 가능
- [ ] Tab 순서가 논리적
- [ ] 포커스 인디케이터 항상 보임
- [ ] 화면 확대 200%에서도 사용 가능
- [ ] 스크린 리더로 모든 콘텐츠 접근 가능
