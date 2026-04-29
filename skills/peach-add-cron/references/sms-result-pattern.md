# SMS Result Service 크론 패턴 분석

## 핵심 패턴

### 1. 적응형 스케줄러 구조

```typescript
static async startScheduler(): Promise<void> {
  while (true) {
    try {
      await SmsResultService.processOnce();
    } catch (error) {
      logger.error('[SMS] 처리 오류:', error);
      await SmsResultService.sleep(60000); // 에러 시 1분 대기
    }
  }
}
```

**특징**:
- 무한 루프 백그라운드 실행
- 처리 후 다음 실행 시점을 동적으로 결정
- 에러 발생 시 1분 대기 후 재시도

### 2. 처리 사이클 로직

```typescript
private static async processOnce(): Promise<void> {
  let consecutiveRuns = 0;
  const MAX_CONSECUTIVE = 10;

  while (consecutiveRuns < MAX_CONSECUTIVE) {
    // 1. 미처리 건수 확인
    const processableCount = await SmsResultDao.countPendingSms();

    // 2. 미처리 없음 → 30초 대기 후 종료
    if (processableCount === 0) {
      await SmsResultService.sleep(30000);
      break;
    }

    // 3. 처리 실행
    await SmsResultService.processSmsResults({ limit: 50, hours: 24 });
    consecutiveRuns++;

    // 4. 남은 건수 확인
    const remaining = await SmsResultDao.countPendingSms();

    // 5. 대기 시간 결정
    if (remaining === 0) {
      await SmsResultService.sleep(60000); // 모두 처리 완료 → 60초
      break;
    } else if (remaining < 50) {
      // 소량 남음 → 즉시 재처리
    } else {
      await SmsResultService.sleep(3000); // 대량 남음 → 3초 후
    }
  }

  if (consecutiveRuns >= MAX_CONSECUTIVE) {
    await SmsResultService.sleep(30000); // 10회 연속 → 30초 강제 대기
  }
}
```

### 3. Cron 로그 기록 패턴

#### 로그 생성 (시작 시)
```typescript
const cronLogSeq = await SmsResultDao.insertCronLog({
  jobName: 'sms-result-processor',
  jobType: 'auto',
  startTime: dayjs(startTime).format('YYYY-MM-DD HH:mm:ss'),
  status: 'running',
  serverInfo: SmsResultService.getServerInfo(),
  insertSeq: 0, // SYSTEM_SEQ
});
```

#### 로그 업데이트 (완료 시)
```typescript
await SmsResultService.updateCronLog(
  cronLogSeq,
  startTime,
  'success', // or 'failed'
  processedCount,
  successCount,
  failedCount,
  histories, // 상세 처리 내역
);
```

### 4. 서버 정보 수집

```typescript
static getServerInfo(): string {
  const os = require('node:os');
  const networkInterfaces = os.networkInterfaces();

  // IP 주소 추출 (IPv4 우선)
  let ipAddress = 'unknown';
  for (const name of Object.keys(networkInterfaces)) {
    const interfaces = networkInterfaces[name];
    if (interfaces) {
      for (const iface of interfaces) {
        if (iface.family === 'IPv4' && !iface.internal) {
          ipAddress = iface.address;
          break;
        }
      }
    }
    if (ipAddress !== 'unknown') break;
  }

  const hostname = os.hostname().substring(0, 30);
  const info = `${ipAddress}|${hostname}|pid:${process.pid}|${process.version}|${os.platform()}`;
  return info.substring(0, 200); // varchar(200) 제한
}
```

### 5. 에러 처리 패턴

#### 치명적 에러 판별
```typescript
private static isCriticalError(error: unknown): boolean {
  if (!(error instanceof Error)) return false;

  const message = error.message.toLowerCase();
  const sqlErrorPatterns = [
    'sql', 'unknown column', 'syntax', 'table',
    'database', 'connection', 'duplicate entry'
  ];

  return sqlErrorPatterns.some(pattern => message.includes(pattern));
}
```

#### 에러별 처리 전략
```typescript
try {
  const processResult = await SmsResultService.processSmsResult(sms);
  // 성공 처리
} catch (error) {
  // 치명적 에러 → 즉시 throw (전체 중단)
  if (SmsResultService.isCriticalError(error)) {
    logger.error(`[치명적] 시스템 에러`, error);
    throw error;
  }

  // 일반 에러 → 기록만 하고 계속 처리
  logger.error(`[SMS처리실패] 계속 처리`, error);
  failedCount++;
}
```

### 6. 상세 로그 포맷팅

```typescript
private static formatHistoryAsText(
  histories: SmsProcessHistory[],
  processedCount: number,
  successCount: number,
  failedCount: number,
  duration: number,
): string {
  const lines: string[] = [];

  lines.push('=== SMS 전송 결과 처리 완료 ===');
  lines.push(`전체: ${processedCount}건 | 성공: ${successCount}건 | 실패: ${failedCount}건 | 처리시간: ${duration}초`);
  lines.push('');

  for (const h of histories) {
    lines.push(`#${h.smsSeq} | ${h.sourceType} | ${h.sendName}(${h.sendHpNumber}) | ${h.type} | ${h.state}`);

    if (h.receivers && h.receivers.length > 0) {
      for (const receiver of h.receivers) {
        lines.push(`수신: ${receiver.name}(${receiver.hpNumber}) | 상태: ${receiver.state}`);
      }
    }
  }

  return lines.join('\n');
}
```

### 7. common_log_cron 테이블 구조

```sql
CREATE TABLE common_log_cron (
  log_seq INT AUTO_INCREMENT PRIMARY KEY,
  job_name VARCHAR(100) NOT NULL,      -- 작업명
  job_type VARCHAR(20) NOT NULL,       -- auto/manual
  start_time DATETIME NOT NULL,         -- 시작 시간
  end_time DATETIME,                    -- 종료 시간
  duration INT,                         -- 실행 시간 (초)
  status VARCHAR(20) NOT NULL,          -- running/success/failed
  processed_count INT DEFAULT 0,        -- 처리 건수
  success_count INT DEFAULT 0,          -- 성공 건수
  failed_count INT DEFAULT 0,           -- 실패 건수
  error_message TEXT,                   -- 에러 메시지
  error_stack TEXT,                     -- 에러 스택
  server_info VARCHAR(200),             -- 서버 정보
  detail_log TEXT,                      -- 상세 로그 (JSON)
  insert_seq INT NOT NULL,
  insert_date DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  update_seq INT,
  update_date DATETIME
);
```

## 체크리스트

크론 작업 생성 시 확인 사항:
- [ ] 적응형 스케줄러 구조 사용
- [ ] 치명적/일반 에러 구분 처리
- [ ] Cron 로그 기록 (시작/완료)
- [ ] 서버 정보 수집
- [ ] 시간대 설정 (Asia/Seoul)
- [ ] 무한 루프 에러 방지 (MAX_CONSECUTIVE)
- [ ] 상세 처리 내역 로그 (JSON/TEXT)
