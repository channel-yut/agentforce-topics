@isTest
private class CheckRecentEarningsTest {

    @TestSetup
    static void setup() {
        Account acc = new Account(Name = 'テスト株式会社');
        insert acc;

        // 決算サマリーTopicを作成（直近14日以内）
        Agentforce_Topic__c topic = new Agentforce_Topic__c(
            Related_Record_Id__c = acc.Id,
            Trigger_Type__c = '決算サマリー',
            Generated_Date__c = DateTime.now().addDays(-3)
        );
        insert topic;
    }

    @isTest
    static void testHasExistingTopic_found() {
        Account acc = [SELECT Id FROM Account WHERE Name = 'テスト株式会社' LIMIT 1];

        CheckRecentEarnings.Request req = new CheckRecentEarnings.Request();
        req.accountName = 'テスト株式会社';
        req.relatedRecordId = acc.Id;

        Test.startTest();
        List<CheckRecentEarnings.Result> results = CheckRecentEarnings.checkEarnings(
            new List<CheckRecentEarnings.Request>{ req }
        );
        Test.stopTest();

        System.assertEquals(1, results.size());
        System.assertEquals(true, results[0].hasExistingTopic,
            '直近14日以内の決算Topicが存在するため true であること');
        System.assertEquals(false, results[0].hasRecentEarnings,
            'スタブのため常に false であること');
        System.assertEquals('', results[0].earningsDate);
    }

    @isTest
    static void testHasExistingTopic_notFound() {
        Account acc = new Account(Name = '別の株式会社');
        insert acc;

        CheckRecentEarnings.Request req = new CheckRecentEarnings.Request();
        req.accountName = '別の株式会社';
        req.relatedRecordId = acc.Id;

        Test.startTest();
        List<CheckRecentEarnings.Result> results = CheckRecentEarnings.checkEarnings(
            new List<CheckRecentEarnings.Request>{ req }
        );
        Test.stopTest();

        System.assertEquals(1, results.size());
        System.assertEquals(false, results[0].hasExistingTopic,
            '決算Topicが存在しないため false であること');
    }

    @isTest
    static void testBlankRelatedRecordId() {
        CheckRecentEarnings.Request req = new CheckRecentEarnings.Request();
        req.accountName = 'テスト株式会社';
        req.relatedRecordId = null;

        Test.startTest();
        List<CheckRecentEarnings.Result> results = CheckRecentEarnings.checkEarnings(
            new List<CheckRecentEarnings.Request>{ req }
        );
        Test.stopTest();

        System.assertEquals(1, results.size());
        System.assertEquals(false, results[0].hasExistingTopic,
            'relatedRecordId が null の場合は false であること');
    }

    @isTest
    static void testOldTopicNotCounted() {
        Account acc = new Account(Name = '古いトピック株式会社');
        insert acc;

        // 15日以上前のTopicは対象外
        Agentforce_Topic__c oldTopic = new Agentforce_Topic__c(
            Related_Record_Id__c = acc.Id,
            Trigger_Type__c = '決算サマリー',
            Generated_Date__c = DateTime.now().addDays(-20)
        );
        insert oldTopic;

        CheckRecentEarnings.Request req = new CheckRecentEarnings.Request();
        req.accountName = '古いトピック株式会社';
        req.relatedRecordId = acc.Id;

        Test.startTest();
        List<CheckRecentEarnings.Result> results = CheckRecentEarnings.checkEarnings(
            new List<CheckRecentEarnings.Request>{ req }
        );
        Test.stopTest();

        System.assertEquals(false, results[0].hasExistingTopic,
            '14日以上前のTopicは対象外のため false であること');
    }

    @isTest
    static void testBulkInvocation() {
        Account acc = [SELECT Id FROM Account WHERE Name = 'テスト株式会社' LIMIT 1];

        List<CheckRecentEarnings.Request> reqs = new List<CheckRecentEarnings.Request>();
        for (Integer i = 0; i < 5; i++) {
            CheckRecentEarnings.Request req = new CheckRecentEarnings.Request();
            req.accountName = 'テスト' + i;
            req.relatedRecordId = i == 0 ? acc.Id : null;
            reqs.add(req);
        }

        Test.startTest();
        List<CheckRecentEarnings.Result> results = CheckRecentEarnings.checkEarnings(reqs);
        Test.stopTest();

        System.assertEquals(5, results.size());
        System.assertEquals(true, results[0].hasExistingTopic);
        for (Integer i = 1; i < 5; i++) {
            System.assertEquals(false, results[i].hasExistingTopic);
        }
    }
}
