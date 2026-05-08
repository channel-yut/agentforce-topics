# 顧客リサーチエージェント UX改善 実装計画

## 目標

チャットモードでの手順を削減し、ユーザーが極力テキスト入力せずに選択だけで完結できる UX にする。

## 変更方針

1. **保存先レコードの自動検索** — ユーザーに ID 入力を求めない。リサーチ完了後にエージェントが自動で候補レコードを検索し提示する
2. **選択肢 UX** — Yes/No・保存先選択など全ての確認をテキスト入力ではなく `setVariables` 複数露出による選択肢で行う
3. **保存は前提** — 「保存しますか？」を省略。リサーチ完了後は自動で候補を提示して「どこに保存するか」だけ聞く
4. **決算サジェストも選択肢** — 決算サジェストを 2 択（決算もまとめる / このまま保存）で提示

---

## 新規 Apex クラス

### `FindRelatedRecords` ✅ 作成済み

- 入力: `accountName: string`
- 出力:
  - `hasAccount: boolean`
  - `accountId: string`
  - `accountName: string`
  - `hasOpportunity: boolean`
  - `opportunityId: string`
  - `opportunityName: string`
  - `candidateSummary: string`（LLM が提示するテキスト）
- ファイル: `force-app/main/default/classes/FindRelatedRecords.cls`

---

## Agent Script 変更内容

### 変数追加

```
candidate_account_id: mutable string = ""
candidate_account_name: mutable string = ""
candidate_opp_id: mutable string = ""
candidate_opp_name: mutable string = ""
has_candidate_account: mutable boolean = False
has_candidate_opp: mutable boolean = False
```

### save_topic サブエージェント — 完全リデザイン

**旧**: ユーザーに「保存しますか？」→「レコード ID 入力してください」と 2 回テキスト入力
**新**: 候補レコードが変数にセット済みの状態で遷移 → 選択肢を提示してクリックだけで完結

#### 新しい reasoning フロー

```
if topic_id != "":
    → 保存完了メッセージ + go_to_router_after_save

if related_record_id != "" and topic_id == "":
    → 保存を実行（st_create_topic available when）

if related_record_id == "" and topic_id == "":
    → 候補レコードを提示して選択を促す
    → save_to_account / save_to_opp / skip_save の 3 択
```

#### reasoning actions

```
save_to_account: @utils.setVariables
    description: "取引先に保存する"
    with related_record_id = candidate_account_id
    with object_api_name = "Account"
    available when has_candidate_account == True and related_record_id == "" and topic_id == ""

save_to_opp: @utils.setVariables
    description: "商談に保存する"
    with related_record_id = candidate_opp_id
    with object_api_name = "Opportunity"
    available when has_candidate_opp == True and related_record_id == "" and topic_id == ""

enter_record_id: @utils.setVariables
    description: "別のレコードIDを手動入力する"
    with related_record_id = ...
    with object_api_name = ...
    available when related_record_id == "" and topic_id == ""

st_create_topic: @actions.st_create_topic
    available when related_record_id != "" and topic_id == ""

go_to_router_after_save: @utils.transition to @subagent.agent_router
    available when topic_id != ""

skip_save: @utils.transition to @subagent.agent_router
    description: "保存しない"
    available when topic_id == ""
```

### web_research サブエージェント変更

#### after_reasoning ブロック追加

```
after_reasoning:
    if research_result_summary != "" and related_record_id == "" and topic_id == "":
        transition to @subagent.save_topic
```

#### before_reasoning での FindRelatedRecords 実行

```
before_reasoning:
    if account_name != "":
        run @actions.find_related_records
            with accountName = account_name
            set has_candidate_account = @outputs.hasAccount
            set candidate_account_id = @outputs.accountId
            set candidate_account_name = @outputs.accountName
            set has_candidate_opp = @outputs.hasOpportunity
            set candidate_opp_id = @outputs.opportunityId
            set candidate_opp_name = @outputs.opportunityName
```

#### instructions 変更（決算サジェスト部分）

```
suggest_earnings アクション:
    description: "直近の決算発表がありAgentforce Topicsが未作成の場合、決算サマリーもまとめるか選択させる"
    available when has_recent_earnings == True and has_existing_earnings_topic == False
    → earnings_summary へ遷移

skip_earnings_and_save:
    description: "決算サジェストをスキップして保存へ進む"
    available when has_recent_earnings == True and has_existing_earnings_topic == False
    → save_topic へ遷移
```

### competitive_analysis / earnings_summary サブエージェント変更

- web_research と同様に `before_reasoning` で `FindRelatedRecords` 実行
- リサーチ完了後 `after_reasoning` で save_topic に自動遷移
- 「保存」依頼に依存しない

---

## タスクリスト

- [x] `FindRelatedRecords.cls` 作成
- [x] `FindRelatedRecords.cls-meta.xml` 作成
- [ ] `FindRelatedRecords` を org にデプロイ
- [ ] `.agent` ファイル更新（変数追加・サブエージェント修正）
  - [ ] variables ブロックに候補レコード変数追加
  - [ ] `web_research`: before_reasoning + after_reasoning + actions 更新
  - [ ] `competitive_analysis`: before_reasoning + after_reasoning + actions 更新
  - [ ] `earnings_summary`: before_reasoning + after_reasoning + actions 更新
  - [ ] `save_topic`: reasoning 完全リデザイン + actions 更新
- [ ] validate authoring-bundle
- [ ] live preview でテスト
- [ ] publish + activate

---

## 確認事項（実装中に判断が必要な場合）

- `FindRelatedRecords` は accountName の部分一致（LIKE）でマッチする。複数候補が想定される場合は最終更新日順で1件のみ返す
- `candidateSummary` は LLM がそのまま読み上げて選択肢提示に使う
- `objectApiName` は `AgentforceTopicCreator` が `relatedRecordId` から自動検出できるため、未設定でも可
