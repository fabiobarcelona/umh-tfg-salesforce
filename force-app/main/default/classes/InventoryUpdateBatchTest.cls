@isTest
private class InventoryUpdateBatchTest {

    @TestSetup
    static void setup() {
        Product2 prod = TestDataFactory.createProduct('Test Product Batch', 'TST-BATCH-001');
        PricebookEntry stdPbe = TestDataFactory.createStandardPricebookEntry(prod.Id, 100);

        Account acc = TestDataFactory.createAccount('Test Account Batch');
        Order ord = TestDataFactory.createOrderWithPricebook(acc.Id);

        // Inventario con stock bajo el punto de reposición (debe existir antes del OrderItem para el flow)
        TestDataFactory.createInventory(prod.Id, 15, 10);

        TestDataFactory.createOrderItem(ord.Id, prod.Id, stdPbe.Id, 3, 100);
    }

    @isTest
    static void testBatchUpdatesReservedStock() {
        Test.startTest();
        Id batchId = Database.executeBatch(new InventoryUpdateBatch(), 200);
        Test.stopTest();

        Inventory__c inv = [
            SELECT Reserved_Stock__c, Available_Stock__c
            FROM Inventory__c
            LIMIT 1
        ];

        Assert.areEqual(3, inv.Reserved_Stock__c, 'El stock reservado debería ser 3 (del OrderItem)');
    }

    @isTest
    static void testBatchCreatesAlertTaskWhenBelowReorderPoint() {
        // Actualizar inventario para que esté por debajo del punto de reposición
        Inventory__c inv = [SELECT Id FROM Inventory__c LIMIT 1];
        inv.Available_Stock__c = 5;
        inv.Reorder_Point__c = 10;
        update inv;

        Test.startTest();
        Database.executeBatch(new InventoryUpdateBatch(), 200);
        Test.stopTest();

        List<Task> alerts = [
            SELECT Subject, Priority
            FROM Task
            WHERE Subject LIKE '%stock bajo%'
        ];

        Assert.isFalse(alerts.isEmpty(), 'Debería haberse creado una tarea de alerta de stock bajo');
        Assert.areEqual('High', alerts[0].Priority, 'La prioridad de la alerta debe ser High');
    }

    @isTest
    static void testBatchNoAlertWhenAboveReorderPoint() {
        // Actualizar inventario para que esté por encima del punto de reposición
        Inventory__c inv = [SELECT Id FROM Inventory__c LIMIT 1];
        inv.Available_Stock__c = 50;
        inv.Reorder_Point__c = 10;
        update inv;

        Test.startTest();
        Database.executeBatch(new InventoryUpdateBatch(), 200);
        Test.stopTest();

        List<Task> alerts = [
            SELECT Id
            FROM Task
            WHERE Subject LIKE '%stock bajo%'
        ];

        Assert.isTrue(alerts.isEmpty(), 'No debería crearse alerta cuando el stock está por encima del punto de reposición');
    }

    @isTest
    static void testBatchNoOrdersZeroReserved() {
        // Eliminar los OrderItems para que no haya stock reservado
        delete [SELECT Id FROM OrderItem];

        Test.startTest();
        Database.executeBatch(new InventoryUpdateBatch(), 200);
        Test.stopTest();

        Inventory__c inv = [
            SELECT Reserved_Stock__c
            FROM Inventory__c
            LIMIT 1
        ];

        Assert.areEqual(0, inv.Reserved_Stock__c, 'Sin OrderItems, el stock reservado debe ser 0');
    }
}