public with sharing class OrderTrackingController {

    @AuraEnabled(cacheable=true)
    public static Shipment_Tracking__c getTrackingInfo(Id orderId) {
        List<Shipment_Tracking__c> trackings = [
            SELECT Id, Tracking_Number__c, Carrier__c, Status__c,
                   Estimated_Delivery__c, Last_API_Update__c
            FROM Shipment_Tracking__c
            WHERE Order__c = :orderId
            LIMIT 1
        ];

        if (trackings.isEmpty()) {
            return null;
        }

        Shipment_Tracking__c tracking = trackings[0];

        // Si los datos tienen más de 1 hora, actualizar desde API
        if (tracking.Last_API_Update__c == null ||
            tracking.Last_API_Update__c < System.now().addHours(-1)) {
            ShipmentTrackingService.updateTrackingInfo(tracking.Id);
        }

        return tracking;
    }

    @AuraEnabled(cacheable=true)
    public static List<Order> getCustomerOrders(Id accountId) {
        return [
            SELECT Id, OrderNumber, Status, EffectiveDate, TotalAmount,
                   Payment_Status__c, Shipping_Status__c,
                   (SELECT Id, Tracking_Number__c, Carrier__c, Status__c, Estimated_Delivery__c
                    FROM Shipment_Trackings__r)
            FROM Order
            WHERE AccountId = :accountId
            ORDER BY EffectiveDate DESC
            LIMIT 100
        ];
    }
}