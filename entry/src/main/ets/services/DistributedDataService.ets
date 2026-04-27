/**
 * 分布式数据服务
 * 使用 HarmonyOS 分布式数据管理实现跨设备数据同步
 * 
 * API参考：
 * https://developer.huawei.com/consumer/cn/doc/harmonyos-references/js-apis-distributed-dataManager
 */
import distributedKVStore from '@ohos.distributedKvStore';

/**
 * 数据类型定义
 */
export type DataType = 'string' | 'number' | 'boolean' | 'object' | 'array';

/**
 * 键值对条目
 */
interface KVEntry {
  key: string;
  value: any;
  type: DataType;
}

/**
 * 分布式数据服务
 * 管理家庭数据的跨设备同步
 */
export class DistributedDataService {
  private static instance: DistributedDataService | null = null;
  private kvStore: distributedKVStore.KVStore | null = null;
  private isInitialized: boolean = false;
  private storeId: string = 'family_smarthub_data';
  private changeListeners: Map<string, (value: any) => void> = new Map();

  static getInstance(): DistributedDataService {
    if (!DistributedDataService.instance) {
      DistributedDataService.instance = new DistributedDataService();
    }
    return DistributedDataService.instance;
  }

  private constructor() {}

  /**
   * 初始化分布式数据存储
   */
  async initialize(): Promise<boolean> {
    try {
      console.info('Initializing distributed data service...');

      // 获取键值存储管理器
      const kvManager = distributedKVStore.getKVStoreManager();
      
      // 获取或创建指定的KVStore
      // options: { createIfMissing, encrypt, backup, autoSync }
      const options: distributedKVStore.Options = {
        createIfMissing: true,
        encrypt: false,           // 是否加密（敏感数据应设为true）
        backup: true,             // 是否支持备份
        autoSync: true,           // 是否自动同步
        kvStoreType: distributedKVStore.KVStoreType.SINGLE.VERSION_001,
      };

      this.kvStore = await kvManager.getKVStore(this.storeId, options);
      
      // 注册数据变化监听
      this.registerChangeListener();

      this.isInitialized = true;
      console.info('Distributed data service initialized');
      return true;
    } catch (error) {
      console.error('Failed to initialize distributed data:', JSON.stringify(error));
      return false;
    }
  }

  /**
   * 注册数据变化监听器
   */
  private registerChangeListener(): void {
    if (!this.kvStore) return;

    try {
      this.kvStore.on('dataChange', distributedKVStore.SubscribeType.SUBSCRIBE_TYPE_LOCAL, (data) => {
        console.info('Local data changed:', JSON.stringify(data));
        this.handleDataChange(data);
      });

      // 跨设备同步监听
      this.kvStore.on('dataChange', distributedKVStore.SubscribeType.SUBSCRIBE_TYPE_REMOTE, (data) => {
        console.info('Remote data changed:', JSON.stringify(data));
        this.handleDataChange(data);
      });
    } catch (error) {
      console.warn('Failed to register change listener:', JSON.stringify(error));
    }
  }

  /**
   * 处理数据变化
   */
  private handleDataChange(data: distributedKVStore.ChangeNotification): void {
    const { insertEntries, updateEntries, deleteEntries } = data;

    // 处理新增数据
    if (insertEntries) {
      insertEntries.forEach(entry => {
        const callback = this.changeListeners.get(entry.key);
        if (callback) {
          callback(entry.value);
        }
      });
    }

    // 处理更新数据
    if (updateEntries) {
      updateEntries.forEach(entry => {
        const callback = this.changeListeners.get(entry.key);
        if (callback) {
          callback(entry.value);
        }
      });
    }

    // 处理删除数据
    if (deleteEntries) {
      deleteEntries.forEach(entry => {
        const callback = this.changeListeners.get(entry.key);
        if (callback) {
          callback(null); // null表示数据被删除
        }
      });
    }
  }

  /**
   * 添加数据变化监听
   */
  addChangeListener(key: string, callback: (value: any) => void): void {
    this.changeListeners.set(key, callback);
  }

  /**
   * 移除数据变化监听
   */
  removeChangeListener(key: string): void {
    this.changeListeners.delete(key);
  }

  /**
   * 保存字符串
   */
  async putString(key: string, value: string): Promise<boolean> {
    return this.put(key, value, 'string');
  }

  /**
   * 保存数字
   */
  async putNumber(key: string, value: number): Promise<boolean> {
    return this.put(key, value, 'number');
  }

  /**
   * 保存布尔值
   */
  async putBoolean(key: string, value: boolean): Promise<boolean> {
    return this.put(key, value, 'boolean');
  }

  /**
   * 保存对象
   */
  async putObject<T>(key: string, value: T): Promise<boolean> {
    return this.put(key, JSON.stringify(value), 'object');
  }

  /**
   * 保存数据（通用方法）
   */
  async put(key: string, value: any, type: DataType): Promise<boolean> {
    try {
      if (!this.kvStore) {
        await this.initialize();
      }

      if (!this.kvStore) {
        console.error('KVStore not available');
        return false;
      }

      const entry: distributedKVStore.Entry = {
        key,
        value: {
          type: this.mapValueType(type),
          value: value,
        },
      };

      await this.kvStore.put(key, entry.value);
      console.info(`Data saved: ${key} = ${JSON.stringify(value)}`);
      return true;
    } catch (error) {
      console.error('Failed to put data:', JSON.stringify(error));
      return false;
    }
  }

  /**
   * 获取字符串
   */
  async getString(key: string, defaultValue: string = ''): Promise<string> {
    const result = await this.get(key);
    return typeof result === 'string' ? result : defaultValue;
  }

  /**
   * 获取数字
   */
  async getNumber(key: string, defaultValue: number = 0): Promise<number> {
    const result = await this.get(key);
    return typeof result === 'number' ? result : defaultValue;
  }

  /**
   * 获取布尔值
   */
  async getBoolean(key: string, defaultValue: boolean = false): Promise<boolean> {
    const result = await this.get(key);
    return typeof result === 'boolean' ? result : defaultValue;
  }

  /**
   * 获取对象
   */
  async getObject<T>(key: string, defaultValue?: T): Promise<T | undefined> {
    const result = await this.get(key);
    if (typeof result === 'string') {
      try {
        return JSON.parse(result) as T;
      } catch (e) {
        return defaultValue;
      }
    }
    return defaultValue;
  }

  /**
   * 获取数据（通用方法）
   */
  async get(key: string): Promise<any> {
    try {
      if (!this.kvStore) {
        await this.initialize();
      }

      if (!this.kvStore) {
        return undefined;
      }

      const entry = await this.kvStore.get(key);
      if (entry) {
        return entry.value.value;
      }
      return undefined;
    } catch (error) {
      console.error('Failed to get data:', JSON.stringify(error));
      return undefined;
    }
  }

  /**
   * 删除数据
   */
  async delete(key: string): Promise<boolean> {
    try {
      if (!this.kvStore) {
        await this.initialize();
      }

      if (!this.kvStore) {
        return false;
      }

      await this.kvStore.delete(key);
      console.info(`Data deleted: ${key}`);
      return true;
    } catch (error) {
      console.error('Failed to delete data:', JSON.stringify(error));
      return false;
    }
  }

  /**
   * 获取所有键
   */
  async getAllKeys(): Promise<string[]> {
    try {
      if (!this.kvStore) {
        await this.initialize();
      }

      if (!this.kvStore) {
        return [];
      }

      const result = await this.kvStore.getAllKeys();
      return result;
    } catch (error) {
      console.error('Failed to get all keys:', JSON.stringify(error));
      return [];
    }
  }

  /**
   * 批量保存
   */
  async putBatch(entries: KVEntry[]): Promise<boolean> {
    try {
      if (!this.kvStore) {
        await this.initialize();
      }

      if (!this.kvStore) {
        return false;
      }

      const batch: distributedKVStore.Entry[] = entries.map(entry => ({
        key: entry.key,
        value: {
          type: this.mapValueType(entry.type),
          value: entry.value,
        },
      }));

      await this.kvStore.putBatch(batch);
      console.info(`Batch data saved: ${entries.length} entries`);
      return true;
    } catch (error) {
      console.error('Failed to put batch:', JSON.stringify(error));
      return false;
    }
  }

  /**
   * 清除所有数据
   */
  async clear(): Promise<boolean> {
    try {
      if (!this.kvStore) {
        await this.initialize();
      }

      if (!this.kvStore) {
        return false;
      }

      await this.kvStore.clear();
      console.info('All data cleared');
      return true;
    } catch (error) {
      console.error('Failed to clear data:', JSON.stringify(error));
      return false;
    }
  }

  /**
   * 同步数据到远程设备
   */
  async sync(deviceId?: string): Promise<boolean> {
    try {
      if (!this.kvStore) {
        await this.initialize();
      }

      if (!this.kvStore) {
        return false;
      }

      if (deviceId) {
        // 同步到指定设备
        await this.kvStore.sync([deviceId], distributedKVStore.SyncMode.PUSH_ONLY);
      } else {
        // 同步到所有设备
        await this.kvStore.sync(undefined, distributedKVStore.SyncMode.PUSH_ONLY);
      }

      console.info('Data sync triggered');
      return true;
    } catch (error) {
      console.error('Failed to sync data:', JSON.stringify(error));
      return false;
    }
  }

  /**
   * 映射值类型
   */
  private mapValueType(type: DataType): distributedKVStore.ValueType {
    switch (type) {
      case 'string':
        return '';
      case 'number':
        return 0;
      case 'boolean':
        return false;
      case 'object':
        return {};
      case 'array':
        return [];
      default:
        return '';
    }
  }

  /**
   * 获取服务状态
   */
  getStatus(): { initialized: boolean; storeId: string } {
    return {
      initialized: this.isInitialized,
      storeId: this.storeId,
    };
  }
}

/**
 * 数据存储键名常量
 */
export const DataStoreKeys = {
  // 家庭成员
  FAMILY_MEMBERS: 'family_members',
  
  // 家庭场景
  FAMILY_SCENES: 'family_scenes',
  
  // 记忆任务
  MEMORY_TASKS: 'memory_tasks',
  
  // 任务列表
  TASKS: 'tasks',
  
  // 用户配置
  USER_SETTINGS: 'user_settings',
  
  // 设备列表
  DEVICES: 'devices',
  
  // 同步时间戳
  LAST_SYNC_TIME: 'last_sync_time',
} as const;
