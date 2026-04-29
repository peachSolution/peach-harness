import axios from 'axios';
import type {
  CommonResDto,
  // TODO: Import request/response types
  // ExampleReqDto,
  // ExampleResDto,
} from '../type/{{MODULE_NAME}}.interface';

export class {{ServiceClassName}} {
  /**
   * TODO: Add method description
   *
   * @param authorization - Bearer 토큰 (필수)
   * @param params - 요청 DTO
   * @returns 응답 DTO
   */
  static async {{methodName}}(
    authorization: string,
    // params: ExampleReqDto,
  ): Promise<CommonResDto<any>> {
    const apiUrl = `${process.env.{{ENV_VAR}}_API_URL}/{{endpoint}}`;
    const response = await axios.get<CommonResDto<any>>(apiUrl, {
      headers: {
        Authorization: authorization,
      },
    });
    return response.data;
  }

  /**
   * TODO: Add POST method description
   *
   * @param authorization - Bearer 토큰 (필수)
   * @param params - 요청 DTO
   * @returns 응답 DTO
   */
  static async {{postMethodName}}(
    authorization: string,
    params: any,
  ): Promise<CommonResDto<any>> {
    const apiUrl = `${process.env.{{ENV_VAR}}_API_URL}/{{endpoint}}`;
    const response = await axios.post<CommonResDto<any>>(apiUrl, params, {
      headers: {
        Authorization: authorization,
        'Content-Type': 'application/json',
      },
    });
    return response.data;
  }
}
