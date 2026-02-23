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
    static void testGetCustomerOrdersWithOrders() {
        Account acc = [SELECT Id FROM Account WHERE Name = 'Test Account Tracking' LIMIT 1];

        Test.startTest();
        List<Order> orders = OrderTrackingController.getCustomerOrders(acc.Id);
        Test.stopTest();

        Assert.isFalse(orders.isEmpty(), 'Debería devolver al menos un pedido');
        Assert.areEqual(1, orders.size(), 'Debería haber exactamente 1 pedido');
    }

    @isTest
    static void testGetCustomerOrdersNoOrders() {
        Account accNoOrders = TestDataFactory.createAccount('Account Sin Pedidos');

        Test.startTest();
        List<Order> orders = OrderTrackingController.getCustomerOrders(accNoOrders.Id);
        Test.stopTest();

        Assert.isTrue(orders.isEmpty(), 'No debería devolver pedidos para una cuenta sin pedidos');
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