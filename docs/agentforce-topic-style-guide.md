# Agentforce Topics スタイルガイド

このドキュメントは、Agentforce Topicsのコンテンツフィールドに使用するHTMLスタイルの標準を定義します。

## デザイン原則

1. **視認性**: 見出しとコンテンツのコントラストを明確に
2. **階層性**: 情報の重要度を視覚的に表現
3. **アクション誘導**: リンクは明確で分かりやすく
4. **一貫性**: 色やスペーシングのルールを統一

---

## タイポグラフィ

### 見出し

```html
<!-- メインセクション見出し (H3) -->
<h3 style="color: #カラーコード; font-size: 20px; font-weight: bold; margin-bottom: 12px; margin-top: 8px;">
    絵文字 見出しテキスト
</h3>
```

**使用する色:**
- 緊急/注意: `#d32f2f` (赤)
- 情報/提案: `#1976d2` (青)
- フィードバック/評価: `#f57c00` (オレンジ)
- 成功/完了: `#388e3c` (緑)

### 本文

```html
<!-- 通常の段落 -->
<p style="font-size: 14px; line-height: 1.7; margin-bottom: 8px;">テキスト</p>

<!-- 強調テキスト -->
<p style="font-size: 14px; line-height: 1.7; margin-bottom: 8px;">
    <strong>ラベル:</strong> 内容
</p>

<!-- サブ見出し（セクション内） -->
<p style="font-size: 15px; font-weight: 600; margin-bottom: 12px;">サブ見出し:</p>
```

### リスト

```html
<!-- 番号付きリスト -->
<ol style="font-size: 14px; line-height: 1.6; margin: 0; padding-left: 20px;">
    <li style="margin-bottom: 8px;"><strong>項目名</strong> - 説明文</li>
    <li style="margin-bottom: 8px;"><strong>項目名</strong> - 説明文</li>
    <li><strong>項目名</strong> - 説明文</li>
</ol>

<!-- 箇条書きリスト -->
<ul style="font-size: 14px; line-height: 1.6; margin: 0; padding-left: 20px;">
    <li style="margin-bottom: 8px;">項目1</li>
    <li style="margin-bottom: 8px;">項目2</li>
    <li>項目3</li>
</ul>
```

---

## カラーパレットとボックススタイル

### セクションボックス

各セクションは背景色とボーダーで強調します。

```html
<div style="background-color: #背景色; padding: 16px; margin-bottom: 20px; border-radius: 8px; border-left: 4px solid #ボーダー色;">
    <!-- コンテンツ -->
</div>
```

**推奨カラーセット:**

| 用途 | 背景色 | 左ボーダー | 見出し色 |
|------|--------|------------|----------|
| 緊急・警告 | `#fff9c4` | `#fbc02d` | `#d32f2f` |
| 情報・提案 | `#e1f5fe` | `#0288d1` | `#1976d2` |
| 評価・フィードバック | `#fff3e0` | `#f57c00` | `#f57c00` |
| 成功・完了 | `#e8f5e9` | `#4caf50` | `#388e3c` |

---

## リンクスタイル

### 関連レコードリンク（重要）

```html
<a href="URL" style="background-color: #e3f2fd; padding: 4px 8px; border-radius: 4px; text-decoration: none; font-weight: 600; color: inherit;">
    リンクテキスト
</a>
```

### アクションリンク（ToDo等）

```html
<a href="URL" style="color: #d84315; text-decoration: none; font-weight: 600; border-bottom: 2px solid #d84315;">
    → ToDo
</a>
```

### ナレッジ・学習リンク

```html
<a href="URL" target="_blank" style="color: #1976d2; font-weight: 600; text-decoration: none;">
    リンクテキスト
</a>
```

---

## レイアウト要素

### 区切り線

```html
<hr style="margin: 16px 0; border: 0; border-top: 2px solid #e0e0e0;">
```

### ヘッダー行（面談記録等）

```html
<p style="font-size: 16px; margin-bottom: 12px;">
    <strong>📋 ラベル:</strong>
    <a href="URL" style="background-color: #e3f2fd; padding: 4px 8px; border-radius: 4px; text-decoration: none; font-weight: 600;">
        概要テキスト
    </a>
</p>
```

---

## 絵文字の使用

情報の種類を視覚的に表現するために絵文字を活用します。

| 用途 | 絵文字 |
|------|--------|
| 記録・ドキュメント | 📋 📝 📄 |
| 警告・注意 | ⚠️ 🚨 ⚡ |
| アクション・タスク | 💼 🎯 ✅ |
| 評価・分析 | 📊 📈 📉 |
| 学習・参考資料 | 📚 📖 🎓 |
| 成功・OK | ✅ ✓ |
| 注意・要確認 | ⚠️ △ |
| 問題・NG | ❌ ✗ |

---

## スペーシング

### 基本ルール

- **セクション間**: `margin-bottom: 20px`
- **段落間**: `margin-bottom: 8px`
- **見出し下**: `margin-bottom: 12px`
- **見出し上**: `margin-top: 8px`
- **ボックス内パディング**: `padding: 16px`
- **リスト項目間**: `margin-bottom: 8px` (最後の項目は不要)

---

## プロンプトへの組み込み指示

Agentforceでコンテンツを生成する際の推奨事項：

### 必須要素

1. **関連レコードへのリンク** - 面談記録、商談などへのリンクを冒頭に含める
2. **セクション分け** - 情報を論理的なセクションに分割
3. **アクションへのリンク** - ToDoレコードやフォローアップタスクへのリンク

### HTMLの注意点

- インラインスタイルのみ使用（外部CSS不可）
- タグは必ず閉じる
- 文字エンコーディングはUTF-8
- Salesforce URLは有効なIDを使用

### サマリーとトリガータイプ

**Summary__c:**
- 日付 + 顧客名/対象 + 主要なアクション
- 例: `2026/03/22 山陽工機様ご訪問 - 設備投資3億円相談｜ガバナンス対応3件必要`

**Trigger_Type__c:**
- 面談記録、商談更新、フォローアップ、定期レビューなど

---

## 使用例

```html
<p style="font-size: 16px; margin-bottom: 12px;"><strong>📋 面談記録:</strong> <a href="https://xxx.salesforce.com/00T..." style="background-color: #e3f2fd; padding: 4px 8px; border-radius: 4px; text-decoration: none; font-weight: 600;">鈴木部長様 - 設備投資相談</a></p>
<hr style="margin: 16px 0; border: 0; border-top: 2px solid #e0e0e0;">

<h3 style="color: #d32f2f; font-size: 20px; font-weight: bold; margin-bottom: 12px; margin-top: 8px;">⚠️ 即対応が必要な項目</h3>
<div style="background-color: #fff9c4; padding: 16px; margin-bottom: 20px; border-radius: 8px; border-left: 4px solid #fbc02d;">
<ol style="font-size: 14px; line-height: 1.6; margin: 0; padding-left: 20px;">
<li style="margin-bottom: 8px;"><strong>タスク1</strong> - 詳細説明 <a href="https://xxx.salesforce.com/00T..." style="color: #d84315; text-decoration: none; font-weight: 600; border-bottom: 2px solid #d84315;">→ ToDo</a></li>
<li><strong>タスク2</strong> - 詳細説明 <a href="https://xxx.salesforce.com/00T..." style="color: #d84315; text-decoration: none; font-weight: 600; border-bottom: 2px solid #d84315;">→ ToDo</a></li>
</ol>
</div>

<h3 style="color: #1976d2; font-size: 20px; font-weight: bold; margin-bottom: 12px; margin-top: 8px;">💼 提案内容</h3>
<div style="background-color: #e1f5fe; padding: 16px; margin-bottom: 20px; border-radius: 8px; border-left: 4px solid #0288d1;">
<p style="font-size: 14px; line-height: 1.7; margin: 0;">提案の詳細をここに記載</p>
</div>
```

---

## バージョン履歴

- v1.0 (2026-03-23): 初版作成
  - デザイン原則の策定
  - タイポグラフィとカラーパレットの定義
  - 柔軟なスタイルガイドラインの確立
