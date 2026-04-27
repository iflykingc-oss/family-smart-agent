/**
 * ============================================================================
 * 远程数据源接口 - IRemoteDataSource
 * 负责远程 API 调用（LLM/Analytics）
 * ============================================================================
 */

/**
 * HTTP 请求方法
 */
export enum HttpMethod {
  GET = 'GET',
  POST = 'POST',
  PUT = 'PUT',
  DELETE = 'DELETE',
  PATCH = 'PATCH',
}

/**
 * HTTP 响应
 */
export interface HttpResponse<T> {
  code: number;
  data: T;
  message: string;
  headers: Record<string, string>;
}

/**
 * 远程数据源接口
 */
export interface IRemoteDataSource {
  /**
   * GET 请求
   */
  get<T>(url: string, params?: Record<string, string>): Promise<HttpResponse<T>>;
  
  /**
   * POST 请求
   */
  post<T>(url: string, body: any): Promise<HttpResponse<T>>;
  
  /**
   * PUT 请求
   */
  put<T>(url: string, body: any): Promise<HttpResponse<T>>;
  
  /**
   * DELETE 请求
   */
  delete<T>(url: string): Promise<HttpResponse<T>>;
  
  /**
   * 通用请求
   */
  request<T>(
    method: HttpMethod,
    url: string,
    body?: any,
    params?: Record<string, string>
  ): Promise<HttpResponse<T>>;
  
  /**
   * 设置认证 Token
   */
  setAuthToken(token: string): void;
  
  /**
   * 清除认证 Token
   */
  clearAuthToken(): void;
}
