/**
 * @description Trigger handler for Agentforce_Topic__c
 * Handles feedback aggregation and statistics calculation
 */
public with sharing class AgentforceTopicTriggerHandler {

    /**
     * @description Handles after update logic
     * @param newTopics New version of records
     * @param oldTopicsMap Old version of records mapped by Id
     */
    public static void handleAfterUpdate(List<Agentforce_Topic__c> newTopics, Map<Id, Agentforce_Topic__c> oldTopicsMap) {
        Set<Id> topicsToAggregate = new Set<Id>();

        // Identify records where Feedback__c changed
        for (Agentforce_Topic__c newTopic : newTopics) {
            Agentforce_Topic__c oldTopic = oldTopicsMap.get(newTopic.Id);

            // If feedback field changed, mark for aggregation
            if (newTopic.Feedback__c != oldTopic.Feedback__c) {
                topicsToAggregate.add(newTopic.Id);
            }
        }

        // Aggregate feedback counts
        if (!topicsToAggregate.isEmpty()) {
            aggregateFeedbackCounts(topicsToAggregate);
        }
    }

    /**
     * @description Aggregates feedback counts for related records
     * @param topicIds Set of topic IDs that need aggregation
     */
    private static void aggregateFeedbackCounts(Set<Id> topicIds) {
        // Get the related record IDs for these topics
        Map<Id, String> topicToRelatedRecordMap = new Map<Id, String>();
        for (Agentforce_Topic__c topic : [SELECT Id, Related_Record_Id__c FROM Agentforce_Topic__c WHERE Id IN :topicIds]) {
            topicToRelatedRecordMap.put(topic.Id, topic.Related_Record_Id__c);
        }

        Set<String> relatedRecordIds = new Set<String>(topicToRelatedRecordMap.values());

        // Aggregate feedback for all topics related to these record IDs
        Map<String, FeedbackStats> statsMap = new Map<String, FeedbackStats>();

        // Query all topics with feedback grouped by related record and feedback value
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
            String feedback = (String)ar.get('feedback');
            Integer cnt = (Integer)ar.get('cnt');

            // Initialize stats if not exists
            if (!statsMap.containsKey(relatedId)) {
                statsMap.put(relatedId, new FeedbackStats());
            }

            FeedbackStats stats = statsMap.get(relatedId);
            stats.total += cnt;

            if (feedback == getFeedbackHelpfulValue()) {
                stats.helpful += cnt;
            } else if (feedback == getFeedbackNotHelpfulValue()) {
                stats.notHelpful += cnt;
            }
        }

        // Query all topics that need to be updated
        List<Agentforce_Topic__c> topicsToUpdate = new List<Agentforce_Topic__c>();
        for (Agentforce_Topic__c topic : [
            SELECT Id, Related_Record_Id__c
            FROM Agentforce_Topic__c
            WHERE Related_Record_Id__c IN :relatedRecordIds
        ]) {
            FeedbackStats stats = statsMap.get(topic.Related_Record_Id__c);
            if (stats != null) {
                topic.Helpful_Count__c = stats.helpful;
                topic.Not_Helpful_Count__c = stats.notHelpful;
                topic.Total_Feedback_Count__c = stats.total;
            } else {
                // No feedback yet, reset to zero
                topic.Helpful_Count__c = 0;
                topic.Not_Helpful_Count__c = 0;
                topic.Total_Feedback_Count__c = 0;
            }
            topicsToUpdate.add(topic);
        }

        if (!topicsToUpdate.isEmpty()) {
            update topicsToUpdate;
        }
    }

    /**
     * @description Gets the "Helpful" feedback value
     * @return The helpful feedback value based on user's language
     */
    private static String getFeedbackHelpfulValue() {
        // Use the same label that the LWC uses
        return '役立った'; // This should match the picklist value
    }

    /**
     * @description Gets the "Not Helpful" feedback value
     * @return The not helpful feedback value based on user's language
     */
    private static String getFeedbackNotHelpfulValue() {
        // Use the same label that the LWC uses
        return '役立たなかった'; // This should match the picklist value
    }

    /**
     * @description Inner class to hold feedback statistics
     */
    private class FeedbackStats {
        public Integer total = 0;
        public Integer helpful = 0;
        public Integer notHelpful = 0;
    }
}
