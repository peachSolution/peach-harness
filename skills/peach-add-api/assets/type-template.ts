/**
 * 공통 응답 DTO
 */
export interface CommonResDto<T> {
  success: boolean;  // 성공 여부
  message: string;   // 응답 메시지
  data: T;           // 응답 데이터
}

/**
 * TODO: Add request DTO description
 */
export interface {{RequestDtoName}} {
  // TODO: Add request fields
  // field1: string;
  // field2: number;
}

/**
 * TODO: Add response DTO description
 */
export interface {{ResponseDtoName}} {
  // TODO: Add response fields
  // field1: string;
  // field2: number;
}
