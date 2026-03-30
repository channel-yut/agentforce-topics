# Agentforce Topics - パッケージング ガイド

## 📦 概要

このプロジェクトは**未ロックパッケージ (Unlocked Package)** として配布可能です。

---

## 🎯 パッケージタイプ比較

| 項目 | 未管理 | 管理 (1st Gen) | 未ロック (2nd Gen) ⭐ |
|------|--------|----------------|---------------------|
| バージョン管理 | ❌ | ✅ | ✅ |
| Namespace | 不要 | **必須** | 不要 |
| カスタマイズ | ✅ 完全 | ⚠️ 制限 | ✅ 完全 |
| Translations対応 | ✅ | ⚠️ 制限 | ✅ |
| アップグレード | ❌ | ✅ | ✅ |
| 推奨度 | ⭐⭐ | ⭐⭐ | ⭐⭐⭐ |

**推奨**: 未ロックパッケージ (Unlocked Package)

---

## 🚀 未ロックパッケージの作成手順

### 前提条件

- Dev Hub組織へのアクセス
- Salesforce CLI (`sf`) インストール済み
- Dev Hub機能が有効化されている

### ステップ1: Dev Hub組織の準備

```bash
# Dev Hubにログイン
sf org login web --alias my-devhub --set-default-dev-hub

# Dev Hub有効化確認
sf org display --target-org my-devhub
```

Dev Hub機能が無効の場合：
1. Setup → Dev Hub → Enable Dev Hub
2. Setup → Dev Hub → Enable Unlocked Packages and Second-Generation Managed Packages

### ステップ2: sfdx-project.json の更新

```json
{
  "packageDirectories": [
    {
      "path": "force-app",
      "package": "Agentforce Topics",
      "versionName": "Spring 2026",
      "versionNumber": "1.0.0.NEXT",
      "default": true
    }
  ],
  "name": "agentforce-topics",
  "namespace": "",
  "sfdcLoginUrl": "https://login.salesforce.com",
  "sourceApiVersion": "64.0",
  "packageAliases": {}
}
```

### ステップ3: パッケージ作成

```bash
# パッケージ登録
sf package create \
  --name "Agentforce Topics" \
  --description "AI-Powered Insights System with Self-Learning Capabilities" \
  --package-type Unlocked \
  --path force-app \
  --target-dev-hub my-devhub

# 結果確認
sf package list --target-dev-hub my-devhub
```

**出力例:**
```
Package Id (0Ho...): 0HoXXXXXXXXXXXXXXX
```

このIDは `sfdx-project.json` の `packageAliases` に自動追加されます。

### ステップ4: パッケージバージョン作成

```bash
# バージョン1.0.0 作成（10-20分かかる）
sf package version create \
  --package "Agentforce Topics" \
  --installation-key-bypass \
  --wait 20 \
  --target-dev-hub my-devhub

# 進行状況確認（別ターミナル）
sf package version create report --target-dev-hub my-devhub
```

**成功時の出力:**
```
Package Version Id (04t...): 04tXXXXXXXXXXXXXXX
Subscriber Package Version Id (04t...): 04tXXXXXXXXXXXXXXX
```

### ステップ5: バージョン昇格（Production配布用）

```bash
# Beta版 → Production版に昇格
sf package version promote \
  --package 04tXXXXXXXXXXXXXXX \
  --target-dev-hub my-devhub

# 結果確認
sf package version list --target-dev-hub my-devhub
```

---

## 📥 インストール手順

### 方法1: CLI経由

```bash
# 任意の組織にインストール
sf package install \
  --package 04tXXXXXXXXXXXXXXX \
  --target-org target-org-alias \
  --wait 10 \
  --publish-wait 10 \
  --no-prompt

# Permission Set 割り当て（インストール後）
sf org assign permset \
  --name Agentforce_Topics_Access \
  --target-org target-org-alias
```

### 方法2: ブラウザ経由

1. インストールURLを生成：
```
https://login.salesforce.com/packaging/installPackage.apexp?p0=04tXXXXXXXXXXXXXXX
```

2. URLをブラウザで開く
3. インストール対象組織にログイン
4. "Install for All Users" を選択
5. インストール完了後、Permission Set を手動割り当て

---

## 🔄 アップグレード手順

### 新バージョンの作成

```bash
# sfdx-project.json のバージョン番号を更新
# versionNumber: "1.0.0.NEXT" → "1.1.0.NEXT"

# 新バージョン作成
sf package version create \
  --package "Agentforce Topics" \
  --installation-key-bypass \
  --wait 20 \
  --target-dev-hub my-devhub

# 昇格
sf package version promote \
  --package 04tYYYYYYYYYYYYYYY \
  --target-dev-hub my-devhub
```

### 既存組織へのアップグレード

```bash
# 新バージョンをインストール（自動アップグレード）
sf package install \
  --package 04tYYYYYYYYYYYYYYY \
  --target-org target-org-alias \
  --wait 10 \
  --upgrade-type Mixed
```

**アップグレードタイプ:**
- `Mixed` (推奨): コンポーネント単位で判断
- `Delete-Only`: 削除のみ
- `Deprecate-Only`: 非推奨化のみ

---

## 📋 パッケージに含まれるコンポーネント

### ✅ すべて含まれる

- CustomObject: Agentforce_Topic__c (14 fields)
- ApexClass: 7個
- ApexTrigger: 1個
- LightningComponentBundle: 2個
- Flow: 2個
- CustomLabels: 42個
- Translations: 2個 (ja, en_US)
- CustomTab: 1個
- QuickAction: 2個
- Layout: 2個
- PermissionSet: 1個

**合計**: 77コンポーネント

### 🚫 除外されるもの

- `lwc/jsconfig.json` (`.forceignore` で除外)
- `**/__tests__/**` (テストファイル)
- `.eslintrc.json` (開発ツール設定)

---

## ⚠️ 注意事項

### 1. 翻訳ファイルの互換性

**問題**: インストール先組織で日本語言語パックが無効の場合、翻訳がスキップされる

**対策**: インストール前に言語パックを有効化
```
Setup → Company Information → Supported Languages → Japanese
```

### 2. Permission Set の依存関係

**問題**: Permission Setは Tab/Layout を参照するため、インストール順序が重要

**対策**: パッケージは自動的に依存関係を解決しますが、手動デプロイの場合は CLAUDE.md の順序に従う

### 3. Einstein AI 連携

**注意**: `AgentforceTopicGeneratorService` はサンプル実装です。
本番環境では Einstein AI API の統合が必要（コード内にコメントあり）。

---

## 🔧 トラブルシューティング

### パッケージバージョン作成が失敗

**エラー**: "No Dev Hub found"

**対策**:
```bash
# Dev Hub設定を確認
sf config get target-dev-hub

# Dev Hub再設定
sf config set target-dev-hub=my-devhub
```

### インストールが失敗

**エラー**: "This package requires features that aren't enabled in your org"

**対策**: 以下の機能を有効化
1. Lightning Experience
2. My Domain
3. (オプション) Einstein

### 依存関係エラー

**エラー**: "Component X has a dependency on Y"

**対策**: パッケージバージョン作成時に `--skip-validation` は使用せず、エラーを確認して依存関係を解決

---

## 📊 バージョン管理戦略

### セマンティックバージョニング

```
Major.Minor.Patch.Build
1.0.0.1
```

- **Major**: 破壊的変更（例: フィールド削除）
- **Minor**: 新機能追加（例: 新フィールド追加）
- **Patch**: バグ修正
- **Build**: 自動インクリメント（.NEXT）

### 推奨バージョンアップ

- **1.0.0**: 初回リリース（2026-03-30）
- **1.1.0**: 新機能追加（例: Slack統合）
- **1.2.0**: 新機能追加（例: Einstein AI統合）
- **2.0.0**: 破壊的変更（例: データモデル変更）

---

## 📝 リリースノート管理

各バージョンでリリースノートを作成：

```bash
# リリースノート追加
sf package version update \
  --package 04tXXXXXXXXXXXXXXX \
  --version-description "$(cat <<EOF
Version 1.0.0 - Initial Release

Features:
- AI-powered insights display
- Self-learning feedback system
- Multi-language support (Japanese, English)
- Agentforce Action integration

Installation:
sf package install --package 04tXXXXXXXXXXXXXXX

Documentation: See README.md and CLAUDE.md
EOF
)" \
  --target-dev-hub my-devhub
```

---

## 🔗 関連リソース

- [Salesforce DX Developer Guide - Unlocked Packages](https://developer.salesforce.com/docs/atlas.en-us.sfdx_dev.meta/sfdx_dev/sfdx_dev_unlocked_pkg.htm)
- [Package Version Create](https://developer.salesforce.com/docs/atlas.en-us.sfdx_cli_reference.meta/sfdx_cli_reference/cli_reference_package_commands_unified.htm)
- [README.md](README.md) - システム概要
- [CLAUDE.md](CLAUDE.md) - デプロイ手順

---

**Version**: 1.0
**Last Updated**: 2026-03-30
