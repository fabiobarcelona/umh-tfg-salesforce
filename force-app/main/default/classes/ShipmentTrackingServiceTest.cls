@isTest
private class ShipmentTrackingServiceTest {

    @isTest
    static void testUpdateTrackingInfoSuccess() {
        Account acc = TestDataFactory.createAccount('Test Account');
        Order ord = TestDataFactory.createOrder(acc.Id);
        Shipment_Tracking__c shipment = TestDataFactory.createShipmentTracking(ord.Id, 'TRACK123456', 'SEUR');

        Test.setMock(HttpCalloutMock.class, new ShipmentTrackingMock());

        Test.startTest();
        ShipmentTrackingService.updateTrackingInfo(shipment.Id);
        Test.stopTest();

        Shipment_Tracking__c updatedShipment = [
            SELECT Status__c, Estimated_Delivery__c, Last_API_Update__c
            FROM Shipment_Tracking__c
            WHERE Id = :shipment.Id
        ];

        Assert.areEqual('En tránsito', updatedShipment.Status__c, 'El estado debería ser En tránsito');
        Assert.isNotNull(updatedShipment.Last_API_Update__c, 'La fecha de última actualización no debería ser nula');
    }

    @isTest
    static void testUpdateTrackingInfoNoTrackingNumber() {
        Account acc = TestDataFactory.createAccount('Test Account 2');
        Order ord = TestDataFactory.createOrder(acc.Id);
        Shipment_Tracking__c shipment = TestDataFactory.createShipmentTracking(ord.Id, null, 'MRW');

        Test.startTest();
        ShipmentTrackingService.updateTrackingInfo(shipment.Id);
        Test.stopTest();

        // No debería haber lanzado excepción y el status no cambia
        Shipment_Tracking__c updatedShipment = [
            SELECT Status__c, Last_API_Update__c
            FROM Shipment_Tracking__c
            WHERE Id = :shipment.Id
        ];

        Assert.isNull(updatedShipment.Last_API_Update__c, 'No debería haberse actualizado la fecha');
    }

    @isTest
    static void testUpdateTrackingInfoFromFlow() {
        Account acc = TestDataFactory.createAccount('Test Account 3');
        Order ord = TestDataFactory.createOrder(acc.Id);
        Shipment_Tracking__c shipment = TestDataFactory.createShipmentTracking(ord.Id, 'FLOW123456', 'SEUR');

        Test.setMock(HttpCalloutMock.class, new ShipmentTrackingMock());

        Test.startTest();
        ShipmentTrackingService.updateTrackingInfoFromFlow(new List<Id>{ shipment.Id });
        Test.stopTest();

        Shipment_Tracking__c updatedShipment = [
            SELECT Status__c
            FROM Shipment_Tracking__c
            WHERE Id = :shipment.Id
        ];

        Assert.areEqual('En tránsito', updatedShipment.Status__c, 'El estado debería actualizarse via Flow también');
    }

    // Clase mock para simular la respuesta de la API
    private class ShipmentTrackingMock implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setBody('{"status":"En tránsito","estimated_delivery":"2026-03-01"}');
            res.setStatusCode(200);
            return res;
        }
    }
}