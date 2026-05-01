/**
 * @description Trigger handler for Agentforce_Topic__c.
 * Handles feedback aggregation and statistics calculation.
 * Aggregated counts are written back only to the latest topic per related record
 * to avoid DML row count scaling with topic volume.
 */
public with sharing class AgentforceTopicTriggerHandler {

    private static final String FEEDBACK_HELPFUL     = '役立った';
    private static final String FEEDBACK_NOT_HELPFUL = '役立たなかった';

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
