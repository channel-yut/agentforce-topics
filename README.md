# Agentforce Topics - AI-Powered Insights System

## 📋 概要

Salesforce組織上で動作する**自己学習型AIインサイトシステム**です。レコードに関連するAI生成コンテンツを表示し、ユーザーフィードバックを収集・分析して継続的に改善します。

### 主要機能

- 🤖 **AIインサイト表示** - レコードページでAI生成コンテンツをリッチテキスト形式で表示
- 📊 **フィードバックシステム** - 「役立った」「役立たなかった」の2段階評価
- 🔄 **自己学習機能** - フィードバックを分析し、改善指示を自動生成
- 📈 **統計ダッシュボード** - フィードバック集計とKPI表示
- 🌐 **多言語対応** - 日本語・英語対応（42個のカスタムラベル）
- 🎨 **スタイルガイド** - 統一されたHTMLスタイル（docs/agentforce-topic-style-guide.md）

---

## 🚀 適用済み環境

### agentforce-trial-demo (2026-03-30)

| 項目 | 詳細 |
|------|------|
| **組織URL** | https://trailsignup-1fe1da6a5ff4ca.my.salesforce.com |
| **ユーザー名** | admin@agentforce.trial.demo.com |
| **トライアル期限** | 2026-04-29 |
| **デプロイ日時** | 2026-03-30 01:53 (JST) |
| **コンポーネント数** | 75+ (オブジェクト、Apex、LWC、Flow等) |

**適用済みメタデータ:**
- ✅ カスタムオブジェクト: Agentforce_Topic__c (14フィールド)
- ✅ Apexクラス: 7個 (Controller, TriggerHandler, SelfLearningService等)
- ✅ LWCコンポーネント: 2個 (agentforceTopics, agentforceTopicsStats)
- ✅ Flow: 2個 (Create, Edit)
- ✅ Trigger: 1個 (AgentforceTopicTrigger)
- ✅ カスタムラベル: 42個
- ✅ Permission Set: Agentforce_Topics_Access (割り当て済み)
- ✅ Tab, Layout, QuickAction

---

## 🎯 Agentforce 連携（重要）

### 利用可能なApex Action

デプロイ済みのApexクラスは **@InvocableMethod** アノテーション付きのため、**Agentforce Actionとして自動的に利用可能**です。

#### 1️⃣ Create or Update Agentforce Topic

**Apexクラス**: `AgentforceTopicCreator.createOrUpdateTopic`

**用途**: AgentがAI生成コンテンツをカスタムオブジェクトに保存

**入力パラメータ:**
- `topicId` (String, 任意) - 更新時は既存レコードID
- `relatedRecordId` (String, 任意) - 関連レコードID (Account, Opportunity等)
- `triggerType` (String, 任意) - トリガータイプ（例: 面談記録、商談更新）
- `summary` (String, 必須) - 概要テキスト
- `content` (String, 必須) - リッチHTMLコンテンツ

**出力:**
- `topicId` (String) - 作成/更新されたレコードID
- `success` (Boolean) - 成功/失敗
- `message` (String) - 結果メッセージ

#### 2️⃣ Generate Agentforce Topic

**Apexクラス**: `AgentforceTopicGeneratorService.generateTopicFromFlow`

**用途**: レコードデータを分析してAIインサイトを生成（サンプル実装）

**入力パラメータ:**
- `recordId` (String, 必須) - 分析対象レコードID
- `triggerType` (String, 必須) - トリガータイプ

**出力:**
- `topicId` (String) - 生成されたレコードID

**注意**: 現在はサンプルコンテンツを返す実装。本番環境ではEinstein AI APIと連携する必要があります（コード内にコメント例あり）。

### Agentでの使用方法

```
1. Setup → Agent Builder を開く
2. 新しいAgentまたは既存のAgentを編集
3. Topic を作成
4. Action セクションで "Add Action"
5. Action Type: "Apex Action" を選択
6. "Create or Update Agentforce Topic" を選択
7. 入力パラメータをマッピング:
   - summary: {Agent生成の概要}
   - content: {Agent生成のHTMLコンテンツ}
   - relatedRecordId: {コンテキストレコードID}
   - triggerType: "Agentforce生成"
```

---

## 📦 主要コンポーネント

### カスタムオブジェクト: Agentforce_Topic__c

**主要フィールド:**
- `Content__c` (Rich Text Area) - AI生成HTMLコンテンツ
- `Summary__c` (Text) - 1-2行の概要
- `Trigger_Type__c` (Text) - トリガータイプ
- `Related_Record_Id__c` (Text) - 関連レコードID
- `Generated_Date__c` (DateTime) - 生成日時
- `Feedback__c` (Text) - フィードバック（役立った/役立たなかった）

**自己学習フィールド:**
- `Helpful_Count__c` (Number) - 役立った件数
- `Not_Helpful_Count__c` (Number) - 役立たなかった件数
- `Total_Feedback_Count__c` (Number) - 総フィードバック数
- `Feedback_Rate__c` (Percent) - フィードバック率
- `Feedback_Category__c` (Text) - フィードバックカテゴリ
- `Improvement_Patterns__c` (Long Text) - 改善パターン（JSON）
- `Learning_Context__c` (Long Text) - 学習コンテキスト（JSON）
- `Generation__c` (Number) - 世代番号

### LWCコンポーネント

**1. agentforceTopics**
- レコードページに配置可能
- 最新トピック表示、履歴一覧、詳細ビュー
- フィードバック機能、クリップボードコピー
- 折りたたみ/展開機能

**2. agentforceTopicsStats**
- フィードバック統計ダッシュボード
- プログレスバーとKPI表示

### Apexクラス

| クラス名 | 役割 |
|---------|------|
| AgentforceTopicsController | LWC用データ取得・更新API |
| AgentforceTopicCreator | **Agentforce Action** - レコード作成/更新 |
| AgentforceTopicGeneratorService | **Agentforce Action** - AI生成 |
| AgentforceSelfLearningService | フィードバック分析・改善指示生成 |
| AgentforceTopicTriggerHandler | フィードバック集計処理 |
| WeeklyFeedbackAnalysisScheduler | 定期分析スケジューラー |
| AgentforceTopicCreatorTest | テストクラス |

---

## 🔧 使い方

### 1. レコードページにコンポーネント追加

```
1. Setup → Object Manager → Account (または任意のオブジェクト)
2. Lightning Record Pages → Edit
3. App Builder でページを開く
4. "agentforceTopics" コンポーネントをページに配置
5. (任意) "agentforceTopicsStats" も配置
6. 保存・有効化
```

### 2. テストデータ作成

```
1. App Launcher → "Agentforce Topics" タブ
2. "New" ボタンでレコード作成
3. または Quick Action "New Topic" を使用
4. または Flow "Agentforce Topic Create" を実行
```

### 3. 自己学習機能の有効化（任意）

```apex
// 週次フィードバック分析をスケジュール
System.schedule('Weekly Feedback Analysis', '0 0 0 ? * MON', new WeeklyFeedbackAnalysisScheduler());
```

---

## 🎨 HTMLスタイルガイド

AI生成コンテンツのHTML構造については [docs/agentforce-topic-style-guide.md](docs/agentforce-topic-style-guide.md) を参照してください。

**主要ルール:**
- 見出し: `<h3>` タグ（カラーコード指定）
- セクションボックス: 背景色 + 左ボーダー
- リンク: 関連レコードリンク、アクションリンク、ナレッジリンク
- 絵文字の使用ガイドライン

---

## 🔄 自己学習フロー

```
1. ユーザーがフィードバック評価 (役立った/役立たなかった)
   ↓
2. トリガーでフィードバックカウント集計
   ↓
3. スケジューラーが週次でネガティブフィードバックを分析
   ↓
4. カテゴリ別に問題パターンと改善指示を抽出
   ↓
5. マスターレコード (IMPROVEMENT_MASTER_{triggerType}) に保存
   ↓
6. 次回生成時、改善コンテキストをプロンプトに注入
```

**マスターレコード形式:**
- Related_Record_Id__c = `IMPROVEMENT_MASTER_{triggerType}`
- Improvement_Patterns__c = JSON形式の改善パターン
- Generation__c = 世代番号（v1, v2, v3...）

---

## 📝 カスタムラベル

**主要ラベル (42個):**
- AgentforceTopics_Title
- AgentforceTopics_SubtitleLatest
- AgentforceTopics_FeedbackHelpful
- AgentforceTopics_FeedbackNotHelpful
- AgentforceTopics_StatsTitle
- (その他37個 - 日英対応)

---

## 🚨 注意事項

### Prompt Template について

過去に `AgentforceTopicGenerator.prompt-meta.xml` が存在しましたが、**Metadata API v66の構造非互換性により削除**されました（コミット 3740c95）。

現在は Apex 内でサンプルコンテンツを生成していますが、本番環境では以下の統合が推奨されます：

```apex
// AgentforceTopicGeneratorService.cls 107-123行目参照
ConnectApi.EinsteinPromptTemplateGenerationsInput input =
    new ConnectApi.EinsteinPromptTemplateGenerationsInput();
input.promptTemplateApiName = 'YourPromptTemplate';
// ... (詳細はコード参照)
```

---

## 📚 関連ドキュメント

- [デプロイ手順](CLAUDE.md) - 他の組織への適用方法
- [HTMLスタイルガイド](docs/agentforce-topic-style-guide.md)
- [Git履歴](https://github.com/your-repo/agentforce-topics)

---

## 📊 デプロイ履歴

| 日付 | 組織 | 結果 | 備考 |
|------|------|------|------|
| 2026-03-30 | agentforce-trial-demo | ✅ 成功 | 全75+コンポーネント |
| 2026-03-23 | kw-demo-org | ✅ 成功 | Prompt削除後 |

---

## 🤝 サポート

質問や問題がある場合は、プロジェクトチームまたはSlackチャンネルでお問い合わせください。

---

**Version**: 1.0
**Last Updated**: 2026-03-30
**Maintained by**: Yutaro Nakamura
