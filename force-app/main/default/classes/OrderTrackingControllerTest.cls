@isTest
private class OrderTrackingControllerTest {

    @TestSetup
    static void setup() {
        Account acc = TestDataFactory.createAccount('Test Account Tracking');
        TestDataFactory.createOrder(acc.Id);
    }

    @isTest
    static void testGetTrackingInfoWithTracking() {
        Order ord = [SELECT Id FROM Order LIMIT 1];

        // El mock debe estar registrado antes de crear el Shipment_Tracking__c,
        // porque el Flow Shipment_Notification dispara un @future(callout=true)
        // al insertar el registro. Test.stopTest() ejecutará ese future con el mock activo.
        Test.setMock(HttpCalloutMock.class, new TrackingMock());

        Test.startTest();
        TestDataFactory.createShipmentTrackingWithStatus(ord.Id, 'TEST-TRACK-001', 'SEUR', 'En tránsito');
        Shipment_Tracking__c result = OrderTrackingController.getTrackingInfo(ord.Id);
        Test.stopTest();

        Assert.isNotNull(result, 'Debería devolver un registro de tracking');
        Assert.areEqual('TEST-TRACK-001', result.Tracking_Number__c, 'El número de tracking debe coincidir');
    }

    @isTest
    static void testGetTrackingInfoNoTracking() {
        Account acc = [SELECT Id FROM Account WHERE Name = 'Test Account Tracking' LIMIT 1];
        Order ordNoTracking = TestDataFactory.createOrder(acc.Id);

        Test.startTest();
        Shipment_Tracking__c result = OrderTrackingController.getTrackingInfo(ordNoTracking.Id);
        Test.stopTest();

        Assert.isNull(result, 'Debería devolver null cuando no hay tracking asociado');
    }

    @isTest
    static void testRefreshTrackingInfo() {
        Order ord = [SELECT Id FROM Order LIMIT 1];

        Test.setMock(HttpCalloutMock.class, new TrackingMock());

        Test.startTest();
        // Crear tracking sin Last_API_Update__c para forzar el refresh
        TestDataFactory.createShipmentTrackingWithStatus(ord.Id, 'TEST-TRACK-002', 'DHL', 'Pendiente de recogida');
        OrderTrackingController.refreshTrackingInfo(ord.Id);
        Test.stopTest();

        Shipment_Tracking__c updated = [
            SELECT Status__c, Last_API_Update__c
            FROM Shipment_Tracking__c
            WHERE Order__c = :ord.Id
            LIMIT 1
        ];
        Assert.isNotNull(updated.Last_API_Update__c, 'Last_API_Update__c debería estar actualizado tras el refresh');
    }

    @isTest
    static void testRefreshTrackingInfoNoTracking() {
        Account acc = [SELECT Id FROM Account WHERE Name = 'Test Account Tracking' LIMIT 1];
        Order ordNoTracking = TestDataFactory.createOrder(acc.Id);

        Test.startTest();
        // No debe lanzar excepción cuando no hay tracking
        OrderTrackingController.refreshTrackingInfo(ordNoTracking.Id);
        Test.stopTest();
    }

    @isTest
    static void testGetCustomerOrdersAsInternalUser() {
        // Un usuario interno no tiene ContactId, debe devolver lista vacía
        Test.startTest();
        List<Order> orders = OrderTrackingController.getCustomerOrders();
        Test.stopTest();

        Assert.isTrue(orders.isEmpty(), 'Un usuario interno sin Contact debe recibir lista vacía');
    }

    private class TrackingMock implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setBody('{"status":"En tránsito","estimated_delivery":"2026-03-15"}');
            res.setStatusCode(200);
            return res;
        }
    }
}