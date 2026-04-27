/**
 * ============================================================================
 * 用户仓库实现 - UserRepository
 * 实现 IUserRepository 接口
 * ============================================================================
 */

import { HiLog } from '@kit.BasicServicesKit';
import { IUserRepository } from '../interfaces/IUserRepository';
import { UserEntity, UserDTO } from '../../../domain/entities/UserEntity';
import { ILocalDataSource } from '../../datasources/interfaces/ILocalDataSource';
import { PreferencesLocalDataSource } from '../../datasources/impl/PreferencesLocalDataSource';

/**
 * 用户仓库实现
 */
export class UserRepository implements IUserRepository {
  private static instance: UserRepository | null = null;
  
  private localDataSource: ILocalDataSource;
  private readonly keyPrefix: string = 'user_';

  /**
   * 获取单例实例
   */
  static getInstance(): UserRepository {
    if (!UserRepository.instance) {
      UserRepository.instance = new UserRepository();
    }
    return UserRepository.instance;
  }

  private constructor() {
    this.localDataSource = PreferencesLocalDataSource.getInstance();
    HiLog.info("UserRepository", "初始化");
  }

  /**
   * 根据 ID 查找用户
   */
  async findById(id: string): Promise<UserEntity | null> {
    try {
      const key = `${this.keyPrefix}${id}`;
      const dto = await this.localDataSource.getObject<UserDTO>(key);
      
      if (!dto) {
        return null;
      }
      
      return UserEntity.fromDTO(dto);
    } catch (error: any) {
      HiLog.error("UserRepository", `查找失败：${error.message}`);
      return null;
    }
  }

  /**
   * 保存用户
   */
  async save(user: UserEntity): Promise<void> {
    try {
      const key = `${this.keyPrefix}${user.id}`;
      const dto = user.toDTO();
      await this.localDataSource.setObject(key, dto);
      HiLog.info("UserRepository", `保存成功：${user.id}`);
    } catch (error: any) {
      HiLog.error("UserRepository", `保存失败：${error.message}`);
      throw error;
    }
  }

  /**
   * 更新用户
   */
  async update(user: UserEntity): Promise<void> {
    // 用户更新就是保存
    await this.save(user);
  }

  /**
   * 删除用户
   */
  async delete(id: string): Promise<void> {
    try {
      const key = `${this.keyPrefix}${id}`;
      await this.localDataSource.delete(key);
      HiLog.info("UserRepository", `删除成功：${id}`);
    } catch (error: any) {
      HiLog.error("UserRepository", `删除失败：${error.message}`);
      throw error;
    }
  }

  /**
   * 查找所有用户
   */
  async findAll(): Promise<UserEntity[]> {
    try {
      const keys = await this.localDataSource.getAllKeys();
      const userKeys = keys.filter(k => k.startsWith(this.keyPrefix));
      
      const users: UserEntity[] = [];
      for (const key of userKeys) {
        const dto = await this.localDataSource.getObject<UserDTO>(key);
        if (dto) {
          users.push(UserEntity.fromDTO(dto));
        }
      }
      
      return users;
    } catch (error: any) {
      HiLog.error("UserRepository", `查找所有失败：${error.message}`);
      return [];
    }
  }
}
