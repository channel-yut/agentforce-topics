public with sharing class AgentforceTopicCreator {

    @InvocableMethod(label='Create or Update Agentforce Topic' description='Creates or updates an Agentforce Topic record with rich content')
    public static List<Result> createOrUpdateTopic(List<Request> requests) {
        List<Result> results = new List<Result>();

        if (!Schema.SObjectType.Agentforce_Topic__c.isCreateable()
                || !Schema.SObjectType.Agentforce_Topic__c.isUpdateable()) {
            Result r = new Result();
            r.success = false;
            r.message = 'Insufficient permissions to create or update Agentforce Topic';
            return new List<Result>{ r };
        }

        for (Request req : requests) {
            Result result = new Result();

            try {
                if (String.isNotBlank(req.topicId)) {
                    Agentforce_Topic__c topic = new Agentforce_Topic__c(
                        Id         = req.topicId,
                        Subject__c = req.subject,
                        Content__c = req.content
                    );
                    if (String.isNotBlank(req.relatedRecordId)) {
                        topic.Related_Record_Id__c = req.relatedRecordId;
                    }
                    if (String.isNotBlank(req.triggerType)) {
                        topic.Trigger_Type__c = req.triggerType;
                    }
                    if (String.isNotBlank(req.objectApiName)) {
                        topic.Object_Api_Name__c = req.objectApiName;
                    }
                    if (String.isNotBlank(req.relatedLinks)) {
                        topic.Related_Links__c = req.relatedLinks;
                    }
                    update topic;

                    result.topicId = topic.Id;
                    result.success = true;
                    result.message = 'Successfully updated Agentforce Topic';
                } else {
                    Agentforce_Topic__c topic = new Agentforce_Topic__c(
                        Related_Record_Id__c = req.relatedRecordId,
                        Trigger_Type__c      = req.triggerType,
                        Generated_Date__c    = DateTime.now(),
                        Subject__c           = req.subject,
                        Content__c           = req.content
                    );
                    if (String.isNotBlank(req.relatedLinks)) {
                        topic.Related_Links__c = req.relatedLinks;
                    }
                    if (String.isNotBlank(req.objectApiName)) {
                        topic.Object_Api_Name__c = req.objectApiName;
                    } else if (String.isNotBlank(req.relatedRecordId) && req.relatedRecordId.length() >= 3) {
                        // Auto-detect object type from record ID prefix when objectApiName is not provided
                        topic.Object_Api_Name__c = resolveObjectApiName(req.relatedRecordId);
                    }
                    insert topic;

                    result.topicId = topic.Id;
                    result.success = true;
                    result.message = 'Successfully created Agentforce Topic';
                }

                results.add(result);
            } catch (Exception e) {
                result.success = false;
                result.message = 'Error: ' + e.getMessage();
                results.add(result);
            }
        }

        return results;
    }

    /**
     * @description Resolves object API name from a Salesforce record ID using Schema.
     * Returns null if the ID is not a valid Salesforce ID or the object cannot be resolved.
     */
    private static String resolveObjectApiName(String recordId) {
        try {
            Id sfId = (Id)recordId;
            return sfId.getSObjectType().getDescribe().getName();
        } catch (Exception e) {
            return null;
        }
    }

    public class Request {
        @InvocableVariable(label='Topic ID (for update)' description='ID of existing Agentforce Topic (leave blank for new record)' required=false)
        public String topicId;

        @InvocableVariable(label='Related Record ID' description='ID of the related record (Account, Opportunity, etc.)' required=false)
        public String relatedRecordId;

        @InvocableVariable(label='Trigger Type' description='Type of trigger (e.g., 面談記録, 商談更新)' required=false)
        public String triggerType;

        @InvocableVariable(label='Object API Name' description='Salesforce object API name (e.g., Account, Opportunity). Auto-detected from Related Record ID if omitted.' required=false)
        public String objectApiName;

        @InvocableVariable(label='Subject' description='Subject title (single line)' required=true)
        public String subject;

        @InvocableVariable(label='Content' description='Rich HTML content' required=true)
        public String content;

        @InvocableVariable(label='Related Links' description='JSON array of related record IDs (e.g. ["001xxx","00Txxx"])' required=false)
        public String relatedLinks;
    }

    public class Result {
        @InvocableVariable(label='Topic ID' description='ID of the created or updated Agentforce Topic')
        public String topicId;

        @InvocableVariable(label='Success' description='Whether the operation was successful')
        public Boolean success;

        @InvocableVariable(label='Message' description='Success or error message')
        public String message;
    }
}
