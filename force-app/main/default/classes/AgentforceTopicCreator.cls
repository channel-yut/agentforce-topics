public with sharing class AgentforceTopicCreator {

    @InvocableMethod(label='Create or Update Agentforce Topic' description='Creates or updates an Agentforce Topic record with rich content')
    public static List<Result> createOrUpdateTopic(List<Request> requests) {
        List<Result> results = new List<Result>();

        for (Request req : requests) {
            Result result = new Result();

            try {
                if (String.isNotBlank(req.topicId)) {
                    // Update existing record
                    Agentforce_Topic__c topic = new Agentforce_Topic__c(
                        Id = req.topicId,
                        Summary__c = req.summary,
                        Content__c = req.content
                    );

                    // Update optional fields if provided
                    if (String.isNotBlank(req.relatedRecordId)) {
                        topic.Related_Record_Id__c = req.relatedRecordId;
                    }
                    if (String.isNotBlank(req.triggerType)) {
                        topic.Trigger_Type__c = req.triggerType;
                    }

                    update topic;

                    result.topicId = topic.Id;
                    result.success = true;
                    result.message = 'Successfully updated Agentforce Topic';
                } else {
                    // Create new record
                    Agentforce_Topic__c topic = new Agentforce_Topic__c();
                    topic.Related_Record_Id__c = req.relatedRecordId;
                    topic.Trigger_Type__c = req.triggerType;
                    topic.Generated_Date__c = DateTime.now();
                    topic.Summary__c = req.summary;
                    topic.Content__c = req.content;

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

    public class Request {
        @InvocableVariable(label='Topic ID (for update)' description='ID of existing Agentforce Topic (leave blank for new record)' required=false)
        public String topicId;

        @InvocableVariable(label='Related Record ID' description='ID of the related record (Task, Event, etc.)' required=false)
        public String relatedRecordId;

        @InvocableVariable(label='Trigger Type' description='Type of trigger (e.g., 面談記録, 商談更新)' required=false)
        public String triggerType;

        @InvocableVariable(label='Summary' description='Short summary text' required=true)
        public String summary;

        @InvocableVariable(label='Content' description='Rich HTML content' required=true)
        public String content;
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
