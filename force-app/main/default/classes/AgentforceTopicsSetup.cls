/**
 * @description Post-install setup utility for Agentforce Topics.
 * Run from Anonymous Apex after deployment to enable/disable the scheduler.
 *
 * Usage:
 *   AgentforceTopicsSetup.enableScheduler();   // Production: enable auto-analysis
 *   AgentforceTopicsSetup.disableScheduler();  // Demo: disable auto-analysis
 *   AgentforceTopicsSetup.getStatus();         // Check current state
 */
public with sharing class AgentforceTopicsSetup {

    /**
     * @description Enables the feedback analysis scheduler.
     * Frequency is read from Agentforce_Topics_Config__mdt (Default record).
     */
    public static void enableScheduler() {
        WeeklyFeedbackAnalysisScheduler.enableScheduler();
        System.debug('Agentforce Topics: scheduler enabled.');
    }

    /**
     * @description Disables (aborts) the feedback analysis scheduler.
     * Config record is not modified — toggle Analysis_Enabled__c via Setup UI.
     */
    public static void disableScheduler() {
        WeeklyFeedbackAnalysisScheduler.disableScheduler();
        System.debug('Agentforce Topics: scheduler disabled.');
    }

    /**
     * @description Prints current scheduler and config status to debug log.
     */
    public static void getStatus() {
        List<Agentforce_Topics_Config__mdt> configs = [
            SELECT Analysis_Enabled__c, Analysis_Frequency__c, Min_Feedback_Count__c
            FROM Agentforce_Topics_Config__mdt
            WHERE DeveloperName = 'Default'
            LIMIT 1
        ];

        if (configs.isEmpty()) {
            System.debug('Config: Default record not found.');
        } else {
            Agentforce_Topics_Config__mdt c = configs[0];
            System.debug('Config: Enabled=' + c.Analysis_Enabled__c
                + ', Frequency=' + c.Analysis_Frequency__c
                + ', MinCount=' + c.Min_Feedback_Count__c);
        }

        List<CronTrigger> jobs = [
            SELECT Id, State, NextFireTime
            FROM CronTrigger
            WHERE CronJobDetail.Name = 'Agentforce Topics Feedback Analysis'
        ];

        if (jobs.isEmpty()) {
            System.debug('Scheduler: not scheduled.');
        } else {
            CronTrigger job = jobs[0];
            System.debug('Scheduler: State=' + job.State + ', NextFireTime=' + job.NextFireTime);
        }
    }
}
