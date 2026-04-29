# 인쇄 컴포넌트 템플릿

## 세련된 인쇄 페이지 구조

```vue
<template>
  <div class="print-container">
    <!-- 문서 헤더 -->
    <header class="print-header">
      <h1 class="print-title">{{ mainData.year }}년 {{ mainData.clientName }} 매출채권 원장</h1>
      <div class="print-meta">
        <span>출력일: {{ printDate }}</span>
      </div>
    </header>

    <!-- 요약 정보 박스 -->
    <section class="print-summary">
      <div class="summary-grid">
        <div class="summary-item">
          <span class="summary-label">이월미수금</span>
          <span class="summary-value">{{ mainData.balanceAmnt.toLocaleString() }}원</span>
        </div>
        <div class="summary-item">
          <span class="summary-label">집계기간</span>
          <span class="summary-value">{{ params.startDate }} ~ {{ params.endDate }}</span>
        </div>
        <div class="summary-item highlight">
          <span class="summary-label">미수금 잔액</span>
          <span class="summary-value negative">{{ mainData.totalBalance.toLocaleString() }}원</span>
        </div>
      </div>
    </section>

    <!-- 데이터 테이블 -->
    <section class="print-content">
      <table class="print-table">
        <thead>
          <tr>
            <th class="col-date">월/일</th>
            <th class="col-desc">적요</th>
            <th class="col-amount">차변</th>
            <th class="col-amount">대변</th>
            <th class="col-amount">잔액</th>
          </tr>
        </thead>
        <tbody>
          <tr v-if="list.length === 0">
            <td colspan="5" class="empty-row">데이터가 없습니다.</td>
          </tr>
          <template v-for="(item, index) in list" :key="index">
            <!-- 월계 구분선 -->
            <tr v-if="shouldShowMonthTotal(index)" class="month-total-row">
              <td></td>
              <td class="month-total-label">월계</td>
              <td class="text-right">{{ getMonthTotal(index - 1, 'left').toLocaleString() }}</td>
              <td class="text-right">{{ getMonthTotal(index - 1, 'right').toLocaleString() }}</td>
              <td></td>
            </tr>
            <!-- 데이터 행 -->
            <tr :class="{ 'new-month': item.isNewMonth }">
              <td>{{ item.date }}</td>
              <td class="text-left">{{ item.description }}</td>
              <td class="text-right">{{ item.leftAmnt.toLocaleString() }}</td>
              <td class="text-right">{{ item.rightAmnt.toLocaleString() }}</td>
              <td class="text-right" :class="{ 'negative': item.balance < 0 }">
                {{ item.balance.toLocaleString() }}
              </td>
            </tr>
          </template>
          <!-- 최종 합계 -->
          <tr class="total-row">
            <td colspan="2" class="total-label">합계</td>
            <td class="text-right">{{ totalLeft.toLocaleString() }}</td>
            <td class="text-right">{{ totalRight.toLocaleString() }}</td>
            <td class="text-right negative">{{ mainData.totalBalance.toLocaleString() }}</td>
          </tr>
        </tbody>
      </table>
    </section>

    <!-- 문서 푸터 -->
    <footer class="print-footer">
      <div class="footer-left">
        {{ mainData.clientName }} - 매출채권 원장
      </div>
      <div class="footer-right">
        <!-- CSS counter로 페이지 번호 자동 생성 -->
      </div>
    </footer>
  </div>
</template>

<script setup lang="ts">
import { ref, computed, onMounted } from 'vue';
import { useRoute } from 'vue-router';
import dayjs from 'dayjs';

const route = useRoute();
const printDate = dayjs().format('YYYY-MM-DD HH:mm');

// 파라미터
const params = ref({
  clientSeq: 0,
  year: new Date().getFullYear().toString(),
  startDate: '',
  endDate: ''
});

// 메인 데이터
const mainData = ref({
  year: '',
  clientName: '',
  balanceAmnt: 0,
  totalBalance: 0
});

// 목록 데이터
const list = ref<any[]>([]);

// 합계 계산
const totalLeft = computed(() => list.value.reduce((sum, item) => sum + item.leftAmnt, 0));
const totalRight = computed(() => list.value.reduce((sum, item) => sum + item.rightAmnt, 0));

// 날짜 범위 설정
const setDateRange = () => {
  const year = parseInt(params.value.year, 10);
  const now = new Date();
  params.value.startDate = `${year}-01-01`;
  params.value.endDate = year === now.getFullYear()
    ? now.toISOString().split('T')[0]
    : `${year}-12-31`;
};

// 월계 표시 여부
const shouldShowMonthTotal = (index: number) => {
  return index > 0 && list.value[index].isNewMonth;
};

// 월 합계 계산
const getMonthTotal = (index: number, type: 'left' | 'right') => {
  const month = list.value[index].date.slice(0, 7);
  const field = type === 'left' ? 'leftAmnt' : 'rightAmnt';
  return list.value
    .slice(0, index + 1)
    .filter(item => item.date.slice(0, 7) === month)
    .reduce((sum, item) => sum + item[field], 0);
};

// 데이터 조회
const getList = async () => {
  setDateRange();
  // API 호출 로직
  // const result = await SomeService.getList(params.value);
  // list.value = result.content;
};

onMounted(async () => {
  // URL 파라미터 추출
  params.value.clientSeq = parseInt(String(route.query.clientSeq)) || 0;
  params.value.year = String(route.query.year) || new Date().getFullYear().toString();
  mainData.value.year = params.value.year;

  if (params.value.clientSeq > 0) {
    await getList();
    // 데이터 로드 후 자동 인쇄
    setTimeout(() => window.print(), 500);
  }
});
</script>

<style scoped>
/* ===================================
   인쇄 전용 스타일 시스템
   =================================== */

/* 기본 컨테이너 */
.print-container {
  max-width: 210mm;  /* A4 너비 */
  margin: 0 auto;
  padding: 15mm;
  background: #fff;
  font-family: 'Noto Sans KR', 'Malgun Gothic', -apple-system, sans-serif;
  font-size: 10pt;
  line-height: 1.5;
  color: #1a1a1a;
}

/* ===== 문서 헤더 ===== */
.print-header {
  text-align: center;
  margin-bottom: 8mm;
  padding-bottom: 5mm;
  border-bottom: 2px solid #1a1a1a;
}

.print-title {
  font-size: 16pt;
  font-weight: 700;
  letter-spacing: -0.02em;
  margin: 0 0 3mm 0;
  color: #000;
}

.print-meta {
  font-size: 9pt;
  color: #666;
}

/* ===== 요약 정보 박스 ===== */
.print-summary {
  margin-bottom: 6mm;
  padding: 4mm 5mm;
  background: #f8f9fa;
  border: 1px solid #e9ecef;
  border-radius: 2px;
}

.summary-grid {
  display: flex;
  justify-content: space-between;
  align-items: center;
}

.summary-item {
  display: flex;
  flex-direction: column;
  gap: 1mm;
}

.summary-label {
  font-size: 8pt;
  color: #666;
  font-weight: 500;
}

.summary-value {
  font-size: 11pt;
  font-weight: 600;
  color: #1a1a1a;
}

.summary-item.highlight {
  padding: 3mm 5mm;
  background: #fff;
  border: 1px solid #dee2e6;
  border-radius: 2px;
}

.summary-value.negative {
  color: #dc2626;
  font-weight: 700;
}

/* ===== 데이터 테이블 ===== */
.print-table {
  width: 100%;
  border-collapse: collapse;
  font-size: 9pt;
}

.print-table thead {
  display: table-header-group;  /* 페이지마다 헤더 반복 */
}

.print-table th {
  padding: 3mm 2mm;
  background: #f1f3f4;
  border-top: 2px solid #1a1a1a;
  border-bottom: 1px solid #1a1a1a;
  font-weight: 600;
  text-align: center;
  white-space: nowrap;
}

.print-table td {
  padding: 2.5mm 2mm;
  border-bottom: 1px solid #dee2e6;
  text-align: center;
}

/* 컬럼 너비 */
.col-date { width: 18%; }
.col-desc { width: 34%; }
.col-amount { width: 16%; }

/* 텍스트 정렬 */
.text-left { text-align: left; }
.text-right { text-align: right; }

/* 음수 강조 */
td.negative {
  color: #dc2626;
  font-weight: 600;
}

/* 빈 데이터 */
.empty-row {
  padding: 10mm 0;
  color: #999;
  font-style: italic;
}

/* 월계 행 */
.month-total-row {
  background: #f8f9fa;
}

.month-total-row td {
  border-top: 1px solid #adb5bd;
  border-bottom: 1px solid #adb5bd;
  font-weight: 600;
}

.month-total-label {
  font-weight: 600;
  color: #495057;
}

/* 새 월 시작 */
.new-month td {
  border-top: 1px solid #adb5bd;
}

/* 최종 합계 */
.total-row {
  background: #e9ecef;
}

.total-row td {
  border-top: 2px solid #1a1a1a;
  border-bottom: 2px solid #1a1a1a;
  font-weight: 700;
  padding: 3mm 2mm;
}

.total-label {
  text-align: center;
  font-weight: 700;
}

/* ===== 문서 푸터 ===== */
.print-footer {
  display: flex;
  justify-content: space-between;
  margin-top: 8mm;
  padding-top: 4mm;
  border-top: 1px solid #dee2e6;
  font-size: 8pt;
  color: #868e96;
}

/* ===== 인쇄 미디어 쿼리 ===== */
@media print {
  @page {
    size: A4;
    margin: 10mm;
  }

  .print-container {
    padding: 0;
    max-width: none;
  }

  /* 페이지 브레이크 제어 */
  .print-header { page-break-after: avoid; }
  .print-summary { page-break-inside: avoid; }
  .total-row { page-break-inside: avoid; }

  /* 테이블 행 분리 방지 */
  tr { page-break-inside: avoid; }

  /* 배경색 출력 강제 */
  * {
    -webkit-print-color-adjust: exact !important;
    print-color-adjust: exact !important;
  }

  /* 고아/과부 줄 방지 */
  p, li { orphans: 3; widows: 3; }
}

/* ===== 화면용 프리뷰 스타일 ===== */
@media screen {
  .print-container {
    box-shadow: 0 0 10px rgba(0, 0, 0, 0.1);
  }
}
</style>
```

## 핵심 디자인 요소

### 1. 정보 계층

- **레벨 1**: 문서 타이틀 (16pt, Bold)
- **레벨 2**: 요약 정보 박스 (배경색 구분)
- **레벨 3**: 테이블 헤더 (배경색, 굵은 테두리)
- **레벨 4**: 데이터 행 (깔끔한 구분선)
- **레벨 5**: 푸터 (작은 글씨, 회색)

### 2. 색상 시스템

```css
/* 인쇄 최적화 팔레트 */
--text-primary: #1a1a1a;    /* 본문 */
--text-secondary: #666666;  /* 보조 텍스트 */
--text-muted: #868e96;      /* 푸터 등 */
--negative: #dc2626;        /* 음수/경고 */
--border-dark: #1a1a1a;     /* 강조 테두리 */
--border-light: #dee2e6;    /* 일반 테두리 */
--bg-header: #f1f3f4;       /* 테이블 헤더 */
--bg-summary: #f8f9fa;      /* 요약 박스 */
```

### 3. 타이포그래피

```css
/* 인쇄용 폰트 크기 체계 */
--title: 16pt;      /* 문서 제목 */
--subtitle: 12pt;   /* 섹션 제목 */
--body: 10pt;       /* 본문 */
--table: 9pt;       /* 테이블 내용 */
--caption: 8pt;     /* 캡션, 푸터 */
```

### 4. 페이지 브레이크

```css
/* 분리 방지 */
page-break-inside: avoid;  /* 요소 내부 분리 금지 */

/* 분리 강제 */
page-break-before: always; /* 요소 앞에서 페이지 분리 */
page-break-after: always;  /* 요소 뒤에서 페이지 분리 */
```
