public class HeadlessResearchQueueable implements Queueable, Database.AllowsCallouts {

    private static final String AGENT_API_NAME = 'Customer_Research_Agent';

    private final String accountName;
    private final String relatedRecordId;
    private final String objectApiName;
    private final Boolean hasRecentEarnings;
    private final Boolean hasExistingEarningsTopic;

    public HeadlessResearchQueueable(
        String accountName,
        String relatedRecordId,
        String objectApiName,
        Boolean hasRecentEarnings,
        Boolean hasExistingEarningsTopic
    ) {
        this.accountName             = accountName;
        this.relatedRecordId         = relatedRecordId;
        this.objectApiName           = objectApiName;
        this.hasRecentEarnings       = hasRecentEarnings;
        this.hasExistingEarningsTopic = hasExistingEarningsTopic;
    }

    public void execute(QueueableContext ctx) {
        invokeAgent(accountName, relatedRecordId, objectApiName, '顧客リサーチ');

        if (hasRecentEarnings == true && hasExistingEarningsTopic == false) {
            invokeAgent(accountName, relatedRecordId, objectApiName, '決算サマリー');
        }
    }

    private static void invokeAgent(String accountName, String relatedRecordId, String objectApiName, String researchType) {
        String userMessage = buildUserMessage(accountName, relatedRecordId, objectApiName, researchType);

        Invocable.Action action = Invocable.Action.createCustomAction(
            'generateAiAgentResponse',
            AGENT_API_NAME
        );
        action.setInvocationParameter('userMessage', userMessage);
        action.setInvocationParameter('sessionId', '');
        action.invoke();
    }

    private static String buildUserMessage(String accountName, String relatedRecordId, String objectApiName, String researchType) {
        String obj      = String.isBlank(objectApiName)   ? 'Account' : sanitize(objectApiName,  50);
        String recordId = String.isBlank(relatedRecordId) ? ''        : sanitize(relatedRecordId, 18);
        String name     = sanitize(accountName,  200);
        String rType    = sanitize(researchType, 50);
        return '【自動実行】' + name + ' / ' + rType + ' / ' + recordId + ' / ' + obj;
    }

    private static String sanitize(String value, Integer maxLength) {
        if (String.isBlank(value)) return '';
        String s = value.replaceAll('[\\p{Cntrl}]', '').trim();
        return s.length() > maxLength ? s.left(maxLength) : s;
    }
}
