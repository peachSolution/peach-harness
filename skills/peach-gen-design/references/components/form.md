# 폼 / 인풋 디자인 가이드

> 기준 파일: 대상 프로젝트의 `theme.css`와 디자인 시스템 문서

---

## 인풋 스펙 (닥터팔레트)

```css
.input {
  width: 100%;
  padding: 10px 12px;
  border: 1px solid #d3d3d3;  /* neutral-300 */
  border-radius: 6px;         /* radius-md */
  font-size: 14px;
  color: #242424;             /* neutral-800 */
  background-color: #ffffff;
  transition: border-color 0.15s ease;
}

.input:focus {
  outline: none;
  border-color: #287dff;      /* primary-500 */
  box-shadow: 0 0 0 3px rgba(40, 125, 255, 0.1);
}

.input::placeholder {
  color: #9ca3af;             /* neutral-400 */
}
```

---

## 인풋 해부학

```
Label* (상단 정렬, 12px, font-weight: 500, neutral-700)
┌─────────────────────────────────┐
│ [Icon] Placeholder/Value        │ ← 높이: 40px, padding: 10px 12px
└─────────────────────────────────┘
Helper text (12px, neutral-500)
Error text (12px, error-500)
```

---

## 레이블 패턴

| 패턴 | 설명 | 권장 |
|------|------|------|
| **Top-aligned** | 스캔 용이, 접근성 최적 | **기본 권장** |
| Floating | 공간 효율적이나 접근성 우려 | 제한적 사용 |
| Left-aligned | 수직 공간 절약 필요 시 | 특수 상황 |

---

## Validation 피드백

- **인라인**: debounce 300ms
- **blur 시**: 필드 포커스 해제 시 검증
- **submit 시**: 최종 검증

### 에러 스타일
- 빨간 테두리: `#ef4444` (error-500)
- 에러 아이콘 (선택)
- 하단 에러 텍스트

---

## NuxtUI 폼 컴포넌트

### 기본 인풋

```vue
<template>
  <u-form-field label="이메일" required>
    <u-input
      v-model="email"
      type="email"
      placeholder="이메일 입력"
    />
  </u-form-field>
</template>
```

### 에러 상태

```vue
<template>
  <u-form-field label="이메일" required :error="emailError">
    <u-input
      v-model="email"
      type="email"
      placeholder="이메일 입력"
      :error="!!emailError"
    />
  </u-form-field>
</template>
```

### 헬퍼 텍스트

```vue
<template>
  <u-form-field label="비밀번호" required>
    <u-input v-model="password" type="password" />
    <template #hint>
      <span class="text-xs text-neutral-500">8자 이상, 영문/숫자/특수문자 포함</span>
    </template>
  </u-form-field>
</template>
```

---

## 인풋 유형별 가이드

### 텍스트 인풋

```vue
<template>
  <u-input v-model="text" placeholder="입력" />

  <!-- 아이콘 포함 -->
  <u-input v-model="search" placeholder="검색" icon="i-heroicons-magnifying-glass" />

  <!-- 클리어 버튼 -->
  <u-input v-model="text" placeholder="입력">
    <template #trailing>
      <u-button
        v-if="text"
        icon="i-heroicons-x-mark"
        size="xs"
        variant="ghost"
        @click="text = ''"
      />
    </template>
  </u-input>
</template>
```

### 셀렉트

```vue
<template>
  <u-form-field label="카테고리">
    <u-select
      v-model="category"
      :options="categories"
      placeholder="선택하세요"
    />
  </u-form-field>
</template>

<script setup>
const categories = [
  { label: '전체', value: '' },
  { label: '카테고리1', value: '1' },
  { label: '카테고리2', value: '2' },
];
</script>
```

### 텍스트에어리어

```vue
<template>
  <u-form-field label="설명">
    <u-textarea
      v-model="description"
      placeholder="설명 입력"
      :rows="4"
    />
  </u-form-field>
</template>
```

### 체크박스 / 라디오

```vue
<template>
  <!-- 체크박스 -->
  <u-checkbox v-model="agreed" label="약관에 동의합니다" />

  <!-- 라디오 그룹 -->
  <u-radio-group v-model="selected" :options="options" />
</template>
```

### 스위치

```vue
<template>
  <u-form-field label="알림 수신">
    <u-switch v-model="notifications" />
  </u-form-field>
</template>
```

---

## 폼 레이아웃

### 세로 레이아웃 (기본)

```vue
<template>
  <form class="space-y-4">
    <u-form-field label="이름" required>
      <u-input v-model="form.name" />
    </u-form-field>

    <u-form-field label="이메일" required>
      <u-input v-model="form.email" type="email" />
    </u-form-field>

    <u-form-field label="전화번호">
      <u-input v-model="form.phone" type="tel" />
    </u-form-field>

    <div class="flex justify-end gap-2 pt-4">
      <u-button variant="soft">취소</u-button>
      <u-button type="submit">저장</u-button>
    </div>
  </form>
</template>
```

### 가로 레이아웃

```vue
<template>
  <form class="space-y-4">
    <div class="grid grid-cols-2 gap-4">
      <u-form-field label="이름" required>
        <u-input v-model="form.firstName" />
      </u-form-field>

      <u-form-field label="성" required>
        <u-input v-model="form.lastName" />
      </u-form-field>
    </div>

    <u-form-field label="이메일" required>
      <u-input v-model="form.email" type="email" />
    </u-form-field>
  </form>
</template>
```

### 검색 폼 (인라인)

```vue
<template>
  <div class="flex gap-2 items-end">
    <u-form-field label="검색어" class="flex-1">
      <u-input v-model="keyword" placeholder="검색어 입력" />
    </u-form-field>

    <u-form-field label="상태">
      <u-select v-model="status" :options="statusOptions" />
    </u-form-field>

    <u-button icon="i-heroicons-magnifying-glass">검색</u-button>
  </div>
</template>
```

---

## 유효성 검증 (Yup)

```typescript
import * as yup from 'yup';

const schema = yup.object({
  name: yup.string().required('이름을 입력하세요'),
  email: yup.string().email('올바른 이메일을 입력하세요').required('이메일을 입력하세요'),
  phone: yup.string().matches(/^01[0-9]-?[0-9]{4}-?[0-9]{4}$/, '올바른 전화번호를 입력하세요'),
});
```

```vue
<script setup>
const errors = ref<Record<string, string>>({});

async function validate() {
  try {
    await schema.validate(form.value, { abortEarly: false });
    errors.value = {};
    return true;
  } catch (err) {
    if (err instanceof yup.ValidationError) {
      errors.value = err.inner.reduce((acc, e) => {
        acc[e.path!] = e.message;
        return acc;
      }, {} as Record<string, string>);
    }
    return false;
  }
}
</script>

<template>
  <u-form-field label="이름" required :error="errors.name">
    <u-input v-model="form.name" :error="!!errors.name" />
  </u-form-field>
</template>
```

---

## 모바일 키보드 최적화

```vue
<template>
  <!-- 숫자 키보드 -->
  <u-input v-model="cardNumber" inputmode="numeric" pattern="[0-9]*" />

  <!-- 이메일 키보드 -->
  <u-input v-model="email" type="email" inputmode="email" />

  <!-- 전화번호 키보드 -->
  <u-input v-model="phone" type="tel" inputmode="tel" />

  <!-- URL 키보드 -->
  <u-input v-model="website" type="url" inputmode="url" />
</template>
```

---

## 접근성 체크리스트

- [ ] 모든 인풋에 `<label>` 연결 (for/id 매칭)
- [ ] 필수 필드: `aria-required="true"`
- [ ] 에러 메시지: `aria-describedby` 연결
- [ ] 유효하지 않은 필드: `aria-invalid="true"`
- [ ] 관련 인풋: `<fieldset>`, `<legend>` 그룹화

> NuxtUI의 `UFormField`와 `UInput`은 기본적으로 접근성 요구사항을 충족합니다.

---

## 금지 패턴

```vue
<!-- 금지: placeholder만 사용 (레이블 없음) -->
<u-input placeholder="이름" />

<!-- 금지: 빨간색만으로 에러 표시 (색맹 고려) -->
<u-input class="border-error-500" />

<!-- 금지: 자동 포커스 남용 -->
<u-input autofocus />

<!-- 금지: 과도한 그림자 -->
<input class="shadow-xl" />
```

---

## 권장 패턴

```vue
<template>
  <u-form-field label="이름" required :error="errors.name">
    <u-input
      v-model="form.name"
      placeholder="이름 입력"
      :error="!!errors.name"
    />
    <template #hint>
      <span class="text-xs text-neutral-500">실명을 입력하세요</span>
    </template>
  </u-form-field>
</template>
```

---

## 실제 사용 예시

### 회원 등록 폼

```vue
<template>
  <u-card>
    <template #header>
      <h3 class="text-base font-semibold text-neutral-800">회원 정보</h3>
    </template>

    <form class="space-y-4" @submit.prevent="handleSubmit">
      <div class="grid grid-cols-2 gap-4">
        <u-form-field label="이름" required :error="errors.name">
          <u-input v-model="form.name" placeholder="이름" :error="!!errors.name" />
        </u-form-field>

        <u-form-field label="휴대폰" required :error="errors.phone">
          <u-input v-model="form.phone" type="tel" placeholder="010-0000-0000" :error="!!errors.phone" />
        </u-form-field>
      </div>

      <u-form-field label="이메일" required :error="errors.email">
        <u-input v-model="form.email" type="email" placeholder="이메일" :error="!!errors.email" />
      </u-form-field>

      <u-form-field label="비고">
        <u-textarea v-model="form.memo" placeholder="비고 입력" :rows="3" />
      </u-form-field>
    </form>

    <template #footer>
      <div class="flex justify-end gap-2">
        <u-button variant="soft" @click="cancel">취소</u-button>
        <u-button :loading="isSubmitting" @click="handleSubmit">저장</u-button>
      </div>
    </template>
  </u-card>
</template>
```

### 검색 폼

```vue
<template>
  <div class="bg-neutral-50 rounded-lg p-4">
    <div class="grid grid-cols-1 md:grid-cols-4 gap-4">
      <u-form-field label="검색어">
        <u-input v-model="params.keyword" placeholder="검색어 입력" />
      </u-form-field>

      <u-form-field label="상태">
        <u-select v-model="params.status" :options="statusOptions" />
      </u-form-field>

      <u-form-field label="등록일">
        <u-input v-model="params.startDate" type="date" />
      </u-form-field>

      <div class="flex items-end">
        <u-button class="w-full" icon="i-heroicons-magnifying-glass" @click="search">
          검색
        </u-button>
      </div>
    </div>
  </div>
</template>
```
