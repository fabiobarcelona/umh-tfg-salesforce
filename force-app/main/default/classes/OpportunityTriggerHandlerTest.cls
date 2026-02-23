@isTest
private class OpportunityTriggerHandlerTest {

    @TestSetup
    static void setup() {
        Account acc = TestDataFactory.createAccount('Test Account Trigger');
        TestDataFactory.createOpportunityWithAmount('Test Opp Trigger', acc.Id, 10000);
    }

    @isTest
    static void testCloseWonWithoutQuoteShouldFail() {
        Opportunity opp = [SELECT Id, StageName FROM Opportunity WHERE Name = 'Test Opp Trigger' LIMIT 1];
        opp.StageName = 'Closed Won';

        Test.startTest();
        Database.SaveResult result = Database.update(opp, false);
        Test.stopTest();

        Assert.isFalse(result.isSuccess(), 'No debería permitir cerrar sin un presupuesto sincronizado');
        Assert.isTrue(
            result.getErrors()[0].getMessage().contains('presupuesto sincronizado'),
            'El error debe mencionar la falta de presupuesto sincronizado'
        );
    }

    @isTest
    static void testCloseWonWithNonAcceptedQuoteShouldFail() {
        Opportunity opp = [SELECT Id, StageName FROM Opportunity WHERE Name = 'Test Opp Trigger' LIMIT 1];
        Quote q = TestDataFactory.createQuote('Test Quote', opp.Id, 'Draft');

        // Sincronizar el quote con la oportunidad
        opp.SyncedQuoteId = q.Id;
        update opp;

        opp.StageName = 'Closed Won';

        Test.startTest();
        Database.SaveResult result = Database.update(opp, false);
        Test.stopTest();

        Assert.isFalse(result.isSuccess(), 'No debería permitir cerrar con un presupuesto no aceptado');
        Assert.isTrue(
            result.getErrors()[0].getMessage().contains('Aceptado'),
            'El error debe mencionar que el presupuesto debe estar Aceptado'
        );
    }

    @isTest
    static void testCloseWonWithAcceptedSyncedQuoteShouldSucceed() {
        Opportunity opp = [SELECT Id, StageName FROM Opportunity WHERE Name = 'Test Opp Trigger' LIMIT 1];
        Quote q = TestDataFactory.createQuote('Test Quote', opp.Id, 'Accepted');

        // Sincronizar el quote con la oportunidad
        opp.SyncedQuoteId = q.Id;
        update opp;

        opp.StageName = 'Closed Won';

        Test.startTest();
        Database.SaveResult result = Database.update(opp, false);
        Test.stopTest();

        Assert.isTrue(result.isSuccess(), 'Debería permitir cerrar con un presupuesto sincronizado y aceptado');
    }

    @isTest
    static void testStageChangeNotToClosedWonShouldSucceed() {
        Opportunity opp = [SELECT Id, StageName FROM Opportunity WHERE Name = 'Test Opp Trigger' LIMIT 1];
        opp.StageName = 'Qualification';

        Test.startTest();
        Database.SaveResult result = Database.update(opp, false);
        Test.stopTest();

        Assert.isTrue(result.isSuccess(), 'Cambiar a un stage distinto de Closed Won no deberia fallar');
    }

    @isTest
    static void testStageChangeAlreadyClosedWonShouldNotRevalidate() {
        Opportunity opp = [SELECT Id, StageName FROM Opportunity WHERE Name = 'Test Opp Trigger' LIMIT 1];
        opp.StageName = 'Needs Analysis';
        update opp;

        opp.StageName = 'Proposal';

        Test.startTest();
        Database.SaveResult result = Database.update(opp, false);
        Test.stopTest();

        Assert.isTrue(result.isSuccess(), 'Transiciones entre stages normales no deberian disparar validacion de Quote');
    }
}