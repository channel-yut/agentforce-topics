# Agentforce Topics - インストールガイド

**AI-Powered Insights System with Self-Learning**

自己学習型AIインサイトシステムをSalesforce組織に導入するためのガイドです。

---

## 📦 パッケージインストール

### ステップ1: パッケージをインストール

```bash
sf package install \
  --package 04tXXXXXXXXXXXXXXX \
  --target-org your-org-alias \
  --wait 10 \
  --publish-wait 10
```

**パッケージID**: `04tXXXXXXXXXXXXXXX` (リリース時に更新)

または、ブラウザでインストール：
```
https://login.salesforce.com/packaging/installPackage.apexp?p0=04tXXXXXXXXXXXXXXX
```

### ステップ2: Permission Set を割り当て

```bash
sf org assign permset \
  --name Agentforce_Topics_Access \
  --target-org your-org-alias
```

または、Setup画面で手動割り当て：
```
Setup → Users → Permission Sets → Agentforce Topics Access
→ Manage Assignments → ユーザーを選択
```

---

## 🔧 初期設定

### 1. レコードページにコンポーネント追加

```
1. Setup → Object Manager → Account (または任意のオブジェクト)
2. Lightning Record Pages → 編集するページを選択
3. Lightning App Builder が開く
4. 左側から "agentforceTopics" コンポーネントを選択
5. ページ上にドラッグ&ドロップ
6. (オプション) "agentforceTopicsStats" も追加
7. Save → Activate
```

### 2. 言語設定（日本語表示）

```
Setup → 自分の名前のアイコン → Settings
→ Language and Time Zone
→ Language: Japanese (日本語)
→ Save
```

### 3. 自己学習機能の有効化（オプション）

週次フィードバック分析を自動化する場合：

```apex
// Developer Console または Execute Anonymous で実行
WeeklyFeedbackAnalysisScheduler.scheduleWeeklyJob();
```

これで毎週月曜 9:00 AM に自動分析が実行されます。

---

## 💡 使い方

### パターンA: テストレコードで動作確認

#### 1. レコード作成

```
App Launcher → "Agentforce Topics" タブ → New
```

必要項目：
- **Related Record Id**: Account/OpportunityのID (例: 001XXXXXXXXXXXXXX)
- **Trigger Type**: "テスト"
- **Summary**: "2026/03/30 顧客名 - 概要"
- **Content**: HTMLコンテンツ（下記サンプル参照）
- **Generated Date**: 今日の日付

#### 2. HTMLコンテンツサンプル

```html
<div style="background-color: #e1f5fe; padding: 16px; margin-bottom: 20px; border-radius: 8px; border-left: 4px solid #0288d1;">
    <h3 style="color: #1976d2; font-size: 20px; font-weight: bold; margin-bottom: 12px;">💼 ネクストアクション</h3>
    <ol style="font-size: 14px; line-height: 1.6; margin: 0; padding-left: 20px;">
        <li style="margin-bottom: 8px;"><strong>フォローアップ</strong> - 10/28週までに実施</li>
        <li style="margin-bottom: 8px;"><strong>提案資料更新</strong> - 3営業日以内に送付</li>
        <li><strong>技術チーム連携</strong> - 本日中に確認</li>
    </ol>
</div>

<div style="background-color: #fff9c4; padding: 16px; margin-bottom: 20px; border-radius: 8px; border-left: 4px solid #fbc02d;">
    <h3 style="color: #d32f2f; font-size: 20px; font-weight: bold; margin-bottom: 12px;">⚠️ 推奨事項</h3>
    <p style="font-size: 14px; line-height: 1.7; margin: 0;">
        競合分析資料の準備を推奨します。提案の受注率を<strong>15%向上</strong>させることを目指します。
    </p>
</div>
```

#### 3. レコードページで確認

Related Record Idに指定したレコード（Account/Opportunity）を開くと、
`agentforceTopics` コンポーネントにコンテンツが表示されます。

- ✅ 「役立った」「役立たなかった」ボタンでフィードバック
- ✅ 「履歴を表示」で過去のトピック確認
- ✅ 統計ダッシュボードでフィードバック集計

---

### パターンB: Agentforce に組み込む

#### 1. Agent Builder を開く

```
Setup → Einstein → Agent Builder
→ 新規作成 or 既存Agent編集
```

#### 2. Topic を作成

```
Topics タブ → New Topic
- Topic Name: "顧客インサイト生成"
- Instructions: 「顧客情報を分析し、ネクストアクション、推奨事項、
  主要インサイトをHTML形式で生成してください。」
```

#### 3. Action を追加

```
Actions セクション → Add Action
→ Action Type: "Apex Action"
→ Apex Class: "Create or Update Agentforce Topic"
```

**入力パラメータのマッピング:**
- `summary`: Agent生成の概要テキスト
- `content`: Agent生成のHTMLコンテンツ
- `relatedRecordId`: コンテキストレコードID
- `triggerType`: "Agentforce"

#### 4. プロンプト例

Agent Instructionsに追加：

```
【出力形式】HTML形式で以下を生成：
1. ネクストアクション（期限明記）
2. 推奨事項（数値目標含む）
3. 主要インサイト（リスクと機会）

【HTMLスタイル】
- 見出し: <h3 style="color: #1976d2;">タイトル</h3>
- セクション: <div style="background-color: #e1f5fe; padding: 16px;">
- リスト: <ol style="font-size: 14px;">

【重要】具体的な担当者、期限、数値目標を必ず含める
```

#### 5. テスト実行

```
Agent Builder → Test ボタン
→ テスト対話を実行
→ Agentforce_Topic__c レコードが自動作成される
→ レコードページで確認
```

---

## 🔄 自己学習機能について

### 仕組み

1. **フィードバック収集** - ユーザーが「役立った」「役立たなかった」を評価
2. **週次分析** - 毎週月曜に自動分析（ステップ3で設定済みの場合）
3. **改善適用** - 次回生成時に自動的に改善パターンを反映

### 確認方法

```apex
// Developer Console で実行
// フィードバック分析を手動実行
Map<String, Object> analysis =
    AgentforceSelfLearningService.analyzeFeedbackPatterns('Agentforce');
System.debug('分析結果: ' + JSON.serializePretty(analysis));
```

---

## 📊 含まれるコンポーネント

- **カスタムオブジェクト**: Agentforce_Topic__c (14フィールド)
- **Apexクラス**: 7個（Controller, Action, 自己学習等）
- **LWCコンポーネント**: 2個（表示用、統計用）
- **Flow**: 2個（作成、編集）
- **カスタムラベル**: 42個（日英対応）
- **Permission Set**: 1個

---

## 🆘 トラブルシューティング

### コンポーネントが表示されない

**原因**: Permission Set未割り当て

**対策**:
```
Setup → Users → Permission Sets
→ Agentforce Topics Access → Manage Assignments
```

### 日本語が表示されない

**原因**: 言語設定が英語

**対策**:
```
Setup → 自分のアイコン → Settings → Language: Japanese
```

### フィードバックが集計されない

**原因**: Triggerが無効

**対策**:
```
Setup → Apex Triggers → AgentforceTopicTrigger → Active確認
```

### Action が表示されない

**原因**: Apexクラスがデプロイされていない

**対策**: パッケージが正しくインストールされているか確認
```
Setup → Apex Classes → AgentforceTopicCreator 確認
```

---

## 📚 追加リソース

### HTMLスタイルガイド

詳細なスタイルガイドは GitHub リポジトリの `docs/agentforce-topic-style-guide.md` を参照：
- カラーパレット（緊急=赤、情報=青、評価=オレンジ）
- セクションボックスのスタイル
- リンクのスタイル
- 絵文字の使用方法

### 技術ドキュメント

完全な技術ドキュメントはGitHubリポジトリを参照：
- **README.md** - システム概要と詳細仕様
- **CLAUDE.md** - ソースからのデプロイ手順
- **PACKAGING.md** - パッケージング詳細ガイド

リポジトリURL: (リリース時に追加)

---

## 📝 バージョン情報

- **Version**: 1.0.0
- **Release Date**: 2026-03-30
- **API Version**: 64.0
- **Package Type**: Unlocked Package

---

## 🤝 サポート

質問や問題がある場合：
1. GitHub Issues でレポート（リポジトリURL参照）
2. 技術ドキュメント（README.md, PACKAGING.md）を確認
3. Salesforce Trailblazer Community で質問

---

**🎉 インストールが完了したら、パターンAでまず動作確認を行い、その後パターンBでAgentforce統合を進めることを推奨します！**
