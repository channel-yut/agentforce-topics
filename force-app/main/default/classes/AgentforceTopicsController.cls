/**
 * @description Controller for Agentforce Topics LWC component
 * Handles data operations for AI-generated insights and recommendations
 */
public with sharing class AgentforceTopicsController {

    @AuraEnabled(cacheable=true)
    public static Agentforce_Topic__c getLatestTopic(String recordId) {
        try {
            List<Agentforce_Topic__c> topics = [
                SELECT Id, Name, Content__c, Summary__c, Trigger_Type__c,
                       Generated_Date__c, Feedback__c, Related_Record_Id__c
                FROM Agentforce_Topic__c
                WHERE Related_Record_Id__c = :recordId
                WITH SECURITY_ENFORCED
                ORDER BY Generated_Date__c DESC NULLS LAST, CreatedDate DESC
                LIMIT 1
            ];
            return topics.isEmpty() ? null : topics[0];
        } catch (Exception e) {
            throw new AuraHandledException('Error retrieving latest topic');
        }
    }

    @AuraEnabled(cacheable=true)
    public static List<Agentforce_Topic__c> getTopicHistory(String recordId) {
        try {
            return [
                SELECT Id, Name, Content__c, Summary__c, Trigger_Type__c,
                       Generated_Date__c, Feedback__c, Related_Record_Id__c
                FROM Agentforce_Topic__c
                WHERE Related_Record_Id__c = :recordId
                WITH SECURITY_ENFORCED
                ORDER BY Generated_Date__c DESC NULLS LAST, CreatedDate DESC
            ];
        } catch (Exception e) {
            throw new AuraHandledException('Error retrieving topic history');
        }
    }

    @AuraEnabled
    public static void updateFeedback(String topicId, String feedback) {
        if (String.isBlank(topicId)) {
            throw new AuraHandledException('topicId is required');
        }
        try {
            Id.valueOf(topicId);
        } catch (Exception e) {
            throw new AuraHandledException('Invalid topicId format');
        }
        Set<String> validFeedbacks = new Set<String>{'役立った', '役立たなかった'};
        if (!validFeedbacks.contains(feedback)) {
            throw new AuraHandledException('Invalid feedback value');
        }
        if (!Schema.SObjectType.Agentforce_Topic__c.isUpdateable()) {
            throw new AuraHandledException('Insufficient permissions to update topic');
        }
        try {
            update new Agentforce_Topic__c(
                Id = (Id)topicId,
                Feedback__c = feedback
            );
        } catch (Exception e) {
            throw new AuraHandledException('Error updating feedback');
        }
    }

    @AuraEnabled
    public static String createTopic(String recordId, String content, String summary, String triggerType) {
        if (!Schema.SObjectType.Agentforce_Topic__c.isCreateable()) {
            throw new AuraHandledException('Insufficient permissions to create topic');
        }
        try {
            Agentforce_Topic__c newTopic = new Agentforce_Topic__c(
                Related_Record_Id__c = recordId,
                Content__c           = content,
                Summary__c           = summary,
                Trigger_Type__c      = triggerType,
                Generated_Date__c    = System.now()
            );
            insert newTopic;
            return newTopic.Id;
        } catch (Exception e) {
            throw new AuraHandledException('Error creating topic');
        }
    }

    @AuraEnabled(cacheable=true)
    public static FeedbackStatistics getFeedbackStatistics(String recordId) {
        try {
            FeedbackStatistics stats = new FeedbackStatistics();

            List<AggregateResult> aggregates = [
                SELECT COUNT(Id) totalTopics,
                       MAX(Helpful_Count__c) helpfulCount,
                       MAX(Not_Helpful_Count__c) notHelpfulCount,
                       MAX(Total_Feedback_Count__c) totalFeedbackCount,
                       MAX(Feedback_Rate__c) feedbackRate
                FROM Agentforce_Topic__c
                WHERE Related_Record_Id__c = :recordId
                WITH SECURITY_ENFORCED
            ];

            if (!aggregates.isEmpty()) {
                AggregateResult ar = aggregates[0];
                stats.totalTopicsCount   = ar.get('totalTopics')        != null ? ((Integer)ar.get('totalTopics'))                        : 0;
                stats.helpfulCount       = ar.get('helpfulCount')       != null ? ((Decimal)ar.get('helpfulCount')).intValue()            : 0;
                stats.notHelpfulCount    = ar.get('notHelpfulCount')    != null ? ((Decimal)ar.get('notHelpfulCount')).intValue()         : 0;
                stats.totalFeedbackCount = ar.get('totalFeedbackCount') != null ? ((Decimal)ar.get('totalFeedbackCount')).intValue()      : 0;
                stats.feedbackRate       = ar.get('feedbackRate')       != null ? (Decimal)ar.get('feedbackRate')                        : 0;
            }

            return stats;
        } catch (Exception e) {
            throw new AuraHandledException('Error retrieving feedback statistics');
        }
    }

    public class FeedbackStatistics {
        @AuraEnabled public Integer helpfulCount      { get; set; }
        @AuraEnabled public Integer notHelpfulCount   { get; set; }
        @AuraEnabled public Integer totalFeedbackCount { get; set; }
        @AuraEnabled public Decimal feedbackRate      { get; set; }
        @AuraEnabled public Integer totalTopicsCount  { get; set; }

        public FeedbackStatistics() {
            this.helpfulCount       = 0;
            this.notHelpfulCount    = 0;
            this.totalFeedbackCount = 0;
            this.feedbackRate       = 0;
            this.totalTopicsCount   = 0;
        }
    }
}
