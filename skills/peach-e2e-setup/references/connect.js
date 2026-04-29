/**
 * Chrome CDP 연결 공통 모듈
 * 이미 열린 Chrome에 연결하여 대상 탭의 page 객체를 반환한다.
 *
 * 탭 식별: CDP targetId (탭별 고유 해시) — 동일 URL 탭도 정확히 구분.
 *
 * 탭 선택 방식:
 *   1. targetId (가장 정확 — selector.js TUI에서 사용)
 *      E2E_TAB_ID=ABC123... node 시나리오.js
 *
 *   2. 탭 인덱스 (--tab N 직접 지정)
 *      E2E_TAB=3 node 시나리오.js
 *      → 내부적으로 CDP /json 조회 후 targetId로 변환
 *
 *   3. 인자 없음 → 첫 번째 비-chrome 페이지 탭 자동 선택
 *
 * origin은 선택된 탭의 URL에서 동적 추출.
 * 환경(local/test/prod) 구분 없이, 사용자가 로그인한 탭을 그대로 사용.
 */
// playwright-core: API만 포함 (브라우저 바이너리 없음). CDP 모드에서는 Chrome Beta를 직접 사용하므로 충분.
const { chromium } = require('playwright-core');
const http = require('http');

const CDP_URL = 'http://127.0.0.1:9222';

/**
 * CDP HTTP API로 탭 목록 가져오기
 */
function fetchCdpTabs() {
  return new Promise((resolve) => {
    http.get(`${CDP_URL}/json`, (res) => {
      let data = '';
      res.on('data', (c) => (data += c));
      res.on('end', () => {
        try {
          resolve(JSON.parse(data));
        } catch {
          resolve([]);
        }
      });
    }).on('error', () => resolve([]));
  });
}

/**
 * CDP 탭 목록에서 비-chrome 페이지 탭만 필터 (status/selector와 동일 기준)
 */
function filterPageTabs(cdpTabs) {
  return cdpTabs.filter(
    (t) => t.type === 'page' && !t.url.startsWith('chrome')
  );
}

/**
 * Playwright page에서 CDP targetId를 추출
 */
async function getTargetId(page) {
  const session = await page.context().newCDPSession(page);
  const { targetInfo } = await session.send('Target.getTargetInfo');
  return targetInfo.targetId;
}

/**
 * allPages에서 targetId가 일치하는 page를 찾아 반환
 */
async function findPageByTargetId(allPages, targetId) {
  for (const p of allPages) {
    const id = await getTargetId(p);
    if (id === targetId) return p;
  }
  return null;
}

/**
 * CDP로 Chrome에 연결하고 대상 탭의 page 객체를 반환
 * @param {object} [options] - { tab: number, tabId: string }
 * @returns {{ browser, context, page, origin, defaultDialogHandler }}
 */
async function connect(options) {
  const envTabId = process.env.E2E_TAB_ID;
  const envTab = process.env.E2E_TAB;

  let tabId = null;
  let tabIndex = null;

  // 인자 파싱
  if (options && typeof options === 'object') {
    if (options.tabId) tabId = options.tabId;
    if (options.tab != null) tabIndex = options.tab;
  }

  // 환경변수 우선 (CLI에서 전달)
  if (envTabId && !tabId) tabId = envTabId;
  if (envTab != null && tabIndex == null && !tabId) tabIndex = parseInt(envTab, 10);

  const browser = await chromium.connectOverCDP(CDP_URL);
  const context = browser.contexts()[0];
  const allPages = context.pages();

  let page = null;

  if (tabId) {
    // targetId 매칭 — 동일 URL이어도 정확히 구분
    page = await findPageByTargetId(allPages, tabId);

    if (!page) {
      const tabList = allPages.map((p, i) => `  ${i}: ${p.url()}`).join('\n');
      throw new Error(
        `탭을 찾을 수 없습니다 (id: ${tabId})\n` +
          `열린 탭:\n${tabList}`
      );
    }
    console.log(`📍 탭 선택: ${page.url()}`);
  } else if (tabIndex != null) {
    // 탭 인덱스 → CDP /json 조회 후 targetId로 변환
    const cdpTabs = await fetchCdpTabs();
    const pageTabs = filterPageTabs(cdpTabs);

    if (tabIndex < 0 || tabIndex >= pageTabs.length) {
      const tabList = pageTabs
        .map((t, i) => `  ${i}: ${t.url}`)
        .join('\n');
      throw new Error(
        `${tabIndex}번 탭이 없습니다. (0~${pageTabs.length - 1}번 사용 가능)\n` +
          `열린 탭:\n${tabList}`
      );
    }

    const targetId = pageTabs[tabIndex].id;
    page = await findPageByTargetId(allPages, targetId);

    if (!page) {
      const tabList = allPages.map((p, i) => `  ${i}: ${p.url()}`).join('\n');
      throw new Error(
        `${tabIndex}번 탭을 Playwright에서 찾을 수 없습니다.\n` +
          `Playwright 탭:\n${tabList}`
      );
    }
    console.log(`📍 ${tabIndex}번 탭 선택: ${page.url()}`);
  } else {
    // 기본: 첫 번째 비-chrome 페이지 탭
    const cdpTabs = await fetchCdpTabs();
    const pageTabs = filterPageTabs(cdpTabs);

    if (pageTabs.length > 0) {
      const targetId = pageTabs[0].id;
      page = await findPageByTargetId(allPages, targetId);
    }

    if (!page) {
      page = allPages.find((p) => !p.url().startsWith('chrome'));
    }

    if (!page) {
      const tabList = allPages.map((p, i) => `  ${i}: ${p.url()}`).join('\n');
      throw new Error(
        `사용 가능한 탭을 찾을 수 없습니다.\n` +
          `브라우저에서 페이지를 열어주세요.\n` +
          `열린 탭:\n${tabList}`
      );
    }
    console.log(`📍 자동 선택: ${page.url()}`);
  }

  // 라이트 모드 강제 (reload 없이 즉시 적용)
  // 1. CSS 미디어 쿼리 오버라이드
  await page.emulateMedia({ colorScheme: 'light' });
  // 2. localStorage + html class 강제 변경 (vueuse/Nuxt 앱의 JS 다크모드 대응)
  await page.evaluate(() => {
    localStorage.setItem('vueuse-color-scheme', 'light');
    localStorage.setItem('theme', 'light');
    document.documentElement.classList.remove('dark');
    document.documentElement.classList.add('light');
    document.documentElement.style.colorScheme = 'light';
  });

  // origin은 현재 탭 URL에서 동적 추출
  const origin = new URL(page.url()).origin;

  // 기본 dialog handler 등록
  // - handler가 없으면 Playwright DialogManager가 자동으로 dismiss(false)를 호출한다.
  // - 기본값은 accept(true). 시나리오에서 다른 동작이 필요하면 setDialogHandler()로 교체.
  //   (page.on('dialog')를 직접 추가하면 두 handler가 모두 실행되어 충돌한다.)
  const defaultDialogHandler = async (dialog) => {
    await dialog.accept();
  };
  page.on('dialog', defaultDialogHandler);

  return { browser, context, page, origin, defaultDialogHandler };
}

/**
 * dialog handler 교체 유틸리티
 * connect()가 등록한 기본 handler를 제거하고 새 handler로 교체한다.
 *
 * 사용 예:
 *   const { page, defaultDialogHandler } = await connect();
 *   const newHandler = setDialogHandler(page, defaultDialogHandler, async (dialog) => {
 *     logs.push({ type: dialog.type(), message: dialog.message() });
 *     await dialog.accept();
 *   });
 *   // 사용 후 복원
 *   setDialogHandler(page, newHandler, defaultDialogHandler);
 *
 * @param {import('playwright-core').Page} page
 * @param {Function} prevHandler - 제거할 이전 handler (defaultDialogHandler 또는 이전 교체 handler)
 * @param {Function} newHandler  - 등록할 새 handler (null이면 제거만)
 * @returns {Function} newHandler (다음 교체 시 prevHandler로 전달)
 */
function setDialogHandler(page, prevHandler, newHandler) {
  if (prevHandler) page.removeListener('dialog', prevHandler);
  if (newHandler) page.on('dialog', newHandler);
  return newHandler;
}

module.exports = { connect, setDialogHandler, CDP_URL };
