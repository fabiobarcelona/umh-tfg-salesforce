public class ShipmentTrackingService {

    private static final String API_ENDPOINT = 'callout:TrackingProvider/v1/shipments';

    @future(callout=true)
    public static void updateTrackingInfo(Id shipmentId) {
        Shipment_Tracking__c shipment = [
            SELECT Id, Tracking_Number__c, Carrier__c, Order__c
            FROM Shipment_Tracking__c
            WHERE Id = :shipmentId
            LIMIT 1
        ];

        if (String.isBlank(shipment.Tracking_Number__c)) {
            System.debug('No tracking number available for shipment: ' + shipmentId);
            return;
        }

        HttpRequest req = new HttpRequest();
        req.setEndpoint(API_ENDPOINT + '/' + shipment.Tracking_Number__c);
        req.setMethod('GET');
        req.setHeader('Content-Type', 'application/json');
        req.setTimeout(12000);

        Http http = new Http();
        HttpResponse res = http.send(req);

        if (res.getStatusCode() == 200) {
            parseAndUpdateShipment(shipment, res.getBody());
        } else {
            System.debug('Error calling tracking API: ' + res.getStatus());
        }
    }

    private static void parseAndUpdateShipment(Shipment_Tracking__c shipment, String jsonBody) {
        Map<String, Object> responseData = (Map<String, Object>) JSON.deserializeUntyped(jsonBody);

        shipment.Status__c = (String) responseData.get('status');

        String estimatedDelivery = (String) responseData.get('estimated_delivery');
        if (String.isNotBlank(estimatedDelivery)) {
            shipment.Estimated_Delivery__c = Date.valueOf(estimatedDelivery);
        }

        shipment.Last_API_Update__c = System.now();

        update shipment;
    }

    // Método invocable desde Flow
    @InvocableMethod(label='Update Shipment Tracking' description='Calls external API to update shipment status')
    public static void updateTrackingInfoFromFlow(List<Id> shipmentIds) {
        for (Id shipmentId : shipmentIds) {
            updateTrackingInfo(shipmentId);
        }
    }
}