@isTest
private class ProductSearchControllerTest {

    @TestSetup
    static void setup() {
        Product2 prod = TestDataFactory.createProductWithFamily(
            'Servidor HP ProLiant', 'SRV-HP-001', 'Servidor de alto rendimiento', 'Hardware'
        );
        TestDataFactory.createStandardPricebookEntry(prod.Id, 5000);

        Account acc = TestDataFactory.createAccount('Test Account Search');
        TestDataFactory.createOpportunityWithPricebook('Test Opp Search', acc.Id);
    }

    @isTest
    static void testSearchProductsByName() {
        Test.startTest();
        List<Product2> results = ProductSearchController.searchProducts('Servidor');
        Test.stopTest();

        Assert.isFalse(results.isEmpty(), 'Debería encontrar al menos un producto con "Servidor"');
        Assert.areEqual('Servidor HP ProLiant', results[0].Name, 'El nombre del producto debe coincidir');
    }

    @isTest
    static void testSearchProductsByProductCode() {
        Test.startTest();
        List<Product2> results = ProductSearchController.searchProducts('SRV-HP');
        Test.stopTest();

        Assert.isFalse(results.isEmpty(), 'Debería encontrar al menos un producto por código');
    }

    @isTest
    static void testSearchProductsNoResults() {
        Test.startTest();
        List<Product2> results = ProductSearchController.searchProducts('ProductoInexistente12345');
        Test.stopTest();

        Assert.isTrue(results.isEmpty(), 'No debería encontrar productos con un término inexistente');
    }

    @isTest
    static void testAddProductsToOpportunity() {
        Opportunity opp = [SELECT Id FROM Opportunity WHERE Name = 'Test Opp Search' LIMIT 1];
        Product2 prod = [SELECT Id FROM Product2 WHERE ProductCode = 'SRV-HP-001' LIMIT 1];

        List<Map<String, Object>> products = new List<Map<String, Object>>();
        Map<String, Object> productMap = new Map<String, Object>();
        productMap.put('productId', prod.Id);
        productMap.put('quantity', 2);
        productMap.put('discount', 10);
        products.add(productMap);

        Test.startTest();
        ProductSearchController.addProductsToOpportunity(opp.Id, products);
        Test.stopTest();

        List<OpportunityLineItem> lineItems = [
            SELECT Id, Quantity, Discount
            FROM OpportunityLineItem
            WHERE OpportunityId = :opp.Id
        ];

        Assert.areEqual(1, lineItems.size(), 'Debería haberse creado un OpportunityLineItem');
        Assert.areEqual(2, lineItems[0].Quantity, 'La cantidad debe ser 2');
        Assert.areEqual(10, lineItems[0].Discount, 'El descuento debe ser 10%');
    }
}