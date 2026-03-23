@isTest
private class AgentforceTopicCreatorTest {

    @isTest
    static void testCreateTopic() {
        // Test data
        AgentforceTopicCreator.Request req = new AgentforceTopicCreator.Request();
        req.relatedRecordId = 'a8RgK00000002JZUAY';
        req.triggerType = '面談記録';
        req.summary = 'Test Summary';
        req.content = '<p>Test Content</p>';

        Test.startTest();
        List<AgentforceTopicCreator.Result> results = AgentforceTopicCreator.createOrUpdateTopic(
            new List<AgentforceTopicCreator.Request>{ req }
        );
        Test.stopTest();

        // Verify
        System.assertEquals(1, results.size(), 'Should return one result');
        System.assertEquals(true, results[0].success, 'Should be successful');
        System.assertNotEquals(null, results[0].topicId, 'Should return topic ID');

        Agentforce_Topic__c topic = [SELECT Id, Summary__c, Content__c FROM Agentforce_Topic__c WHERE Id = :results[0].topicId];
        System.assertEquals('Test Summary', topic.Summary__c, 'Summary should match');
        System.assertEquals('<p>Test Content</p>', topic.Content__c, 'Content should match');
    }

    @isTest
    static void testUpdateTopic() {
        // Create initial record
        Agentforce_Topic__c topic = new Agentforce_Topic__c();
        topic.Related_Record_Id__c = 'a8RgK00000002JZUAY';
        topic.Trigger_Type__c = '面談記録';
        topic.Generated_Date__c = DateTime.now();
        topic.Summary__c = 'Original Summary';
        topic.Content__c = '<p>Original Content</p>';
        insert topic;

        // Update request
        AgentforceTopicCreator.Request req = new AgentforceTopicCreator.Request();
        req.topicId = topic.Id;
        req.summary = 'Updated Summary';
        req.content = '<p>Updated Content</p>';

        Test.startTest();
        List<AgentforceTopicCreator.Result> results = AgentforceTopicCreator.createOrUpdateTopic(
            new List<AgentforceTopicCreator.Request>{ req }
        );
        Test.stopTest();

        // Verify
        System.assertEquals(1, results.size(), 'Should return one result');
        System.assertEquals(true, results[0].success, 'Should be successful');
        System.assertEquals(topic.Id, results[0].topicId, 'Should return same topic ID');

        Agentforce_Topic__c updatedTopic = [SELECT Id, Summary__c, Content__c FROM Agentforce_Topic__c WHERE Id = :topic.Id];
        System.assertEquals('Updated Summary', updatedTopic.Summary__c, 'Summary should be updated');
        System.assertEquals('<p>Updated Content</p>', updatedTopic.Content__c, 'Content should be updated');
    }
}
