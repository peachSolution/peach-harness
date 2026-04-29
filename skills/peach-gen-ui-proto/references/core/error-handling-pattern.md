# Error Handling 패턴 가이드

> test-data 모듈의 검증된 에러 처리 패턴 (실제 운영 코드 기반)

---

## 📋 목차

1. [FormService 에러 처리 패턴](#1-formservice-에러-처리-패턴)
2. [Toast 알림 패턴](#2-toast-알림-패턴)
3. [try-catch + Toast 패턴](#3-try-catch--toast-패턴)
4. [API 에러 처리 (자동 인터셉터)](#4-api-에러-처리-자동-인터셉터)
5. [Store 액션 에러 처리](#5-store-액션-에러-처리)
6. [DO/DON'T 정리](#6-dodont-정리)

---

## 1. FormService 에러 처리 패턴

### 1.1 FormService.loading() - 자동 try-catch-finally (⭐ 가장 일반적)

**파일**: `front/src/modules/_common/services/form.service.ts:17-29`

```typescript
/**
 * 비동기 작업 로딩 상태 관리
 * try-catch-finally 자동 처리, 로딩 스피너 자동 표시
 */
static async loading(callback: any, isUse: boolean = true): Promise<void> {
  const defaultLayoutStore = useDefaultLayoutStore();
  try {
    defaultLayoutStore.loading(true, isUse);  // 로딩 시작
    await callback();                          // 비동기 작업 실행
  } catch (error) {
    throw error;  // 에러 재발생 → 호출처 또는 인터셉터에서 처리
  } finally {
    defaultLayoutStore.loading(false, isUse); // 로딩 종료 (항상 실행)
  }
}
```

**특징:**
- ✅ try-catch-finally 자동 처리
- ✅ 로딩 스피너 자동 표시/숨김
- ✅ 에러 발생 시에도 반드시 로딩 종료
- ✅ 에러는 호출처로 전파 (재발생)

**사용 시점:**
- 모든 CRUD 작업
- API 호출이 필요한 비동기 작업
- 사용자에게 대기 중임을 알려야 하는 경우

**호출 패턴:**
```typescript
// 기본 사용 (가장 일반적)
await FormService.loading(async () => {
  await store.insert(formData);
  FormService.toastMessage('저장되었습니다.', 'success');
});
```

---

### 1.2 FormService.toastMessage() - 간편 메시지 표시

**파일**: `front/src/modules/_common/services/form.service.ts:79-81`

```typescript
/**
 * Toast 메시지 표시
 * @param message 메시지 내용
 * @param msgType 'success' | 'error' | 'info'
 */
static toastMessage(message: string, msgType: 'success' | 'error' | 'info' = 'info') {
  const toastStore = useToastStore();
  toastStore.showToast(message, msgType);
}
```

**사용 예시:**
```typescript
// 성공 메시지
FormService.toastMessage('저장되었습니다.', 'success');

// 에러 메시지
FormService.toastMessage('오류가 발생했습니다.', 'error');

// 정보 메시지
FormService.toastMessage('처리 중입니다...', 'info');
```

**특징:**
- ✅ 간결한 호출
- ✅ 3가지 타입 지원 (success, error, info)
- ✅ 자동 1.8초 후 사라짐
- ✅ 여러 toast 동시 표시 가능

---

### 1.3 FormService.onError() - 폼 검증 에러 처리

**파일**: `front/src/modules/_common/services/form.service.ts:84-111`

```typescript
/**
 * 폼 검증 에러 처리
 * Yup 유효성 검증 실패 시 자동 포커스 및 스크롤
 * @param event FormErrorEvent (Vue Form)
 */
static onError(event: FormErrorEvent) {
  const defaultLayoutStore = useDefaultLayoutStore();
  const errorItem = event.errors[0];

  // 첫 번째 에러 메시지 표시
  if (errorItem) {
    defaultLayoutStore.modalMsg(MessageType.Warning, errorItem.message);
  }

  // 에러가 발생한 필드로 포커스 및 스크롤
  const firstErrorField = Object.keys(event.errors)[0];
  const element = document.querySelector(`[name="${firstErrorField}"]`) as HTMLElement;

  if (element) {
    element.focus();
    element.scrollIntoView({ behavior: 'smooth', block: 'center' });
  }
}
```

**사용 패턴:**
```vue
<template>
  <u-form :state="detailData" @error="handleFormError">
    <u-form-field label="이름" name="name">
      <u-input v-model="detailData.name" />
    </u-form-field>

    <u-button type="submit">저장</u-button>
  </u-form>
</template>

<script setup lang="ts">
const handleFormError = (event: FormErrorEvent) => {
  FormService.onError(event);
};
</script>
```

**특징:**
- ✅ 첫 번째 에러 메시지 모달 표시
- ✅ 에러 필드로 자동 포커스
- ✅ 에러 필드로 자동 스크롤 (UX 개선)
- ✅ Yup validation과 완벽 통합

---

## 2. Toast 알림 패턴

### 2.1 useToast().add() - 상세 제어

**파일**: `front/src/modules/test-data/modals/insert.modal.vue:180-184`

```typescript
// 성공 메시지 (상세)
useToast().add({
  title: '등록 완료',
  description: '등록이 완료되었습니다.',
  color: 'success'
});

// 에러 메시지 (상세)
useToast().add({
  title: '엑셀 다운로드 오류',
  description: `엑셀 파일 다운로드 중 오류가 발생했습니다: ${error}`,
  color: 'error'
});
```

**특징:**
- ✅ title + description 분리 가능
- ✅ 에러 상세 정보 포함 가능
- ✅ color로 시각적 구분 (success, error, info, warning)

**사용 시점:**
- 상세한 메시지가 필요한 경우
- 에러 내용을 포함해야 하는 경우

---

### 2.2 FormService.toastMessage() vs useToast().add()

| 구분 | FormService.toastMessage() | useToast().add() |
|-----|---------------------------|------------------|
| **간결성** | ⭐⭐⭐ 간결함 | ⭐⭐ 보통 |
| **상세 제어** | ⭐ 제한적 | ⭐⭐⭐ 상세함 |
| **사용 시점** | 간단한 알림 | 복잡한 알림 |
| **메시지 구조** | 한 줄 텍스트 | title + description |

---

## 3. try-catch + Toast 패턴

### 3.1 엑셀 다운로드 패턴

**파일**: `front/src/modules/test-data/pages/crud-excel/list-table.vue:204-236`

```typescript
/**
 * 엑셀 다운로드
 * FormService.loading 내부 try-catch로 에러 처리
 */
const downloadExcel = async () => {
  await FormService.loading(async () => {
    try {
      // 1단계: API 호출
      const blob = await testDataStore.downloadExcel(listParams.value);

      // 2단계: Blob 다운로드
      const url = window.URL.createObjectURL(blob);
      const link = document.createElement('a');
      link.href = url;
      link.download = `test-data-${dayjs().format('YYYY-MM-DD')}.xlsx`;
      document.body.appendChild(link);
      link.click();

      // 3단계: 리소스 정리
      document.body.removeChild(link);
      window.URL.revokeObjectURL(url);

      // 4단계: 성공 메시지
      useToast().add({
        title: '엑셀 다운로드',
        description: '엑셀 파일이 성공적으로 다운로드되었습니다.',
        color: 'success'
      });
    } catch (error) {
      console.error('❌ 엑셀 다운로드 오류:', error);

      // 5단계: 에러 메시지
      useToast().add({
        title: '엑셀 다운로드 오류',
        description: `엑셀 파일 다운로드 중 오류가 발생했습니다: ${error}`,
        color: 'error'
      });
    }
  });
};
```

**특징:**
- ✅ FormService.loading() 으로 로딩 자동 관리
- ✅ try-catch로 에러 핸들링
- ✅ 성공/실패 모두 toast 표시
- ✅ console.error로 디버깅 정보 남김
- ✅ 리소스 정리 (URL.revokeObjectURL)

---

### 3.2 엑셀 업로드 패턴 (행별 에러 처리)

**파일**: `front/src/modules/test-data/modals/excel-upload.modal.vue:487-523`

```typescript
/**
 * 엑셀 데이터 업로드
 * 중첩 try-catch로 전체/행별 에러 분리 처리
 */
const uploadData = async () => {
  try {
    // 선택된 행들을 순차적으로 업로드
    for (const rowIndex of selectedRows.value) {
      const adjustedIndex = rowIndex - 1;

      // 업로드 시작
      rowUploadStatus.value[adjustedIndex] = 'loading';
      rowUploadMethod.value[adjustedIndex] = '';

      try {
        // DTO 생성 및 API 호출
        const dto = createUploadDto(
          excelData.value[adjustedIndex],
          columnSelections.value
        );
        const result = await uploadApi(dto);

        // 성공 처리
        rowUploadStatus.value[adjustedIndex] = 'success';
        rowUploadMethod.value[adjustedIndex] = result.method;
      } catch (error) {
        // 행별 실패 처리
        rowUploadStatus.value[adjustedIndex] = 'failure';
        console.error(`Row ${rowIndex} upload failed:`, error);
      }
    }

    // 업로드 완료 이벤트
    emits('upload-ok');
  } catch (error) {
    console.error('Upload process failed:', error);

    // 처리 중이던 행들을 실패로 설정
    selectedRows.value.forEach(rowIndex => {
      const adjustedIndex = rowIndex - 1;
      if (rowUploadStatus.value[adjustedIndex] === 'loading') {
        rowUploadStatus.value[adjustedIndex] = 'failure';
      }
    });
  }
};
```

**특징:**
- ✅ 중첩 try-catch (전체 + 행별)
- ✅ 행별 상태 관리 (pending/loading/success/failure)
- ✅ 부분 실패에도 계속 처리
- ✅ UI에 진행 상황 실시간 표시

**언제 사용?**
- 여러 항목을 순차적으로 처리
- 일부 실패해도 나머지는 계속 처리
- 사용자에게 각 항목의 성공/실패 표시 필요

---

## 4. API 에러 처리 (자동 인터셉터)

### 4.1 공통 에러 인터셉터

**파일**: `front/src/modules/_common/services/api.service.ts:71-102`

```typescript
/**
 * 응답 에러 인터셉터
 * 모든 API 호출의 에러를 자동으로 처리
 */
const errorInterceptor = async (error: any) => {
  logApiInfo('ERROR', error);

  if (error.response) {
    const { status, data } = error.response;

    // 401 에러 (Unauthorized) - 자동 처리
    if (status === 401) {
      await handle401Error(status);
      return Promise.reject(error);
    }

    // 기타 응답 에러
    if (!useCommonErrorHandler) {
      return Promise.reject(error); // 호출처에서 처리
    }

    handleResponseError(data);
  } else {
    // 네트워크 오류
    if (!useCommonErrorHandler) {
      return Promise.reject(error);
    }

    handleNetworkError(error);
  }

  return Promise.reject(error);
};
```

**특징:**
- ✅ 모든 API 에러를 자동으로 가로챔
- ✅ 401 에러는 자동 로그아웃 처리
- ✅ 네트워크 에러는 자동 알림
- ✅ useCommonErrorHandler로 선택적 처리 가능

---

### 4.2 401 Unauthorized 에러 처리

**파일**: `front/src/modules/_common/services/api.service.ts:195-211`

```typescript
let isHandling401Error = false;  // 중복 처리 방지 플래그

/**
 * 401 에러 처리 (자동 로그아웃)
 * 중복 처리 방지 로직 포함
 */
const handle401Error = async (status: number) => {
  if (!isHandling401Error) {
    isHandling401Error = true;

    // 에러 메시지 표시
    FormService.toastMessage(
      `오류 (${status}) : 로그인 정보가 만료되었습니다. 다시 로그인 해주세요.`,
      'error'
    );

    // 로그아웃 처리
    const store = useAuthStore();
    await store.logout();

    // 2초 후 플래그 해제 (중복 처리 방지)
    setTimeout(() => {
      isHandling401Error = false;
    }, 2000);
  }
  return true;
};
```

**특징:**
- ✅ 전역 플래그로 중복 처리 방지
- ✅ 자동 로그아웃
- ✅ Toast로 사용자 알림
- ✅ 로그인 페이지로 자동 이동

---

### 4.3 일반 응답 에러 처리

**파일**: `front/src/modules/_common/services/api.service.ts:219-227`

```typescript
/**
 * 일반 응답 에러 처리
 * 환경별로 다른 처리 (test vs prod)
 */
const handleResponseError = (data: any) => {
  const errorMessage = data?.error?.message || '서버 오류가 발생했습니다.';

  if (import.meta.env.MODE === 'test') {
    // 테스트 환경: console만
    console.log('response error', errorMessage);
  } else {
    // 운영 환경: 모달 표시
    const defaultLayoutStore = useDefaultLayoutStore();
    defaultLayoutStore.modalMsg(MessageType.Warning, errorMessage);
  }
};
```

**특징:**
- ✅ 환경별 처리 (test / prod)
- ✅ 에러 메시지 자동 추출
- ✅ 기본 메시지 제공

---

### 4.4 네트워크 에러 처리

**파일**: `front/src/modules/_common/services/api.service.ts:233-242`

```typescript
/**
 * 네트워크 에러 처리
 * 서버 연결 불가 시 처리
 */
const handleNetworkError = (error: any) => {
  const message = '서버에 연결할 수 없습니다. 네트워크 연결을 확인해주세요.';

  if (import.meta.env.MODE === 'test') {
    console.log(message, error);
    return;
  } else {
    const defaultLayoutStore = useDefaultLayoutStore();
    defaultLayoutStore.modalMsg(MessageType.Warning, message);
  }
};
```

**특징:**
- ✅ 네트워크 연결 문제 감지
- ✅ 사용자 친화적 메시지
- ✅ 환경별 처리

---

## 5. Store 액션 에러 처리

### 5.1 기본 패턴: Promise 반환 (에러 위임)

**파일**: `front/src/modules/test-data/store/test-data.store.ts:110-120`

```typescript
/**
 * 데이터 등록
 * Promise를 그대로 반환 → 호출처에서 에러 처리
 */
insert(params: TestDataInsertDto): Promise<{ isSuccess: boolean; testSeq: number }> {
  return useApi().post<{ isSuccess: boolean; testSeq: number }>('/test-data', params);
}

/**
 * 데이터 수정
 */
update(testSeq: number, params: TestDataUpdateDto): Promise<{ isSuccess: boolean }> {
  return useApi().put<{ isSuccess: boolean }>(`/test-data/${testSeq}`, params);
}
```

**특징:**
- ✅ Promise 그대로 반환
- ✅ 에러는 호출처 (컴포넌트)에서 처리
- ✅ API 인터셉터가 공통 에러 처리

**호출 패턴:**
```typescript
// 컴포넌트에서 호출
try {
  const result = await testDataStore.insert(formData);
  if (result.isSuccess) {
    FormService.toastMessage('등록되었습니다.', 'success');
  }
} catch (error) {
  // 인터셉터가 이미 처리했으므로 추가 처리 불필요
}
```

---

### 5.2 조건부 에러: 환경 체크

**파일**: `front/src/modules/test-data/store/test-data.store.ts:149-156`

```typescript
/**
 * 물리 삭제 (테스트 환경 전용)
 * 운영 환경에서는 에러 발생
 */
hardDelete(testSeq: number): Promise<{ isSuccess: boolean }> {
  const env = import.meta.env.MODE;

  // 환경 체크
  if (env !== 'local' && env !== 'test') {
    throw new Error('hardDelete는 테스트 환경에서만 사용 가능합니다.');
  }

  return useApi().delete<{ isSuccess: boolean }>(`/test-data/${testSeq}`);
}
```

**특징:**
- ✅ 환경별 접근 제한
- ✅ 명시적 에러 발생
- ✅ 운영 환경 실수 방지

---

### 5.3 데이터 검증 에러

**파일**: `front/src/modules/test-data/store/test-data.store.ts:216-277`

```typescript
/**
 * S3 파일 업로드
 * 데이터 검증 실패 시 에러 발생
 */
async uploadFileS3(
  isPrivate: boolean,
  file: File,
  callback: ProgressCallback
): Promise<TestDataFileS3UploadResult> {
  const res = await useApi().post<TestDataFileS3UploadResult>(...);

  // 응답 검증
  if (!res?.uploadUrl) {
    throw new Error('Upload URL not received from server');
  }

  await this.uploadFileToS3(res.uploadUrl, file, callback);
  return res;
}

/**
 * 다운로드 URL 생성
 * 조건에 맞지 않으면 에러 발생
 */
getDownloadUrl(file: TestDataFile): string {
  // PRIVATE 파일 검증
  if (file.fileAuth === 'PRIVATE') {
    throw new Error('비공개 파일은 직접 다운로드 불가');
  }

  // 환경 변수 검증
  if (!import.meta.env.VITE_FILE_HOST) {
    throw new Error('VITE_FILE_HOST 환경변수 필수');
  }

  return `${import.meta.env.VITE_FILE_HOST}/${file.filePath}`;
}
```

**특징:**
- ✅ 명시적 데이터 검증
- ✅ 명확한 에러 메시지
- ✅ 조기 에러 발생 (fail-fast)

---

## 6. DO/DON'T 정리

### ✅ DO (권장 패턴)

| 패턴 | 예시 | 이유 |
|-----|------|------|
| FormService.loading() 사용 | CRUD 작업 | 자동 로딩 스피너 관리 |
| Toast 메시지 (성공/실패) | `FormService.toastMessage('완료', 'success')` | 사용자 피드백 제공 |
| Promise 반환 (Store) | API 호출 그대로 반환 | 호출처에서 유연한 처리 |
| Confirm 대화상자 | 삭제 전 확인 | 실수 방지 |
| UI 즉시 업데이트 | `isUse.value[item] = true` | 응답성 개선 |
| 환경별 에러 처리 | `MODE === 'test'` 시 console만 | 테스트/운영 분리 |
| 행별 에러 처리 | 엑셀 업로드 | 부분 성공 지원 |

### ❌ DON'T (금지 패턴)

| 패턴 | 문제점 |
|-----|--------|
| Store에서 toast 직접 호출 | 관심사 분리 위반 |
| API 에러를 무시 | 사용자가 상태를 모름 |
| try-catch 없이 비동기 | 예기치 않은 에러 |
| FormService.loading() 없이 API 호출 | 사용자가 대기 중인지 모름 |
| 하드코딩된 에러 메시지 | 유지보수 어려움 |
| console.error만 사용 | 운영 환경에서 사용자 통보 X |
| 전역 에러 처리 + 로컬 처리 중복 | 메시지 표시 2번 |

---

## 7. 계층별 에러 처리 책임

| 계층 | 담당 | 방식 |
|-----|-----|------|
| **API 인터셉터** | 401, 네트워크 에러 | 자동 처리 (공통) |
| **Store** | 데이터 검증 | throw new Error() |
| **컴포넌트** | 사용자 피드백 | toast + confirm |
| **FormService** | UI 상태 관리 | loading/toast/modal |

---

## 8. 실제 사용 예시 모음

### 예시 1: 기본 CRUD (toast 포함)
```typescript
await FormService.loading(async () => {
  const result = await store.insert(data);
  if (result.isSuccess) {
    FormService.toastMessage('저장되었습니다.', 'success');
    emit('insert-ok');
  }
});
```

### 예시 2: 파일 다운로드 (try-catch)
```typescript
await FormService.loading(async () => {
  try {
    const blob = await store.downloadExcel(params);
    // 다운로드 로직
    useToast().add({ title: '완료', color: 'success' });
  } catch (error) {
    useToast().add({ title: '오류', color: 'error' });
  }
});
```

### 예시 3: 행별 처리 (엑셀 업로드)
```typescript
try {
  for (const rowIndex of selectedRows) {
    rowStatus[rowIndex] = 'loading';
    try {
      await uploadApi(data);
      rowStatus[rowIndex] = 'success';
    } catch (error) {
      rowStatus[rowIndex] = 'failure';
    }
  }
} catch (error) {
  // 전체 실패 처리
}
```

### 예시 4: API 에러 자동 처리
```typescript
// api.service.ts의 인터셉터가 자동 처리
// 호출처는 성공만 처리하면 됨
const result = await useApi().get('/data');
if (result) {
  // 성공 처리
}
```

---

## 핵심 규칙

1. **모든 비동기 작업은 `FormService.loading()` 으로 감싸기**
2. **성공/실패 모두 toast로 알리기**
3. **중요 작업은 confirm으로 확인받기**
4. **Store는 에러 throw, 컴포넌트는 catch+toast**
5. **API는 인터셉터가 공통 처리, 호출처는 성공만 처리**

---

**참고 파일:**
- `front/src/modules/_common/services/form.service.ts`
- `front/src/modules/_common/services/api.service.ts`
- `front/src/modules/test-data/pages/crud/list-table.vue`
- `front/src/modules/test-data/modals/insert.modal.vue`
- `front/src/modules/test-data/modals/excel-upload.modal.vue`
