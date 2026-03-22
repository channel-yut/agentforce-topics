/**
 * @description Self-learning service for Agentforce Topics
 * Analyzes feedback patterns and generates improvement guidelines
 */
public with sharing class AgentforceSelfLearningService {

    private static final String MASTER_PREFIX = 'IMPROVEMENT_MASTER_';
    private static final Integer ANALYSIS_DAYS = 30;

    /**
     * @description Analyzes feedback patterns for a specific trigger type
     * @param triggerType The trigger type to analyze
     * @return Map containing analysis results
     */
    public static Map<String, Object> analyzeFeedbackPatterns(String triggerType) {
        // Get negative feedback from last 30 days
        List<Agentforce_Topic__c> negativeTopics = [
            SELECT Id, Content__c, Feedback_Category__c, Trigger_Type__c,
                   Summary__c, CreatedDate
            FROM Agentforce_Topic__c
            WHERE Trigger_Type__c = :triggerType
              AND Feedback__c = '役立たなかった'
              AND CreatedDate = LAST_N_DAYS:30
              AND Related_Record_Id__c != :MASTER_PREFIX + triggerType
            ORDER BY CreatedDate DESC
        ];

        // Analyze patterns
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
                        'summary' => topic.Summary__c,
                        'category' => category,
                        'date' => topic.CreatedDate.format('yyyy-MM-dd')
                    });
                }
            }
        }

        // Build analysis result
        return new Map<String, Object>{
            'total_count' => negativeTopics.size(),
            'category_breakdown' => categoryCount,
            'problem_examples' => problemExamples,
            'analysis_date' => System.now().format('yyyy-MM-dd HH:mm:ss'),
            'trigger_type' => triggerType
        };
    }

    /**
     * @description Saves improvement patterns to master record
     * @param triggerType The trigger type
     * @param analysisResult Analysis result from analyzeFeedbackPatterns
     */
    public static void saveImprovementPattern(String triggerType, Map<String, Object> analysisResult) {
        String masterId = MASTER_PREFIX + triggerType;

        // Get or create master record
        List<Agentforce_Topic__c> masters = [
            SELECT Id, Improvement_Patterns__c, Generation__c
            FROM Agentforce_Topic__c
            WHERE Related_Record_Id__c = :masterId
            LIMIT 1
        ];

        Agentforce_Topic__c master;
        Integer currentVersion = 1;

        if (masters.isEmpty()) {
            master = new Agentforce_Topic__c(
                Related_Record_Id__c = masterId,
                Trigger_Type__c = triggerType,
                Summary__c = 'Improvement Master Record for ' + triggerType,
                Content__c = '<p>自動生成された改善パターンマスターレコード</p>'
            );
        } else {
            master = masters[0];
            currentVersion = (master.Generation__c != null ? Integer.valueOf(master.Generation__c) : 0) + 1;
        }

        // Merge with existing patterns
        Map<String, Object> existingPatterns = new Map<String, Object>();
        if (String.isNotBlank(master.Improvement_Patterns__c)) {
            try {
                existingPatterns = (Map<String, Object>)JSON.deserializeUntyped(master.Improvement_Patterns__c);
            } catch (Exception e) {
                System.debug('Error parsing existing patterns: ' + e.getMessage());
            }
        }

        // Create new pattern version
        Map<String, Object> newPattern = new Map<String, Object>{
            'version' => currentVersion,
            'trigger_type' => triggerType,
            'analysis_result' => analysisResult,
            'learned_improvements' => generateImprovementGuidelines(analysisResult),
            'last_updated' => System.now().format('yyyy-MM-dd HH:mm:ss')
        };

        master.Improvement_Patterns__c = JSON.serialize(newPattern);
        master.Generation__c = currentVersion;

        upsert master;
    }

    /**
     * @description Generates improvement guidelines based on analysis
     * @param analysisResult Analysis result
     * @return List of improvement guidelines
     */
    private static List<Map<String, Object>> generateImprovementGuidelines(Map<String, Object> analysisResult) {
        List<Map<String, Object>> guidelines = new List<Map<String, Object>>();
        Map<String, Object> categoryBreakdown = (Map<String, Object>)analysisResult.get('category_breakdown');

        if (categoryBreakdown != null) {
            for (String category : categoryBreakdown.keySet()) {
                Integer count = (Integer)categoryBreakdown.get(category);
                guidelines.add(new Map<String, Object>{
                    'pattern' => category,
                    'problem' => getProblemDescription(category),
                    'solution' => getSolutionGuideline(category),
                    'sample_count' => count,
                    'effectiveness' => 0.0 // Will be calculated based on future feedback
                });
            }
        }

        return guidelines;
    }

    /**
     * @description Gets problem description for a category
     */
    private static String getProblemDescription(String category) {
        Map<String, String> descriptions = new Map<String, String>{
            '抽象的' => 'アクションやインサイトが抽象的すぎて実行できない',
            '不正確' => '提供された情報が不正確または古い',
            '無関係' => 'レコードの状況と無関係な提案がされている',
            '期限不明確' => 'ネクストアクションに具体的な期限が含まれていない',
            '数値目標なし' => '推奨事項に数値目標やKPIが含まれていない',
            'その他' => 'その他の問題'
        };
        return descriptions.containsKey(category) ? descriptions.get(category) : category;
    }

    /**
     * @description Gets solution guideline for a category
     */
    private static String getSolutionGuideline(String category) {
        Map<String, String> solutions = new Map<String, String>{
            '抽象的' => '具体的な行動、担当者、期限を明記する。例：「営業部長に報告」ではなく「山田営業部長に10/28までに報告」',
            '不正確' => 'レコードの最新データを確認し、正確な情報のみを提供する',
            '無関係' => 'レコードの現在のステージや状況を考慮した適切な提案を行う',
            '期限不明確' => '必ず「〇〇日以内」「〇月〇日まで」など具体的な期限を含める',
            '数値目標なし' => '「売上向上」ではなく「売上15%向上」など数値目標を含める',
            'その他' => 'フィードバックの詳細を確認し、改善策を検討する'
        };
        return solutions.containsKey(category) ? solutions.get(category) : 'フィードバックに基づき改善する';
    }

    /**
     * @description Gets improvement context for prompt generation
     * @param triggerType The trigger type
     * @return Formatted improvement context string for prompt
     */
    @AuraEnabled(cacheable=true)
    public static String getImprovementContext(String triggerType) {
        String masterId = MASTER_PREFIX + triggerType;

        List<Agentforce_Topic__c> masters = [
            SELECT Improvement_Patterns__c, Generation__c
            FROM Agentforce_Topic__c
            WHERE Related_Record_Id__c = :masterId
            LIMIT 1
        ];

        if (masters.isEmpty() || String.isBlank(masters[0].Improvement_Patterns__c)) {
            return ''; // No improvement patterns yet for first generation
        }

        try {
            Map<String, Object> patterns =
                (Map<String, Object>)JSON.deserializeUntyped(masters[0].Improvement_Patterns__c);
            return buildImprovementPrompt(patterns);
        } catch (Exception e) {
            System.debug('Error building improvement context: ' + e.getMessage());
            return '';
        }
    }

    /**
     * @description Builds human-readable improvement prompt
     */
    private static String buildImprovementPrompt(Map<String, Object> patterns) {
        String prompt = '\n【過去のフィードバックから学んだ改善点】\n';
        prompt += 'バージョン: v' + patterns.get('version') + '\n\n';

        Map<String, Object> analysisResult = (Map<String, Object>)patterns.get('analysis_result');
        if (analysisResult == null) {
            return prompt;
        }

        Integer totalCount = (Integer)analysisResult.get('total_count');
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

            List<Object> guidelines = (List<Object>)patterns.get('learned_improvements');
            if (guidelines != null && !guidelines.isEmpty()) {
                prompt += '\n【必ず守るべき改善指示】\n';
                Integer index = 1;
                for (Object guidelineObj : guidelines) {
                    Map<String, Object> guideline = (Map<String, Object>)guidelineObj;
                    String solution = (String)guideline.get('solution');
                    prompt += index + '. ' + solution + '\n';
                    index++;
                }
            }
        }

        return prompt;
    }

    /**
     * @description Stores learning context when topic is generated
     * @param topicId The generated topic ID
     * @param triggerType The trigger type
     * @param referencedFeedbacks List of feedback IDs that were considered
     */
    public static void storeLearningContext(String topicId, String triggerType, List<String> referencedFeedbacks) {
        Map<String, Object> context = new Map<String, Object>{
            'trigger_type' => triggerType,
            'referenced_feedbacks' => referencedFeedbacks,
            'generation_timestamp' => System.now().format('yyyy-MM-dd HH:mm:ss'),
            'improvement_applied' => !referencedFeedbacks.isEmpty()
        };

        Agentforce_Topic__c topic = new Agentforce_Topic__c(
            Id = topicId,
            Learning_Context__c = JSON.serialize(context)
        );

        update topic;
    }
}
