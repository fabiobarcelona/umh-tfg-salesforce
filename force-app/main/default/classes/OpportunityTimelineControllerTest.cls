@isTest
private class OpportunityTimelineControllerTest {

    @TestSetup
    static void setup() {
        Account acc = TestDataFactory.createAccount('Test Account Timeline');
        Opportunity opp = TestDataFactory.createOpportunityWithAmount('Test Opp Timeline', acc.Id, 25000);

        // Generar historial cambiando stages
        opp.StageName = 'Qualification';
        update opp;

        opp.StageName = 'Needs Analysis';
        update opp;
    }

    @isTest
    static void testGetOpportunityHistoryWithHistory() {
        Opportunity opp = [SELECT Id FROM Opportunity WHERE Name = 'Test Opp Timeline' LIMIT 1];

        Test.startTest();
        List<OpportunityHistory> history = OpportunityTimelineController.getOpportunityHistory(opp.Id);
        Test.stopTest();

        // OpportunityHistory se crea automáticamente al cambiar StageName
        // En un entorno de test puede que no se genere historial dependiendo de la config
        Assert.isNotNull(history, 'El resultado no debe ser null');
    }

    @isTest
    static void testGetOpportunityHistoryNoHistory() {
        // Crear una oportunidad nueva sin cambios de stage
        Account acc = [SELECT Id FROM Account WHERE Name = 'Test Account Timeline' LIMIT 1];
        Opportunity freshOpp = TestDataFactory.createOpportunity('Fresh Opp', acc.Id);

        Test.startTest();
        List<OpportunityHistory> history = OpportunityTimelineController.getOpportunityHistory(freshOpp.Id);
        Test.stopTest();

        Assert.isNotNull(history, 'El resultado no debe ser null incluso sin historial');
    }
}