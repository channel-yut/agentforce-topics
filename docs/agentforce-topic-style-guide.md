# Agentforce Topics スタイルガイド

顧客リサーチエージェントが生成する `Content__c`（リッチテキスト）フィールドの HTML スタイル標準です。

---

## カラーパレット

| 役割 | カラーコード | 用途 |
|---|---|---|
| Salesforce Blue | `#0070d2` | メインセクション（H2）・ボーダー |
| Salesforce Green | `#2e844a` | トレンド・分析セクション（H3）・ボーダー |
| Salesforce Red | `#c23934` | 示唆・アクションセクション（H3）・ボーダー |
| 薄青背景 | `#e8f4fd` | Blue セクションのボックス背景 |
| 薄緑背景 | `#e8f5e9` | Green セクションのボックス背景 |
| 薄赤背景 | `#ffebee` | Red セクションのボックス背景 |
| ベーステキスト | `#333` | ラッパー全体の文字色 |

---

## 基本構造テンプレート

```html
<div style="font-family: sans-serif; padding: 16px; color: #333;">

  <!-- メインセクション（青） -->
  <h2 style="color: #0070d2; margin: 0 0 12px 0; padding-bottom: 8px; border-bottom: 3px solid #0070d2; font-size: 1.2em; font-weight: 600;">
    📋 セクションタイトル
  </h2>
  <div style="background-color: #e8f4fd; border-left: 4px solid #0070d2; padding: 12px; margin-bottom: 16px;">
    本文テキスト
  </div>

  <!-- サブセクション（緑）: トレンド・分析 -->
  <h3 style="color: #2e844a; margin: 24px 0 12px 0; font-size: 1.2em; font-weight: 600; padding-bottom: 8px; border-bottom: 2px solid #2e844a;">
    📊 トレンド・動向
  </h3>
  <div style="background-color: #e8f5e9; border-left: 4px solid #2e844a; padding: 12px; margin-bottom: 16px;">
    トレンドテキスト
  </div>

  <!-- サブセクション（赤）: 示唆・アクション -->
  <h3 style="color: #c23934; margin: 24px 0 12px 0; font-size: 1.2em; font-weight: 600; padding-bottom: 8px; border-bottom: 2px solid #c23934;">
    💼 営業活動への示唆
  </h3>
  <div style="background-color: #ffebee; border-left: 4px solid #c23934; padding: 12px; margin-bottom: 16px;">
    示唆テキスト
  </div>

</div>
```

---

## セクション別カラーの使い分け

| 色 | H タグ | ボーダー幅 | 適用シーン |
|---|---|---|---|
| `#0070d2`（青） | `<h2>` | `3px` | 概要・主要情報・メインセクション |
| `#2e844a`（緑） | `<h3>` | `2px` | トレンド・分析・前期比較・経営コメント |
| `#c23934`（赤） | `<h3>` | `2px` | 営業示唆・差別化ポイント・アクション |

---

## スペーシングルール

| 箇所 | 値 |
|---|---|
| ラッパーパディング | `padding: 16px` |
| H2 マージン | `margin: 0 0 12px 0` |
| H3 マージン | `margin: 24px 0 12px 0` |
| ボックス内パディング | `padding: 12px` |
| ボックス下マージン | `margin-bottom: 16px` |

---

## タイポグラフィ

- フォントファミリー: `font-family: sans-serif`（ラッパーで一括指定）
- 見出しサイズ: `font-size: 1.2em`（H2・H3 共通）
- 見出しウェイト: `font-weight: 600`
- ベーステキスト色: `color: #333`

> ⚠️ フォントサイズは `px` ではなく `em` を使用する。Salesforce のリッチテキスト領域に合わせた相対指定。

---

## 絵文字の使い分け

| 絵文字 | 用途 |
|---|---|
| 📋 | 概要・記録 |
| 📰 | ニュース・トピック |
| 🏢 | 企業・競合 |
| 📊 | 分析・トレンド・前期比較 |
| 📈 | 決算・業績 |
| 💼 | 営業示唆・戦略 |
| 💬 | 経営コメント・発言 |

---

## コンテンツタイプ別テンプレート例

### 顧客リサーチ

```html
<div style="font-family: sans-serif; padding: 16px; color: #333;">
  <h2 style="color: #0070d2; margin: 0 0 12px 0; padding-bottom: 8px; border-bottom: 3px solid #0070d2; font-size: 1.2em; font-weight: 600;">📰 主要ニュース・トピック</h2>
  <div style="background-color: #e8f4fd; border-left: 4px solid #0070d2; padding: 12px; margin-bottom: 16px;">ニューステキスト</div>
  <h3 style="color: #2e844a; margin: 24px 0 12px 0; font-size: 1.2em; font-weight: 600; padding-bottom: 8px; border-bottom: 2px solid #2e844a;">📊 事業動向・注目点</h3>
  <div style="background-color: #e8f5e9; border-left: 4px solid #2e844a; padding: 12px; margin-bottom: 16px;">動向テキスト</div>
  <h3 style="color: #c23934; margin: 24px 0 12px 0; font-size: 1.2em; font-weight: 600; padding-bottom: 8px; border-bottom: 2px solid #c23934;">💼 営業活動への示唆</h3>
  <div style="background-color: #ffebee; border-left: 4px solid #c23934; padding: 12px; margin-bottom: 16px;">示唆テキスト</div>
</div>
```

### 競合分析

```html
<div style="font-family: sans-serif; padding: 16px; color: #333;">
  <h2 style="color: #0070d2; margin: 0 0 12px 0; padding-bottom: 8px; border-bottom: 3px solid #0070d2; font-size: 1.2em; font-weight: 600;">🏢 主要競合他社</h2>
  <div style="background-color: #e8f4fd; border-left: 4px solid #0070d2; padding: 12px; margin-bottom: 16px;"><strong>競合社名</strong><br/>強み: テキスト<br/>弱み: テキスト</div>
  <h3 style="color: #2e844a; margin: 24px 0 12px 0; font-size: 1.2em; font-weight: 600; padding-bottom: 8px; border-bottom: 2px solid #2e844a;">📊 市場ポジション・シェア概況</h3>
  <div style="background-color: #e8f5e9; border-left: 4px solid #2e844a; padding: 12px; margin-bottom: 16px;">市場概況テキスト</div>
  <h3 style="color: #c23934; margin: 24px 0 12px 0; font-size: 1.2em; font-weight: 600; padding-bottom: 8px; border-bottom: 2px solid #c23934;">💼 差別化ポイント・営業戦略への示唆</h3>
  <div style="background-color: #ffebee; border-left: 4px solid #c23934; padding: 12px; margin-bottom: 16px;">示唆テキスト</div>
</div>
```

### 決算サマリー

```html
<div style="font-family: sans-serif; padding: 16px; color: #333;">
  <h2 style="color: #0070d2; margin: 0 0 12px 0; padding-bottom: 8px; border-bottom: 3px solid #0070d2; font-size: 1.2em; font-weight: 600;">📈 決算概要</h2>
  <div style="background-color: #e8f4fd; border-left: 4px solid #0070d2; padding: 12px; margin-bottom: 16px;">決算数値テキスト</div>
  <h3 style="color: #2e844a; margin: 24px 0 12px 0; font-size: 1.2em; font-weight: 600; padding-bottom: 8px; border-bottom: 2px solid #2e844a;">📊 前期比較・トレンド</h3>
  <div style="background-color: #e8f5e9; border-left: 4px solid #2e844a; padding: 12px; margin-bottom: 16px;">前期比較テキスト</div>
  <h3 style="color: #2e844a; margin: 24px 0 12px 0; font-size: 1.2em; font-weight: 600; padding-bottom: 8px; border-bottom: 2px solid #2e844a;">💬 経営陣のコメント・今後の見通し</h3>
  <div style="background-color: #e8f5e9; border-left: 4px solid #2e844a; padding: 12px; margin-bottom: 16px;">コメントテキスト</div>
  <h3 style="color: #c23934; margin: 24px 0 12px 0; font-size: 1.2em; font-weight: 600; padding-bottom: 8px; border-bottom: 2px solid #c23934;">💼 営業活動への示唆</h3>
  <div style="background-color: #ffebee; border-left: 4px solid #c23934; padding: 12px; margin-bottom: 16px;">示唆テキスト</div>
</div>
```

---

## HTML の注意点

- インラインスタイルのみ使用（外部 CSS 不可）
- タグは必ず閉じる
- フォントサイズは `em` 単位（`px` は使わない）
- `<h2>` はメインセクション1つのみ、`<h3>` でサブセクションを展開する

---

## バージョン履歴

- v2.0 (2026-05-08): 顧客リサーチエージェントの実装に合わせてカラーパレット・テンプレートを全面改訂
  - カラーを Salesforce Design System 準拠（`#0070d2` / `#2e844a` / `#c23934`）に統一
  - フォントサイズを `px` から `em` に変更
  - コンテンツタイプ別テンプレート（顧客リサーチ / 競合分析 / 決算サマリー）を追加
- v1.0 (2026-03-23): 初版作成
