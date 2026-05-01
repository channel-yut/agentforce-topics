/**
 * @description Trigger handler for Agentforce_Topic__c.
 * Handles feedback aggregation and statistics calculation.
 */
public with sharing class AgentforceTopicTriggerHandler {

    private static final String FEEDBACK_HELPFUL     = '役立った';
    private static final String FEEDBACK_NOT_HELPFUL = '役立たなかった';

    /**
     * @description Handles after update logic.
     */
    public static void handleAfterUpdate(List<Agentforce_Topic__c> newTopics, Map<Id, Agentforce_Topic__c> oldTopicsMap) {
        Set<Id> changedIds = new Set<Id>();

        for (Agentforce_Topic__c newTopic : newTopics) {
            if (newTopic.Feedback__c != oldTopicsMap.get(newTopic.Id).Feedback__c) {
                changedIds.add(newTopic.Id);
            }
        }

        if (!changedIds.isEmpty()) {
            aggregateFeedbackCounts(changedIds);
        }
    }

    /**
     * @description Aggregates feedback counts for all topics sharing the same Related_Record_Id__c.
     */
    private static void aggregateFeedbackCounts(Set<Id> changedIds) {
        // Resolve Related_Record_Id__c values from changed topics
        Set<String> relatedRecordIds = new Set<String>();
        for (Agentforce_Topic__c topic : [
            SELECT Related_Record_Id__c
            FROM Agentforce_Topic__c
            WHERE Id IN :changedIds
              AND Related_Record_Id__c != null
        ]) {
            relatedRecordIds.add(topic.Related_Record_Id__c);
        }

        if (relatedRecordIds.isEmpty()) {
            return;
        }

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

        // Update all topics under the same related records
        List<Agentforce_Topic__c> toUpdate = new List<Agentforce_Topic__c>();
        for (Agentforce_Topic__c topic : [
            SELECT Id, Related_Record_Id__c
            FROM Agentforce_Topic__c
            WHERE Related_Record_Id__c IN :relatedRecordIds
        ]) {
            FeedbackStats stats = statsMap.get(topic.Related_Record_Id__c);
            topic.Helpful_Count__c       = stats != null ? stats.helpful    : 0;
            topic.Not_Helpful_Count__c   = stats != null ? stats.notHelpful : 0;
            topic.Total_Feedback_Count__c = stats != null ? stats.total     : 0;
            toUpdate.add(topic);
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
