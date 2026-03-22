/**
 * @description Weekly scheduler for automatic feedback pattern analysis
 * Runs every Monday at 9 AM to analyze feedback and update improvement patterns
 */
global class WeeklyFeedbackAnalysisScheduler implements Schedulable {

    global void execute(SchedulableContext sc) {
        // Get all active trigger types
        List<String> triggerTypes = getTriggerTypes();

        Integer totalAnalyzed = 0;
        Integer totalImproved = 0;
        List<String> reportLines = new List<String>();

        // Analyze each trigger type
        for (String triggerType : triggerTypes) {
            try {
                // Analyze feedback patterns
                Map<String, Object> analysis =
                    AgentforceSelfLearningService.analyzeFeedbackPatterns(triggerType);

                Integer feedbackCount = (Integer)analysis.get('total_count');
                totalAnalyzed += feedbackCount;

                // Save improvement patterns if there's negative feedback
                if (feedbackCount > 0) {
                    AgentforceSelfLearningService.saveImprovementPattern(triggerType, analysis);
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

        // Send weekly report to administrators
        if (totalAnalyzed > 0) {
            sendWeeklyReport(totalAnalyzed, totalImproved, reportLines);
        }
    }

    /**
     * @description Gets all active trigger types from picklist
     */
    private List<String> getTriggerTypes() {
        List<String> triggerTypes = new List<String>();

        // Get picklist values from Trigger_Type__c field
        Schema.DescribeFieldResult fieldResult =
            Agentforce_Topic__c.Trigger_Type__c.getDescribe();
        List<Schema.PicklistEntry> entries = fieldResult.getPicklistValues();

        for (Schema.PicklistEntry entry : entries) {
            if (entry.isActive()) {
                triggerTypes.add(entry.getValue());
            }
        }

        return triggerTypes;
    }

    /**
     * @description Builds report line for a trigger type
     */
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

    /**
     * @description Sends weekly analysis report to administrators
     */
    private void sendWeeklyReport(
        Integer totalAnalyzed,
        Integer totalImproved,
        List<String> reportLines
    ) {
        // Get system administrators
        List<User> admins = [
            SELECT Email
            FROM User
            WHERE Profile.Name = 'System Administrator'
              AND IsActive = true
            LIMIT 50
        ];

        if (admins.isEmpty()) {
            return;
        }

        List<String> toAddresses = new List<String>();
        for (User admin : admins) {
            if (String.isNotBlank(admin.Email)) {
                toAddresses.add(admin.Email);
            }
        }

        if (toAddresses.isEmpty()) {
            return;
        }

        // Build email body
        String emailBody = buildEmailBody(totalAnalyzed, totalImproved, reportLines);

        // Send email
        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
        mail.setToAddresses(toAddresses);
        mail.setSubject('【Agentforce Topics】週次フィードバック分析レポート - ' + System.today().format());
        mail.setPlainTextBody(emailBody);
        mail.setHtmlBody(emailBody.replace('\n', '<br/>'));

        try {
            Messaging.sendEmail(new List<Messaging.SingleEmailMessage>{ mail });
        } catch (Exception e) {
            System.debug('Error sending weekly report email: ' + e.getMessage());
        }
    }

    /**
     * @description Builds email body for weekly report
     */
    private String buildEmailBody(
        Integer totalAnalyzed,
        Integer totalImproved,
        List<String> reportLines
    ) {
        String body = '==============================================\n';
        body += '  Agentforce Topics 週次フィードバック分析レポート\n';
        body += '==============================================\n\n';
        body += '分析期間: 過去30日間\n';
        body += '実行日時: ' + System.now().format('yyyy年MM月dd日 HH:mm') + '\n\n';

        body += '【サマリー】\n';
        body += '総フィードバック数: ' + totalAnalyzed + '件\n';
        body += '改善パターン更新: ' + totalImproved + 'トリガータイプ\n\n';

        if (!reportLines.isEmpty()) {
            body += '【詳細】\n';
            body += String.join(reportLines, '\n') + '\n';
        }

        body += '\n【アクション】\n';
        body += '改善パターンは自動的に次回のトピック生成時に反映されます。\n';
        body += 'さらなる改善が必要な場合は、プロンプトテンプレートの見直しをご検討ください。\n\n';

        body += '詳細は Agentforce_Topic__c オブジェクトのレコード\n';
        body += '(Related_Record_Id__c が "IMPROVEMENT_MASTER_" で始まるもの) をご確認ください。\n\n';

        body += '==============================================\n';
        body += 'このメールは自動送信されています。\n';

        return body;
    }

    /**
     * @description Schedules this job to run every Monday at 9 AM
     * Execute in Anonymous Apex:
     *
     * WeeklyFeedbackAnalysisScheduler scheduler = new WeeklyFeedbackAnalysisScheduler();
     * String cronExp = '0 0 9 ? * MON';
     * System.schedule('Agentforce Topics Weekly Feedback Analysis', cronExp, scheduler);
     */
    public static void scheduleWeeklyJob() {
        String cronExp = '0 0 9 ? * MON'; // Every Monday at 9 AM
        String jobName = 'Agentforce Topics Weekly Feedback Analysis';

        // Check if job already exists
        List<CronTrigger> existingJobs = [
            SELECT Id, CronJobDetail.Name
            FROM CronTrigger
            WHERE CronJobDetail.Name = :jobName
        ];

        // Delete existing job if found
        for (CronTrigger job : existingJobs) {
            System.abortJob(job.Id);
        }

        // Schedule new job
        System.schedule(jobName, cronExp, new WeeklyFeedbackAnalysisScheduler());
    }
}
