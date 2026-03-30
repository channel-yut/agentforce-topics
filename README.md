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

## 📦 インストール方法

> **📄 パッケージユーザー向け**: シンプルなインストールガイドは [PACKAGE_README.md](PACKAGE_README.md) を参照してください。

### 方法A: 未ロックパッケージ（推奨）

```bash
# パッケージIDでインストール
sf package install \
  --package 04tXXXXXXXXXXXXXXX \
  --target-org your-org-alias \
  --wait 10 \
  --publish-wait 10

# Permission Set 割り当て
sf org assign permset \
  --name Agentforce_Topics_Access \
  --target-org your-org-alias
```

**パッケージID**: (作成後に記載)

### 方法B: ソースからデプロイ

詳細は [CLAUDE.md](CLAUDE.md) を参照してください。

```bash
# クローン
git clone <repository-url>
cd agentforce-topics

# デプロイ（段階的）
sf project deploy start --source-dir force-app/main/default/objects --target-org your-org-alias --wait 10
sf project deploy start --source-dir force-app/main/default/classes --target-org your-org-alias --wait 10
# ... (続きはCLAUDE.md参照)
```

---

## 🔧 セットアップ

### 1. レコードページにコンポーネント追加

```
1. Setup → Object Manager → Account (または任意のオブジェクト)
2. Lightning Record Pages → Edit
3. App Builder でページを開く
4. "agentforceTopics" コンポーネントをページに配置
5. (任意) "agentforceTopicsStats" も配置
6. 保存・有効化
```

### 2. 言語設定（日本語表示）

組織の言語設定を日本語にすると、UI表示が日本語になります。

```
Setup → 自分の名前のアイコン → Settings
→ Language and Time Zone → Language: Japanese (日本語) → Save
```

### 3. 自己学習機能の有効化（任意）

週次フィードバック分析を自動実行するスケジューラーを設定します。

```apex
// Developer Console または Execute Anonymous で実行
System.schedule(
    'Agentforce Topics Weekly Feedback Analysis',
    '0 0 9 ? * MON',  // 毎週月曜 9:00 AM
    new WeeklyFeedbackAnalysisScheduler()
);
```

**または便利メソッド:**
```apex
WeeklyFeedbackAnalysisScheduler.scheduleWeeklyJob();
```

---

## 💡 使い方：2つのパターン

### パターン1: テストレコードを直接作成

レコードページでコンポーネントの動作を確認したい場合に最適です。

#### ステップ1: レコード作成

**方法A: Agentforce Topics タブから作成**

```
1. App Launcher → "Agentforce Topics" タブ
2. "New" ボタンをクリック
3. 以下のフィールドを入力：
   - Related Record Id: 001XXXXXXXXXXXXXX (任意のAccount/OpportunityのID)
   - Trigger Type: "テスト" or "手動作成"
   - Summary: "2026/03/30 山田商事様 - 売上向上提案"
   - Content: HTMLコンテンツ（下記サンプル参照）
   - Generated Date: 今日の日付
4. Save
```

**方法B: Quick Action から作成**

```
1. Account または Opportunity レコードページを開く
2. ページ上部の Quick Action "New Topic" をクリック
3. 必要項目を入力
4. Save
```

**方法C: Flow から作成**

```
1. Setup → Flows → "Agentforce Topic Create" を開く
2. Run を クリック
3. パラメータを入力して実行
```

#### ステップ2: HTMLコンテンツのサンプル

```html
<div style="background-color: #fff9c4; padding: 16px; margin-bottom: 20px; border-radius: 8px; border-left: 4px solid #fbc02d;">
    <h3 style="color: #d32f2f; font-size: 20px; font-weight: bold; margin-bottom: 12px;">⚠️ 即対応が必要な項目</h3>
    <ol style="font-size: 14px; line-height: 1.6; margin: 0; padding-left: 20px;">
        <li style="margin-bottom: 8px;"><strong>フォローアップミーティング</strong> - 10/28週までにスケジューリング（営業部長承認済み）</li>
        <li style="margin-bottom: 8px;"><strong>提案資料更新</strong> - 3営業日以内にCTO宛に送付</li>
        <li><strong>技術チーム連携</strong> - 本日中に確認（担当：田中）</li>
    </ol>
</div>

<div style="background-color: #e1f5fe; padding: 16px; margin-bottom: 20px; border-radius: 8px; border-left: 4px solid #0288d1;">
    <h3 style="color: #1976d2; font-size: 20px; font-weight: bold; margin-bottom: 12px;">💼 推奨事項</h3>
    <p style="font-size: 14px; line-height: 1.7; margin-bottom: 8px;">
        <strong>重要：</strong>競合分析資料の準備を推奨します。顧客は複数社を比較検討している段階です。
    </p>
    <p style="font-size: 14px; line-height: 1.7; margin: 0;">
        <strong>目標：</strong>提案の受注率を<strong>15%向上</strong>させることを目指します。
    </p>
</div>
```

詳細なスタイルガイドは [docs/agentforce-topic-style-guide.md](docs/agentforce-topic-style-guide.md) を参照。

#### ステップ3: レコードページで確認

```
1. Related Record Id に指定したレコード（Account/Opportunity）を開く
2. agentforceTopics コンポーネントに作成したコンテンツが表示される
3. 「役立った」「役立たなかった」ボタンでフィードバック送信を試す
4. 履歴表示ボタンをクリックして過去のトピックを確認
```

---

### パターン2: Agentforce Action に組み込む

AgentがAI生成コンテンツをカスタムオブジェクトに保存する方法です。

#### ステップ1: Agent Builder を開く

```
Setup → Einstein → Agent Builder → 新規作成 or 既存Agent編集
```

#### ステップ2: Topic を作成

```
1. Topics タブ → "New Topic"
2. Topic Name: "顧客インサイト生成"
3. Description: "顧客レコードから重要なインサイトを生成"
4. Instructions:
   「顧客情報を分析し、次のアクション、推奨事項、主要インサイトを生成してください。
   出力はHTML形式で、見出しには<h3>タグ、リストには<ul>/<ol>タグを使用してください。」
```

#### ステップ3: Action を追加

```
1. Actions セクション → "Add Action"
2. Action Type: "Apex Action" を選択
3. Apex Class: "Create or Update Agentforce Topic" を選択
4. 入力パラメータのマッピング:
   - summary: {Agent生成の概要テキスト}
   - content: {Agent生成のHTMLコンテンツ}
   - relatedRecordId: {コンテキストレコードID}
   - triggerType: "Agentforce"
```

#### ステップ4: プロンプトの設定例

Agent Instructionsに以下を追加：

```
【出力形式】
以下の構造でHTML形式のコンテンツを生成してください：

1. ネクストアクション（優先順位順、期限明記）
2. 推奨事項（具体的な数値目標を含む）
3. 主要インサイト（リスクと機会を明確に）

【HTMLスタイル】
- 見出し: <h3 style="color: #1976d2; font-size: 20px; font-weight: bold;">
- セクション: <div style="background-color: #e1f5fe; padding: 16px; border-radius: 8px;">
- リスト: <ol style="font-size: 14px; line-height: 1.6;">

【重要】
- 具体的な担当者、期限、数値目標を必ず含める
- 抽象的な表現は避ける
```

#### ステップ5: Agent をテスト

```
1. Agent Builder で "Test" ボタンをクリック
2. テスト対話を実行
3. 生成されたコンテンツがAgentforce_Topic__cレコードに保存される
4. レコードページでLWCコンポーネントに表示されることを確認
```

#### ステップ6: 自己学習の確認

```
1. 複数のトピックを生成
2. フィードバックボタン（役立った/役立たなかった）をクリック
3. スケジューラーを実行（手動またはスケジュール）
4. 次回生成時に改善パターンが反映される
```

**自己学習の動作確認:**
```apex
// 手動でフィードバック分析を実行
Map<String, Object> analysis =
    AgentforceSelfLearningService.analyzeFeedbackPatterns('Agentforce');
System.debug('Analysis: ' + JSON.serializePretty(analysis));

// 改善コンテキストを確認
String context =
    AgentforceSelfLearningService.getImprovementContext('Agentforce');
System.debug('Improvement Context: ' + context);
```

---

### 🎯 どちらのパターンを選ぶべきか？

| 用途 | パターン1 | パターン2 |
|------|----------|----------|
| **動作確認・テスト** | ✅ 最適 | - |
| **デモ・プレゼン** | ✅ 最適 | - |
| **手動コンテンツ作成** | ✅ 最適 | - |
| **AI自動生成** | - | ✅ 最適 |
| **Agentforce統合** | - | ✅ 最適 |
| **自己学習の検証** | ✅ 可能 | ✅ 可能 |

**推奨**: まずパターン1でコンポーネントの動作を確認し、その後パターン2でAgentforce統合を進める。

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

### ユーザー向け
- **[PACKAGE_README.md](PACKAGE_README.md)** - パッケージインストールガイド（エンドユーザー向け）
- [HTMLスタイルガイド](docs/agentforce-topic-style-guide.md) - コンテンツ作成ガイド

### 開発者向け
- **[CLAUDE.md](CLAUDE.md)** - ソースからのデプロイ手順
- **[PACKAGING.md](PACKAGING.md)** - パッケージング詳細ガイド
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
