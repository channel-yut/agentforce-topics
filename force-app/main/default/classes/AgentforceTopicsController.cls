/**
 * @description Controller for Agentforce Topics LWC component
 * Handles data operations for AI-generated insights and recommendations
 */
public with sharing class AgentforceTopicsController {

    /**
     * @description Retrieves the latest topic for a given record ID
     * @param recordId The ID of the related record (Account, Opportunity, etc.)
     * @return The latest Agentforce_Topic__c record or null if none exists
     */
    @AuraEnabled(cacheable=true)
    public static Agentforce_Topic__c getLatestTopic(String recordId) {
        try {
            List<Agentforce_Topic__c> topics = [
                SELECT Id, Name, Content__c, Summary__c, Trigger_Type__c,
                       Generated_Date__c, Feedback__c, Related_Record_Id__c
                FROM Agentforce_Topic__c
                WHERE Related_Record_Id__c = :recordId
                ORDER BY Generated_Date__c DESC NULLS LAST, CreatedDate DESC
                LIMIT 1
            ];

            return topics.isEmpty() ? null : topics[0];
        } catch (Exception e) {
            throw new AuraHandledException('Error retrieving latest topic: ' + e.getMessage());
        }
    }

    /**
     * @description Retrieves all topics for a given record ID (history)
     * @param recordId The ID of the related record
     * @return List of all Agentforce_Topic__c records ordered by date (newest first)
     */
    @AuraEnabled(cacheable=true)
    public static List<Agentforce_Topic__c> getTopicHistory(String recordId) {
        try {
            return [
                SELECT Id, Name, Content__c, Summary__c, Trigger_Type__c,
                       Generated_Date__c, Feedback__c, Related_Record_Id__c
                FROM Agentforce_Topic__c
                WHERE Related_Record_Id__c = :recordId
                ORDER BY Generated_Date__c DESC NULLS LAST, CreatedDate DESC
            ];
        } catch (Exception e) {
            throw new AuraHandledException('Error retrieving topic history: ' + e.getMessage());
        }
    }

    /**
     * @description Updates feedback for a specific topic
     * @param topicId The ID of the Agentforce_Topic__c record
     * @param feedback The feedback value ('役立った' or '役立たなかった')
     */
    @AuraEnabled
    public static void updateFeedback(String topicId, String feedback) {
        try {
            Agentforce_Topic__c topic = new Agentforce_Topic__c(
                Id = topicId,
                Feedback__c = feedback
            );
            update topic;
        } catch (Exception e) {
            throw new AuraHandledException('Error updating feedback: ' + e.getMessage());
        }
    }

    /**
     * @description Creates a new Agentforce Topic record
     * @param recordId The related record ID
     * @param content Rich text content
     * @param summary Brief summary
     * @param triggerType Type of trigger event
     * @return The newly created topic ID
     */
    @AuraEnabled
    public static String createTopic(String recordId, String content, String summary, String triggerType) {
        try {
            Agentforce_Topic__c newTopic = new Agentforce_Topic__c(
                Related_Record_Id__c = recordId,
                Content__c = content,
                Summary__c = summary,
                Trigger_Type__c = triggerType,
                Generated_Date__c = System.now()
            );
            insert newTopic;
            return newTopic.Id;
        } catch (Exception e) {
            throw new AuraHandledException('Error creating topic: ' + e.getMessage());
        }
    }

    /**
     * @description Retrieves aggregated feedback statistics for a given record
     * @param recordId The ID of the related record
     * @return FeedbackStatistics wrapper with aggregated data
     */
    @AuraEnabled(cacheable=true)
    public static FeedbackStatistics getFeedbackStatistics(String recordId) {
        try {
            FeedbackStatistics stats = new FeedbackStatistics();

            // Get the latest topic with aggregated counts
            List<Agentforce_Topic__c> topics = [
                SELECT Id, Helpful_Count__c, Not_Helpful_Count__c,
                       Total_Feedback_Count__c, Feedback_Rate__c
                FROM Agentforce_Topic__c
                WHERE Related_Record_Id__c = :recordId
                ORDER BY Generated_Date__c DESC NULLS LAST, CreatedDate DESC
                LIMIT 1
            ];

            if (!topics.isEmpty()) {
                Agentforce_Topic__c topic = topics[0];
                stats.helpfulCount = (Integer)(topic.Helpful_Count__c != null ? topic.Helpful_Count__c : 0);
                stats.notHelpfulCount = (Integer)(topic.Not_Helpful_Count__c != null ? topic.Not_Helpful_Count__c : 0);
                stats.totalFeedbackCount = (Integer)(topic.Total_Feedback_Count__c != null ? topic.Total_Feedback_Count__c : 0);
                stats.feedbackRate = topic.Feedback_Rate__c != null ? topic.Feedback_Rate__c : 0;
            }

            // Get total topics count
            stats.totalTopicsCount = [
                SELECT COUNT()
                FROM Agentforce_Topic__c
                WHERE Related_Record_Id__c = :recordId
            ];

            return stats;
        } catch (Exception e) {
            throw new AuraHandledException('Error retrieving feedback statistics: ' + e.getMessage());
        }
    }

    /**
     * @description Wrapper class for feedback statistics
     */
    public class FeedbackStatistics {
        @AuraEnabled public Integer helpfulCount { get; set; }
        @AuraEnabled public Integer notHelpfulCount { get; set; }
        @AuraEnabled public Integer totalFeedbackCount { get; set; }
        @AuraEnabled public Decimal feedbackRate { get; set; }
        @AuraEnabled public Integer totalTopicsCount { get; set; }

        public FeedbackStatistics() {
            this.helpfulCount = 0;
            this.notHelpfulCount = 0;
            this.totalFeedbackCount = 0;
            this.feedbackRate = 0;
            this.totalTopicsCount = 0;
        }
    }
}
