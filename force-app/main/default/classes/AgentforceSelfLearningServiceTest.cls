@isTest
private class AgentforceSelfLearningServiceTest {

    private static final String TRIGGER_TYPE   = '面談記録';
    private static final String OBJECT_API     = 'Account';
    private static final String RELATED_ID_SIM = 'TEST000000000001';

    // ─────────────────────────────────────────────
    // analyzeFeedbackPatterns
    // ─────────────────────────────────────────────

    @isTest
    static void analyzeFeedbackPatterns_WithNegativeFeedback_ReturnsCounts() {
        // Given
        TestDataFactory.createTopics(5, RELATED_ID_SIM, TRIGGER_TYPE, '役立たなかった', '抽象的', true);

        // When
        Test.startTest();
        Map<String, Object> result = AgentforceSelfLearningService.analyzeFeedbackPatterns(TRIGGER_TYPE, null);
        Test.stopTest();

        // Then
        Assert.areEqual(5, (Integer)result.get('total_count'), 'Should return 5 negative feedbacks');
        Assert.areEqual(TRIGGER_TYPE, (String)result.get('trigger_type'), 'Trigger type should match');
    }

    @isTest
    static void analyzeFeedbackPatterns_WithObjectScope_ReturnsOnlyMatchingObject() {
        // Given
        TestDataFactory.createTopics(3, RELATED_ID_SIM, TRIGGER_TYPE, '役立たなかった', '不正確', true);
        // Different object — should NOT be counted
        List<Agentforce_Topic__c> otherTopics = TestDataFactory.createTopics(2, RELATED_ID_SIM, TRIGGER_TYPE, '役立たなかった', '無関係', false);
        for (Agentforce_Topic__c t : otherTopics) { t.Object_Api_Name__c = 'Opportunity'; }
        insert otherTopics;

        // When
        Test.startTest();
        Map<String, Object> result = AgentforceSelfLearningService.analyzeFeedbackPatterns(TRIGGER_TYPE, OBJECT_API);
        Test.stopTest();

        // Then — object-scoped query returns 0 because none have Object_Api_Name__c = 'Account'
        Assert.areEqual(0, (Integer)result.get('total_count'), 'Object-scoped query should return only Account topics');
    }

    @isTest
    static void analyzeFeedbackPatterns_NoNegativeFeedback_ReturnsZeroCount() {
        // Given
        TestDataFactory.createTopics(3, RELATED_ID_SIM, TRIGGER_TYPE, '役立った', null, true);

        // When
        Test.startTest();
        Map<String, Object> result = AgentforceSelfLearningService.analyzeFeedbackPatterns(TRIGGER_TYPE, null);
        Test.stopTest();

        // Then
        Assert.areEqual(0, (Integer)result.get('total_count'), 'No negative feedback should return 0');
    }

    @isTest
    static void analyzeFeedbackPatterns_CategoryBreakdown_AggregatesCorrectly() {
        // Given
        TestDataFactory.createTopics(3, RELATED_ID_SIM, TRIGGER_TYPE, '役立たなかった', '抽象的', true);
        TestDataFactory.createTopics(2, RELATED_ID_SIM, TRIGGER_TYPE, '役立たなかった', '不正確', true);

        // When
        Test.startTest();
        Map<String, Object> result = AgentforceSelfLearningService.analyzeFeedbackPatterns(TRIGGER_TYPE, null);
        Test.stopTest();

        // Then
        Assert.areEqual(5, (Integer)result.get('total_count'), 'Total count should be 5');
        Map<String, Object> breakdown = (Map<String, Object>)result.get('category_breakdown');
        Assert.isTrue(breakdown.containsKey('抽象的'), 'Breakdown should contain 抽象的');
        Assert.areEqual(3, (Integer)breakdown.get('抽象的'), '抽象的 count should be 3');
        Assert.areEqual(2, (Integer)breakdown.get('不正確'), '不正確 count should be 2');
    }

    // ─────────────────────────────────────────────
    // saveImprovementPattern
    // ─────────────────────────────────────────────

    @isTest
    static void saveImprovementPattern_FirstSave_CreatesGenerationOne() {
        // Given
        TestDataFactory.createTopics(3, RELATED_ID_SIM, TRIGGER_TYPE, '役立たなかった', '抽象的', true);
        Map<String, Object> analysis = AgentforceSelfLearningService.analyzeFeedbackPatterns(TRIGGER_TYPE, null);

        // When
        Test.startTest();
        AgentforceSelfLearningService.saveImprovementPattern(TRIGGER_TYPE, null, analysis);
        Test.stopTest();

        // Then
        List<Agentforce_Topic_Learning__c> records = [
            SELECT Generation__c, Is_Active__c, Trigger_Type__c
            FROM Agentforce_Topic_Learning__c
            WHERE Trigger_Type__c = :TRIGGER_TYPE
        ];
        Assert.areEqual(1, records.size(), 'Should create one learning record');
        Assert.areEqual(1, records[0].Generation__c.intValue(), 'First save should be generation 1');
        Assert.isTrue(records[0].Is_Active__c, 'New record should be active');
    }

    @isTest
    static void saveImprovementPattern_SecondSave_IncrementsGenerationAndDeactivatesPrevious() {
        // Given
        TestDataFactory.createLearningRecord(TRIGGER_TYPE, null, 1, true, true);
        TestDataFactory.createTopics(3, RELATED_ID_SIM, TRIGGER_TYPE, '役立たなかった', '不正確', true);
        Map<String, Object> analysis = AgentforceSelfLearningService.analyzeFeedbackPatterns(TRIGGER_TYPE, null);

        // When
        Test.startTest();
        AgentforceSelfLearningService.saveImprovementPattern(TRIGGER_TYPE, null, analysis);
        Test.stopTest();

        // Then
        List<Agentforce_Topic_Learning__c> allRecords = [
            SELECT Generation__c, Is_Active__c
            FROM Agentforce_Topic_Learning__c
            WHERE Trigger_Type__c = :TRIGGER_TYPE
            ORDER BY Generation__c ASC
        ];
        Assert.areEqual(2, allRecords.size(), 'Should have 2 records total');
        Assert.isFalse(allRecords[0].Is_Active__c, 'Previous generation should be deactivated');
        Assert.isTrue(allRecords[1].Is_Active__c, 'New generation should be active');
        Assert.areEqual(2, allRecords[1].Generation__c.intValue(), 'Second save should be generation 2');
    }

    // ─────────────────────────────────────────────
    // getImprovementContext
    // ─────────────────────────────────────────────

    @isTest
    static void getImprovementContext_WithActiveLearningRecord_ReturnsNonEmptyContext() {
        // Given
        TestDataFactory.createLearningRecord(TRIGGER_TYPE, null, 1, true, true);

        // When
        Test.startTest();
        String context = AgentforceSelfLearningService.getImprovementContext(TRIGGER_TYPE, null);
        Test.stopTest();

        // Then
        Assert.isTrue(String.isNotBlank(context), 'Context should not be blank when learning record exists');
        Assert.isTrue(context.contains('v1'), 'Context should mention generation version');
    }

    @isTest
    static void getImprovementContext_NoLearningRecord_ReturnsEmptyString() {
        // Given — no learning records inserted

        // When
        Test.startTest();
        String context = AgentforceSelfLearningService.getImprovementContext(TRIGGER_TYPE, null);
        Test.stopTest();

        // Then
        Assert.areEqual('', context, 'Context should be empty string when no learning record exists');
    }

    @isTest
    static void getImprovementContext_ObjectScopeFallback_FallsBackToTriggerTypeOnly() {
        // Given — learning record exists with triggerType only (no objectApiName)
        TestDataFactory.createLearningRecord(TRIGGER_TYPE, null, 1, true, true);

        // When — request with objectApiName that has no dedicated record
        Test.startTest();
        String context = AgentforceSelfLearningService.getImprovementContext(TRIGGER_TYPE, OBJECT_API);
        Test.stopTest();

        // Then — should fall back to triggerType-only record
        Assert.isTrue(String.isNotBlank(context), 'Should fall back to triggerType-only learning record');
    }

    @isTest
    static void getImprovementContext_BackwardCompatOverload_ReturnsContext() {
        // Given
        TestDataFactory.createLearningRecord(TRIGGER_TYPE, null, 1, true, true);

        // When
        Test.startTest();
        String context = AgentforceSelfLearningService.getImprovementContext(TRIGGER_TYPE);
        Test.stopTest();

        // Then
        Assert.isTrue(String.isNotBlank(context), '1-arg overload should also return context');
    }

    // ─────────────────────────────────────────────
    // Bulk test
    // ─────────────────────────────────────────────

    @isTest
    static void analyzeFeedbackPatterns_BulkTopics_HandlesLargeVolume() {
        // Given
        TestDataFactory.createTopics(251, RELATED_ID_SIM, TRIGGER_TYPE, '役立たなかった', '抽象的', true);

        // When
        Test.startTest();
        Map<String, Object> result = AgentforceSelfLearningService.analyzeFeedbackPatterns(TRIGGER_TYPE, null);
        Test.stopTest();

        // Then
        Assert.isTrue((Integer)result.get('total_count') > 0, 'Should handle 251+ records without hitting governor limits');
    }
}
