/**
 * @description Invocable action to trigger Customer Research Agent headlessly via Apex.
 * Sends a structured message; agent_router LLM extracts variables and routes to
 * headless_research, where deterministic run actions handle search and save.
 */
public with sharing class AgentforceHeadlessResearch {

    private static final String AGENT_API_NAME = 'Customer_Research_Agent';

    public class Request {
        @InvocableVariable(label='Account Name' required=true)
        public String accountName;

        @InvocableVariable(label='Related Record Id')
        public String relatedRecordId;

        @InvocableVariable(label='Object API Name')
        public String objectApiName;

        @InvocableVariable(label='Research Type' description='顧客リサーチ / 競合分析 / 決算サマリー')
        public String researchType;

        @InvocableVariable(label='Has Recent Earnings')
        public Boolean hasRecentEarnings;

        @InvocableVariable(label='Has Existing Earnings Topic')
        public Boolean hasExistingEarningsTopic;
    }

    public class Result {
        @InvocableVariable(label='Success')
        public Boolean success;

        @InvocableVariable(label='Message')
        public String message;

        @InvocableVariable(label='Session Id')
        public String sessionId;
    }

    @InvocableMethod(
        label='Run Customer Research Agent'
        description='顧客リサーチエージェントをヘッドレスで非同期起動する。Check_Recent_EarningsのhasRecentEarnings/hasExistingEarningsTopicを渡すことで決算サマリーの条件実行もQueueable内で行う。'
    )
    public static List<Result> runResearch(List<Request> requests) {
        List<Result> results = new List<Result>();
        for (Request req : requests) {
            Result res = new Result();
            try {
                Boolean hasEarnings      = req.hasRecentEarnings       == true;
                Boolean hasExistingTopic = req.hasExistingEarningsTopic == true;

                System.enqueueJob(new HeadlessResearchQueueable(
                    req.accountName,
                    req.relatedRecordId,
                    req.objectApiName,
                    hasEarnings,
                    hasExistingTopic
                ));

                res.success = true;
                res.message = 'リサーチをキューに登録しました';
            } catch (Exception e) {
                res.success = false;
                res.message = e.getMessage();
            }
            results.add(res);
        }
        return results;
    }
}
