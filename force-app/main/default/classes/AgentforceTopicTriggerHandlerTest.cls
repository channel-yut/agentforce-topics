@isTest
private class AgentforceTopicTriggerHandlerTest {

    private static final String RELATED_ID = 'TEST000000000001';
    private static final String TRIGGER_TYPE = '面談記録';

    // ─────────────────────────────────────────────
    // Feedback aggregation on update
    // ─────────────────────────────────────────────

    @isTest
    static void handleAfterUpdate_HelpfulFeedback_IncrementsHelpfulCount() {
        // Given
        Agentforce_Topic__c topic = TestDataFactory.createTopic(RELATED_ID, TRIGGER_TYPE, null, null, true);

        // When
        Test.startTest();
        topic.Feedback__c = '役立った';
        update topic;
        Test.stopTest();

        // Then
        Agentforce_Topic__c updated = [
            SELECT Helpful_Count__c, Not_Helpful_Count__c, Total_Feedback_Count__c
            FROM Agentforce_Topic__c WHERE Id = :topic.Id
        ];
        Assert.areEqual(1, updated.Helpful_Count__c.intValue(), 'Helpful count should be 1');
        Assert.areEqual(0, updated.Not_Helpful_Count__c.intValue(), 'Not helpful count should be 0');
        Assert.areEqual(1, updated.Total_Feedback_Count__c.intValue(), 'Total count should be 1');
    }

    @isTest
    static void handleAfterUpdate_NotHelpfulFeedback_IncrementsNotHelpfulCount() {
        // Given
        Agentforce_Topic__c topic = TestDataFactory.createTopic(RELATED_ID, TRIGGER_TYPE, null, null, true);

        // When
        Test.startTest();
        topic.Feedback__c = '役立たなかった';
        update topic;
        Test.stopTest();

        // Then
        Agentforce_Topic__c updated = [
            SELECT Helpful_Count__c, Not_Helpful_Count__c, Total_Feedback_Count__c
            FROM Agentforce_Topic__c WHERE Id = :topic.Id
        ];
        Assert.areEqual(0, updated.Helpful_Count__c.intValue(), 'Helpful count should be 0');
        Assert.areEqual(1, updated.Not_Helpful_Count__c.intValue(), 'Not helpful count should be 1');
        Assert.areEqual(1, updated.Total_Feedback_Count__c.intValue(), 'Total count should be 1');
    }

    @isTest
    static void handleAfterUpdate_MultipleTopicsSameRelatedRecord_AggregatesOnLatestOnly() {
        // Given — 3 topics under same related record (inserted in order, last one is latest)
        List<Agentforce_Topic__c> topics = TestDataFactory.createTopics(3, RELATED_ID, TRIGGER_TYPE, null, null, true);

        // When — give feedback to each
        Test.startTest();
        topics[0].Feedback__c = '役立った';
        topics[1].Feedback__c = '役立った';
        topics[2].Feedback__c = '役立たなかった';
        update topics;
        Test.stopTest();

        // Then — aggregated counts are written to the latest topic only
        List<Agentforce_Topic__c> updated = [
            SELECT Id, Helpful_Count__c, Not_Helpful_Count__c, Total_Feedback_Count__c
            FROM Agentforce_Topic__c
            WHERE Related_Record_Id__c = :RELATED_ID
            ORDER BY CreatedDate DESC
        ];
        // Latest topic should have aggregated counts
        Assert.areEqual(2, updated[0].Helpful_Count__c.intValue(), 'Latest topic: helpful count should be 2');
        Assert.areEqual(1, updated[0].Not_Helpful_Count__c.intValue(), 'Latest topic: not helpful count should be 1');
        Assert.areEqual(3, updated[0].Total_Feedback_Count__c.intValue(), 'Latest topic: total count should be 3');
        // Older topics should NOT have counts updated
        Assert.isTrue(updated[1].Helpful_Count__c == null || updated[1].Helpful_Count__c == 0,
            'Older topics should not have counts updated');
    }

    @isTest
    static void handleAfterUpdate_FeedbackUnchanged_DoesNotRecalculate() {
        // Given — topic with existing feedback
        Agentforce_Topic__c topic = TestDataFactory.createTopic(RELATED_ID, TRIGGER_TYPE, '役立った', null, true);
        // Manually set counts to known values
        topic.Helpful_Count__c = 99;
        update topic;

        // When — update something other than feedback
        Test.startTest();
        topic.Subject__c = 'Updated Subject';
        update topic;
        Test.stopTest();

        // Then — counts should not be recalculated (trigger only fires on feedback change)
        Agentforce_Topic__c updated = [
            SELECT Helpful_Count__c FROM Agentforce_Topic__c WHERE Id = :topic.Id
        ];
        Assert.areEqual(99, updated.Helpful_Count__c.intValue(), 'Counts should not change when feedback is unchanged');
    }

    @isTest
    static void handleAfterUpdate_DifferentRelatedRecords_AggregatesSeparately() {
        // Given — 2 topics under different related records
        Agentforce_Topic__c topicA = TestDataFactory.createTopic('TEST000000000001', TRIGGER_TYPE, null, null, true);
        Agentforce_Topic__c topicB = TestDataFactory.createTopic('TEST000000000002', TRIGGER_TYPE, null, null, true);

        // When
        Test.startTest();
        topicA.Feedback__c = '役立った';
        topicB.Feedback__c = '役立たなかった';
        update new List<Agentforce_Topic__c>{ topicA, topicB };
        Test.stopTest();

        // Then — each record's counts should be independent
        Agentforce_Topic__c updatedA = [SELECT Helpful_Count__c, Not_Helpful_Count__c FROM Agentforce_Topic__c WHERE Id = :topicA.Id];
        Agentforce_Topic__c updatedB = [SELECT Helpful_Count__c, Not_Helpful_Count__c FROM Agentforce_Topic__c WHERE Id = :topicB.Id];
        Assert.areEqual(1, updatedA.Helpful_Count__c.intValue(), 'TopicA should have 1 helpful');
        Assert.areEqual(0, updatedA.Not_Helpful_Count__c.intValue(), 'TopicA should have 0 not helpful');
        Assert.areEqual(0, updatedB.Helpful_Count__c.intValue(), 'TopicB should have 0 helpful');
        Assert.areEqual(1, updatedB.Not_Helpful_Count__c.intValue(), 'TopicB should have 1 not helpful');
    }

    @isTest
    static void handleAfterUpdate_BulkUpdate_HandlesLargeVolume() {
        // Given
        List<Agentforce_Topic__c> topics = TestDataFactory.createTopics(251, RELATED_ID, TRIGGER_TYPE, null, null, true);

        // When
        Test.startTest();
        for (Agentforce_Topic__c t : topics) {
            t.Feedback__c = '役立った';
        }
        update topics;
        Test.stopTest();

        // Then
        Integer helpfulCount = [
            SELECT COUNT() FROM Agentforce_Topic__c
            WHERE Related_Record_Id__c = :RELATED_ID AND Helpful_Count__c > 0
        ];
        Assert.isTrue(helpfulCount > 0, 'Bulk update should aggregate counts without hitting governor limits');
    }
}
