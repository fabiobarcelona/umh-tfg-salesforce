@isTest
public class TestDataFactory {

    public static Account createAccount(String name) {
        Account acc = new Account(Name = name);
        insert acc;
        return acc;
    }

    public static Order createOrder(Id accountId) {
        Order ord = new Order(
            AccountId = accountId,
            EffectiveDate = Date.today(),
            Status = 'Draft'
        );
        insert ord;
        return ord;
    }

    public static Order createOrderWithPricebook(Id accountId) {
        Order ord = new Order(
            AccountId = accountId,
            EffectiveDate = Date.today(),
            Status = 'Draft',
            Pricebook2Id = Test.getStandardPricebookId()
        );
        insert ord;
        return ord;
    }

    public static Shipment_Tracking__c createShipmentTracking(Id orderId, String trackingNumber, String carrier) {
        Shipment_Tracking__c shipment = new Shipment_Tracking__c(
            Order__c = orderId,
            Tracking_Number__c = trackingNumber,
            Carrier__c = carrier
        );
        insert shipment;
        return shipment;
    }

    public static Shipment_Tracking__c createShipmentTrackingWithStatus(Id orderId, String trackingNumber, String carrier, String status) {
        Shipment_Tracking__c shipment = new Shipment_Tracking__c(
            Order__c = orderId,
            Tracking_Number__c = trackingNumber,
            Carrier__c = carrier,
            Status__c = status
        );
        insert shipment;
        return shipment;
    }

    public static Product2 createProduct(String name, String productCode) {
        Product2 prod = new Product2(
            Name = name,
            ProductCode = productCode,
            IsActive = true
        );
        insert prod;
        return prod;
    }

    public static Product2 createProductWithFamily(String name, String productCode, String description, String family) {
        Product2 prod = new Product2(
            Name = name,
            ProductCode = productCode,
            Description = description,
            Family = family,
            IsActive = true
        );
        insert prod;
        return prod;
    }

    public static PricebookEntry createStandardPricebookEntry(Id productId, Decimal unitPrice) {
        PricebookEntry pbe = new PricebookEntry(
            Pricebook2Id = Test.getStandardPricebookId(),
            Product2Id = productId,
            UnitPrice = unitPrice,
            IsActive = true
        );
        insert pbe;
        return pbe;
    }

    public static Opportunity createOpportunity(String name, Id accountId) {
        Opportunity opp = new Opportunity(
            Name = name,
            AccountId = accountId,
            StageName = 'Prospecting',
            CloseDate = Date.today().addDays(30)
        );
        insert opp;
        return opp;
    }

    public static Opportunity createOpportunityWithAmount(String name, Id accountId, Decimal amount) {
        Opportunity opp = new Opportunity(
            Name = name,
            AccountId = accountId,
            StageName = 'Prospecting',
            CloseDate = Date.today().addDays(30),
            Amount = amount
        );
        insert opp;
        return opp;
    }

    public static Opportunity createOpportunityWithPricebook(String name, Id accountId) {
        Opportunity opp = new Opportunity(
            Name = name,
            AccountId = accountId,
            StageName = 'Prospecting',
            CloseDate = Date.today().addDays(30),
            Pricebook2Id = Test.getStandardPricebookId()
        );
        insert opp;
        return opp;
    }

    public static Inventory__c createInventory(Id productId, Decimal availableStock, Decimal reorderPoint) {
        Inventory__c inv = new Inventory__c(
            Product__c = productId,
            Available_Stock__c = availableStock,
            Reserved_Stock__c = 0,
            Reorder_Point__c = reorderPoint
        );
        insert inv;
        return inv;
    }

    public static OrderItem createOrderItem(Id orderId, Id productId, Id pricebookEntryId, Decimal quantity, Decimal unitPrice) {
        OrderItem oi = new OrderItem(
            OrderId = orderId,
            Product2Id = productId,
            PricebookEntryId = pricebookEntryId,
            Quantity = quantity,
            UnitPrice = unitPrice
        );
        insert oi;
        return oi;
    }

    public static Quote createQuote(String name, Id opportunityId, String status) {
        Quote q = new Quote(
            Name = name,
            OpportunityId = opportunityId,
            Status = status
        );
        insert q;
        return q;
    }
}