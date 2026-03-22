/**
 * @description Service class for generating Agentforce Topics using AI
 * Integrates with Einstein AI and Prompt Templates
 */
public with sharing class AgentforceTopicGeneratorService {

    /**
     * @description Generates an Agentforce Topic for a given record
     * @param recordId The ID of the record to analyze
     * @param triggerType The type of event that triggered this generation
     * @return The ID of the newly created Agentforce_Topic__c record
     */
    public static String generateTopicForRecord(String recordId, String triggerType) {
        try {
            // Get record data
            String recordData = getRecordData(recordId);
            String recordType = getRecordType(recordId);

            // Call AI to generate insights (placeholder for actual Einstein AI integration)
            // In production, this would call Einstein AI with the prompt template
            Map<String, String> aiResponse = generateAIInsights(recordType, recordId, triggerType, recordData);

            // Create Agentforce_Topic__c record
            Agentforce_Topic__c newTopic = new Agentforce_Topic__c(
                Related_Record_Id__c = recordId,
                Content__c = aiResponse.get('content'),
                Summary__c = aiResponse.get('summary'),
                Trigger_Type__c = triggerType,
                Generated_Date__c = System.now()
            );

            insert newTopic;
            return newTopic.Id;

        } catch (Exception e) {
            System.debug('Error generating topic: ' + e.getMessage());
            throw new AuraHandledException('Failed to generate topic: ' + e.getMessage());
        }
    }

    /**
     * @description Retrieves record data for AI analysis
     * @param recordId The record ID
     * @return JSON string of record data
     */
    private static String getRecordData(String recordId) {
        // Determine object type from ID
        Id recId = (Id)recordId;
        String objectType = recId.getSObjectType().getDescribe().getName();

        // Build dynamic SOQL to get relevant fields
        List<String> fields = new List<String>();

        // Get common fields based on object type
        if (objectType == 'Account') {
            fields.addAll(new List<String>{'Name', 'Industry', 'AnnualRevenue', 'Description', 'Phone', 'Website'});
        } else if (objectType == 'Opportunity') {
            fields.addAll(new List<String>{'Name', 'StageName', 'Amount', 'CloseDate', 'Description', 'Probability'});
        } else if (objectType == 'Lead') {
            fields.addAll(new List<String>{'Name', 'Company', 'Status', 'Email', 'Phone', 'Description'});
        } else {
            fields.addAll(new List<String>{'Name'});
        }

        // Build and execute query
        String query = 'SELECT ' + String.join(fields, ', ') + ' FROM ' + objectType + ' WHERE Id = :recordId LIMIT 1';
        List<SObject> records = Database.query(query);

        if (records.isEmpty()) {
            return '{}';
        }

        // Convert to JSON
        return JSON.serialize(records[0]);
    }

    /**
     * @description Gets the object type name for a record ID
     * @param recordId The record ID
     * @return The object API name
     */
    private static String getRecordType(String recordId) {
        Id recId = (Id)recordId;
        return recId.getSObjectType().getDescribe().getName();
    }

    /**
     * @description Calls AI service to generate insights
     * This is a placeholder for actual Einstein AI integration
     * @param recordType The object type
     * @param recordId The record ID
     * @param triggerType The trigger event type
     * @param recordData The record data as JSON
     * @return Map with 'content' and 'summary' keys
     */
    private static Map<String, String> generateAIInsights(
        String recordType,
        String recordId,
        String triggerType,
        String recordData
    ) {
        // Get improvement context from self-learning service
        String improvementContext = AgentforceSelfLearningService.getImprovementContext(triggerType);

        // PLACEHOLDER: In production, integrate with Einstein AI / Prompt Builder
        // Example integration code:
        /*
        ConnectApi.EinsteinPromptTemplateGenerationsInput input =
            new ConnectApi.EinsteinPromptTemplateGenerationsInput();
        input.promptTemplateApiName = 'AgentforceTopicGenerator';
        input.inputParams = new Map<String, String>{
            'recordType' => recordType,
            'recordId' => recordId,
            'triggerType' => triggerType,
            'recordData' => recordData,
            'improvementContext' => improvementContext
        };

        ConnectApi.EinsteinLlmGenerationItemOutput response =
            ConnectApi.EinsteinLLM.generateMessagesForPromptTemplate(input);

        String generatedContent = response.generations[0].text;
        */

        // For now, return a sample response with improvement context indicator
        String sampleContent = buildSampleContent(recordType, triggerType, improvementContext);
        String sampleSummary = buildSampleSummary(recordType, triggerType);

        return new Map<String, String>{
            'content' => sampleContent,
            'summary' => sampleSummary
        };
    }

    /**
     * @description Builds sample content for demonstration
     * @param recordType The object type
     * @param triggerType The trigger type
     * @param improvementContext Improvement context from self-learning
     */
    private static String buildSampleContent(String recordType, String triggerType, String improvementContext) {
        String content = '';

        // Show improvement context indicator if available
        if (String.isNotBlank(improvementContext)) {
            content += '<div style="background-color:#f4f6f9;padding:10px;margin-bottom:15px;border-left:4px solid #0070d2;">' +
                       '<p><strong>🔄 自己学習適用:</strong> 過去のフィードバックから学んだ改善点を反映しています</p>' +
                       '</div>';
        }

        content += '<h3>ネクストアクション</h3>' +
                   '<ul>' +
                   '<li><strong>10/28週までに</strong>フォローアップミーティングをスケジューリング（営業部長承認済み）</li>' +
                   '<li><strong>3営業日以内に</strong>提案資料を更新し、CTO宛に送付</li>' +
                   '<li><strong>本日中に</strong>技術チームとの連携を確認（担当：田中）</li>' +
                   '</ul>' +
                   '<h3>推奨事項</h3>' +
                   '<p><strong>重要：</strong>競合分析資料の準備を推奨します。顧客は複数社を比較検討している段階です。</p>' +
                   '<p><strong>目標：</strong>提案の受注率を<strong>15%向上</strong>させることを目指します。</p>' +
                   '<h3>主要インサイト</h3>' +
                   '<p>顧客のビジネス拡大に伴い、現在のソリューションでは対応が難しくなっています。' +
                   'スケーラビリティを重視した提案を行うことで、成約率が向上する見込みです。</p>';

        return content;
    }

    /**
     * @description Builds sample summary for demonstration
     */
    private static String buildSampleSummary(String recordType, String triggerType) {
        return triggerType + 'に基づく分析結果です。フォローアップミーティングの実施と競合比較資料の準備を推奨します。';
    }

    /**
     * @description Invocable method for Flow integration
     * Allows this service to be called from Salesforce Flows
     */
    @InvocableMethod(label='Generate Agentforce Topic'
                     description='Generates an AI-powered topic for a record'
                     category='Agentforce')
    public static List<String> generateTopicFromFlow(List<FlowInput> inputs) {
        List<String> topicIds = new List<String>();

        for (FlowInput input : inputs) {
            String topicId = generateTopicForRecord(input.recordId, input.triggerType);
            topicIds.add(topicId);
        }

        return topicIds;
    }

    /**
     * @description Input class for Flow integration
     */
    public class FlowInput {
        @InvocableVariable(label='Record ID' required=true)
        public String recordId;

        @InvocableVariable(label='Trigger Type' required=true)
        public String triggerType;
    }
}
