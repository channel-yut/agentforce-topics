/**
 * @description Controller for Agentforce Topics LWC component
 * Handles data operations for AI-generated insights and recommendations
 */
public with sharing class AgentforceTopicsController {

    @AuraEnabled(cacheable=true)
    public static Agentforce_Topic__c getLatestTopic(String recordId) {
        try {
            List<Agentforce_Topic__c> topics = [
                SELECT Id, Name, Content__c, Subject__c, Trigger_Type__c,
                       Generated_Date__c, Feedback__c, Related_Record_Id__c, Related_Links__c
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
                SELECT Id, Name, Content__c, Subject__c, Trigger_Type__c,
                       Generated_Date__c, Feedback__c, Related_Record_Id__c, Related_Links__c
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
    public static String createTopic(String recordId, String content, String subject, String triggerType) {
        if (!Schema.SObjectType.Agentforce_Topic__c.isCreateable()) {
            throw new AuraHandledException('Insufficient permissions to create topic');
        }
        try {
            Agentforce_Topic__c newTopic = new Agentforce_Topic__c(
                Related_Record_Id__c = recordId,
                Content__c           = content,
                Subject__c           = subject,
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
    public static List<RelatedRecordInfo> getRelatedRecordsInfo(List<String> recordIds) {
        List<RelatedRecordInfo> results = new List<RelatedRecordInfo>();
        if (recordIds == null || recordIds.isEmpty()) return results;

        Map<String, List<String>> objectToIds = new Map<String, List<String>>();
        for (String rid : recordIds) {
            try {
                Id sfId = (Id) rid;
                String objName = sfId.getSObjectType().getDescribe().getName();
                if (!objectToIds.containsKey(objName)) {
                    objectToIds.put(objName, new List<String>());
                }
                objectToIds.get(objName).add(rid);
            } catch (Exception e) {
                RelatedRecordInfo info = new RelatedRecordInfo();
                info.recordId = rid;
                info.label = rid;
                info.iconName = 'standard:record';
                results.add(info);
            }
        }

        Map<String, String> idToName = new Map<String, String>();
        Map<String, String> idToIcon = new Map<String, String>();

        for (String objName : objectToIds.keySet()) {
            List<String> ids = objectToIds.get(objName);
            String icon = getIconForObject(objName);
            String nameField = getNameFieldForObject(objName);

            try {
                String safeNameField = String.escapeSingleQuotes(nameField);
                String soql = 'SELECT Id, ' + safeNameField + ' FROM ' + objName
                    + ' WHERE Id IN :ids WITH SECURITY_ENFORCED LIMIT 200';
                for (SObject obj : Database.query(soql)) {
                    String recId = (String) obj.get('Id');
                    Object nameVal = obj.get(nameField);
                    idToName.put(recId, nameVal != null ? String.valueOf(nameVal) : recId);
                    idToIcon.put(recId, icon);
                }
            } catch (Exception e) {
                for (String rid : ids) {
                    idToName.put(rid, rid);
                    idToIcon.put(rid, 'standard:record');
                }
            }
        }

        for (String rid : recordIds) {
            RelatedRecordInfo info = new RelatedRecordInfo();
            info.recordId = rid;
            info.label = idToName.containsKey(rid) ? idToName.get(rid) : rid;
            info.iconName = idToIcon.containsKey(rid) ? idToIcon.get(rid) : 'standard:record';
            results.add(info);
        }
        return results;
    }

    private static String getNameFieldForObject(String objName) {
        Map<String, String> nameFields = new Map<String, String>{
            'Task'         => 'Subject',
            'Event'        => 'Subject',
            'Case'         => 'Subject',
            'EmailMessage' => 'Subject'
        };
        return nameFields.containsKey(objName) ? nameFields.get(objName) : 'Name';
    }

    private static String getIconForObject(String objName) {
        Map<String, String> icons = new Map<String, String>{
            'Account'      => 'standard:account',
            'Opportunity'  => 'standard:opportunity',
            'Contact'      => 'standard:contact',
            'Lead'         => 'standard:lead',
            'Case'         => 'standard:case',
            'Task'         => 'standard:task',
            'Event'        => 'standard:event',
            'Contract'     => 'standard:contract',
            'Order'        => 'standard:orders'
        };
        if (icons.containsKey(objName)) return icons.get(objName);
        if (objName.endsWith('__c')) return 'standard:custom';
        return 'standard:record';
    }

    public class RelatedRecordInfo {
        @AuraEnabled public String recordId  { get; set; }
        @AuraEnabled public String label     { get; set; }
        @AuraEnabled public String iconName  { get; set; }
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
