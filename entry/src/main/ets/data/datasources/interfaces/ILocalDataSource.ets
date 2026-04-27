/**
 * ============================================================================
 * 本地数据源接口 - ILocalDataSource
 * 负责本地数据存储（Preferences/Database）
 * ============================================================================
 */

/**
 * 本地数据源接口
 */
export interface ILocalDataSource {
  /**
   * 保存键值对
   */
  set(key: string, value: string): Promise<void>;
  
  /**
   * 获取键值对
   */
  get(key: string): Promise<string | null>;
  
  /**
   * 删除键值对
   */
  delete(key: string): Promise<void>;
  
  /**
   * 检查键是否存在
   */
  contains(key: string): Promise<boolean>;
  
  /**
   * 保存对象（JSON 序列化）
   */
  setObject<T>(key: string, value: T): Promise<void>;
  
  /**
   * 获取对象（JSON 反序列化）
   */
  getObject<T>(key: string): Promise<T | null>;
  
  /**
   * 清空所有数据
   */
  clear(): Promise<void>;
  
  /**
   * 获取所有键
   */
  getAllKeys(): Promise<string[]>;
}
