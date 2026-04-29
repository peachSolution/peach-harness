# Mock Store 패턴 가이드

## 개요

Backend API가 아직 없을 때, Mock 데이터 기반 Store를 먼저 생성합니다.
나중에 API 연결 시 **경로만 수정**하면 됩니다.

---

## Mock Store 예시

```typescript
// front/src/modules/[모듈명]/store/[모듈명].store.ts
import { defineStore } from 'pinia';
// import api from '@/modules/_common/services/api.service';  // API 준비 후 활성화

export const use[ModuleName]Store = defineStore('[moduleName]', {
  state: () => ({
    listData: [] as [ModuleName]Detail[],
    listTotalRow: 0,
    detailData: {} as [ModuleName]Detail
  }),

  actions: {
    async paging(params: [ModuleName]PagingDto) {
      // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
      // TODO: Backend API 완성 후 아래 코드로 교체
      // const res = await api.get('/[모듈명]/paging', { params });
      // this.listData = res.data.list;
      // this.listTotalRow = res.data.totalRow;
      // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

      // Mock 데이터 (임시)
      this.listData = [
        { [pk]Seq: 1, subject: '테스트1', isUse: 'Y', insertDate: '2024-01-01' },
        { [pk]Seq: 2, subject: '테스트2', isUse: 'N', insertDate: '2024-01-02' },
      ] as [ModuleName]Detail[];
      this.listTotalRow = 2;
    },

    async detail([pk]Seq: number) {
      // TODO: await api.get(`/[모듈명]/${[pk]Seq}`);
      this.detailData = this.listData.find(d => d.[pk]Seq === [pk]Seq) || {} as [ModuleName]Detail;
    },

    async insert(data: [ModuleName]InsertDto) {
      // TODO: await api.post('/[모듈명]', data);
      console.log('Mock insert:', data);
      return { [pk]Seq: Date.now() };
    },

    async update([pk]Seq: number, data: [ModuleName]UpdateDto) {
      // TODO: await api.put(`/[모듈명]/${[pk]Seq}`, data);
      console.log('Mock update:', [pk]Seq, data);
    },

    async softDelete([pk]Seq: number) {
      // TODO: await api.delete(`/[모듈명]/${[pk]Seq}`);
      console.log('Mock delete:', [pk]Seq);
    }
  }
});
```

---

## Backend API 연결 시 수정 포인트

```typescript
// Before (Mock)
async paging(params: PagingDto) {
  // Mock 데이터
  this.listData = [...];
}

// After (API 연결) - 경로만 수정!
async paging(params: PagingDto) {
  const res = await api.get('/[모듈명]/paging', { params });
  this.listData = res.data.list;
  this.listTotalRow = res.data.totalRow;
}
```

---

## API 연결 체크리스트

Backend API 완성 후:
- [ ] `import api` 활성화
- [ ] 각 action에서 `api.get/post/put/delete` 호출로 교체
- [ ] Mock 데이터 코드 제거
- [ ] 응답 구조 확인 (`list`, `totalRow` 등)

---

## test-data Store 참조

실제 API 연결된 Store 예시는 `front/src/modules/test-data/store/test-data.store.ts` 참조
