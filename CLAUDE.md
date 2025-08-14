# CLAUDE.md

## 概要

仕訳屋（Shiwakeya）は、Googleスプレッドシートとマネーフォワード（Money Forward）を統合し、財務データ管理と記帳自動化を実現するRailsアプリケーションです。

## 技術スタック

- **フレームワーク**: Rails 8.0.2（Propshaftアセットパイプライン使用）
- **データベース**: SQLite3（本番環境ではSolid Cache、Solid Queue、Solid Cable使用）
- **CSS**: Tailwind CSS
- **Webサーバー**: Puma（本番環境ではThruster使用）
- **デプロイ**: Kamal（Dockerベースのデプロイメント）
- **Rubyバージョン**: `.ruby-version`ファイルで現在のバージョンを確認

## 開発コマンド

### 初期セットアップ
```bash
bin/setup              # 依存関係のインストール、データベース準備、サーバー起動
```

### アプリケーションの実行
```bash
bin/dev                # Tailwind CSSウォッチモード付き開発サーバー起動（Procfile.dev使用）
bin/rails server       # Railsサーバーのみ起動
bin/rails tailwindcss:watch  # Tailwind CSSウォッチモード起動
```

### データベース管理
```bash
bin/rails db:create    # 開発・テスト用データベース作成
bin/rails db:migrate   # データベースマイグレーション実行
bin/rails db:prepare   # データベースセットアップ（作成、マイグレーション、シード）
bin/rails db:drop      # データベース削除
bin/rails db:seed      # シードデータ投入
bin/rails db:reset     # 削除、作成、マイグレーション、シードを一括実行
```

### コード品質
```bash
bin/rubocop            # RuboCopでRubyコードをリント（.rubocop.ymlでrails-omakase使用）
bin/brakeman           # セキュリティ分析を実行
```

### アセット管理
```bash
bin/rails assets:precompile  # 本番環境用アセットのコンパイル
bin/rails assets:clean        # 古いコンパイル済みアセットを削除
bin/rails assets:clobber      # すべてのコンパイル済みアセットを削除
```

### コンソールとタスク
```bash
bin/rails console      # Railsコンソール起動
bin/rails c            # コンソールの省略形
bin/rails routes       # すべてのアプリケーションルートを表示
bin/rails -T           # 利用可能なrakeタスク一覧を表示
```

## アーキテクチャ

### アプリケーション構造
標準的なRails MVCアーキテクチャに従っています：

- **モデル** (`app/models/`): ビジネスロジックとデータ永続化のためのActive Recordモデル
- **ビュー** (`app/views/`): Tailwind CSSスタイリング付きERBテンプレート
- **コントローラー** (`app/controllers/`): リクエスト処理とレスポンス調整
  - ルーティングはDHH式のRESTfulルーティングを採用
- **アセット** (`app/assets/`): Propshaftで管理されるスタイルシートと画像
  - Tailwind CSSコンパイル出力: `app/assets/builds/`
  - ソーススタイル: `app/assets/stylesheets/`と`app/assets/tailwind/`

### データベース設定
- 開発環境: SQLite3（`storage/development.sqlite3`に保存）
- テスト環境: SQLite3（`storage/test.sqlite3`に保存）
- 本番環境: プライマリ、キャッシュ、キュー、ケーブル用の複数のSQLite3データベース
  - 目的別にマイグレーションを分離: `db/cache_migrate`、`db/queue_migrate`、`db/cable_migrate`

### 主要な設定ファイル
- `config/routes.rb`: アプリケーションルーティング
- `config/database.yml`: データベース設定
- `config/application.rb`: メインアプリケーション設定（モジュール名: Shiwakeya）
- `Procfile.dev`: 開発サーバープロセス（Webサーバー + Tailwindウォッチ）

### 開発ツール
- **Foreman**: 開発環境で複数サービスを実行するプロセスマネージャー
- **Debug gem**: リモート接続対応のRubyデバッグツール

## GoogleスプレッドシートとマネーフォワードAPI統合

このアプリケーションは、Googleスプレッドシートとマネーフォワード間の架け橋となり、記帳と財務データの同期を自動化します。統合の実装詳細は以下に追加されます：

- OAuthとAPIエンドポイント処理用コントローラー
- Google Sheets API操作用サービスオブジェクト
- マネーフォワードAPI操作用サービスオブジェクト
- データ同期用バックグラウンドジョブ
- 統合設定とマッピングルール保存用モデル

## 開発ワークフロー

1. クローンまたは大きな変更をプル後は必ず`bin/setup`を実行
2. 開発時は`bin/dev`を使用してTailwind CSSコンパイルを確保
3. コミット前に`bin/rubocop`を実行してコード品質を維持
4. `bin/brakeman`によるセキュリティスキャンは開発/テスト環境用に設定済み
5. データベース変更はRailsマイグレーションを使用（`bin/rails generate migration`）
