public with sharing class OpportunityTimelineController {

    @AuraEnabled(cacheable=true)
    public static List<OpportunityHistory> getOpportunityHistory(Id opportunityId) {
        return [
            SELECT Id, OpportunityId, StageName, CreatedDate, Amount, Probability
            FROM OpportunityHistory
            WHERE OpportunityId = :opportunityId
            ORDER BY CreatedDate ASC
        ];
    }
}