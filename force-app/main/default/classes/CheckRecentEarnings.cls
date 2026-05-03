public with sharing class CheckRecentEarnings {

    public class Request {
        @InvocableVariable(
            label='Account Name'
            description='Name of the account to check for recent earnings'
            required=true
        )
        public String accountName;

        @InvocableVariable(
            label='Related Record Id'
            description='ID of the related record (optional)'
            required=false
        )
        public String relatedRecordId;
    }

    public class Result {
        @InvocableVariable(
            label='Has Recent Earnings'
            description='True if the account had an earnings announcement within the last 2 weeks'
        )
        public Boolean hasRecentEarnings;

        @InvocableVariable(
            label='Has Existing Topic'
            description='True if an earnings Agentforce Topic already exists for this account'
        )
        public Boolean hasExistingTopic;

        @InvocableVariable(
            label='Earnings Date'
            description='Date of the most recent earnings announcement (if found)'
        )
        public String earningsDate;
    }

    @InvocableMethod(
        label='Check Recent Earnings'
        description='Checks whether the account had an earnings announcement in the last 2 weeks and whether an earnings Agentforce Topic already exists'
    )
    public static List<Result> checkEarnings(List<Request> requests) {
        List<Result> results = new List<Result>();

        for (Request req : requests) {
            Result r = new Result();

            r.hasExistingTopic = hasExistingEarningsTopic(req.relatedRecordId);

            // Stub: hasRecentEarnings is always false until web search logic is implemented
            r.hasRecentEarnings = false;
            r.earningsDate = '';

            results.add(r);
        }

        return results;
    }

    private static Boolean hasExistingEarningsTopic(String relatedRecordId) {
        if (String.isBlank(relatedRecordId)) {
            return false;
        }

        List<Agentforce_Topic__c> existing = [
            SELECT Id
            FROM Agentforce_Topic__c
            WHERE Related_Record_Id__c = :relatedRecordId
              AND Trigger_Type__c = '決算サマリー'
              AND Generated_Date__c >= :DateTime.now().addDays(-14)
            LIMIT 1
        ];

        return !existing.isEmpty();
    }
}
