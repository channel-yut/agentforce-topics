@isTest
public class TestDataFactory {

    public static Agentforce_Topic__c createTopic(String relatedRecordId, String triggerType, String feedback, String feedbackCategory, Boolean doInsert) {
        Agentforce_Topic__c topic = new Agentforce_Topic__c(
            Related_Record_Id__c  = relatedRecordId,
            Trigger_Type__c       = triggerType,
            Summary__c            = 'Test Summary - ' + triggerType,
            Content__c            = '<p>Test Content</p>',
            Generated_Date__c     = System.now(),
            Feedback__c           = feedback,
            Feedback_Category__c  = feedbackCategory
        );
        if (doInsert) insert topic;
        return topic;
    }

    public static List<Agentforce_Topic__c> createTopics(Integer count, String relatedRecordId, String triggerType, String feedback, String feedbackCategory, Boolean doInsert) {
        List<Agentforce_Topic__c> topics = new List<Agentforce_Topic__c>();
        for (Integer i = 0; i < count; i++) {
            topics.add(new Agentforce_Topic__c(
                Related_Record_Id__c  = relatedRecordId,
                Trigger_Type__c       = triggerType,
                Summary__c            = 'Test Summary ' + i,
                Content__c            = '<p>Test Content ' + i + '</p>',
                Generated_Date__c     = System.now(),
                Feedback__c           = feedback,
                Feedback_Category__c  = feedbackCategory
            ));
        }
        if (doInsert) insert topics;
        return topics;
    }

    public static Agentforce_Topic_Learning__c createLearningRecord(String triggerType, String objectApiName, Integer generation, Boolean isActive, Boolean doInsert) {
        Agentforce_Topic_Learning__c rec = new Agentforce_Topic_Learning__c(
            Trigger_Type__c            = triggerType,
            Object_Api_Name__c         = objectApiName,
            Generation__c              = generation,
            Is_Active__c               = isActive,
            Analysis_Date__c           = System.now(),
            Negative_Feedback_Count__c = 3,
            Improvement_Patterns__c    = '[{"pattern":"抽象的","solution":"具体的に書く"}]',
            Analysis_Result__c         = '{"total_count":3}'
        );
        if (doInsert) insert rec;
        return rec;
    }
}
