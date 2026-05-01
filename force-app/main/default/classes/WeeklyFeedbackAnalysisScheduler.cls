/**
 * @description Scheduled job for automatic feedback pattern analysis.
 * Controlled by Agentforce_Topics_Config__mdt (Default record).
 * Enable/disable from Setup → Custom Metadata Types → Agentforce Topics Config → Manage Records.
 */
global without sharing class WeeklyFeedbackAnalysisScheduler implements Schedulable {

    private static final String JOB_NAME   = 'Agentforce Topics Feedback Analysis';
    private static final String CRON_DAILY  = '0 0 9 * * ?';
    private static final String CRON_WEEKLY = '0 0 9 ? * MON';

    global void execute(SchedulableContext sc) {
        Agentforce_Topics_Config__mdt config = getConfig();

        if (!config.Analysis_Enabled__c) {
            System.debug('Agentforce Topics: analysis disabled via config. Skipping.');
            return;
        }

        Integer minCount = config.Min_Feedback_Count__c != null
            ? config.Min_Feedback_Count__c.intValue()
            : 5;

        // Count only feedbacks since the last analysis run
        List<Agentforce_Topic_Learning__c> lastRun = [
            SELECT Analysis_Date__c
            FROM Agentforce_Topic_Learning__c
            ORDER BY Analysis_Date__c DESC
            LIMIT 1
        ];
        DateTime sinceDate = lastRun.isEmpty() ? DateTime.newInstance(1900, 1, 1) : lastRun[0].Analysis_Date__c;

        Integer unanalyzedCount = [
            SELECT COUNT()
            FROM Agentforce_Topic__c
            WHERE Feedback__c = '役立たなかった'
              AND CreatedDate > :sinceDate
        ];

        if (unanalyzedCount < minCount) {
            System.debug('Agentforce Topics: new feedback count (' + unanalyzedCount + ') below threshold (' + minCount + '). Skipping.');
            return;
        }

        runAnalysis();
    }

    private void runAnalysis() {
        List<String> triggerTypes = getTriggerTypes();
        Integer totalAnalyzed = 0;
        Integer totalImproved = 0;
        List<String> reportLines = new List<String>();

        for (String triggerType : triggerTypes) {
            try {
                Map<String, Object> analysis =
                    AgentforceSelfLearningService.analyzeFeedbackPatterns(triggerType, null);

                Integer feedbackCount = (Integer)analysis.get('total_count');
                totalAnalyzed += feedbackCount;

                if (feedbackCount > 0) {
                    AgentforceSelfLearningService.saveImprovementPattern(triggerType, null, analysis);
                    totalImproved++;

                    Map<String, Object> categoryBreakdown =
                        (Map<String, Object>)analysis.get('category_breakdown');
                    reportLines.add(buildTriggerTypeReport(triggerType, feedbackCount, categoryBreakdown));
                }
            } catch (Exception e) {
                System.debug('Error analyzing trigger type ' + triggerType + ': ' + e.getMessage());
                reportLines.add('❌ ' + triggerType + ': エラーが発生しました - ' + e.getMessage());
            }
        }

        if (totalAnalyzed > 0) {
            sendReport(totalAnalyzed, totalImproved, reportLines);
        }
    }

    private static Agentforce_Topics_Config__mdt getConfig() {
        List<Agentforce_Topics_Config__mdt> configs = [
            SELECT Analysis_Enabled__c, Analysis_Frequency__c, Min_Feedback_Count__c, Admin_Profile_Name__c
            FROM Agentforce_Topics_Config__mdt
            WHERE DeveloperName = 'Default'
            LIMIT 1
        ];
        if (!configs.isEmpty()) {
            return configs[0];
        }
        // Fallback: disabled with safe defaults
        Agentforce_Topics_Config__mdt fallback = new Agentforce_Topics_Config__mdt();
        fallback.Analysis_Enabled__c   = false;
        fallback.Min_Feedback_Count__c = 5;
        fallback.Analysis_Frequency__c = 'Weekly';
        return fallback;
    }

    private List<String> getTriggerTypes() {
        List<String> triggerTypes = new List<String>();
        Schema.DescribeFieldResult fieldResult =
            Agentforce_Topic__c.Trigger_Type__c.getDescribe();
        for (Schema.PicklistEntry entry : fieldResult.getPicklistValues()) {
            if (entry.isActive()) {
                triggerTypes.add(entry.getValue());
            }
        }
        return triggerTypes;
    }

    private String buildTriggerTypeReport(
        String triggerType,
        Integer feedbackCount,
        Map<String, Object> categoryBreakdown
    ) {
        String report = '📊 ' + triggerType + ': ' + feedbackCount + '件の「役立たなかった」フィードバック\n';
        if (categoryBreakdown != null && !categoryBreakdown.isEmpty()) {
            report += '   問題カテゴリ:\n';
            for (String category : categoryBreakdown.keySet()) {
                Integer count = (Integer)categoryBreakdown.get(category);
                report += '   - ' + category + ': ' + count + '件\n';
            }
        }
        return report;
    }

    private void sendReport(Integer totalAnalyzed, Integer totalImproved, List<String> reportLines) {
        Agentforce_Topics_Config__mdt config = getConfig();
        String profileName = String.isNotBlank(config.Admin_Profile_Name__c)
            ? config.Admin_Profile_Name__c
            : 'System Administrator';

        List<User> admins = [
            SELECT Email FROM User
            WHERE Profile.Name = :profileName AND IsActive = true
            LIMIT 50
        ];
        if (admins.isEmpty()) return;

        List<String> toAddresses = new List<String>();
        for (User admin : admins) {
            if (String.isNotBlank(admin.Email)) toAddresses.add(admin.Email);
        }
        if (toAddresses.isEmpty()) return;

        String body = buildEmailBody(totalAnalyzed, totalImproved, reportLines);
        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
        mail.setToAddresses(toAddresses);
        mail.setSubject('【Agentforce Topics】フィードバック分析レポート - ' + System.today().format());
        mail.setPlainTextBody(body);
        mail.setHtmlBody(String.escapeSingleQuotes(body).replace('\n', '<br/>'));

        try {
            Messaging.sendEmail(new List<Messaging.SingleEmailMessage>{ mail });
        } catch (Exception e) {
            System.debug('Error sending report email: ' + e.getMessage());
        }
    }

    private String buildEmailBody(Integer totalAnalyzed, Integer totalImproved, List<String> reportLines) {
        String body = '==============================================\n';
        body += '  Agentforce Topics フィードバック分析レポート\n';
        body += '==============================================\n\n';
        body += '実行日時: ' + System.now().format('yyyy年MM月dd日 HH:mm') + '\n\n';
        body += '【サマリー】\n';
        body += '総フィードバック数: ' + totalAnalyzed + '件\n';
        body += '改善パターン更新: ' + totalImproved + 'トリガータイプ\n\n';
        if (!reportLines.isEmpty()) {
            body += '【詳細】\n';
            body += String.join(reportLines, '\n') + '\n';
        }
        body += '\n改善パターンは次回のトピック生成時に自動反映されます。\n';
        body += '==============================================\n';
        body += 'このメールは自動送信されています。\n';
        return body;
    }

    /**
     * @description Schedules this job based on config frequency (Daily/Weekly).
     * Safe to call repeatedly — aborts any existing job first.
     */
    public static void enableScheduler() {
        abortExistingJob();
        Agentforce_Topics_Config__mdt config = [
            SELECT Analysis_Frequency__c
            FROM Agentforce_Topics_Config__mdt
            WHERE DeveloperName = 'Default'
            LIMIT 1
        ];
        String cronExp = (config.Analysis_Frequency__c == 'Daily') ? CRON_DAILY : CRON_WEEKLY;
        System.schedule(JOB_NAME, cronExp, new WeeklyFeedbackAnalysisScheduler());
    }

    /**
     * @description Aborts the scheduled job without disabling the config.
     */
    public static void disableScheduler() {
        abortExistingJob();
    }

    private static void abortExistingJob() {
        for (CronTrigger job : [
            SELECT Id FROM CronTrigger
            WHERE CronJobDetail.Name = :JOB_NAME
        ]) {
            System.abortJob(job.Id);
        }
    }
}
