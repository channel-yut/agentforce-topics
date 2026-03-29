# Agentforce Topics - デプロイガイド

## 🎯 このドキュメントについて

このプロジェクトを**新しいSalesforce組織にデプロイする際の手順書**です。

---

## 📋 前提条件

- Salesforce CLI (`sf`) がインストール済み
- デプロイ先組織にログイン済み
- API バージョン 64.0 以上

---

## 🚀 デプロイ手順

### ステップ1: 組織に接続

```bash
# ブラウザ認証でログイン
sf org login web --alias your-org-alias

# デフォルト組織として設定
sf config set target-org your-org-alias
```

### ステップ2: デプロイ実行

**方法A: 段階的デプロイ（推奨）**

依存関係の順にデプロイします：

```bash
# 1. カスタムオブジェクト
sf project deploy start --source-dir force-app/main/default/objects --target-org your-org-alias --wait 10

# 2. Apexクラス
sf project deploy start --source-dir force-app/main/default/classes --target-org your-org-alias --wait 10

# 3. カスタムラベル
sf project deploy start --source-dir force-app/main/default/labels --target-org your-org-alias --wait 10

# 4. 翻訳ファイル（日本語対応）
sf project deploy start --source-dir force-app/main/default/translations --target-org your-org-alias --wait 10

# 5. LWCコンポーネント
sf project deploy start --source-dir force-app/main/default/lwc --target-org your-org-alias --wait 10

# 6. Flows
sf project deploy start --source-dir force-app/main/default/flows --target-org your-org-alias --wait 10

# 7. Trigger
sf project deploy start --source-dir force-app/main/default/triggers --target-org your-org-alias --wait 10

# 8. Tab
sf project deploy start --source-dir force-app/main/default/tabs --target-org your-org-alias --wait 10

# 9. Quick Actions
sf project deploy start --source-dir force-app/main/default/quickActions --target-org your-org-alias --wait 10

# 10. Layouts
sf project deploy start --source-dir force-app/main/default/layouts --target-org your-org-alias --wait 10

# 11. Permission Set
sf project deploy start --source-dir force-app/main/default/permissionsets --target-org your-org-alias --wait 10
```

**方法B: 一括デプロイ**

```bash
# 全メタデータを一度にデプロイ
sf project deploy start --target-org your-org-alias --wait 10
```

⚠️ **注意**: トライアル組織では方法Aを推奨。方法Bで Pending 状態が続く場合は Ctrl+C でキャンセルして方法Aに切り替え。

### ステップ3: Permission Set 割り当て

```bash
sf org assign permset --name Agentforce_Topics_Access --target-org your-org-alias
```

---

## ✅ デプロイ確認

```bash
# 組織を開く
sf org open --target-org your-org-alias

# Setup → Object Manager → Agentforce Topic でオブジェクト確認
# Setup → Apex Classes で7個のクラス確認
# App Launcher → Agentforce Topics タブ確認
```

---

## 🛠️ セットアップ

### レコードページにコンポーネント追加

1. Setup → Object Manager → Account (または任意のオブジェクト)
2. Lightning Record Pages → 編集するページを選択
3. Lightning App Builder でページを開く
4. 左側のコンポーネント一覧から **agentforceTopics** を選択
5. ページ上の適切な位置にドラッグ&ドロップ
6. (任意) **agentforceTopicsStats** も追加
7. 保存 → Activate

### 言語設定（日本語表示）

1. Setup → 自分の名前のアイコン → Settings
2. Language and Time Zone → Language: **Japanese (日本語)**
3. Save してページをリロード

### 自己学習スケジューラー設定（任意）

Developer Console または Execute Anonymous で実行：

```apex
System.schedule('Weekly Feedback Analysis', '0 0 0 ? * MON', new WeeklyFeedbackAnalysisScheduler());
```

---

## 🎯 Agentforce 連携設定

### Apex Action の登録

1. Setup → **Agent Builder** を開く
2. 新しいAgentを作成または既存のAgentを編集
3. **Topic** を作成
4. **Actions** セクションで **"Add Action"** をクリック
5. **Action Type**: "Apex Action" を選択
6. リストから選択：
   - **Create or Update Agentforce Topic**
   - または **Generate Agentforce Topic**
7. 入力パラメータをマッピング：

**例: Create or Update Agentforce Topic**
```
summary: {Agent生成の概要テキスト}
content: {Agent生成のHTMLコンテンツ}
relatedRecordId: {コンテキストレコードID}
triggerType: "Agentforce"
```

8. 保存してテスト実行

---

## 🐛 トラブルシューティング

### デプロイが Pending で止まる

**原因**: トライアル組織の処理能力制限

**対処法**:
1. Ctrl+C でキャンセル
2. 段階的デプロイ（方法A）に切り替え
3. または5-10分待ってから再試行

```bash
# 現在のデプロイをキャンセル
sf project deploy cancel --job-id <JOB_ID> --target-org your-org-alias

# ステータス確認
sf project deploy report --use-most-recent --target-org your-org-alias
```

### Permission Set デプロイエラー

**エラー**: "no CustomTab named Agentforce_Topic__c found"

**対処法**: Tab を先にデプロイ
```bash
sf project deploy start --source-dir force-app/main/default/tabs --target-org your-org-alias --wait 10
sf project deploy start --source-dir force-app/main/default/permissionsets --target-org your-org-alias --wait 10
```

### Layout デプロイエラー

**エラー**: "no QuickAction named Agentforce_Topic__c.New_Topic found"

**対処法**: Quick Actions を先にデプロイ
```bash
sf project deploy start --source-dir force-app/main/default/quickActions --target-org your-org-alias --wait 10
sf project deploy start --source-dir force-app/main/default/layouts --target-org your-org-alias --wait 10
```

### LWC デプロイエラー

**エラー**: "no label named c.AgentforceTopics_xxx found"

**対処法**: カスタムラベルを先にデプロイ
```bash
sf project deploy start --source-dir force-app/main/default/labels --target-org your-org-alias --wait 10
sf project deploy start --source-dir force-app/main/default/lwc --target-org your-org-alias --wait 10
```

---

## 📦 デプロイされるコンポーネント一覧

- カスタムオブジェクト: 1個 (Agentforce_Topic__c)
- カスタムフィールド: 14個
- Apexクラス: 7個
- Apexトリガー: 1個
- LWCコンポーネント: 2個
- Flow: 2個
- カスタムラベル: 42個
- 翻訳ファイル: 2個（日本語・英語）
- カスタムタブ: 1個
- Quick Action: 2個
- Page Layout: 2個
- Permission Set: 1個

**合計**: 75+ コンポーネント

---

## 🔄 更新時の手順

既存組織に更新を適用する場合：

```bash
# 変更されたコンポーネントのみデプロイ
sf project deploy start --target-org your-org-alias --wait 10

# または特定のメタデータのみ
sf project deploy start --source-dir force-app/main/default/classes --target-org your-org-alias --wait 10
```

---

## 🧪 テスト

### 手動テスト

1. Agentforce Topics タブからレコード作成
2. レコードページで agentforceTopics コンポーネント表示確認
3. フィードバックボタン（役立った/役立たなかった）をクリック
4. 統計ダッシュボード（agentforceTopicsStats）で集計確認

### Apex テスト実行

```bash
sf apex run test --class-names AgentforceTopicCreatorTest --target-org your-org-alias --result-format human
```

---

## 📝 デプロイ記録

デプロイ後は README.md の「デプロイ履歴」セクションに記録してください：

```markdown
| 日付 | 組織 | 結果 | 備考 |
|------|------|------|------|
| YYYY-MM-DD | org-alias | ✅/❌ | コメント |
```

---

## 🔗 関連リソース

- [README.md](README.md) - システム概要とAgentforce連携
- [HTMLスタイルガイド](docs/agentforce-topic-style-guide.md)
- [Salesforce CLI リファレンス](https://developer.salesforce.com/docs/atlas.en-us.sfdx_cli_reference.meta/sfdx_cli_reference/)

---

**Version**: 1.0
**Last Updated**: 2026-03-30
