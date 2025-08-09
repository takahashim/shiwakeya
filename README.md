# 仕訳屋（Shiwakeya）

仕訳屋は、サービスアカウント認証を使用して複数のGoogleスプレッドシートを管理・読み書きする Rails アプリケーションです。
データベースでスプレッドシートを管理し、各シートのデータ読み取り、書き込み、更新を行い、将来的にマネーフォワードとの自動連携を実現します。

## 主な機能

### 実装済み機能
- **サービスアカウント認証**: アプリケーション専用のサービスアカウントで認証
- **複数スプレッドシート管理**: データベースで複数のスプレッドシートを登録・管理
- **シートビューア**: スプレッドシート内の各シートデータをテーブル形式で表示
- **データ操作**: データの読み取り、書き込み、追加、クリア機能
- **ユーザー管理**: メールアドレスベースの簡易ログイン（管理者/一般ユーザー）
- **レスポンシブUI**: Tailwind CSSによるモバイル対応デザイン

### 今後の実装予定
- マネーフォワードAPI連携
- スプレッドシートデータの自動仕訳
- 定期的な自動同期
- データエクスポート機能（CSV、JSON）

## システム要件

- Ruby 3.x以上
- Rails 8.0.2以上
- SQLite3
- Node.js（Tailwind CSS用）

## セットアップ手順

### 1. リポジトリのクローン

```bash
git clone https://github.com/yourusername/shiwakeya.git
cd shiwakeya
```

### 2. 依存関係のインストール

```bash
bundle install
```

### 3. データベースのセットアップ

```bash
bin/rails db:create
bin/rails db:migrate
```

### 4. サービスアカウント認証の設定

#### Google Cloud Consoleでの設定

1. [Google Cloud Console](https://console.cloud.google.com/)にアクセス
2. 新しいプロジェクトを作成または既存のプロジェクトを選択
3. 「APIとサービス」→「認証情報」を開く
4. 「認証情報を作成」→「サービスアカウント」を選択
5. サービスアカウントの詳細を入力：
   - 名前: 任意（例：Shiwakeya Service Account）
   - ID: 自動生成されるIDを使用
6. 「作成して続行」をクリック
7. ロールで「編集者」または必要な権限を付与
8. 「完了」をクリック
9. 作成したサービスアカウントをクリック
10. 「キー」タブから「鍵を追加」→「新しい鍵を作成」→「JSON」を選択
11. JSONファイルがダウンロードされる

#### APIの有効化

Google Cloud Consoleで以下のAPIを有効化：
- Google Sheets API

#### スプレッドシートの共有設定

1. 使用するGoogleスプレッドシートを開く
2. 「共有」ボタンをクリック
3. サービスアカウントのメールアドレス（JSONファイル内の`client_email`）を入力
4. 「編集者」権限を付与して共有

#### 環境変数の設定

`.env`ファイルを作成（`.env.example`をコピー）：

```bash
cp .env.example .env
```

以下の内容を設定：

```bash
# ダウンロードしたJSONファイルの内容を1行にして設定
GOOGLE_SERVICE_ACCOUNT_JSON='{"type":"service_account",...}'

# 管理者メールアドレス（このメールアドレスで初回ログインすると管理者権限が付与されます）
ADMIN_EMAIL='admin@example.com'
```

### 5. アプリケーションの起動

```bash
bin/dev
```

アプリケーションは http://localhost:7000 でアクセスできます。

## 使い方

### 初回ログイン

1. ブラウザで http://localhost:7000 にアクセス
2. メールアドレスを入力してログイン
3. 初回ログイン時は自動的にユーザーが作成されます
4. 環境変数`ADMIN_EMAIL`に設定したメールアドレスでログインすると自動的に管理者権限が付与されます

### スプレッドシートの登録と同期

1. 管理者アカウントでログイン
2. 「スプレッドシート」メニューから「新規追加」をクリック
3. スプレッドシートIDを入力して登録
   - IDはURLの`https://docs.google.com/spreadsheets/d/{ID}/edit`部分から取得
4. 「同期」ボタンをクリックしてシート情報を取得
5. 複数のスプレッドシートを登録・管理可能

### シートデータの閲覧

1. スプレッドシート一覧から任意のスプレッドシートを選択
2. シート一覧が表示されます
3. 各シートをクリックするとデータがテーブル形式で表示されます
4. 「データを同期」ボタンで最新のデータを取得

### データの操作

1. スプレッドシート一覧から対象を選択
2. シート一覧から操作したいシートを選択
3. 以下の操作が可能：
   - **表示**: データをテーブル形式で閲覧
   - **同期**: 最新データを取得
   - **追加**: 新しい行を追加（入力用シートのみ）
   - **クリア**: データを全削除（管理者のみ）

## ディレクトリ構造

```
shiwakeya/
├── app/
│   ├── controllers/       # コントローラー
│   │   ├── dashboard_controller.rb
│   │   ├── sessions_controller.rb
│   │   ├── service_spreadsheets_controller.rb
│   │   └── service_sheets_controller.rb
│   ├── models/            # モデル
│   │   ├── user.rb
│   │   ├── service_spreadsheet.rb
│   │   └── service_sheet.rb
│   ├── services/          # サービスクラス
│   │   └── service_account_sheets_service.rb
│   └── views/             # ビューテンプレート
├── config/
│   ├── routes.rb          # ルーティング設定
│   └── initializers/
├── db/
│   └── migrate/           # マイグレーションファイル
└── bin/
    └── dev                # 開発サーバー起動スクリプト
```

## 開発コマンド

```bash
# 開発サーバーの起動（Tailwind CSS監視モード付き）
bin/dev

# Railsサーバーのみ起動
bin/rails server

# コンソールの起動
bin/rails console

# データベースのリセット
bin/rails db:reset

# ルーティングの確認
bin/rails routes

# コードの静的解析
bin/rubocop

# セキュリティチェック
bin/brakeman
```

## トラブルシューティング

### ポート変更が必要な場合

デフォルトではポート7000を使用していますが、変更が必要な場合：

1. `bin/dev`ファイルの`PORT`を変更
2. `config/puma.rb`のポート設定を変更

### 認証エラーが発生する場合

1. Google Cloud ConsoleでSheets APIが有効になっているか確認
2. `.env`ファイルの環境変数が正しく設定されているか確認
3. サービスアカウントがスプレッドシートに共有されているか確認
4. JSONの形式が正しいか（1行になっているか）確認

### データベースエラーの場合

```bash
bin/rails db:drop
bin/rails db:create
bin/rails db:migrate
```

## ライセンス

このプロジェクトはMITライセンスの下で公開されています。

## 貢献

プルリクエストは歓迎です。大きな変更の場合は、まずissueを開いて変更内容について議論してください。

## 作者

[あなたの名前]

## 謝辞

- Ruby on Rails コミュニティ
- Google APIs
- Tailwind CSS
