/**
 * ============================================================================
 * LLM 远程数据源实现 - LLMRemoteDataSource
 * 负责调用华为云大模型 API
 * ============================================================================
 */

import { HiLog } from '@kit.BasicServicesKit';
import { IRemoteDataSource, HttpResponse, HttpMethod } from '../interfaces/IRemoteDataSource';
import { LLMConfig } from '../../../core/config/LLMConfig';

/**
 * LLM 远程数据源实现
 */
export class LLMRemoteDataSource implements IRemoteDataSource {
  private static instance: LLMRemoteDataSource | null = null;
  
  private authToken: string = '';
  private baseUrl: string = '';
  private timeout: number = 30000;

  /**
   * 获取单例实例
   */
  static getInstance(): LLMRemoteDataSource {
    if (!LLMRemoteDataSource.instance) {
      LLMRemoteDataSource.instance = new LLMRemoteDataSource();
    }
    return LLMRemoteDataSource.instance;
  }

  private constructor() {
    // 从配置加载
    this.baseUrl = LLMConfig.API_BASE_URL;
    this.timeout = LLMConfig.TIMEOUT;
    HiLog.info("LLMRemoteDataSource", `初始化：${this.baseUrl}`);
  }

  /**
   * 设置认证 Token
   */
  setAuthToken(token: string): void {
    this.authToken = token;
    HiLog.info("LLMRemoteDataSource", "Token 已设置");
  }

  /**
   * 清除认证 Token
   */
  clearAuthToken(): void {
    this.authToken = '';
    HiLog.info("LLMRemoteDataSource", "Token 已清除");
  }

  /**
   * GET 请求
   */
  async get<T>(url: string, params?: Record<string, string>): Promise<HttpResponse<T>> {
    return this.request<T>(HttpMethod.GET, url, undefined, params);
  }

  /**
   * POST 请求
   */
  async post<T>(url: string, body: any): Promise<HttpResponse<T>> {
    return this.request<T>(HttpMethod.POST, url, body);
  }

  /**
   * PUT 请求
   */
  async put<T>(url: string, body: any): Promise<HttpResponse<T>> {
    return this.request<T>(HttpMethod.PUT, url, body);
  }

  /**
   * DELETE 请求
   */
  async delete<T>(url: string): Promise<HttpResponse<T>> {
    return this.request<T>(HttpMethod.DELETE, url);
  }

  /**
   * 通用请求
   */
  async request<T>(
    method: HttpMethod,
    url: string,
    body?: any,
    params?: Record<string, string>
  ): Promise<HttpResponse<T>> {
    HiLog.info("LLMRemoteDataSource", `${method} ${url}`);
    
    try {
      // 构建完整 URL
      const fullUrl = this.buildUrl(url, params);
      
      // 构建请求头
      const headers = this.buildHeaders();
      
      // 构建请求体
      const requestBody = body ? JSON.stringify(body) : undefined;
      
      // 发送请求（简化实现，实际应该用 http 模块）
      const response = await this.sendRequest(fullUrl, method, requestBody, headers);
      
      HiLog.info("LLMRemoteDataSource", `响应码：${response.code}`);
      
      return response;
    } catch (error: any) {
      HiLog.error("LLMRemoteDataSource", `请求失败：${error.message}`);
      throw error;
    }
  }

  /**
   * 构建完整 URL
   */
  private buildUrl(url: string, params?: Record<string, string>): string {
    let fullUrl = url.startsWith('http') ? url : `${this.baseUrl}${url}`;
    
    if (params) {
      const queryString = Object.entries(params)
        .map(([key, value]) => `${encodeURIComponent(key)}=${encodeURIComponent(value)}`)
        .join('&');
      fullUrl += `?${queryString}`;
    }
    
    return fullUrl;
  }

  /**
   * 构建请求头
   */
  private buildHeaders(): Record<string, string> {
    const headers: Record<string, string> = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    
    if (this.authToken) {
      headers['Authorization'] = `Bearer ${this.authToken}`;
    }
    
    return headers;
  }

  /**
   * 发送请求（简化实现）
   */
  private async sendRequest(
    url: string,
    method: string,
    body?: string,
    headers?: Record<string, string>
  ): Promise<HttpResponse<any>> {
    // TODO: 实际实现应该使用 http 模块
    // 这里是简化实现，返回模拟响应
    
    return new Promise((resolve) => {
      setTimeout(() => {
        resolve({
          code: 200,
          data: { message: 'Mock response' },
          message: 'Success',
          headers: {},
        });
      }, 100);
    });
  }

  /**
   * 调用 LLM 生成内容
   */
  async generateContent(prompt: string): Promise<string> {
    HiLog.info("LLMRemoteDataSource", `生成内容：${prompt.substring(0, 50)}...`);
    
    try {
      const response = await this.post('/v1/chat/completions', {
        model: LLMConfig.MODEL_NAME,
        messages: [
          { role: 'system', content: LLMConfig.SYSTEM_PROMPT },
          { role: 'user', content: prompt }
        ],
        max_tokens: LLMConfig.MAX_TOKENS,
        temperature: LLMConfig.TEMPERATURE,
      });
      
      const content = response.data.choices?.[0]?.message?.content || '';
      HiLog.info("LLMRemoteDataSource", `生成成功，长度：${content.length}`);
      
      return content;
    } catch (error: any) {
      HiLog.error("LLMRemoteDataSource", `生成失败：${error.message}`);
      
      // 降级：返回空字符串
      return '';
    }
  }
}
