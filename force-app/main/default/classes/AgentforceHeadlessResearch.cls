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
        description='顧客リサーチエージェントをヘッドレスで起動し、指定のリサーチを実行・保存する'
        callout=true
    )
    public static List<Result> runResearch(List<Request> requests) {
        List<Result> results = new List<Result>();
        for (Request req : requests) {
            results.add(invokeAgent(req));
        }
        return results;
    }

    private static Result invokeAgent(Request req) {
        Result res = new Result();
        try {
            String researchType = String.isBlank(req.researchType) ? '顧客リサーチ' : req.researchType;
            String userMessage = buildUserMessage(req.accountName, req.relatedRecordId, req.objectApiName, researchType);

            Invocable.Action action = Invocable.Action.createCustomAction(
                'generateAiAgentResponse',
                AGENT_API_NAME
            );
            action.setInvocationParameter('userMessage', userMessage);
            action.setInvocationParameter('sessionId', '');

            List<Invocable.Action.Result> actionResults = action.invoke();

            if (!actionResults.isEmpty() && actionResults[0].isSuccess()) {
                res.success = true;
                res.sessionId = (String) actionResults[0].getOutputParameters().get('sessionId');
                res.message = '処理を開始しました';
            } else {
                res.success = false;
                res.message = actionResults.isEmpty() ? 'エージェントの呼び出しに失敗しました' :
                    String.valueOf(actionResults[0].getErrors());
            }
        } catch (Exception e) {
            res.success = false;
            res.message = e.getMessage();
        }
        return res;
    }

    private static String buildUserMessage(String accountName, String relatedRecordId, String objectApiName, String researchType) {
        String obj      = String.isBlank(objectApiName)  ? 'Account' : sanitizeInput(objectApiName,  50);
        String recordId = String.isBlank(relatedRecordId) ? ''       : sanitizeInput(relatedRecordId, 18);
        String name     = sanitizeInput(accountName,  200);
        String rType    = sanitizeInput(researchType, 50);
        return '【自動実行】' + name + ' / ' + rType + ' / ' + recordId + ' / ' + obj;
    }

    private static String sanitizeInput(String value, Integer maxLength) {
        if (String.isBlank(value)) return '';
        // 制御文字・改行を除去してプロンプトインジェクションを防止
        String sanitized = value.replaceAll('[\\p{Cntrl}]', '').trim();
        return sanitized.length() > maxLength ? sanitized.left(maxLength) : sanitized;
    }
}
