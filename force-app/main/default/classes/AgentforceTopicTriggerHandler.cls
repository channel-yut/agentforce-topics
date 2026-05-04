/**
 * @description Trigger handler for Agentforce_Topic__c.
 * Handles feedback aggregation and statistics calculation.
 * Aggregated counts are written back only to the latest topic per related record
 * to avoid DML row count scaling with topic volume.
 */
public with sharing class AgentforceTopicTriggerHandler {

    private static final String FEEDBACK_HELPFUL     = '役立った';
    private static final String FEEDBACK_NOT_HELPFUL = '役立たなかった';

    private static final String SAMPLE_SUMMARY = 'サンプルコンテンツ（コピーしてGemini等で編集してください）';
    private static final String SAMPLE_CONTENT =
        '<h2 style="color: #0070d2; margin: 0 0 12px 0; padding-bottom: 8px; border-bottom: 3px solid #0070d2; font-size: 1.2em; font-weight: 600;">&#127919; 優先アプローチ推奨</h2>' +
        '<div style="background-color: #f0f8ff; border-left: 4px solid #0070d2; padding: 16px; margin-bottom: 24px;">' +
        '<p style="margin: 0; font-size: 1.02em;">この企業は<strong>2つの戦略テーマ</strong>に取り組んでおり、<strong>166日間接触がない</strong>状態です。過去の面談記録や決算発表の内容から、複数の事業課題に対して具体的な投資計画を検討していることが確認されており、優先的なアプローチをお勧めします。</p></div>' +
        '<h3 style="color: #2e844a; margin: 24px 0 12px 0; font-size: 1.2em; font-weight: 600; padding-bottom: 8px; border-bottom: 2px solid #2e844a;">✨ 顧客関心領域</h3>' +
        '<div style="background-color: #e8f5e9; border-left: 4px solid #2e844a; padding: 16px; margin-bottom: 24px;">' +
        '<div style="margin-bottom: 16px;"><div style="font-weight: bold; color: #2e844a; margin-bottom: 6px;">&#128202; DX推進</div>' +
        '<p style="margin: 0 0 0 20px; font-size: 0.95em; color: #3c4043;">前期決算説明会でDX投資計画（3年で5億円）を発表。基幹システム刷新と業務効率化に向けた資金ニーズが想定されます。</p></div>' +
        '<div style="margin-bottom: 16px;"><div style="font-weight: bold; color: #2e844a; margin-bottom: 6px;">&#127793; カーボンニュートラル</div>' +
        '<p style="margin: 0 0 0 20px; font-size: 0.95em; color: #3c4043;">昨年11月の面談でESG経営への取り組みを言及。工場の省エネ設備導入と再生可能エネルギー活用を検討中とのこと。</p></div></div>' +
        '<h3 style="color: #c23934; margin: 24px 0 12px 0; font-size: 1.2em; font-weight: 600; padding-bottom: 8px; border-bottom: 2px solid #c23934;">⏰ 最終接触状況</h3>' +
        '<div style="background-color: #ffebee; border-left: 4px solid #c23934; padding: 16px; margin-bottom: 24px;">' +
        '<p style="margin: 0 0 8px 0;"><strong>最終接触日:</strong> 2025/10/18</p>' +
        '<p style="margin: 0; color: #c23934; font-weight: bold;">⚠️ 経過日数: 166日前（関係維持のため早期接触が必要）</p></div>' +
        '<h3 style="color: #0070d2; margin: 24px 0 12px 0; font-size: 1.2em; font-weight: 600; padding-bottom: 8px; border-bottom: 2px solid #0070d2;">&#128161; 推奨アクション</h3>' +
        '<div style="background-color: #f4f6f9; border-left: 4px solid #0070d2; padding: 16px;">' +
        '<ol style="margin: 0; padding-left: 24px;">' +
        '<li style="margin-bottom: 12px;"><strong>面談設定（優先度: 高）</strong><br>' +
        '<span style="font-size: 0.95em; color: #3c4043;">DX投資計画の進捗確認と、設備資金・運転資金ニーズのヒアリング。省エネ設備投資の具体的なスケジュールと予算感も確認。</span></li>' +
        '<li style="margin-bottom: 12px;"><strong>提案書作成</strong><br>' +
        '<span style="font-size: 0.95em; color: #3c4043;">① DX推進向け設備資金融資（5億円規模）<br>② 環境対応設備向け制度融資・補助金活用プラン<br>③ 事業承継サポート（株式評価・相続対策コンサルティング）</span></li>' +
        '<li><strong>社内連携</strong><br>' +
        '<span style="font-size: 0.95em; color: #3c4043;">DXソリューション部門、事業承継専門チーム、環境ファイナンスチームとの連携体制を構築し、包括的な提案を実施。</span></li>' +
        '</ol></div>';

    public static void handleBeforeInsert(List<Agentforce_Topic__c> newTopics) {
        for (Agentforce_Topic__c topic : newTopics) {
            if (String.isBlank(topic.Subject__c)) {
                topic.Subject__c = SAMPLE_SUMMARY;
            }
            if (String.isBlank(topic.Content__c)) {
                topic.Content__c = SAMPLE_CONTENT;
            }
        }
    }

    public static void handleAfterUpdate(List<Agentforce_Topic__c> newTopics, Map<Id, Agentforce_Topic__c> oldTopicsMap) {
        Set<String> changedRelatedIds = new Set<String>();

        for (Agentforce_Topic__c newTopic : newTopics) {
            if (newTopic.Feedback__c != oldTopicsMap.get(newTopic.Id).Feedback__c
                    && String.isNotBlank(newTopic.Related_Record_Id__c)) {
                changedRelatedIds.add(newTopic.Related_Record_Id__c);
            }
        }

        if (!changedRelatedIds.isEmpty()) {
            aggregateFeedbackCounts(changedRelatedIds);
        }
    }

    private static void aggregateFeedbackCounts(Set<String> relatedRecordIds) {
        // Aggregate feedback counts per related record
        Map<String, FeedbackStats> statsMap = new Map<String, FeedbackStats>();
        for (AggregateResult ar : [
            SELECT Related_Record_Id__c relatedId,
                   Feedback__c feedback,
                   COUNT(Id) cnt
            FROM Agentforce_Topic__c
            WHERE Related_Record_Id__c IN :relatedRecordIds
              AND Feedback__c != null
            GROUP BY Related_Record_Id__c, Feedback__c
        ]) {
            String relatedId = (String)ar.get('relatedId');
            String feedback  = (String)ar.get('feedback');
            Integer cnt      = (Integer)ar.get('cnt');

            if (!statsMap.containsKey(relatedId)) {
                statsMap.put(relatedId, new FeedbackStats());
            }

            FeedbackStats stats = statsMap.get(relatedId);
            stats.total += cnt;
            if (feedback == FEEDBACK_HELPFUL) {
                stats.helpful += cnt;
            } else if (feedback == FEEDBACK_NOT_HELPFUL) {
                stats.notHelpful += cnt;
            }
        }

        // Write counts back to the latest topic only (1 DML row per related record)
        List<Agentforce_Topic__c> toUpdate = new List<Agentforce_Topic__c>();
        for (Agentforce_Topic__c latest : [
            SELECT Id, Related_Record_Id__c
            FROM Agentforce_Topic__c
            WHERE Related_Record_Id__c IN :relatedRecordIds
            ORDER BY Generated_Date__c DESC NULLS LAST, CreatedDate DESC
        ]) {
            if (!statsMap.containsKey(latest.Related_Record_Id__c)) continue;
            FeedbackStats stats = statsMap.remove(latest.Related_Record_Id__c);
            latest.Helpful_Count__c        = stats.helpful;
            latest.Not_Helpful_Count__c    = stats.notHelpful;
            latest.Total_Feedback_Count__c = stats.total;
            toUpdate.add(latest);
        }

        if (!toUpdate.isEmpty()) {
            update toUpdate;
        }
    }

    private class FeedbackStats {
        public Integer total      = 0;
        public Integer helpful    = 0;
        public Integer notHelpful = 0;
    }
}
