# 프로젝트 공통 컴포넌트 카탈로그 (_common)

> 경로: `front/src/modules/_common/components/`
> NuxtUI 원본을 래핑한 프로젝트 표준 컴포넌트입니다.
> **디자인 제안 시 NuxtUI 원본 대신 이 컴포넌트를 기준으로 제안하세요.**

---

## 컴포넌트 사용 우선순위

```
1순위: _common 래퍼 컴포넌트 (p-input-box, p-nuxt-select 등)
2순위: NuxtUI 컴포넌트 직접 사용 (UButton, UBadge, UTabs 등)
3순위: 커스텀 HTML + TailwindCSS (특수한 경우만)
```

> _common 래퍼가 있는 경우 반드시 래퍼를 사용합니다.
> NuxtUI 원본을 직접 사용하면 프로젝트 규칙(포맷팅, 전체 옵션 등)이 누락됩니다.

---

## 입력 컴포넌트

### p-input-box

**경로**: `_common/components/forms/p-input-box.vue`
**래핑 대상**: `UInput`

텍스트/숫자 입력의 표준 컴포넌트. 자동 포맷팅 기능 내장.

| Prop | 타입 | 설명 |
|------|------|------|
| `modelValue` | `string \| number` | 입력값 (v-model) |
| `isComma` | `boolean` | 금액 콤마 자동 포맷 (1,000,000) |
| `isRight` | `boolean` | 텍스트 우측 정렬 (금액용) |
| `isHpNumber` | `boolean` | 휴대폰번호 자동 포맷 (010-1234-5678) |
| `isTelNumber` | `boolean` | 전화번호 자동 포맷 (02-1234-5678) |
| `isBizNumber` | `boolean` | 사업자번호 자동 포맷 (123-45-67890) |
| `isJuminNumber` | `boolean` | 주민번호 자동 포맷 |
| `isCardNumber` | `boolean` | 카드번호 자동 포맷 |
| `nextInput` | `string` | 포맷 완료 시 다음 input name으로 자동 포커스 |

**디자인 시 고려사항:**
- 금액 필드: `isComma` + `isRight` 조합으로 우측 정렬 + 콤마 표시
- 전화번호: 자동 하이픈 삽입, 완성 시 다음 필드로 자동 이동
- 기본 높이: UInput과 동일 (40px / h-10)

```vue
<!-- 금액 입력 -->
<p-input-box v-model="data.amount" :is-comma="true" :is-right="true" placeholder="금액" />

<!-- 전화번호 -->
<p-input-box v-model="data.hpNumber" :is-hp-number="true" placeholder="010-0000-0000" />

<!-- 기본 텍스트 -->
<p-input-box v-model="data.name" placeholder="이름을 입력하세요" />
```

---

### p-nuxt-select

**경로**: `_common/components/forms/p-nuxt-select.vue`
**래핑 대상**: `USelect`

셀렉트박스 표준 컴포넌트. **전체 옵션(value='')** 자동 처리.

| Prop | 타입 | 설명 |
|------|------|------|
| `modelValue` | `string \| number` | 선택값 (v-model) |
| `options` | `{text, value}[]` | 옵션 목록 |
| `placeholder` | `string` | 기본: '선택하세요' |

**핵심 동작:**
- `value: ''` → 내부적으로 `'all'`로 변환 (USelect 빈 값 이슈 해결)
- 외부로 emit 시 `'all'` → `''`로 역변환
- **검색 리스트에서 @change="listAction" 필수**

```vue
<p-nuxt-select
  v-model="listParams.isUse"
  :options="[
    { text: '전체', value: '' },
    { text: '사용', value: 'Y' },
    { text: '미사용', value: 'N' }
  ]"
  @change="listAction"
/>
```

---

## 날짜 컴포넌트

### p-date-picker-work

**경로**: `_common/components/date-picker/p-date-picker-work.vue`
**래핑 대상**: `@vuepic/vue-datepicker`

날짜 선택 표준 컴포넌트. 한국어 기본 적용.

| Prop | 타입 | 설명 |
|------|------|------|
| `modelValue` | `string` | 날짜값 (YYYY-MM-DD) |
| `dateFormat` | `string` | 표시 형식 (기본: yyyy-MM-dd) |
| `enableTimePicker` | `boolean` | 시간 선택 활성화 |
| `monthPicker` | `boolean` | 월 단위 선택 |
| `yearPicker` | `boolean` | 년 단위 선택 |
| `minDate` | `Date \| string` | 최소 선택 가능일 |
| `maxDate` | `Date \| string` | 최대 선택 가능일 |

**디자인 시 고려사항:**
- 높이: 32px (2rem), UInput보다 약간 낮음
- 아이콘: 좌측에 달력 아이콘 내장
- 일요일=빨강, 토요일=파랑 커스텀 스타일 적용됨
- 검색 영역에서 **@update:modelValue="listAction" 필수**

```vue
<p-date-picker-work
  v-model="listParams.startDate"
  @update:modelValue="listAction"
/>
```

---

### p-date-period

**경로**: `_common/components/date-picker/p-date-period.vue`

빠른 기간 선택 셀렉트. 오늘/어제/n일전/월별/년별 자동 계산.

| Prop | 타입 | 설명 |
|------|------|------|
| `modelValue` | `string` | 선택된 기간 키 |

| Event | Payload | 설명 |
|-------|---------|------|
| `setDate` | `{startDate, endDate}` | 계산된 날짜 범위 |

**자동 생성 옵션:**
- 모레, 내일, 오늘
- 1일전 ~ 7일전 (날짜+요일 표시)
- 최근 12개월 (YYYY년 MM월)
- 1년 ~ 4년

**디자인 시 고려사항:**
- 검색 영역에 날짜 입력 2개(시작/종료) + 기간 셀렉트 1개 = 3열 구성 권장
- p-date-picker-work와 조합하여 사용

```vue
<!-- 전형적인 기간 검색 패턴 -->
<div class="flex items-center gap-2">
  <p-date-period @setDate="handleSetDate" />
  <p-date-picker-work v-model="listParams.startDate" @update:modelValue="listAction" />
  <span>~</span>
  <p-date-picker-work v-model="listParams.endDate" @update:modelValue="listAction" />
</div>
```

---

## 모달 컴포넌트

### p-modal

**경로**: `_common/components/modal/p-modal.vue`

CRUD 모달 표준 컴포넌트. 동적 컴포넌트 삽입 + 저장 버튼 연동.

| Prop | 타입 | 설명 |
|------|------|------|
| `modelValue` | `boolean` | 열림/닫힘 (v-model) |
| `title` | `string` | 모달 제목 |
| `boxWidth` | `string` | 너비 (px 단위, 기본: '500') |
| `currentComp` | `Component` | 동적 삽입 컴포넌트 |
| `modalProps` | `any` | 동적 컴포넌트에 전달할 props |
| `btnClose` | `boolean` | 닫기 버튼 표시 |
| `btnSave` | `boolean` | 저장 버튼 표시 |
| `btnSaveText` | `string` | 저장 버튼 텍스트 (기본: '저장') |
| `zIndex` | `number` | z-index (기본: 50) |

**디자인 시 고려사항:**
- 배경: 반투명 검정 오버레이 (opacity-50)
- 모서리: rounded-custom8 (8px)
- 그림자: shadow-custom0010
- 헤더: 제목 좌측 + 닫기(×) 우측
- 푸터: 닫기(neutral) + 저장(primary) 우측 정렬

```vue
<p-modal
  v-model="isOpenModal"
  title="회원 등록"
  box-width="600"
  :current-comp="InsertModal"
  :btn-close="true"
  :btn-save="true"
  @fn-save-load="handleSave"
/>
```

---

### p-common-modal

**경로**: `_common/components/modal/p-common-modal.vue`

범용 슬롯 기반 모달. header/body/footer 슬롯 지원.

| Prop | 타입 | 설명 |
|------|------|------|
| `modelValue` | `boolean` | 열림/닫힘 (v-model) |
| `title` | `string` | 제목 (header 슬롯 없을 때) |
| `size` | `sm\|md\|lg\|xl\|full\|custom` | 사이즈 프리셋 |
| `autoClose` | `boolean` | 배경 클릭 시 닫기 (기본: true) |

**사이즈 프리셋:**
- `sm`: max-w-sm
- `md`: max-w-md
- `lg`: max-w-lg
- `xl`: max-w-xl
- `full`: w-11/12 max-w-7xl

---

### p-modal.alert / p-modal.confirm

**경로**: `_common/components/modal/p-modal.alert.vue`, `p-modal.confirm.vue`

전역 알림/확인 다이얼로그. `defaultLayoutStore`를 통해 제어.

- **p-modal.alert**: 에러/경고 표시, 확인 버튼만
- **p-modal.confirm**: 성공/삭제 확인, 확인+취소 버튼

**디자인 시 고려사항:**
- 너비 고정: 400px (alert), 380px (confirm)
- 아이콘: 상단 중앙 배치 (bug/success/delete)
- 다크모드 아이콘 자동 전환
- Enter 키로 확인 가능 (alert)

---

## 파일 컴포넌트

### p-file-upload

**경로**: `_common/components/file/p-file-upload.vue`

파일 업로드 표준 컴포넌트. 드래그앤드롭 + 동시 업로드 + 프로그레스.

| Prop | 타입 | 설명 |
|------|------|------|
| `modelValue` | `FileInfo[]` | 파일 목록 (v-model) |
| `maxFiles` | `number` | 최대 파일 수 (기본: 5) |
| `maxFileSize` | `number` | 최대 크기 (기본: 100MB) |
| `storageType` | `'LOCAL' \| 'S3'` | 저장소 유형 |
| `uploadHandler` | `Function` | 업로드 처리 함수 |
| `downUrlResolver` | `Function` | 다운로드 URL 생성 함수 |
| `maxConcurrentUploads` | `number` | 동시 업로드 수 (기본: 3) |
| `allowedExtensions` | `string[]` | 허용 확장자 |
| `allowedMimeTypes` | `string[]` | 허용 MIME 타입 |
| `isEditorAdd` | `boolean` | 에디터 삽입 버튼 표시 |

**디자인 시 고려사항:**
- 파일 아이템: 3열 그리드 (데스크톱), 2열 (태블릿), 1열 (모바일)
- 프로그레스바: 상단 1px 바 (파란색, 에러 시 빨간색)
- 이미지 미리보기: 50×50px 썸네일
- 드래그앤드롭 정렬 지원 (파일 순서 변경)
- 상태: pending → uploading → completed / error
- 에러 시 재시도 버튼 표시

```vue
<p-file-upload
  v-model="detailData.fileList"
  :upload-handler="store.uploadFileLocal"
  :down-url-resolver="store.getDownloadUrl"
  :max-files="10"
  :storage-type="'LOCAL'"
/>
```

---

## 폼 레이아웃 컴포넌트

### p-form-group

**경로**: `_common/components/forms/p-form-group.vue`

폼 섹션 그룹. 아이콘 + 제목 + 하위 필드 묶음.

| Prop | 타입 | 설명 |
|------|------|------|
| `title` | `string` | 그룹 제목 (필수) |
| `icon` | `string` | 아이콘 이름 |

**디자인 시 고려사항:**
- 하단 테두리로 섹션 구분
- 간격: space-y-4
- 제목: text-lg font-bold

```vue
<p-form-group title="기본 정보" icon="i-heroicons-user">
  <UFormField label="이름">
    <p-input-box v-model="data.name" />
  </UFormField>
  <UFormField label="이메일">
    <p-input-box v-model="data.email" />
  </UFormField>
</p-form-group>
```

---

### p-detail-item

**경로**: `_common/components/forms/p-detail-item.vue`

상세 조회 레이블:값 표시. 반응형 가로 배치.

| Prop | 타입 | 설명 |
|------|------|------|
| `label` | `string` | 레이블 (필수) |
| `value` | `string` | 값 (또는 slot 사용) |
| `labelWidth` | `string` | 레이블 너비 (기본: md:w-1/3) |
| `valueWidth` | `string` | 값 너비 (기본: md:w-2/3) |
| `icon` | `string` | 아이콘 |
| `maxLabelLength` | `number` | 레이블 최대 길이 (기본: 10) |

**디자인 시 고려사항:**
- 모바일: 세로 배치 (label 위, value 아래)
- 데스크톱: 가로 배치 (label 1/3, value 2/3)
- 하단 테두리로 항목 구분
- 레이블 10자 초과 시 말줄임

```vue
<p-detail-item label="회원명" :value="detailData.name" />
<p-detail-item label="등록일" :value="detailData.insertDate" />
<p-detail-item label="상태">
  <u-badge :color="detailData.isUse === 'Y' ? 'success' : 'neutral'">
    {{ detailData.isUse === 'Y' ? '사용' : '미사용' }}
  </u-badge>
</p-detail-item>
```

---

## 기타 컴포넌트

### full-loding (전체 로딩)

**경로**: `_common/components/layouts/full-loding.component.vue`

전체 화면 로딩 오버레이.

- 반투명 검정 배경 + 중앙 스피너
- 사이드바 유무에 따라 자동 너비 조정
- z-index: 99999

### post-code (우편번호)

**경로**: `_common/components/address/post-code.vue`

카카오 주소 API 연동 우편번호 검색.

### p-editor-quill (리치 에디터)

**경로**: `_common/components/quill/p-editor-quill.vue`

Quill 기반 리치 텍스트 에디터. 특수문자 모달 포함.

### tiny-editor (TinyMCE 에디터)

**경로**: `_common/components/tinymce/tiny-editor.vue`

TinyMCE 기반 고급 에디터.

---

## 서비스 (_common/services)

| 서비스 | 용도 |
|--------|------|
| `api.service.ts` | API 호출 (useApi) |
| `form.service.ts` | 폼 제출, 알림, 확인 다이얼로그 |
| `excel.service.ts` | 엑셀 파싱/다운로드 |
| `error-tracker.service.ts` | 에러 추적 |

---

## _common 컴포넌트 vs NuxtUI 직접 사용 판단 기준

| 상황 | 사용할 컴포넌트 |
|------|----------------|
| 텍스트/숫자 입력 | `p-input-box` (포맷팅 지원) |
| 셀렉트박스 | `p-nuxt-select` (전체 옵션 자동 처리) |
| 날짜 선택 | `p-date-picker-work` (한국어, 커스텀 스타일) |
| 기간 빠른 선택 | `p-date-period` |
| 파일 업로드 | `p-file-upload` (프로그레스, 드래그앤드롭) |
| 폼 섹션 묶음 | `p-form-group` |
| 상세 조회 항목 | `p-detail-item` |
| CRUD 모달 | `p-modal` (동적 컴포넌트) |
| 범용 모달 | `p-common-modal` (슬롯 기반) |
| 버튼 | `UButton` (NuxtUI 직접 사용) |
| 배지/태그 | `UBadge` (NuxtUI 직접 사용) |
| 탭 | `UTabs` (NuxtUI 직접 사용) |
| 테이블 | `EasyDataTable` 또는 `UTable` |
| 스위치 | `USwitch` (NuxtUI 직접 사용) |
