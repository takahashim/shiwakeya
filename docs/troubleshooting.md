# トラブルシューティングガイド

## スプレッドシート登録時のエラー

### 「指定されたスプレッドシートIDが見つかりません」エラー

このエラーが発生する場合、以下の点を確認してください：

#### 1. スプレッドシートIDの確認

スプレッドシートのURLから正しいIDを取得しているか確認します。

**URLの例:**
```
https://docs.google.com/spreadsheets/d/1A2B3C4D5E6F7G8H9I0J/edit#gid=0
                                      ^^^^^^^^^^^^^^^^^^^^^
                                      この部分がスプレッドシートID
```

**正しいID:** `1A2B3C4D5E6F7G8H9I0J`  
**間違い例:** 
- URL全体をコピー
- `#gid=0`を含めてコピー
- `/edit`を含めてコピー

#### 2. サービスアカウントへの共有設定

Googleスプレッドシートがサービスアカウントに共有されているか確認します。

**手順:**
1. 対象のGoogleスプレッドシートを開く
2. 右上の「共有」ボタンをクリック
3. サービスアカウントのメールアドレスを入力
   - メールアドレスは `.env` ファイルの `GOOGLE_SERVICE_ACCOUNT_JSON` 内の `client_email` フィールドで確認
   - 例: `shiwakeya-service@project-name.iam.gserviceaccount.com`
4. 「編集者」権限を選択
5. 「送信」をクリック

**サービスアカウントのメールアドレスの確認方法:**
```bash
# .envファイルから確認
cat .env | grep GOOGLE_SERVICE_ACCOUNT_JSON
```

JSONの中の `"client_email"` の値がサービスアカウントのメールアドレスです。

#### 3. Google Sheets APIの有効化

Google Cloud ConsoleでSheets APIが有効になっているか確認します。

**手順:**
1. [Google Cloud Console](https://console.cloud.google.com/)にアクセス
2. プロジェクトを選択
3. 「APIとサービス」→「有効なAPI」を開く
4. 「Google Sheets API」が一覧に表示されているか確認
5. 表示されていない場合:
   - 「APIとサービスを有効化」をクリック
   - 「Google Sheets API」を検索
   - 「有効にする」をクリック

#### 4. 環境変数の設定確認

`.env` ファイルが正しく設定されているか確認します。

**確認コマンド:**
```bash
# 環境変数が設定されているか確認
rails console
> ENV['GOOGLE_SERVICE_ACCOUNT_JSON'].present?
# => true であることを確認

# JSONが正しくパースできるか確認
> JSON.parse(ENV['GOOGLE_SERVICE_ACCOUNT_JSON'])
# => エラーが出ないことを確認
```

**よくある問題:**
- JSONが改行されている（1行になっていない）
- エスケープが正しくない
- クォートが正しくない

**正しい設定例:**
```bash
GOOGLE_SERVICE_ACCOUNT_JSON='{"type":"service_account","project_id":"..."}'
```

#### 5. ログの確認

詳細なエラー情報をログで確認します。

```bash
# 開発環境のログを確認
tail -f log/development.log
```

スプレッドシート登録を試みて、エラーメッセージを確認してください。

#### 6. サービスアカウントの権限確認

Google Cloud Consoleでサービスアカウントの権限を確認します。

**手順:**
1. Google Cloud Consoleの「IAMと管理」→「サービスアカウント」
2. 使用しているサービスアカウントを選択
3. 「権限」タブで以下の権限があることを確認:
   - 編集者（Editor）または
   - Google Sheets API の必要な権限

#### 7. ネットワーク接続の確認

プロキシやファイアウォールがGoogle APIへのアクセスをブロックしていないか確認します。

```bash
# Google APIへの接続テスト
curl -I https://sheets.googleapis.com
```

### デバッグモードでの詳細確認

Railsコンソールで直接APIをテストします：

```ruby
# rails console を起動
rails console

# サービスを初期化
service = GoogleSheetsClient.new

# スプレッドシートIDでテスト（実際のIDに置き換える）
spreadsheet_id = "YOUR_SPREADSHEET_ID"
result = service.get_spreadsheet(spreadsheet_id)

# 結果を確認
if result.nil?
  puts "スプレッドシートが取得できませんでした"
  # log/development.log でエラー詳細を確認
else
  puts "スプレッドシート名: #{result.properties.title}"
end
```

### それでも解決しない場合

1. **新しいスプレッドシートで試す**
   - 新規にGoogleスプレッドシートを作成
   - 即座にサービスアカウントに共有
   - そのIDで登録を試みる

2. **サービスアカウントの再作成**
   - Google Cloud Consoleで新しいサービスアカウントを作成
   - 新しい認証JSONをダウンロード
   - `.env` ファイルを更新

3. **エラーログの共有**
   - `log/development.log` のエラー部分をコピー
   - エラーメッセージ全文を確認

## その他の一般的な問題

### ポート7000にアクセスできない

```bash
# サーバーが起動しているか確認
ps aux | grep rails

# 既存のサーバーを停止
kill -9 [PID]

# サーバーを再起動
bin/dev
```

### セッションエラー

ブラウザのCookieをクリアして、再度ログインしてください。

### データベースエラー

```bash
# データベースをリセット
bin/rails db:drop
bin/rails db:create
bin/rails db:migrate
```