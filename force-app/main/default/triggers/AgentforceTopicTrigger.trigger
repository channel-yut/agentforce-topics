/**
 * @description Trigger for Agentforce_Topic__c object
 * Handles feedback aggregation and statistics
 */
trigger AgentforceTopicTrigger on Agentforce_Topic__c (after update) {
    if (Trigger.isAfter && Trigger.isUpdate) {
        AgentforceTopicTriggerHandler.handleAfterUpdate(Trigger.new, Trigger.oldMap);
    }
}
