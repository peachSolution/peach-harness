import dayjs from 'dayjs';

export class {{ServiceClassName}} {
  private static readonly SYSTEM_SEQ = 0;
  private static readonly JOB_NAME = '{{job-name}}';

  /**
   * 적응형 스케줄러 시작 (무한 루프)
   */
  static async startScheduler(): Promise<void> {
    while (true) {
      try {
        await {{ServiceClassName}}.processOnce();
      } catch (error) {
        logger.error('[{{JOB_NAME}}] 처리 오류:', error);
        await {{ServiceClassName}}.sleep(60000); // 에러 시 1분 대기
      }
    }
  }

  /**
   * 1회 처리 사이클
   */
  private static async processOnce(): Promise<void> {
    let consecutiveRuns = 0;
    const MAX_CONSECUTIVE = 10;

    while (consecutiveRuns < MAX_CONSECUTIVE) {
      // 1. 미처리 건수 확인
      const pendingCount = await {{DaoClassName}}.countPending();

      // 2. 미처리 없음 → 30초 대기 후 종료
      if (pendingCount === 0) {
        logger.debug('[{{JOB_NAME}}] 미처리 없음, 30초 대기');
        await {{ServiceClassName}}.sleep(30000);
        break;
      }

      // 3. 처리 실행
      logger.debug(`[{{JOB_NAME}}] 처리 ${pendingCount}건`);
      await {{ServiceClassName}}.processJob();
      consecutiveRuns++;

      // 4. 남은 건수 확인
      const remaining = await {{DaoClassName}}.countPending();

      // 5. 대기 시간 결정
      if (remaining === 0) {
        logger.debug('[{{JOB_NAME}}] 처리 완료, 60초 대기');
        await {{ServiceClassName}}.sleep(60000);
        break;
      } else if (remaining < 50) {
        logger.debug(`[{{JOB_NAME}}] ${remaining}건 남음, 즉시 재처리`);
      } else {
        logger.debug(`[{{JOB_NAME}}] ${remaining}건 남음, 3초 후 재실행`);
        await {{ServiceClassName}}.sleep(3000);
      }
    }

    if (consecutiveRuns >= MAX_CONSECUTIVE) {
      logger.warn('[{{JOB_NAME}}] 10회 연속 실행, 30초 강제 대기');
      await {{ServiceClassName}}.sleep(30000);
    }
  }

  /**
   * 메인 처리 메서드
   */
  static async processJob(): Promise<void> {
    const startTime = new Date();
    let cronLogSeq = 0;

    try {
      // 1. 처리 대상 조회
      const items = await {{DaoClassName}}.findPending();

      if (items.length === 0) {
        return; // 처리 대상 없으면 조기 종료
      }

      logger.info(`[{{JOB_NAME}}] 대상 ${items.length}건`);

      // 2. Cron 로그 생성
      cronLogSeq = await {{DaoClassName}}.insertCronLog({
        jobName: {{ServiceClassName}}.JOB_NAME,
        jobType: 'auto',
        startTime: dayjs(startTime).format('YYYY-MM-DD HH:mm:ss'),
        status: 'running',
        serverInfo: {{ServiceClassName}}.getServerInfo(),
        insertSeq: {{ServiceClassName}}.SYSTEM_SEQ,
      });

      // 3. 건별 처리
      let successCount = 0;
      let failedCount = 0;
      const histories = [];

      for (const item of items) {
        try {
          // TODO: 실제 처리 로직 구현
          await {{ServiceClassName}}.processItem(item);
          successCount++;
          histories.push({ ...item, result: 'success' });
        } catch (error) {
          // 치명적 에러 확인
          if ({{ServiceClassName}}.isCriticalError(error)) {
            logger.error(`[치명적] 시스템 에러 발생`, error);
            throw error;
          }

          // 일반 에러는 기록만 하고 계속 처리
          logger.error(`[{{JOB_NAME}}] 처리 실패`, error);
          failedCount++;
          histories.push({ ...item, result: 'failed' });
        }
      }

      // 4. Cron 로그 업데이트 (성공)
      await {{ServiceClassName}}.updateCronLog(
        cronLogSeq,
        startTime,
        'success',
        items.length,
        successCount,
        failedCount,
        histories,
      );

      const duration = Math.floor((Date.now() - startTime.getTime()) / 1000);
      logger.info(`[{{JOB_NAME}}] 성공(${successCount}건) / 실패(${failedCount}건) ${duration}초`);
    } catch (error) {
      logger.error('[{{JOB_NAME}}] 처리 중 오류:', error);

      // Cron 로그 업데이트 (실패)
      if (cronLogSeq > 0) {
        const { message: errorMessage, stack: errorStack } =
          {{ServiceClassName}}.extractErrorInfo(error);

        await {{ServiceClassName}}.updateCronLog(
          cronLogSeq,
          startTime,
          'failed',
          0,
          0,
          0,
          [],
          errorMessage,
          errorStack,
        );
      }

      throw error;
    }
  }

  /**
   * 개별 아이템 처리
   */
  private static async processItem(item: any): Promise<void> {
    // TODO: 실제 처리 로직 구현
  }

  /**
   * 치명적 에러 판별
   */
  private static isCriticalError(error: unknown): boolean {
    if (!(error instanceof Error)) return false;

    const message = error.message.toLowerCase();
    const sqlErrorPatterns = [
      'sql',
      'unknown column',
      'syntax',
      'table',
      'database',
      'connection',
    ];

    return sqlErrorPatterns.some((pattern) => message.includes(pattern));
  }

  /**
   * Cron 로그 업데이트
   */
  static async updateCronLog(
    cronLogSeq: number,
    startTime: Date,
    status: 'success' | 'failed',
    processedCount: number,
    successCount: number,
    failedCount: number,
    histories: any[],
    errorMessage: string = '',
    errorStack: string = '',
  ): Promise<void> {
    const endTime = new Date();
    const duration = Math.floor((endTime.getTime() - startTime.getTime()) / 1000);

    const detailLog = {
      format: 'text',
      content:
        status === 'success'
          ? `처리 완료\n전체: ${processedCount}건 | 성공: ${successCount}건 | 실패: ${failedCount}건`
          : `처리 실패\n에러: ${errorMessage}`,
    };

    await {{DaoClassName}}.updateCronLog({
      logSeq: cronLogSeq,
      endTime: dayjs(endTime).format('YYYY-MM-DD HH:mm:ss'),
      duration,
      status,
      processedCount,
      successCount,
      failedCount,
      errorMessage,
      errorStack,
      serverInfo: {{ServiceClassName}}.getServerInfo(),
      detailLog: JSON.stringify(detailLog),
      updateSeq: {{ServiceClassName}}.SYSTEM_SEQ,
    });
  }

  /**
   * 서버 정보 수집
   */
  static getServerInfo(): string {
    const os = require('node:os');
    const networkInterfaces = os.networkInterfaces();

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
    return info.substring(0, 200);
  }

  /**
   * 에러 정보 추출
   */
  private static extractErrorInfo(error: unknown): { message: string; stack: string } {
    if (error instanceof Error) {
      return {
        message: error.message,
        stack: error.stack || '',
      };
    }
    return {
      message: String(error),
      stack: '',
    };
  }

  /**
   * sleep 헬퍼
   */
  private static sleep(ms: number): Promise<void> {
    return new Promise((resolve) => setTimeout(resolve, ms));
  }
}
