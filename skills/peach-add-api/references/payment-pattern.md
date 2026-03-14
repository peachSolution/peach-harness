# Payment Service 패턴 분석

## 핵심 패턴

### 1. Service 클래스 구조
- 모든 메서드는 `static`으로 선언
- axios를 사용한 HTTP 클라이언트
- 타입 정의된 요청/응답 DTO

### 2. API 호출 패턴

#### GET 요청
```typescript
static async getUserPoint(
  authorization: string,
): Promise<CommonResDto<UserPointResDto>> {
  const apiUrl = `${process.env.PAYMENT_API_URL}/external/point/user`;
  const response = await axios.get<CommonResDto<UserPointResDto>>(apiUrl, {
    headers: {
      Authorization: authorization,
    },
  });
  return response.data;
}
```

**핵심 요소**:
- 환경변수 기반 API URL (`process.env.PAYMENT_API_URL`)
- Authorization 헤더 처리
- 제네릭 타입 지정 (`axios.get<ResponseType>`)
- `response.data` 반환

#### POST 요청
```typescript
static async redeemPoint(
  authorization: string,
  params: RedeemPointReqDto,
): Promise<CommonResDto<RedeemPointResDto>> {
  const apiUrl = `${process.env.PAYMENT_API_URL}/external/point/redeem`;
  const response = await axios.post<CommonResDto<RedeemPointResDto>>(apiUrl, params, {
    headers: {
      Authorization: authorization,
      'Content-Type': 'application/json',
    },
  });
  return response.data;
}
```

**핵심 요소**:
- 두 번째 인자로 request body 전달
- `Content-Type: application/json` 헤더
- Authorization 헤더 처리

### 3. 타입 정의 패턴

#### 공통 응답 타입
```typescript
export interface CommonResDto<T> {
  success: boolean;
  message: string;
  data: T;
}
```

#### 요청 DTO
```typescript
export interface RedeemPointReqDto {
  serviceCode: string;  // 서비스 코드
  count: number;        // 사용 횟수
}
```

#### 응답 DTO
```typescript
export interface RedeemPointResDto {
  transactionId: string;  // 거래 ID
  remainingPoint: number; // 남은 포인트
}
```

### 4. 에러 처리
- axios는 HTTP 상태 코드 4xx, 5xx에 대해 자동으로 에러 throw
- Service 레이어에서는 try-catch 없이 호출
- Controller 레이어에서 ErrorHandler 처리

### 5. 환경변수 사용
```typescript
const apiUrl = `${process.env.PAYMENT_API_URL}/external/point/user`;
```

**환경변수 명명 규칙**:
- `{MODULE}_API_URL` 형식
- 예: `PAYMENT_API_URL`, `SMS_API_URL`

### 6. JSDoc 주석 패턴
```typescript
/**
 * 포인트 사용 (차감)
 *
 * 서비스 이용 시 포인트를 차감합니다.
 * 반환된 transactionId를 저장하여 취소 시 사용합니다.
 *
 * @param authorization - Bearer 토큰 (필수)
 * @param params - 포인트 사용 요청 DTO (serviceCode, count)
 * @returns 거래 ID 및 남은 포인트
 */
```

**규칙**:
- 첫 줄: 메서드 목적 (간결하게)
- 두 번째 문단: 상세 설명
- `@param`: 매개변수 설명
- `@returns`: 반환값 설명

### 7. 메서드 명명 규칙
- `get{Resource}`: 조회 (GET)
- `create{Resource}`: 생성 (POST)
- `update{Resource}`: 수정 (PUT/PATCH)
- `delete{Resource}`: 삭제 (DELETE)
- 동사 + 명사 조합

### 8. 파일 구조
```
payment/
├── service/
│   └── payment.service.ts    # API 호출 로직
├── type/
│   └── payment.interface.ts  # 타입 정의
└── test/
    └── payment.test.ts       # 테스트 코드
```

## 체크리스트

코드 생성 시 확인 사항:
- [ ] Service 클래스는 static 메서드 사용
- [ ] 환경변수 기반 API URL
- [ ] Authorization 헤더 처리
- [ ] 타입 정의된 요청/응답
- [ ] JSDoc 주석 작성
- [ ] CommonResDto<T> 제네릭 응답 타입
- [ ] kebab-case 파일명
