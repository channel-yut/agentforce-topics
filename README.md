# Agentforce Topics

Salesforce上でAI生成インサイトを表示・管理するアンロックパッケージです。Agentforce（またはApex）が生成したコンテンツをカスタムオブジェクトに保存し、レコードページで表示します。ユーザーフィードバックを収集・分析して、次回の生成品質を自動改善する自己学習ループを備えています。

---

## 目次

1. [機能概要](#機能概要)
2. [インストール](#インストール)
3. [セットアップ](#セットアップ)
4. [デモデータの作成](#デモデータの作成)
5. [Agentforceからの活用](#agentforceからの活用)
6. [顧客リサーチエージェント](#顧客リサーチエージェント)
7. [自己学習ロジック](#自己学習ロジック)
8. [コンポーネント一覧](#コンポーネント一覧)

---

## 機能概要


| 機能        | 説明                               |
| --------- | -------------------------------- |
| AIインサイト表示 | レコードページにAI生成コンテンツをリッチテキストで表示     |
| フィードバック収集 | 「役立った / 役立たなかった」の2段階評価           |
| 統計ダッシュボード | フィードバック集計・KPI表示コンポーネント           |
| 自己学習      | ネガティブフィードバックを分析し、次回生成時の改善指示を自動生成 |
| 多言語対応     | 日本語・英語（カスタムラベル42個）               |


---

## インストール

### パッケージインストール（推奨）

以下のURLにインストール先の組織でアクセスしてください。

**本番 / トライアル組織:**

```
https://login.salesforce.com/packaging/installPackage.apexp?p0=04tId000000cEhGIAU
```

**Sandbox:**

```
https://test.salesforce.com/packaging/installPackage.apexp?p0=04tId000000cEhGIAU
```

### バージョンアップ

既にインストール済みの組織に最新バージョンを適用する場合は、上記と同じインストールURLに最新の SubscriberPackageVersionId をセットしてアクセスするだけです。Salesforce が自動でアップグレード処理を行います。

### 英語表示に切り替える場合

デフォルトは日本語表示です。英語に切り替えるには、インストール後に翻訳ファイルを別途デプロイしてください。

**前提:** デプロイ先組織で Translation Workbench が有効になっていること
（Setup → Translation Workbench → **Enable**）

```bash
# リポジトリをクローン後、翻訳ファイルのみデプロイ
sf project deploy start \
  --source-dir force-app/main/default/translations \
  --target-org <org-alias>
```

デプロイ後、Salesforce の言語設定を English に変更すると英語表示になります。

---

インストール後、Permission Set **Agentforce Topics Access** を対象ユーザーに割り当てます。

**UIから設定する場合:**

1. Setup → **Permission Sets** を検索
2. `Agentforce Topics Access` を開く
3. **Manage Assignments** → **Add Assignments**
4. 対象ユーザーを選択して **Assign**

**CLIから設定する場合:**

```bash
sf org assign permset --name Agentforce_Topics_Access --target-org <org-alias>
```

---

## セットアップ

### レコードページへのコンポーネント配置

1. Setup → Object Manager → 対象オブジェクト（Account 等）
2. Lightning Record Pages → 編集するページを選択
3. Lightning App Builder を開く
4. 左側コンポーネント一覧から **agentforceTopics** をページ上に配置
5. 任意で **agentforceTopicsStats**（統計ダッシュボード）も配置
6. 保存 → Activate

### Agentforce Topic レコードページの有効化

パッケージには `Agentforce_Topic_Record_Page` が含まれていますが、OrgDefault への設定は自動化できないため、インストール後に手動で行ってください。

1. Setup → **Object Manager** → **Agentforce Topic** を開く
2. 左メニュー **Lightning Record Pages** を選択
3. `Agentforce Topic Record Page` の行をクリック
4. 右上 **Activation...** ボタンをクリック
5. **Org Default** タブを選択 → **Assign as Org Default**
6. **Save** をクリック

---

## デモデータの作成

動作確認やデモ用途にレコードを手動作成する手順です。

### ステップ1: Agentforce Topic レコードを作成

App Launcher → **Agentforce Topics** タブ → **新規**

以下のフィールドを入力して保存します。


| フィールド             | 入力例                      |
| ----------------- | ------------------------ |
| Related Record Id | 表示したいレコード（Account 等）の ID |
| Trigger Type      | `面談記録`                   |
| Generated Date    | 今日の日付                    |


> Summary・Content は空白のまま保存すると、サンプルコンテンツが自動入力されます。

### ステップ2: コンテンツを編集

保存後、作成されたレコードページを開き、**コンテンツ編集** アクションをクリックします。

自動入力されたサンプルの Summary・Content をベースに、Gemini 等で実際のコンテンツに書き換えてください。

※Content はリッチテキストに対応しており、HTML 形式で記述ができます。

### ステップ3: レコードページで確認

Related Record Id に指定したレコード（Account 等）を開くと、**Agentforce Topics** コンポーネントにコンテンツが表示されます。

---

## Agentforce からの活用

エージェントが生成したコンテンツを Agentforce Topic レコードとして保存するには、`AgentforceTopicCreator` Apex Action をサブエージェントのアクションとして組み込みます。Agent Builder で構築したエージェントでも、Agent Script ベースのエージェントでも同じ Action を使います。

### Apex Action: Create or Update Agentforce Topic

`AgentforceTopicCreator.createOrUpdateTopic`

既存レコードがあれば更新、なければ新規作成します。

| パラメータ           | 型      | 必須  | 説明                  |
| --------------- | ------ | --- | ------------------- |
| summary         | String | ○   | タイトル（1文） |
| content         | String | ○   | HTML形式のリッチコンテンツ     |
| relatedRecordId | String | -   | 関連レコードID（Account 等） |
| triggerType     | String | -   | トリガータイプ（例: `顧客リサーチ`）  |
| topicId         | String | -   | 更新時: 既存レコードID       |

| 出力      | 型       | 説明               |
| ------- | ------- | ---------------- |
| topicId | String  | 作成 / 更新されたレコードID |
| success | Boolean | 成功 / 失敗          |
| message | String  | 結果メッセージ          |

### Agent Builder への登録手順

1. Setup → **Agent Builder** → 対象 Agent を開く
2. Topics → **New Topic**（例: `顧客リサーチ`）
3. Actions → **Add Action** → **Apex Action**
4. `Create or Update Agentforce Topic` を選択
5. 入力パラメータをマッピング

```
summary        → {Agent が生成した概要テキスト}
content        → {Agent が生成した HTML コンテンツ}
relatedRecordId → {コンテキストレコードの ID}
triggerType    → 顧客リサーチ  ← Topicに合わせて固定文字列で指定
```

`triggerType` はフィードバックの学習スコープとして使われるため、Topic ごとに適切な値を固定文字列で指定してください。`Trigger_Type__c` は**制限付き選択リスト**です。指定する値はリストに登録された値と一致している必要があります。

**パッケージ初期値:**

| 値        |
| -------- |
| 面談記録     |
| レコードサマリー |
| 推奨アクション  |
| 契約更新     |
| 問い合わせ起票  |
| 顧客リサーチ   |
| 競合分析     |
| リスク分析    |
| 決算サマリー   |
| イベント参加   |
| その他      |

**値の追加・変更方法（UI）:**

1. Setup → **Object Manager** → **Agentforce Topic**
2. **Fields & Relationships** → `Trigger Type` を開く
3. **Values** セクションで **New** をクリックして値を追加

**値の追加・変更方法（メタデータ）:**

[Trigger_Type__c.field-meta.xml](force-app/main/default/objects/Agentforce_Topic__c/fields/Trigger_Type__c.field-meta.xml) の `valueSetDefinition` に値を追加してデプロイします。

```xml
<value>
    <fullName>顧客リサーチ</fullName>
    <default>false</default>
    <label>顧客リサーチ</label>
</value>
```

### Topic Instructions でのアウトプット形式指定

`summary`・`content` に何を渡すかは、Topic Instructions でエージェントに指示します。`content` は HTML 形式に対応しているため、スタイル付きカードレイアウトを指定すると見やすい表示になります。

**指示例:**

```
リサーチ結果を保存する際は以下の形式で出力してください。

summary（1文のタイトル）:
「{会社名} 顧客リサーチ（{年月}）」のように短いタイトルにする。

content（HTML）:
<div style="font-family: sans-serif; padding: 16px; color: #333;">
  <h2 style="color: #0070d2; margin: 0 0 12px 0; padding-bottom: 8px; border-bottom: 3px solid #0070d2; font-size: 1.2em; font-weight: 600;">📋 概要</h2>
  <div style="background-color: #e8f4fd; border-left: 4px solid #0070d2; padding: 12px; margin-bottom: 16px;">
    （主要な情報・数値）
  </div>
  <h3 style="color: #2e844a; margin: 24px 0 12px 0; font-size: 1.2em; font-weight: 600; padding-bottom: 8px; border-bottom: 2px solid #2e844a;">📊 トレンド・動向</h3>
  <div style="background-color: #e8f5e9; border-left: 4px solid #2e844a; padding: 12px; margin-bottom: 16px;">
    （市場・業績トレンド）
  </div>
  <h3 style="color: #c23934; margin: 24px 0 12px 0; font-size: 1.2em; font-weight: 600; padding-bottom: 8px; border-bottom: 2px solid #c23934;">💼 営業活動への示唆</h3>
  <div style="background-color: #ffebee; border-left: 4px solid #c23934; padding: 12px; margin-bottom: 16px;">
    （具体的なアクション・提案）
  </div>
</div>
```

色の使い分け: 青(`#0070d2`)=メインセクション、緑(`#2e844a`)=トレンド・分析、赤(`#c23934`)=示唆・アクション

---

### 活用例：顧客リサーチエージェント

上記の仕組みを実装した Agent Script ベースのエージェントをこのリポジトリで提供しています。詳細は[顧客リサーチエージェント](#顧客リサーチエージェント)セクションを参照してください。

---

## 顧客リサーチエージェント

Einstein Copilot（Employee Agent）として動作する顧客リサーチエージェントです。取引先・商談などのレコードに関するWebリサーチ・競合分析・決算サマリーを自動生成し、Agentforce Topicsとして保存します。

> **注意:** `AiAuthoringBundle` はアンロックパッケージ非対応です。パッケージインストールとは別に、以下の手順でデプロイしてください。

### サブエージェント構成

```
agent_router
  ├── web_research      — Webリサーチ・ニュース
  ├── competitive_analysis — 競合分析
  ├── earnings_summary  — 決算サマリー
  ├── save_topic        — 保存確認・実行（共通）
  ├── off_topic         — スコープ外の応答
  └── ambiguous_question — 意図不明時の確認
```

### 有効化手順（CLI）

**前提:** このリポジトリをクローンし、デプロイ先組織にログイン済みであること。パッケージ本体（v1.3.0）が先にインストール済みであること。

```bash
# 1. エージェントのメタデータをデプロイ
sf project deploy start \
  --source-dir force-app/main/default/aiAuthoringBundles \
  --target-org <org-alias>

# 2. CheckRecentEarnings Apex Action をデプロイ（パッケージに含まれていない場合）
sf project deploy start \
  --metadata ApexClass:CheckRecentEarnings \
  --target-org <org-alias>

# 3. バリデーション
sf agent validate authoring-bundle \
  --api-name Customer_Research_Agent \
  --json

# 4. Publish（バージョンを確定）
sf agent publish authoring-bundle \
  --api-name Customer_Research_Agent \
  --json

# 5. Activate（ユーザーへ公開）
sf agent activate \
  --api-name Customer_Research_Agent \
  --json
```

### 有効化手順（UI）

**前提:** パッケージ本体（v1.3.0）が先にインストール済みであること。

1. **メタデータをデプロイ**
   - このリポジトリをクローンし、`force-app/main/default/aiAuthoringBundles/Customer_Research_Agent/` 配下の2ファイルを Workbench または VS Code の Salesforce 拡張機能でデプロイ

2. **Publish**
   - Setup → **Einstein Agents** → `Customer Research Agent` を開く
   - 右上 **Publish** ボタンをクリック → 確認ダイアログで **Publish**

3. **Activate**
   - Publish 完了後、**Activate** ボタンをクリック

4. **動作確認**
   - Einstein Copilot サイドパネルを開き、「〇〇社の最新ニュースをリサーチして」などと入力して動作を確認

### 利用方法

Einstein Copilot から自由に依頼できます。

| 依頼例 | 実行されるサブエージェント |
|---|---|
| 「〇〇社の最新ニュースをリサーチして」 | web_research |
| 「〇〇社と競合他社を比較して」 | competitive_analysis |
| 「〇〇社の直近の決算をまとめて」 | earnings_summary |
| リサーチ後「保存して」 | save_topic |

リサーチ結果は `Agentforce Topics` として任意のレコード（取引先・商談等）に紐付けて保存できます。

---

## 自己学習ロジック

### 全体フロー

```
ユーザーがフィードバック評価
  ↓
Trigger: フィードバック集計（Helpful_Count / Not_Helpful_Count）を最新レコードに書き戻し
  ↓
WeeklyFeedbackAnalysisScheduler が週次でネガティブフィードバックを分析
  ↓
AgentforceSelfLearningService: カテゴリ別に問題パターンと改善指示を抽出
  ↓
Agentforce_Topic_Learning__c に新レコードを保存（世代番号 +1）
  ↓
次回 Agent 生成時: 有効な学習レコードから改善コンテキストをプロンプトに注入
```

### 学習スコープ

`Trigger_Type__c` + `Object_Api_Name__c` の組み合わせで学習をスコープします。  
`Object_Api_Name__c` が空の場合は `Trigger_Type__c` のみでスコープされます。

- Account と Opportunity で同じ `triggerType` を使っても学習が混在しない
- `Object_Api_Name__c` スコープの学習がない場合は `Trigger_Type__c` のみの学習にフォールバック

### 学習レコードの世代管理


| フィールド                   | 説明                      |
| ----------------------- | ----------------------- |
| Generation__c           | 世代番号（1, 2, 3...と増加）     |
| Is_Active__c            | 現在有効な学習レコードか（最新のみ true） |
| Improvement_Patterns__c | 改善ガイドライン（JSON）          |
| Analysis_Result__c      | 分析生データ（JSON）            |


### 設定（カスタムメタデータ）

自己学習の動作は **`Agentforce_Topics_Config__mdt`** レコード（`Default`）で制御します。

| フィールド | デフォルト値 | 説明 |
|-----------|------------|------|
| Analysis_Enabled__c | false | 自動分析の有効 / 無効 |
| Analysis_Frequency__c | Weekly | 分析頻度（Weekly 固定） |
| Min_Feedback_Count__c | 5 | 分析を実行する最小フィードバック件数 |
| Admin_Profile_Name__c | System Administrator | スケジューラー実行プロファイル名 |

**UIから変更する場合:**

1. Setup → **Custom Metadata Types** を検索
2. `Agentforce Topics Config` → **Manage Records**
3. `Default` レコードを開いて編集

**メタデータから変更する場合:**

[Agentforce_Topics_Config.Default.md-meta.xml](force-app/main/default/customMetadata/Agentforce_Topics_Config.Default.md-meta.xml) を編集してデプロイします。

### スケジューラーの設定

**UIから設定する場合:**

1. Setup → **Apex Classes** を検索
2. 右上 **Schedule Apex** ボタンをクリック
3. 以下を入力して保存：
   - Job Name: `Agentforce Topics Weekly Analysis`
   - Apex Class: `WeeklyFeedbackAnalysisScheduler`
   - Frequency: Weekly（任意の曜日・時間を指定）

**Apex（Execute Anonymous）から設定する場合:**

```apex
// スケジューラーを有効化（カスタムメタデータの Analysis_Enabled__c も true に更新）
AgentforceTopicsSetup.enableScheduler();

// スケジューラーを無効化
AgentforceTopicsSetup.disableScheduler();

// 現在の状態を確認
AgentforceTopicsSetup.getStatus();
```

スケジュールを手動指定する場合：

```apex
System.schedule(
    'Agentforce Topics Weekly Analysis',
    '0 0 9 ? * MON',  // 毎週月曜 9:00 AM
    new WeeklyFeedbackAnalysisScheduler()
);
```

### 手動での動作確認

```apex
// フィードバック分析を手動実行
Map<String, Object> analysis =
    AgentforceSelfLearningService.analyzeFeedbackPatterns('面談記録', null);
System.debug(JSON.serializePretty(analysis));

// 改善コンテキストを確認（Agentのプロンプトに注入される内容）
String context =
    AgentforceSelfLearningService.getImprovementContext('面談記録', null);
System.debug(context);
```

---

## コンポーネント一覧

### カスタムオブジェクト

**Agentforce_Topic__c** — AI生成コンテンツの保存先


| フィールド                   | 型              | 説明                |
| ----------------------- | -------------- | ----------------- |
| Related_Record_Id__c    | Text           | 関連レコードID          |
| Object_Api_Name__c      | Text           | 関連オブジェクトAPI名      |
| Trigger_Type__c         | Picklist       | トリガータイプ           |
| Summary__c              | Text           | 概要テキスト            |
| Content__c              | Rich Text Area | HTML コンテンツ        |
| Generated_Date__c       | DateTime       | 生成日時              |
| Feedback__c             | Text           | フィードバック値          |
| Helpful_Count__c        | Number         | 役立った件数（最新レコードに集計） |
| Not_Helpful_Count__c    | Number         | 役立たなかった件数         |
| Total_Feedback_Count__c | Number         | 総フィードバック件数        |
| Feedback_Rate__c        | Percent        | フィードバック率          |
| Feedback_Category__c    | Text           | フィードバックカテゴリ       |
| Learning_Context__c     | Long Text      | 学習コンテキスト（JSON）    |


**Agentforce_Topic_Learning__c** — 自己学習データの保存先


| フィールド                      | 型         | 説明                |
| -------------------------- | --------- | ----------------- |
| Trigger_Type__c            | Text      | 学習スコープのトリガータイプ    |
| Object_Api_Name__c         | Text      | 学習スコープのオブジェクトAPI名 |
| Generation__c              | Number    | 世代番号              |
| Is_Active__c               | Checkbox  | 有効な学習レコードか        |
| Analysis_Date__c           | DateTime  | 分析実行日時            |
| Negative_Feedback_Count__c | Number    | ネガティブフィードバック件数    |
| Improvement_Patterns__c    | Long Text | 改善ガイドライン（JSON）    |
| Analysis_Result__c         | Long Text | 分析生データ（JSON）      |


### LWCコンポーネント


| コンポーネント                | 説明                                      |
| ---------------------- | --------------------------------------- |
| agentforceTopics       | レコードページ用。最新・履歴・詳細表示、フィードバック、コピー機能       |
| agentforceTopicsStats  | フィードバック統計ダッシュボード。プログレスバーとKPI表示          |
| agentforceTopicContent | トピックレコードページ用。Summary / Content のプレビュー表示 |


### Apexクラス


| クラス                             | 役割                                  |
| ------------------------------- | ----------------------------------- |
| AgentforceTopicsController      | LWC 用データ取得・更新 API                   |
| AgentforceTopicCreator          | **Agentforce Action** — レコード作成 / 更新 |
| CheckRecentEarnings             | **Agentforce Action** — 直近決算の有無を確認（顧客リサーチエージェント用） |
| AgentforceSelfLearningService   | フィードバック分析・改善指示生成                    |
| AgentforceTopicTriggerHandler   | フィードバック集計トリガー処理                     |
| WeeklyFeedbackAnalysisScheduler | 週次分析スケジューラー                         |
| AgentforceTopicsSetup           | スケジューラーの有効化・無効化・状態確認ユーティリティ         |


---

**Package Version**: 1.3.0  
**SubscriberPackageVersionId**: `04tId000000cEhGIAU`  
**Last Updated**: 2026-05-04