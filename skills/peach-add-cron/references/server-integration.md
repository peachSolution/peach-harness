# Server.ts 크론 등록 패턴

## server.ts 구조

```typescript
import * as cron from 'node-cron';
import { SmsResultService } from './modules/message/sms-result/service/sms-result.service';

export class Server {
  static koaServer() {
    // ... 서버 설정
    Server.server = createKoaServer({...}).listen(port, '0.0.0.0', () => {
      logger.info(`서버 시작: http://localhost:${port}/v1`);

      // 서버 시작 후 스케줄러 실행
      Server.startSmsResultScheduler();
      // 다른 스케줄러...
    });
  }
}
```

## 크론 등록 패턴

### 1. node-cron 기반 고정 스케줄

```typescript
static startLogCleanupScheduler() {
  // 매일 새벽 2시에 로그 정리
  cron.schedule(
    '0 2 * * *',
    async () => {
      try {
        logger.info('Starting log cleanup scheduler...');

        const deletedErrorCount = await ErrorLogService.hardDeleteWithLog();
        logger.info(`Deleted error logs: ${deletedErrorCount} records`);

        const deletedAccessCount = await AccessLogService.hardDeleteWithLog();
        logger.info(`Deleted access logs: ${deletedAccessCount} records`);

        logger.info(`Log cleanup completed. Total deleted: ${deletedErrorCount + deletedAccessCount} records`);
      } catch (error) {
        logger.error('Error during log cleanup:', error);
      }
    },
    {
      timezone: 'Asia/Seoul', // 시간대 설정
    },
  );
}
```

**Cron Expression 예시**:
- `'*/5 * * * * *'`: 5초마다
- `'*/10 * * * * *'`: 10초마다
- `'0 2 * * *'`: 매일 새벽 2시
- `'0 0 * * 0'`: 매주 일요일 자정
- `'0 0 1 * *'`: 매월 1일 자정

### 2. 적응형 스케줄러 (백그라운드 무한 루프)

```typescript
static startSmsResultScheduler() {
  logger.info('[SMS] 결과 처리 스케줄러 시작 (적응형 모드)');

  // 적응형 스케줄러 시작 (백그라운드 실행)
  SmsResultService.startScheduler().catch((error) => {
    logger.error('SMS 스케줄러 치명적 오류:', error);
    process.exit(1); // 치명적 오류 시 프로세스 재시작
  });
}
```

### 3. 환경별 스케줄 차별화

```typescript
static startConfigCacheScheduler() {
  const stage = process.env.STAGE || 'local';

  // 환경별 캐시 체크 주기 설정
  const schedules: Record<string, string> = {
    local: '*/5 * * * * *',  // 5초마다
    dev: '*/10 * * * * *',   // 10초마다
    prod: '*/10 * * * * *',  // 10초마다
  };

  const schedule = schedules[stage] || schedules.local;

  cron.schedule(
    schedule,
    async () => {
      try {
        await ConfigCronService.checkAndClearCacheIfChanged();
      } catch (error) {
        logger.error('Config cache check failed:', error);
      }
    },
    { timezone: 'Asia/Seoul' },
  );

  logger.info(`[Config] 캐시 스케줄러 시작 - ${stage} (${schedule})`);
}
```

## 통합 예시

```typescript
export class Server {
  static koaServer() {
    const port = process.env.PORT || 3009;
    Server.server = createKoaServer({
      // ... 설정
    }).listen(port, '0.0.0.0', () => {
      logger.info(`서버: http://localhost:${port}/v1`);

      // ========== 스케줄러 시작 ==========

      // 1. 설정 캐시 관리 (환경별 주기)
      Server.startConfigCacheScheduler();

      // 2. 로그 정리 (매일 새벽 2시)
      Server.startLogCleanupScheduler();

      // 3. SMS 결과 처리 (적응형)
      Server.startSmsResultScheduler();

      // =====================================
    });
  }
}
```

## 주의사항

1. **시간대 설정**: 한국 시간 기준으로 실행하려면 `timezone: 'Asia/Seoul'` 필수
2. **에러 처리**: 각 스케줄러는 독립적으로 에러 처리 (한 스케줄러 오류가 다른 스케줄러에 영향 없도록)
3. **로깅**: 스케줄러 시작 시 로그 출력으로 실행 여부 확인
4. **프로세스 재시작**: 치명적 오류 시 `process.exit(1)`로 재시작 유도 (PM2/Docker 등이 자동 재시작)

## Cron Expression 참고

```
*    *    *    *    *    *
┬    ┬    ┬    ┬    ┬    ┬
│    │    │    │    │    │
│    │    │    │    │    └─── 요일 (0-7) (0 또는 7은 일요일)
│    │    │    │    └────── 월 (1-12)
│    │    │    └─────────── 일 (1-31)
│    │    └──────────────── 시 (0-23)
│    └───────────────────── 분 (0-59)
└────────────────────────── 초 (0-59, 선택사항)
```

**특수 문자**:
- `*`: 모든 값
- `*/n`: n마다 (예: `*/5` → 5분마다)
- `n-m`: 범위 (예: `1-5` → 1시부터 5시)
- `n,m,o`: 여러 값 (예: `1,3,5` → 1시, 3시, 5시)
