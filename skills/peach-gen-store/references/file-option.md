# file 옵션 처리 가이드 (Store)

## file=N (기본)

파일 관련 함수 제외:
- uploadFileLocal ❌
- uploadFileS3 ❌
- getDownloadUrl ❌

---

## file=Y

### Type 추가

```typescript
// 파일 인터페이스
export interface FileItem {
  fileSeq: number;
  fileName: string;
  fileSize: number;
  filePath: string;
  fileType: string;
  createdAt: string;
}

// 파일 UUID
export interface FileUuid {
  uuid: string;
  fileName: string;
}
```

### Store Actions 추가

```typescript
actions: {
  // 로컬 파일 업로드
  async uploadFileLocal(file: File, parentCode: string) {
    const { $api } = useNuxtApp();
    const formData = new FormData();
    formData.append('file', file);
    formData.append('parentCode', parentCode);

    const res = await $api.post('file/upload/local', formData, {
      headers: { 'Content-Type': 'multipart/form-data' },
    });
    return res;
  },

  // S3 파일 업로드
  async uploadFileS3(file: File, parentCode: string) {
    const { $api } = useNuxtApp();
    const formData = new FormData();
    formData.append('file', file);
    formData.append('parentCode', parentCode);

    const res = await $api.post('file/upload/s3', formData, {
      headers: { 'Content-Type': 'multipart/form-data' },
    });
    return res;
  },

  // 다운로드 URL 조회
  async getDownloadUrl(fileSeq: number) {
    const { $api } = useNuxtApp();
    const res = await $api.get(`file/download/${fileSeq}`);
    return res;
  },
}
```
