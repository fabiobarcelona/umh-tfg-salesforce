public with sharing class ProductSearchController {

    @AuraEnabled(cacheable=true)
    public static List<Product2> searchProducts(String searchTerm) {
        String likePattern = '%' + searchTerm + '%';
        return [
            SELECT Id, Name, ProductCode, Description, Family,
                   (SELECT Id, UnitPrice, Pricebook2Id FROM PricebookEntries WHERE Pricebook2.IsStandard = true LIMIT 1)
            FROM Product2
            WHERE IsActive = true
            AND (Name LIKE :likePattern OR ProductCode LIKE :likePattern OR Description LIKE :likePattern)
            ORDER BY Name ASC
            LIMIT 50
        ];
    }

    @AuraEnabled
    public static void addProductsToOpportunity(Id opportunityId, List<Map<String, Object>> products) {
        Opportunity opp = [
            SELECT Id, Pricebook2Id
            FROM Opportunity
            WHERE Id = :opportunityId
            LIMIT 1
        ];

        List<OpportunityLineItem> lineItems = new List<OpportunityLineItem>();

        for (Map<String, Object> product : products) {
            Id productId = (Id) product.get('productId');
            Integer quantity = Integer.valueOf(product.get('quantity'));
            Decimal discount = Decimal.valueOf(String.valueOf(product.get('discount')));

            PricebookEntry pbe = [
                SELECT Id, UnitPrice
                FROM PricebookEntry
                WHERE Product2Id = :productId
                AND Pricebook2Id = :opp.Pricebook2Id
                LIMIT 1
            ];

            OpportunityLineItem oli = new OpportunityLineItem(
                OpportunityId = opportunityId,
                PricebookEntryId = pbe.Id,
                Quantity = quantity,
                UnitPrice = pbe.UnitPrice,
                Discount = discount
            );
            lineItems.add(oli);
        }

        if (!lineItems.isEmpty()) {
            insert lineItems;
        }
    }
}