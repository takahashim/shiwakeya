class UpdateUserRoleTypes < ActiveRecord::Migration[8.0]
  def up
    # 既存のユーザーのroleを更新
    User.where(role: 'user').update_all(role: 'member')

    # roleのデフォルト値を変更
    change_column_default :users, :role, from: 'user', to: 'member'
  end

  def down
    # ロールバック時の処理
    User.where(role: 'member').update_all(role: 'user')
    User.where(role: 'accountant').update_all(role: 'user')

    change_column_default :users, :role, from: 'member', to: 'user'
  end
end
