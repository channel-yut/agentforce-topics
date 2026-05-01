/**
 * @description Trigger for Agentforce_Topic__c object
 * Handles feedback aggregation and statistics
 */
trigger AgentforceTopicTrigger on Agentforce_Topic__c (before insert, after update) {
    if (Trigger.isBefore && Trigger.isInsert) {
        AgentforceTopicTriggerHandler.handleBeforeInsert(Trigger.new);
    }
    if (Trigger.isAfter && Trigger.isUpdate) {
        AgentforceTopicTriggerHandler.handleAfterUpdate(Trigger.new, Trigger.oldMap);
    }
}
