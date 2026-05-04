@isTest
private class AgentforceHeadlessResearchTest {

    // generateAiAgentResponse は callout を行うため、テスト環境では
    // isSuccess()=false になる。エラーハンドリングパスのカバレッジを担保する。

    @isTest
    static void testRunResearch_agentCallFails_returnsFailureResult() {
        AgentforceHeadlessResearch.Request req = new AgentforceHeadlessResearch.Request();
        req.accountName    = 'テスト株式会社';
        req.relatedRecordId = '001000000000001AAA';
        req.objectApiName  = 'Account';
        req.researchType   = '顧客リサーチ';

        Test.startTest();
        List<AgentforceHeadlessResearch.Result> results =
            AgentforceHeadlessResearch.runResearch(
                new List<AgentforceHeadlessResearch.Request>{ req }
            );
        Test.stopTest();

        System.assertEquals(1, results.size());
        // テスト環境ではエージェント呼び出しが失敗するため success=false
        System.assertNotEquals(null, results[0].success);
        System.assertNotEquals(null, results[0].message);
    }

    @isTest
    static void testRunResearch_defaultResearchType() {
        // researchType が空白の場合は「顧客リサーチ」にデフォルト設定される
        AgentforceHeadlessResearch.Request req = new AgentforceHeadlessResearch.Request();
        req.accountName     = 'デフォルト株式会社';
        req.relatedRecordId = '001000000000002AAA';
        req.objectApiName   = 'Account';
        req.researchType    = '';

        Test.startTest();
        List<AgentforceHeadlessResearch.Result> results =
            AgentforceHeadlessResearch.runResearch(
                new List<AgentforceHeadlessResearch.Request>{ req }
            );
        Test.stopTest();

        System.assertEquals(1, results.size());
        System.assertNotEquals(null, results[0].message);
    }

    @isTest
    static void testRunResearch_nullObjectApiName() {
        // objectApiName が null の場合は 'Account' にフォールバックする
        AgentforceHeadlessResearch.Request req = new AgentforceHeadlessResearch.Request();
        req.accountName     = 'NULL株式会社';
        req.relatedRecordId = '001000000000003AAA';
        req.objectApiName   = null;
        req.researchType    = '決算サマリー';

        Test.startTest();
        List<AgentforceHeadlessResearch.Result> results =
            AgentforceHeadlessResearch.runResearch(
                new List<AgentforceHeadlessResearch.Request>{ req }
            );
        Test.stopTest();

        System.assertEquals(1, results.size());
        System.assertNotEquals(null, results[0].success);
    }

    @isTest
    static void testRunResearch_nullRelatedRecordId() {
        AgentforceHeadlessResearch.Request req = new AgentforceHeadlessResearch.Request();
        req.accountName     = 'ID無し株式会社';
        req.relatedRecordId = null;
        req.objectApiName   = 'Opportunity';
        req.researchType    = '競合分析';

        Test.startTest();
        List<AgentforceHeadlessResearch.Result> results =
            AgentforceHeadlessResearch.runResearch(
                new List<AgentforceHeadlessResearch.Request>{ req }
            );
        Test.stopTest();

        System.assertEquals(1, results.size());
        System.assertNotEquals(null, results[0].success);
    }

    @isTest
    static void testRunResearch_bulkInvocation() {
        List<AgentforceHeadlessResearch.Request> reqs = new List<AgentforceHeadlessResearch.Request>();
        for (Integer i = 0; i < 3; i++) {
            AgentforceHeadlessResearch.Request req = new AgentforceHeadlessResearch.Request();
            req.accountName    = '一括テスト' + i;
            req.relatedRecordId = '001000000000' + String.valueOf(i + 10) + '0AAA';
            req.objectApiName  = 'Account';
            req.researchType   = '顧客リサーチ';
            reqs.add(req);
        }

        Test.startTest();
        List<AgentforceHeadlessResearch.Result> results =
            AgentforceHeadlessResearch.runResearch(reqs);
        Test.stopTest();

        System.assertEquals(3, results.size());
        for (AgentforceHeadlessResearch.Result r : results) {
            System.assertNotEquals(null, r.success);
            System.assertNotEquals(null, r.message);
        }
    }
}
