/**
 * @description Self-learning service for Agentforce Topics.
 * Analyzes feedback patterns and persists improvement guidelines
 * to Agentforce_Topic_Learning__c, scoped per object/trigger type.
 */
public with sharing class AgentforceSelfLearningService {

    private static final Integer ANALYSIS_DAYS = 30;

    // ─────────────────────────────────────────────
    // Public API
    // ─────────────────────────────────────────────

    /**
     * @description Analyzes negative feedback patterns for a given scope.
     * @param triggerType  Trigger type to analyze
     * @param objectApiName  Optional Salesforce object API name (e.g. 'Account'). Pass null to analyze all objects.
     * @return Map containing analysis results
     */
    public static Map<String, Object> analyzeFeedbackPatterns(String triggerType, String objectApiName) {
        if (!Schema.SObjectType.Agentforce_Topic__c.isAccessible()) {
            return new Map<String, Object>{ 'total_count' => 0 };
        }
        List<Agentforce_Topic__c> negativeTopics = queryNegativeTopics(triggerType, objectApiName);

        Map<String, Integer> categoryCount = new Map<String, Integer>();
        List<Map<String, String>> problemExamples = new List<Map<String, String>>();

        for (Agentforce_Topic__c topic : negativeTopics) {
            String category = topic.Feedback_Category__c;
            if (String.isNotBlank(category)) {
                Integer count = categoryCount.containsKey(category)
                    ? categoryCount.get(category) + 1
                    : 1;
                categoryCount.put(category, count);

                if (problemExamples.size() < 5) {
                    problemExamples.add(new Map<String, String>{
                        'summary'  => topic.Summary__c,
                        'category' => category,
                        'date'     => topic.CreatedDate.format('yyyy-MM-dd')
                    });
                }
            }
        }

        return new Map<String, Object>{
            'total_count'        => negativeTopics.size(),
            'category_breakdown' => categoryCount,
            'problem_examples'   => problemExamples,
            'analysis_date'      => System.now().format('yyyy-MM-dd HH:mm:ss'),
            'trigger_type'       => triggerType,
            'object_api_name'    => objectApiName
        };
    }

    /**
     * @description Saves improvement patterns to Agentforce_Topic_Learning__c.
     * Marks the new record as active and deactivates previous ones for the same scope.
     * @param triggerType      Trigger type
     * @param objectApiName    Optional Salesforce object API name
     * @param analysisResult   Result from analyzeFeedbackPatterns
     */
    public static void saveImprovementPattern(String triggerType, String objectApiName, Map<String, Object> analysisResult) {
        Integer nextGeneration = getNextGeneration(triggerType, objectApiName);

        // Build new learning record
        Agentforce_Topic_Learning__c newRecord = new Agentforce_Topic_Learning__c(
            Trigger_Type__c           = triggerType,
            Object_Api_Name__c        = objectApiName,
            Generation__c             = nextGeneration,
            Is_Active__c              = true,
            Analysis_Date__c          = System.now(),
            Negative_Feedback_Count__c = (Integer)analysisResult.get('total_count'),
            Analysis_Result__c        = JSON.serialize(analysisResult),
            Improvement_Patterns__c   = JSON.serialize(generateImprovementGuidelines(analysisResult))
        );

        insert newRecord;

        // Deactivate previous active records for this scope
        deactivatePreviousRecords(newRecord.Id, triggerType, objectApiName);
    }

    /**
     * @description Returns formatted improvement context for prompt injection.
     * Looks up the active learning record for the given scope.
     * Falls back to triggerType-only scope when objectApiName is provided but has no record yet.
     * @param triggerType    Trigger type
     * @param objectApiName  Optional Salesforce object API name
     * @return Formatted improvement context string, or empty string if none exists
     */
    @AuraEnabled(cacheable=true)
    public static String getImprovementContext(String triggerType, String objectApiName) {
        Agentforce_Topic_Learning__c record = getActiveLearningRecord(triggerType, objectApiName);

        // Fallback: try without object scope
        if (record == null && String.isNotBlank(objectApiName)) {
            record = getActiveLearningRecord(triggerType, null);
        }

        if (record == null || String.isBlank(record.Improvement_Patterns__c)) {
            return '';
        }

        try {
            List<Object> patterns = (List<Object>)JSON.deserializeUntyped(record.Improvement_Patterns__c);
            Map<String, Object> analysisResult = String.isNotBlank(record.Analysis_Result__c)
                ? (Map<String, Object>)JSON.deserializeUntyped(record.Analysis_Result__c)
                : new Map<String, Object>();
            return buildImprovementPrompt(patterns, analysisResult, (Integer)record.Generation__c);
        } catch (Exception e) {
            System.debug('Error building improvement context: ' + e.getMessage());
            return '';
        }
    }

    /**
     * @description Backward-compatible overload (triggerType only). Not exposed to LWC directly.
     */
    public static String getImprovementContext(String triggerType) {
        return getImprovementContext(triggerType, null);
    }

    /**
     * @description Stores learning context on a generated topic record.
     */
    public static void storeLearningContext(String topicId, String triggerType, List<String> referencedFeedbacks) {
        Map<String, Object> context = new Map<String, Object>{
            'trigger_type'          => triggerType,
            'referenced_feedbacks'  => referencedFeedbacks,
            'generation_timestamp'  => System.now().format('yyyy-MM-dd HH:mm:ss'),
            'improvement_applied'   => !referencedFeedbacks.isEmpty()
        };

        Agentforce_Topic__c topicToUpdate = new Agentforce_Topic__c(
            Id                  = topicId,
            Learning_Context__c = JSON.serialize(context)
        );
        update topicToUpdate;
    }

    // ─────────────────────────────────────────────
    // Private helpers
    // ─────────────────────────────────────────────

    private static List<Agentforce_Topic__c> queryNegativeTopics(String triggerType, String objectApiName) {
        if (String.isNotBlank(objectApiName)) {
            return [
                SELECT Id, Content__c, Feedback_Category__c, Trigger_Type__c,
                       Summary__c, CreatedDate
                FROM Agentforce_Topic__c
                WHERE Trigger_Type__c = :triggerType
                  AND Object_Api_Name__c = :objectApiName
                  AND Feedback__c = '役立たなかった'
                  AND CreatedDate = LAST_N_DAYS:30
                ORDER BY CreatedDate DESC
            ];
        }
        return [
            SELECT Id, Content__c, Feedback_Category__c, Trigger_Type__c,
                   Summary__c, CreatedDate
            FROM Agentforce_Topic__c
            WHERE Trigger_Type__c = :triggerType
              AND Feedback__c = '役立たなかった'
              AND CreatedDate = LAST_N_DAYS:30
            ORDER BY CreatedDate DESC
        ];
    }

    private static Integer getNextGeneration(String triggerType, String objectApiName) {
        List<Agentforce_Topic_Learning__c> existing = getActiveLearningRecords(triggerType, objectApiName, 1);
        if (existing.isEmpty()) {
            return 1;
        }
        return (existing[0].Generation__c != null ? Integer.valueOf(existing[0].Generation__c) : 0) + 1;
    }

    private static void deactivatePreviousRecords(Id excludeId, String triggerType, String objectApiName) {
        List<Agentforce_Topic_Learning__c> toDeactivate = new List<Agentforce_Topic_Learning__c>();
        for (Agentforce_Topic_Learning__c rec : getActiveLearningRecords(triggerType, objectApiName, 200)) {
            if (rec.Id != excludeId) {
                rec.Is_Active__c = false;
                toDeactivate.add(rec);
            }
        }
        if (!toDeactivate.isEmpty()) {
            update toDeactivate;
        }
    }

    private static Agentforce_Topic_Learning__c getActiveLearningRecord(String triggerType, String objectApiName) {
        List<Agentforce_Topic_Learning__c> records = getActiveLearningRecords(triggerType, objectApiName, 1);
        return records.isEmpty() ? null : records[0];
    }

    private static List<Agentforce_Topic_Learning__c> getActiveLearningRecords(String triggerType, String objectApiName, Integer lim) {
        if (String.isNotBlank(objectApiName)) {
            return [
                SELECT Id, Generation__c, Is_Active__c, Improvement_Patterns__c, Analysis_Result__c
                FROM Agentforce_Topic_Learning__c
                WHERE Trigger_Type__c = :triggerType
                  AND Object_Api_Name__c = :objectApiName
                  AND Is_Active__c = true
                ORDER BY Generation__c DESC
                LIMIT :lim
            ];
        }
        return [
            SELECT Id, Generation__c, Is_Active__c, Improvement_Patterns__c, Analysis_Result__c
            FROM Agentforce_Topic_Learning__c
            WHERE Trigger_Type__c = :triggerType
              AND Object_Api_Name__c = null
              AND Is_Active__c = true
            ORDER BY Generation__c DESC
            LIMIT :lim
        ];
    }

    private static List<Map<String, Object>> generateImprovementGuidelines(Map<String, Object> analysisResult) {
        List<Map<String, Object>> guidelines = new List<Map<String, Object>>();
        Map<String, Object> categoryBreakdown = (Map<String, Object>)analysisResult.get('category_breakdown');

        if (categoryBreakdown != null) {
            for (String category : categoryBreakdown.keySet()) {
                Integer count = (Integer)categoryBreakdown.get(category);
                guidelines.add(new Map<String, Object>{
                    'pattern'      => category,
                    'problem'      => getProblemDescription(category),
                    'solution'     => getSolutionGuideline(category),
                    'sample_count' => count,
                    'effectiveness' => 0.0
                });
            }
        }

        return guidelines;
    }

    private static String buildImprovementPrompt(List<Object> guidelines, Map<String, Object> analysisResult, Integer generation) {
        String prompt = '\n【過去のフィードバックから学んだ改善点】\n';
        prompt += 'バージョン: v' + generation + '\n\n';

        Integer totalCount = analysisResult.containsKey('total_count')
            ? (Integer)analysisResult.get('total_count') : 0;
        prompt += '過去' + ANALYSIS_DAYS + '日間で「役立たなかった」フィードバック: ' + totalCount + '件\n\n';

        if (totalCount > 0) {
            Map<String, Object> categoryBreakdown = (Map<String, Object>)analysisResult.get('category_breakdown');
            if (categoryBreakdown != null && !categoryBreakdown.isEmpty()) {
                prompt += '【主な問題パターン】\n';
                for (String category : categoryBreakdown.keySet()) {
                    Integer count = (Integer)categoryBreakdown.get(category);
                    prompt += '- ' + category + ': ' + count + '件\n';
                }
            }

            if (guidelines != null && !guidelines.isEmpty()) {
                prompt += '\n【必ず守るべき改善指示】\n';
                Integer index = 1;
                for (Object guidelineObj : guidelines) {
                    Map<String, Object> guideline = (Map<String, Object>)guidelineObj;
                    prompt += index + '. ' + (String)guideline.get('solution') + '\n';
                    index++;
                }
            }
        }

        return prompt;
    }

    private static String getProblemDescription(String category) {
        Map<String, String> descriptions = new Map<String, String>{
            '抽象的'      => 'アクションやインサイトが抽象的すぎて実行できない',
            '不正確'      => '提供された情報が不正確または古い',
            '無関係'      => 'レコードの状況と無関係な提案がされている',
            '期限不明確'  => 'ネクストアクションに具体的な期限が含まれていない',
            '数値目標なし' => '推奨事項に数値目標やKPIが含まれていない',
            'その他'      => 'その他の問題'
        };
        return descriptions.containsKey(category) ? descriptions.get(category) : category;
    }

    private static String getSolutionGuideline(String category) {
        Map<String, String> solutions = new Map<String, String>{
            '抽象的'      => '具体的な行動、担当者、期限を明記する。例：「営業部長に報告」ではなく「山田営業部長に10/28までに報告」',
            '不正確'      => 'レコードの最新データを確認し、正確な情報のみを提供する',
            '無関係'      => 'レコードの現在のステージや状況を考慮した適切な提案を行う',
            '期限不明確'  => '必ず「〇〇日以内」「〇月〇日まで」など具体的な期限を含める',
            '数値目標なし' => '「売上向上」ではなく「売上15%向上」など数値目標を含める',
            'その他'      => 'フィードバックの詳細を確認し、改善策を検討する'
        };
        return solutions.containsKey(category) ? solutions.get(category) : 'フィードバックに基づき改善する';
    }
}
