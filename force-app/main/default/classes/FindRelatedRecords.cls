public with sharing class FindRelatedRecords {

    public class Request {
        @InvocableVariable(label='Account Name' description='Name of the account to search for' required=true)
        public String accountName;
    }

    public class Result {
        @InvocableVariable(label='Reset Value' description='Always returns empty string. Used to reset topic_id variable between searches.')
        public String resetValue;

        @InvocableVariable(label='Account ID' description='Salesforce ID of the matched Account')
        public String accountId;

        @InvocableVariable(label='Account Name' description='Name of the matched Account')
        public String accountName;

        @InvocableVariable(label='Has Account' description='True if a matching Account was found')
        public Boolean hasAccount;

        @InvocableVariable(label='Opportunity ID' description='Salesforce ID of an open Opportunity linked to the Account')
        public String opportunityId;

        @InvocableVariable(label='Opportunity Name' description='Name of the open Opportunity')
        public String opportunityName;

        @InvocableVariable(label='Has Opportunity' description='True if an open Opportunity was found')
        public Boolean hasOpportunity;

        @InvocableVariable(label='Candidate Summary' description='Human-readable summary of found records for the agent to present to the user')
        public String candidateSummary;
    }

    @InvocableMethod(
        label='Find Related Records'
        description='Searches for an Account matching the given name and returns any open Opportunities linked to it'
    )
    public static List<Result> findRecords(List<Request> requests) {
        List<Result> results = new List<Result>();

        for (Request req : requests) {
            Result r = new Result();
            r.resetValue = '';
            r.hasAccount = false;
            r.hasOpportunity = false;
            r.accountId = '';
            r.accountName = '';
            r.opportunityId = '';
            r.opportunityName = '';
            r.candidateSummary = '';

            if (String.isBlank(req.accountName)) {
                results.add(r);
                continue;
            }

            String searchName = '%' + req.accountName + '%';

            List<Account> accounts = [
                SELECT Id, Name
                FROM Account
                WHERE Name LIKE :searchName
                ORDER BY LastModifiedDate DESC
                LIMIT 1
            ];

            if (!accounts.isEmpty()) {
                Account acc = accounts[0];
                r.hasAccount = true;
                r.accountId = acc.Id;
                r.accountName = acc.Name;

                List<Opportunity> opps = [
                    SELECT Id, Name
                    FROM Opportunity
                    WHERE AccountId = :acc.Id
                      AND IsClosed = false
                    ORDER BY LastModifiedDate DESC
                    LIMIT 1
                ];

                if (!opps.isEmpty()) {
                    r.hasOpportunity = true;
                    r.opportunityId = opps[0].Id;
                    r.opportunityName = opps[0].Name;
                    r.candidateSummary = '取引先「' + acc.Name + '」（ID: ' + acc.Id + '）、商談「' + opps[0].Name + '」（ID: ' + opps[0].Id + '）';
                } else {
                    r.candidateSummary = '取引先「' + acc.Name + '」（ID: ' + acc.Id + '）';
                }
            }

            results.add(r);
        }

        return results;
    }
}
