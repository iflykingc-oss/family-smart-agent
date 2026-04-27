/**
 * ============================================================================
 * 用户仓库接口 - IUserRepository
 * 领域层只依赖此接口，不关心实现
 * ============================================================================
 */

import { UserEntity } from '../../../domain/entities/UserEntity';

/**
 * 用户仓库接口
 */
export interface IUserRepository {
  /**
   * 根据 ID 查找用户
   */
  findById(id: string): Promise<UserEntity | null>;
  
  /**
   * 保存用户
   */
  save(user: UserEntity): Promise<void>;
  
  /**
   * 更新用户
   */
  update(user: UserEntity): Promise<void>;
  
  /**
   * 删除用户
   */
  delete(id: string): Promise<void>;
  
  /**
   * 查找所有用户
   */
  findAll(): Promise<UserEntity[]>;
}
