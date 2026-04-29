# _common 컴포넌트 선택 가이드

> 경로: `front/src/modules/_common/components/`
> DB 컬럼 타입 / UI 상황에 따라 적절한 _common 컴포넌트를 선택하는 의사결정 가이드입니다.

---

## 컬럼 타입별 컴포넌트 매핑

### 텍스트 입력

| DB 컬럼 / 용도 | 컴포넌트 | Props |
|----------------|----------|-------|
| VARCHAR (일반 텍스트) | `p-input-box` | 기본 |
| VARCHAR (이름, 제목 등) | `p-input-box` | `maxlength` 설정 |
| TEXT (긴 텍스트) | `UTextarea` | NuxtUI 직접 사용 |
| TEXT (리치 텍스트) | `p-editor-quill` | 에디터 필요 시 |

```vue
<!-- 일반 텍스트 -->
<p-input-box v-model="data.subject" placeholder="제목" :maxlength="200" />

<!-- 긴 텍스트 -->
<UTextarea v-model="data.content" placeholder="내용" :rows="5" />
```

### 숫자 / 금액

| DB 컬럼 / 용도 | 컴포넌트 | Props |
|----------------|----------|-------|
| INT (일반 정수) | `p-input-box` | `type="number"` |
| DECIMAL(14,0) (금액) | `p-input-box` | `:is-comma="true" :is-right="true"` |
| DECIMAL(10,2) (소수점) | `p-input-box` | `type="number"` |

```vue
<!-- 금액 -->
<p-input-box v-model="data.price" :is-comma="true" :is-right="true" placeholder="0" />

<!-- 수량 -->
<p-input-box v-model="data.quantity" type="number" :min="0" placeholder="0" />
```

### 전화번호 / 특수 포맷

| DB 컬럼 / 용도 | 컴포넌트 | Props |
|----------------|----------|-------|
| hp_number (휴대폰) | `p-input-box` | `:is-hp-number="true"` |
| tel_number (전화번호) | `p-input-box` | `:is-tel-number="true"` |
| biz_number (사업자번호) | `p-input-box` | `:is-biz-number="true"` |
| card_number (카드번호) | `p-input-box` | `:is-card-number="true"` |
| jumin_number (주민번호) | `p-input-box` | `:is-jumin-number="true"` |

```vue
<!-- 전화번호 (자동 하이픈 + 다음 필드 포커스) -->
<p-input-box v-model="data.hpNumber" :is-hp-number="true" next-input="email" />
```

### 선택 (셀렉트)

| DB 컬럼 / 용도 | 컴포넌트 | 비고 |
|----------------|----------|------|
| CHAR(1) Y/N (사용여부) | `p-nuxt-select` | 전체/사용/미사용 |
| CHAR(1) 코드값 (상태) | `p-nuxt-select` | 코드별 옵션 |
| 참조 테이블 (FK) | `p-nuxt-select` | API로 옵션 조회 |
| Boolean 토글 | `USwitch` | NuxtUI 직접 사용 |

```vue
<!-- 검색 영역 셀렉트 (⚠️ @change 필수!) -->
<p-nuxt-select
  v-model="listParams.isUse"
  :options="[
    { text: '전체', value: '' },
    { text: '사용', value: 'Y' },
    { text: '미사용', value: 'N' }
  ]"
  @change="listAction"
/>

<!-- 폼 영역 셀렉트 -->
<p-nuxt-select
  v-model="detailData.status"
  :options="[
    { text: '활성', value: 'A' },
    { text: '비활성', value: 'I' }
  ]"
/>
```

### 날짜 / 기간

| DB 컬럼 / 용도 | 컴포넌트 | 비고 |
|----------------|----------|------|
| DATE (단일 날짜) | `p-date-picker-work` | 기본 날짜 선택 |
| DATETIME (날짜+시간) | `p-date-picker-work` | `:enable-time-picker="true"` |
| 기간 검색 (시작~종료) | `p-date-period` + `p-date-picker-work` × 2 | 3개 조합 |
| 월 선택 | `p-date-picker-work` | `:month-picker="true"` |
| 년 선택 | `p-date-picker-work` | `:year-picker="true"` |

```vue
<!-- ⚠️ 날짜 검색 표준 패턴 (검색 영역) -->
<div class="flex items-center gap-2">
  <p-date-period v-model="periodType" @setDate="handleSetDate" />
  <p-date-picker-work v-model="listParams.startDate" @update:modelValue="listAction" />
  <span class="text-neutral-400">~</span>
  <p-date-picker-work v-model="listParams.endDate" @update:modelValue="listAction" />
</div>

<!-- 폼 영역 단일 날짜 -->
<p-date-picker-work v-model="detailData.birthDate" />

<!-- 날짜+시간 -->
<p-date-picker-work
  v-model="detailData.reservationDate"
  :enable-time-picker="true"
  date-format="yyyy-MM-dd HH:mm"
  date-model="yyyy-MM-dd HH:mm:ss"
/>
```

### 파일

| DB 컬럼 / 용도 | 컴포넌트 | Props |
|----------------|----------|-------|
| 일반 파일 업로드 | `p-file-upload` | `storage-type="LOCAL"` |
| S3 파일 업로드 | `p-file-upload` | `storage-type="S3"` |
| 이미지만 허용 | `p-file-upload` | `:allowed-extensions="['jpg','png','gif']"` |
| 단일 파일 | `p-file-upload` | `:max-files="1"` |

```vue
<!-- 일반 파일 업로드 -->
<p-file-upload
  v-model="detailData.fileList"
  :upload-handler="store.uploadFileLocal"
  :down-url-resolver="store.getDownloadUrl"
  :max-files="10"
  storage-type="LOCAL"
/>

<!-- 이미지 전용 (5개 제한) -->
<p-file-upload
  v-model="detailData.imageList"
  :upload-handler="store.uploadFileLocal"
  :down-url-resolver="store.getDownloadUrl"
  :max-files="5"
  :allowed-extensions="['jpg', 'jpeg', 'png', 'gif', 'webp']"
  storage-type="LOCAL"
/>
```

---

## UI 상황별 컴포넌트 매핑

### 검색 영역 (list-search.vue)

| 요소 | 컴포넌트 | 필수 이벤트 |
|------|----------|------------|
| 키워드 검색 | `p-input-box` | `<form @submit.prevent="listAction">` |
| 상태 필터 | `p-nuxt-select` | `@change="listAction"` |
| 날짜 범위 | `p-date-period` + `p-date-picker-work` × 2 | `@update:modelValue="listAction"` |
| 정렬 | `p-nuxt-select` | `@change="listAction"` |

### 목록 테이블 (list-table.vue)

| 요소 | 컴포넌트 |
|------|----------|
| 테이블 | `EasyDataTable` 또는 `UTable` |
| 상태 배지 | `UBadge` |
| 액션 버튼 | `UButton` (size="xs" variant="ghost") |
| 페이지네이션 | `UPagination` |
| 행 개수 선택 | `p-nuxt-select` (`@change="listAction"`) |

### 등록/수정 모달 (insert.modal.vue, update.modal.vue)

| 요소 | 컴포넌트 |
|------|----------|
| 모달 컨테이너 | `p-modal` |
| 폼 그룹핑 | `p-form-group` |
| 텍스트 입력 | `p-input-box` |
| 셀렉트 | `p-nuxt-select` |
| 날짜 | `p-date-picker-work` |
| 파일 업로드 | `p-file-upload` |
| 토글 | `USwitch` |
| 저장/취소 | `UButton` |

### 상세 모달 (detail.modal.vue)

| 요소 | 컴포넌트 |
|------|----------|
| 항목 표시 | `p-detail-item` |
| 상태 배지 | `UBadge` (slot으로 삽입) |
| 파일 목록 | `p-file-upload` (readonly) |

---

## 주소 입력

| 상황 | 컴포넌트 |
|------|----------|
| 우편번호 + 주소 | `post-code` + `p-input-box` (상세주소) |

```vue
<post-code v-model:address="data.address" v-model:zipcode="data.zipcode" />
<p-input-box v-model="data.addressDetail" placeholder="상세주소" />
```

---

## Import 경로 정리

```typescript
// forms
import PInputBox from '@/modules/_common/components/forms/p-input-box.vue';
import PNuxtSelect from '@/modules/_common/components/forms/p-nuxt-select.vue';
import PFormGroup from '@/modules/_common/components/forms/p-form-group.vue';
import PDetailItem from '@/modules/_common/components/forms/p-detail-item.vue';

// date-picker
import PDatePickerWork from '@/modules/_common/components/date-picker/p-date-picker-work.vue';
import PDatePeriod from '@/modules/_common/components/date-picker/p-date-period.vue';

// modal
import PModal from '@/modules/_common/components/modal/p-modal.vue';
import PCommonModal from '@/modules/_common/components/modal/p-common-modal.vue';

// file
import PFileUpload from '@/modules/_common/components/file/p-file-upload.vue';
import type { FileInfo } from '@/modules/_common/type/file.type.ts';

// services
import { FormService } from '@/modules/_common/services/form.service.ts';
import { ExcelService } from '@/modules/_common/services/excel.service.ts';
```

> **참고**: 케밥케이스 태그 사용 시 import 없이 자동 인식되는 경우도 있음.
> 확실하지 않으면 명시적 import 권장.

---

## ⚠️ 절대 금지: NuxtUI 직접 사용 시

_common 래퍼가 있는데 NuxtUI 원본을 직접 사용하면 안 됩니다:

| ❌ 금지 | ✅ 올바른 사용 | 이유 |
|---------|--------------|------|
| `<UInput>` (텍스트) | `<p-input-box>` | 포맷팅 기능 누락 |
| `<USelect>` (셀렉트) | `<p-nuxt-select>` | 전체 옵션 처리 누락 |
| 직접 datepicker | `<p-date-picker-work>` | 한국어/스타일 누락 |
| 직접 모달 구현 | `<p-modal>` 또는 `<p-common-modal>` | 저장 연동/z-index 관리 누락 |
| 직접 file input | `<p-file-upload>` | 프로그레스/동시업로드 누락 |

**NuxtUI 직접 사용이 허용되는 경우:**
- `UButton` - 래퍼 없음
- `UBadge` - 래퍼 없음
- `UTabs` - 래퍼 없음
- `USwitch` - 래퍼 없음
- `UFormField` - 래퍼 없음
- `UTextarea` - 래퍼 없음
- `UTable` - 래퍼 없음
- `UPagination` - 래퍼 없음
