public with sharing class WebSearchAction {

    public class Request {
        @InvocableVariable(
            label='Search Query'
            description='Search query string to look up on the web'
            required=true
        )
        public String searchQuery;
    }

    public class Result {
        @InvocableVariable(
            label='Search Results'
            description='Web search results as plain text'
        )
        public String searchResults;
    }

    @InvocableMethod(
        label='Search Web'
        description='Searches the web for the given query and returns results as text'
        callout=true
    )
    public static List<Result> search(List<Request> requests) {
        List<Result> results = new List<Result>();

        for (Request req : requests) {
            Result r = new Result();
            // Stub: returns placeholder until web search callout is implemented
            r.searchResults = 'Web search results for "' + req.searchQuery + '": '
                + 'This is a stub implementation. '
                + 'Please implement actual web search callout logic here.';
            results.add(r);
        }

        return results;
    }
}
