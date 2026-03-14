// server.ts에 추가할 코드 (import)
import { {{ServiceClassName}} } from './modules/{{module-name}}/service/{{module-name}}.service';

// server.ts에 추가할 코드 (koaServer 메서드 내부)
export class Server {
  static koaServer() {
    // ... 기존 코드
    Server.server = createKoaServer({...}).listen(port, '0.0.0.0', () => {
      logger.info(`서버 시작: http://localhost:${port}/v1`);

      // ========== 스케줄러 추가 ==========
      Server.start{{SchedulerMethodName}}();
      // ==================================
    });
  }

  /**
   * {{작업 설명}} 스케줄러 시작
   * {{실행 주기 설명}}
   *
   * @description
   * - 실행 주기: {{cron-expression-description}}
   * - 시간대: 한국 표준시 (Asia/Seoul)
   * - 동작: {{작업 설명}}
   */
  static start{{SchedulerMethodName}}() {
    logger.info('[{{JOB_NAME}}] 스케줄러 시작');

    // 적응형 스케줄러 시작 (백그라운드 실행)
    {{ServiceClassName}}.startScheduler().catch((error) => {
      logger.error('[{{JOB_NAME}}] 스케줄러 치명적 오류:', error);
      process.exit(1); // 치명적 오류 시 프로세스 재시작
    });
  }
}
