@isTest
private class WeeklyFeedbackAnalysisSchedulerTest {

    private static final String RELATED_ID  = 'TEST000000000001';
    private static final String TRIGGER_TYPE = '面談記録';
    private static final String JOB_NAME    = 'Agentforce Topics Feedback Analysis';

    // ─────────────────────────────────────────────
    // execute() — config disabled (fallback)
    // ─────────────────────────────────────────────

    @isTest
    static void execute_ConfigDisabled_SkipsAnalysis() {
        // Given — no feedback data, config Default record has Analysis_Enabled=false (default)
        // When
        Test.startTest();
        WeeklyFeedbackAnalysisScheduler scheduler = new WeeklyFeedbackAnalysisScheduler();
        scheduler.execute(null);
        Test.stopTest();

        // Then — no learning records created
        Integer learningCount = [SELECT COUNT() FROM Agentforce_Topic_Learning__c];
        Assert.areEqual(0, learningCount, 'No learning records should be created when analysis is disabled');
    }

    // ─────────────────────────────────────────────
    // execute() — below minimum feedback threshold
    // ─────────────────────────────────────────────

    @isTest
    static void execute_BelowMinFeedbackThreshold_SkipsAnalysis() {
        // Given — config Default record min=5, only 3 feedbacks
        // (config is read from org metadata; Default record has Min_Feedback_Count__c=5, Enabled=false)
        // We test the threshold path by calling execute directly with a low count
        TestDataFactory.createTopics(3, RELATED_ID, TRIGGER_TYPE, '役立たなかった', '抽象的', true);

        // When — execute directly (config is disabled in test org, so it skips anyway)
        Test.startTest();
        WeeklyFeedbackAnalysisScheduler scheduler = new WeeklyFeedbackAnalysisScheduler();
        scheduler.execute(null);
        Test.stopTest();

        // Then — analysis skipped (either due to disabled flag or threshold)
        Integer learningCount = [SELECT COUNT() FROM Agentforce_Topic_Learning__c];
        Assert.areEqual(0, learningCount, 'Analysis should be skipped when below threshold or disabled');
    }

    // ─────────────────────────────────────────────
    // disableScheduler()
    // ─────────────────────────────────────────────

    @isTest
    static void disableScheduler_NoExistingJob_DoesNotThrow() {
        // Given — no scheduled job exists

        // When / Then — should not throw
        Test.startTest();
        try {
            WeeklyFeedbackAnalysisScheduler.disableScheduler();
            Assert.isTrue(true, 'disableScheduler with no existing job should not throw');
        } catch (Exception e) {
            Assert.fail('disableScheduler should not throw: ' + e.getMessage());
        }
        Test.stopTest();
    }

    @isTest
    static void disableScheduler_ExistingJob_AbortsJob() {
        // Given — schedule a job first
        Test.startTest();
        System.schedule(JOB_NAME, '0 0 9 ? * MON', new WeeklyFeedbackAnalysisScheduler());

        // When
        WeeklyFeedbackAnalysisScheduler.disableScheduler();
        Test.stopTest();

        // Then — job should be aborted
        Integer jobCount = [
            SELECT COUNT() FROM CronTrigger
            WHERE CronJobDetail.Name = :JOB_NAME
              AND State != 'DELETED'
        ];
        Assert.areEqual(0, jobCount, 'Job should be aborted after disableScheduler');
    }

    // ─────────────────────────────────────────────
    // enableScheduler()
    // ─────────────────────────────────────────────

    @isTest
    static void enableScheduler_RegistersJob() {
        // When
        Test.startTest();
        WeeklyFeedbackAnalysisScheduler.enableScheduler();
        Test.stopTest();

        // Then
        List<CronTrigger> jobs = [
            SELECT Id, State FROM CronTrigger
            WHERE CronJobDetail.Name = :JOB_NAME
        ];
        Assert.areEqual(1, jobs.size(), 'enableScheduler should register exactly one job');
    }

    @isTest
    static void enableScheduler_CalledTwice_DoesNotCreateDuplicates() {
        // When — call twice
        Test.startTest();
        WeeklyFeedbackAnalysisScheduler.enableScheduler();
        WeeklyFeedbackAnalysisScheduler.enableScheduler();
        Test.stopTest();

        // Then — still only one job
        Integer jobCount = [
            SELECT COUNT() FROM CronTrigger
            WHERE CronJobDetail.Name = :JOB_NAME
              AND State != 'DELETED'
        ];
        Assert.areEqual(1, jobCount, 'Calling enableScheduler twice should not create duplicate jobs');
    }

    // ─────────────────────────────────────────────
    // execute() — enabled path (runAnalysis coverage)
    // ─────────────────────────────────────────────

    @isTest
    static void execute_EnabledWithSufficientFeedback_RunsAnalysis() {
        // Given — enough negative feedback to exceed threshold
        TestDataFactory.createTopics(6, RELATED_ID, TRIGGER_TYPE, '役立たなかった', '抽象的', true);
        WeeklyFeedbackAnalysisScheduler.testOverrideEnabled = true;

        // When
        Test.startTest();
        WeeklyFeedbackAnalysisScheduler scheduler = new WeeklyFeedbackAnalysisScheduler();
        scheduler.execute(null);
        Test.stopTest();

        // Then — learning record should be created
        Integer learningCount = [SELECT COUNT() FROM Agentforce_Topic_Learning__c];
        Assert.isTrue(learningCount > 0, 'Learning record should be created when analysis runs');
    }

    @isTest
    static void execute_EnabledBelowThreshold_SkipsRunAnalysis() {
        // Given — only 1 negative feedback (below default threshold of 5)
        TestDataFactory.createTopics(1, RELATED_ID, TRIGGER_TYPE, '役立たなかった', '抽象的', true);
        WeeklyFeedbackAnalysisScheduler.testOverrideEnabled = true;

        // When
        Test.startTest();
        WeeklyFeedbackAnalysisScheduler scheduler = new WeeklyFeedbackAnalysisScheduler();
        scheduler.execute(null);
        Test.stopTest();

        // Then — no learning record because count is below threshold
        Integer learningCount = [SELECT COUNT() FROM Agentforce_Topic_Learning__c];
        Assert.areEqual(0, learningCount, 'No learning record when feedback count below threshold');
    }

    // ─────────────────────────────────────────────
    // Scheduled execution via System.schedule
    // ─────────────────────────────────────────────

    @isTest
    static void scheduledExecution_RunsWithoutException() {
        // When
        Test.startTest();
        String jobId = System.schedule(
            'Test Agentforce Scheduler',
            '0 0 9 ? * MON',
            new WeeklyFeedbackAnalysisScheduler()
        );
        Test.stopTest();

        // Then — job registered successfully
        Assert.isTrue(String.isNotBlank(jobId), 'System.schedule should return a valid job ID');
    }
}
