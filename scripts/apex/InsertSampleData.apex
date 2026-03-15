/**
 * Script de datos de muestra para IT Solutions TFG
 * Ejecutar como: Anonymous Apex en Developer Console o VS Code
 *
 * Cubre todos los filtros de los reports y dashboards:
 *  - Pipeline por Etapa (oportunidades abiertas, no Closed Won/Lost)
 *  - Oportunidades Ganadas Este Mes (Closed Won, CLOSE_DATE = THIS_MONTH)
 *  - Oportunidades Sin Actividad 30 Días (abiertas, LAST_ACTIVITY < 30 días)
 *  - Descuentos Pendientes Aprobación (Approval_Status__c = Pendiente)
 *  - Casos Abiertos por Cola (Status != Closed, agrupado por Queue/Owner)
 *  - Casos por Tipo y Estado (Matrix: TYPE x STATUS)
 *  - Tiempo Medio Resolución (Status = Closed, con ClosedDate)
 *  - Productos Bajo Reorder Point (Available_Stock__c < Reorder_Point__c)
 *  - Stock Disponible vs Reservado (todos los registros Inventory__c)
 */

// =========================================================
// 1. ACCOUNTS
// =========================================================
List<Account> accounts = new List<Account>{
    new Account(Name='TechCorp Madrid', Industry='Technology', Phone='911234567',
                BillingCity='Madrid', BillingCountry='Spain'),
    new Account(Name='Distribuciones García', Industry='Retail', Phone='931234567',
                BillingCity='Barcelona', BillingCountry='Spain'),
    new Account(Name='Innovatech Solutions', Industry='Technology', Phone='961234567',
                BillingCity='Valencia', BillingCountry='Spain'),
    new Account(Name='Grupo Hernández', Industry='Finance', Phone='951234567',
                BillingCity='Sevilla', BillingCountry='Spain'),
    new Account(Name='Logística Norte', Industry='Transportation', Phone='944234567',
                BillingCity='Bilbao', BillingCountry='Spain'),
    new Account(Name='Consultores del Sur', Industry='Consulting', Phone='952234567',
                BillingCity='Málaga', BillingCountry='Spain')
};
insert accounts;
System.debug('Accounts insertadas: ' + accounts.size());

// =========================================================
// 2. CONTACTS
// =========================================================
List<Contact> contacts = new List<Contact>{
    new Contact(FirstName='Carlos', LastName='Martínez', AccountId=accounts[0].Id,
                Email='carlos.martinez@techcorp.es', Phone='911234568'),
    new Contact(FirstName='Ana', LastName='García', AccountId=accounts[1].Id,
                Email='ana.garcia@distribuciones.es', Phone='931234568'),
    new Contact(FirstName='Luis', LastName='Pérez', AccountId=accounts[2].Id,
                Email='luis.perez@innovatech.es', Phone='961234568'),
    new Contact(FirstName='María', LastName='Hernández', AccountId=accounts[3].Id,
                Email='maria.hernandez@grupo.es', Phone='951234568'),
    new Contact(FirstName='Pablo', LastName='Rodríguez', AccountId=accounts[4].Id,
                Email='pablo.rodriguez@logistica.es', Phone='944234568')
};
insert contacts;
System.debug('Contacts insertados: ' + contacts.size());

// =========================================================
// 3. OPPORTUNITIES
// =========================================================
// Usamos el Pricebook estándar (necesario para Orders después)
Id stdPricebookId = [SELECT Id FROM Pricebook2 WHERE IsStandard = true LIMIT 1].Id;

Date today = Date.today();
Date firstOfMonth = Date.newInstance(today.year(), today.month(), 1);

List<Opportunity> opps = new List<Opportunity>{

    // --- Pipeline por Etapa: oportunidades abiertas ---
    new Opportunity(Name='Renovación Licencias TechCorp', AccountId=accounts[0].Id,
                    StageName='Prospecting', CloseDate=today.addDays(30),
                    Amount=12500, Probability=20),
    new Opportunity(Name='Proyecto ERP Distribuciones', AccountId=accounts[1].Id,
                    StageName='Qualification', CloseDate=today.addDays(45),
                    Amount=35000, Probability=40),
    new Opportunity(Name='Soporte Premium Innovatech', AccountId=accounts[2].Id,
                    StageName='Needs Analysis', CloseDate=today.addDays(20),
                    Amount=8900, Probability=50),
    new Opportunity(Name='Infraestructura Cloud Hernández', AccountId=accounts[3].Id,
                    StageName='Value Proposition', CloseDate=today.addDays(60),
                    Amount=52000, Probability=60),
    new Opportunity(Name='Actualización Hardware Norte', AccountId=accounts[4].Id,
                    StageName='Id. Decision Makers', CloseDate=today.addDays(15),
                    Amount=18750, Probability=70),
    new Opportunity(Name='Consultoría Digital Sur', AccountId=accounts[5].Id,
                    StageName='Perception Analysis', CloseDate=today.addDays(25),
                    Amount=9500, Probability=75),
    new Opportunity(Name='Plataforma BI TechCorp', AccountId=accounts[0].Id,
                    StageName='Proposal/Price Quote', CloseDate=today.addDays(10),
                    Amount=27000, Probability=85),
    new Opportunity(Name='Migración Cloud Innovatech', AccountId=accounts[2].Id,
                    StageName='Negotiation/Review', CloseDate=today.addDays(7),
                    Amount=41000, Probability=90),

    // --- Oportunidades Ganadas Este Mes ---
    new Opportunity(Name='Licencias Office TechCorp', AccountId=accounts[0].Id,
                    StageName='Closed Won',
                    CloseDate=firstOfMonth.addDays(2),
                    Amount=5600, Probability=100),
    new Opportunity(Name='Switch Red Distribuciones', AccountId=accounts[1].Id,
                    StageName='Closed Won',
                    CloseDate=firstOfMonth.addDays(5),
                    Amount=14200, Probability=100),
    new Opportunity(Name='Antivirus Corporativo Grupo', AccountId=accounts[3].Id,
                    StageName='Closed Won',
                    CloseDate=firstOfMonth.addDays(8),
                    Amount=3800, Probability=100),

    // --- Cerradas Perdidas (no deben aparecer en pipeline ni en ganadas) ---
    new Opportunity(Name='CRM Básico Sur', AccountId=accounts[5].Id,
                    StageName='Closed Lost',
                    CloseDate=today.addDays(-15),
                    Amount=7200, Probability=0),

    // --- Descuentos Pendientes Aprobación ---
    new Opportunity(Name='Pack Seguridad Premium Norte', AccountId=accounts[4].Id,
                    StageName='Proposal/Price Quote', CloseDate=today.addDays(20),
                    Amount=22000, Probability=80,
                    Discount_Percentage__c=18, Approval_Status__c='Pendiente',
                    Requires_Approval__c=true),
    new Opportunity(Name='Upgrade Servidor Innovatech', AccountId=accounts[2].Id,
                    StageName='Negotiation/Review', CloseDate=today.addDays(5),
                    Amount=31500, Probability=85,
                    Discount_Percentage__c=20, Approval_Status__c='Pendiente',
                    Requires_Approval__c=true),
    new Opportunity(Name='Bundle Software TechCorp', AccountId=accounts[0].Id,
                    StageName='Proposal/Price Quote', CloseDate=today.addDays(12),
                    Amount=16800, Probability=75,
                    Discount_Percentage__c=16, Approval_Status__c='Pendiente',
                    Requires_Approval__c=true)
};
insert opps;
System.debug('Opportunities insertadas: ' + opps.size());

// --- Oportunidades Sin Actividad: LAST_ACTIVITY ya es calculado por SF ---
// SF calcula LAST_ACTIVITY automáticamente desde actividades. Las oportunidades
// recién creadas sin actividad aparecerán en ese report cuando pasen 30 días.
// Para el demo, las oportunidades del pipeline sin actividad serán visibles
// inmediatamente ya que LAST_ACTIVITY = null (se interpreta como > 30 días).

// =========================================================
// 4. PRODUCTS & PRICEBOOK ENTRIES
// =========================================================
List<Product2> products = new List<Product2>{
    new Product2(Name='Laptop Dell XPS 15', ProductCode='HW-001',
                 Description='Laptop profesional 15 pulgadas', Family='Hardware',
                 IsActive=true),
    new Product2(Name='Servidor HP ProLiant DL380', ProductCode='HW-002',
                 Description='Servidor rack 2U', Family='Hardware', IsActive=true),
    new Product2(Name='Switch Cisco Catalyst 2960', ProductCode='NET-001',
                 Description='Switch 24 puertos gestionable', Family='Hardware',
                 IsActive=true),
    new Product2(Name='Microsoft Office 365 Business', ProductCode='SW-001',
                 Description='Suite ofimática por usuario/año', Family='Software',
                 IsActive=true),
    new Product2(Name='Antivirus Kaspersky Endpoint', ProductCode='SW-002',
                 Description='Seguridad endpoint por licencia/año', Family='Software',
                 IsActive=true),
    new Product2(Name='Soporte Premium Anual', ProductCode='SRV-001',
                 Description='Soporte técnico prioritario 24/7', Family='Services',
                 IsActive=true)
};
insert products;
System.debug('Products insertados: ' + products.size());

List<PricebookEntry> pbeList = new List<PricebookEntry>{
    new PricebookEntry(Pricebook2Id=stdPricebookId, Product2Id=products[0].Id,
                       UnitPrice=1199.99, IsActive=true),
    new PricebookEntry(Pricebook2Id=stdPricebookId, Product2Id=products[1].Id,
                       UnitPrice=4500.00, IsActive=true),
    new PricebookEntry(Pricebook2Id=stdPricebookId, Product2Id=products[2].Id,
                       UnitPrice=890.00, IsActive=true),
    new PricebookEntry(Pricebook2Id=stdPricebookId, Product2Id=products[3].Id,
                       UnitPrice=120.00, IsActive=true),
    new PricebookEntry(Pricebook2Id=stdPricebookId, Product2Id=products[4].Id,
                       UnitPrice=45.00, IsActive=true),
    new PricebookEntry(Pricebook2Id=stdPricebookId, Product2Id=products[5].Id,
                       UnitPrice=2400.00, IsActive=true)
};
insert pbeList;
System.debug('PricebookEntries insertadas: ' + pbeList.size());

// =========================================================
// 5. INVENTORY (Stock Disponible vs Reservado & Bajo Reorder Point)
// =========================================================
// Nota: el flow "Update Inventory on Order Item" descuenta Available_Stock__c
// al crear OrderItems. Los valores iniciales deben cubrir las cantidades pedidas:
//   products[0] Laptop:   OrderItem qty=3  → mínimo 4
//   products[1] Servidor: OrderItem qty=1  → mínimo 2
//   products[2] Switch:   OrderItem qty=2  → mínimo 3
//   products[3] Office:   OrderItem qty=10 → mínimo 11
//   products[5] Soporte:  OrderItem qty=1  → mínimo 2
// Los productos bajo reorder point se mantienen con stock suficiente para los pedidos
// pero por debajo del reorder point DESPUÉS del descuento del flow.
List<Inventory__c> inventories = new List<Inventory__c>{
    // Stock normal (por encima de reorder point tras descuento)
    new Inventory__c(Product__c=products[0].Id, Available_Stock__c=45,
                     Reserved_Stock__c=0, Reorder_Point__c=10),
    new Inventory__c(Product__c=products[1].Id, Available_Stock__c=12,
                     Reserved_Stock__c=0, Reorder_Point__c=5),
    new Inventory__c(Product__c=products[2].Id, Available_Stock__c=30,
                     Reserved_Stock__c=0, Reorder_Point__c=10),
    // Stock bajo reorder point TRAS el descuento del flow:
    // Office: 13 inicial - 10 pedido = 3 restante < reorder 20
    new Inventory__c(Product__c=products[3].Id, Available_Stock__c=13,
                     Reserved_Stock__c=0, Reorder_Point__c=20),
    // Antivirus: sin OrderItem, ya está bajo reorder point directamente
    new Inventory__c(Product__c=products[4].Id, Available_Stock__c=7,
                     Reserved_Stock__c=0, Reorder_Point__c=15),
    // Soporte: 3 inicial - 1 pedido = 2 restante < reorder 10
    new Inventory__c(Product__c=products[5].Id, Available_Stock__c=3,
                     Reserved_Stock__c=0, Reorder_Point__c=10)
};
insert inventories;
System.debug('Inventories insertadas: ' + inventories.size());

// =========================================================
// 6. ORDERS (para Experience Cloud y tracking)
// =========================================================
// Las Orders en SF requieren Status y EffectiveDate
List<Order> orders = new List<Order>{
    new Order(AccountId=accounts[0].Id, Pricebook2Id=stdPricebookId,
              Status='Draft', EffectiveDate=today.addDays(-10),
              Shipping_Status__c='Enviado', Payment_Status__c='Pagado'),
    new Order(AccountId=accounts[1].Id, Pricebook2Id=stdPricebookId,
              Status='Draft', EffectiveDate=today.addDays(-5),
              Shipping_Status__c='Preparando', Payment_Status__c='Pendiente'),
    new Order(AccountId=accounts[2].Id, Pricebook2Id=stdPricebookId,
              Status='Draft', EffectiveDate=today.addDays(-20),
              Shipping_Status__c='Entregado', Payment_Status__c='Pagado'),
    new Order(AccountId=accounts[3].Id, Pricebook2Id=stdPricebookId,
              Status='Draft', EffectiveDate=today,
              Shipping_Status__c='Preparando', Payment_Status__c='Pendiente')
};
insert orders;
System.debug('Orders insertadas: ' + orders.size());

// Order Items
List<OrderItem> orderItems = new List<OrderItem>{
    new OrderItem(OrderId=orders[0].Id, Product2Id=products[0].Id,
                  PricebookEntryId=pbeList[0].Id, Quantity=3, UnitPrice=1199.99),
    new OrderItem(OrderId=orders[0].Id, Product2Id=products[3].Id,
                  PricebookEntryId=pbeList[3].Id, Quantity=10, UnitPrice=120.00),
    new OrderItem(OrderId=orders[1].Id, Product2Id=products[2].Id,
                  PricebookEntryId=pbeList[2].Id, Quantity=2, UnitPrice=890.00),
    new OrderItem(OrderId=orders[2].Id, Product2Id=products[1].Id,
                  PricebookEntryId=pbeList[1].Id, Quantity=1, UnitPrice=4500.00),
    new OrderItem(OrderId=orders[3].Id, Product2Id=products[5].Id,
                  PricebookEntryId=pbeList[5].Id, Quantity=1, UnitPrice=2400.00)
};
insert orderItems;
System.debug('OrderItems insertados: ' + orderItems.size());

// Activar las 3 primeras órdenes (ya tienen OrderItems)
// La orden 3 (Draft) se deja en Draft intencionadamente
List<Order> ordersToActivate = new List<Order>{
    new Order(Id=orders[0].Id, Status='Activated'),
    new Order(Id=orders[1].Id, Status='Activated'),
    new Order(Id=orders[2].Id, Status='Activated')
};
update ordersToActivate;
System.debug('Orders activadas: 3');

// =========================================================
// 7. SHIPMENT TRACKING
// =========================================================
List<Shipment_Tracking__c> shipments = new List<Shipment_Tracking__c>{
    new Shipment_Tracking__c(Order__c=orders[0].Id, Tracking_Number__c='TNT-2026-001234',
                              Carrier__c='DHL', Status__c='En tránsito',
                              Estimated_Delivery__c=today.addDays(2)),
    new Shipment_Tracking__c(Order__c=orders[1].Id, Tracking_Number__c='TNT-2026-001235',
                              Carrier__c='SEUR', Status__c='Pendiente de recogida',
                              Estimated_Delivery__c=today.addDays(5)),
    new Shipment_Tracking__c(Order__c=orders[2].Id, Tracking_Number__c='TNT-2026-001230',
                              Carrier__c='Correos', Status__c='Entregado',
                              Estimated_Delivery__c=today.addDays(-2))
};
insert shipments;
System.debug('Shipment Trackings insertados: ' + shipments.size());

// =========================================================
// 8. CASES (Casos Abiertos por Cola, Casos por Tipo y Estado,
//           Tiempo Medio Resolución)
// =========================================================
// Primero buscamos las colas de soporte
Map<String, Id> queueMap = new Map<String, Id>();
for (Group g : [SELECT Id, Name FROM Group WHERE Type = 'Queue'
                AND Name IN ('Hardware Support Queue', 'Software Support Queue',
                             'Billing Support Queue')]) {
    queueMap.put(g.Name, g.Id);
}
System.debug('Colas encontradas: ' + queueMap.keySet());

// Si no existen las colas aún, los casos se asignarán al usuario actual
Id hwQueueId  = queueMap.get('Hardware Support Queue');
Id swQueueId  = queueMap.get('Software Support Queue');
Id bilQueueId = queueMap.get('Billing Support Queue');

List<Case> cases = new List<Case>{

    // --- Casos Abiertos: Hardware (para cola Hardware) ---
    new Case(Subject='Fallo disco duro servidor', AccountId=accounts[0].Id,
             ContactId=contacts[0].Id, Type='Hardware', Status='New',
             Priority='High', Description='El servidor no arranca tras fallo de disco',
             OwnerId=(hwQueueId != null ? hwQueueId : UserInfo.getUserId())),
    new Case(Subject='Teclado inalámbrico no conecta', AccountId=accounts[1].Id,
             ContactId=contacts[1].Id, Type='Hardware', Status='Working',
             Priority='Medium', Description='El teclado Bluetooth no se empareja',
             OwnerId=(hwQueueId != null ? hwQueueId : UserInfo.getUserId())),
    new Case(Subject='Monitor con líneas verticales', AccountId=accounts[4].Id,
             Type='Hardware', Status='New', Priority='Low',
             Description='Monitor presenta artefactos visuales',
             OwnerId=(hwQueueId != null ? hwQueueId : UserInfo.getUserId())),

    // --- Casos Abiertos: Software ---
    new Case(Subject='Error licencia Office 365', AccountId=accounts[0].Id,
             ContactId=contacts[0].Id, Type='Software', Status='New',
             Priority='High', Description='El usuario no puede activar la licencia',
             OwnerId=(swQueueId != null ? swQueueId : UserInfo.getUserId())),
    new Case(Subject='Actualización Windows falla', AccountId=accounts[2].Id,
             ContactId=contacts[2].Id, Type='Software', Status='Escalated',
             Priority='High', Description='Windows Update da error 0x80073712',
             OwnerId=(swQueueId != null ? swQueueId : UserInfo.getUserId())),
    new Case(Subject='Antivirus bloquea ERP', AccountId=accounts[3].Id,
             ContactId=contacts[3].Id, Type='Software', Status='Working',
             Priority='Medium', Description='Kaspersky bloquea acceso al ERP interno',
             OwnerId=(swQueueId != null ? swQueueId : UserInfo.getUserId())),
    new Case(Subject='VPN no conecta desde casa', AccountId=accounts[5].Id,
             Type='Software', Status='New', Priority='Medium',
             Description='Error de certificado en cliente VPN',
             OwnerId=(swQueueId != null ? swQueueId : UserInfo.getUserId())),

    // --- Casos Abiertos: Facturación ---
    new Case(Subject='Cargo duplicado en factura', AccountId=accounts[1].Id,
             ContactId=contacts[1].Id, Type='Billing', Status='New',
             Priority='High', Description='La factura de enero tiene un cargo doble',
             OwnerId=(bilQueueId != null ? bilQueueId : UserInfo.getUserId())),
    new Case(Subject='Solicitud factura rectificativa', AccountId=accounts[3].Id,
             ContactId=contacts[3].Id, Type='Billing', Status='Working',
             Priority='Medium', Description='Necesitan rectificativa por cambio de datos',
             OwnerId=(bilQueueId != null ? bilQueueId : UserInfo.getUserId())),

    // --- Casos Cerrados (para Tiempo Medio Resolución) ---
    new Case(Subject='Instalación impresora resuelta', AccountId=accounts[0].Id,
             ContactId=contacts[0].Id, Type='Hardware', Status='Closed',
             Priority='Low', Description='Instalación correcta de drivers',
             OwnerId=(hwQueueId != null ? hwQueueId : UserInfo.getUserId())),
    new Case(Subject='Reinstalación Office completada', AccountId=accounts[2].Id,
             ContactId=contacts[2].Id, Type='Software', Status='Closed',
             Priority='Medium', Description='Office reinstalado correctamente',
             OwnerId=(swQueueId != null ? swQueueId : UserInfo.getUserId())),
    new Case(Subject='Factura enviada por email', AccountId=accounts[4].Id,
             Type='Billing', Status='Closed', Priority='Low',
             Description='Se reenvió la factura al email correcto',
             OwnerId=(bilQueueId != null ? bilQueueId : UserInfo.getUserId())),
    new Case(Subject='Configuración email corporativo', AccountId=accounts[1].Id,
             ContactId=contacts[1].Id, Type='Software', Status='Closed',
             Priority='Medium', Description='Outlook configurado correctamente con Exchange',
             OwnerId=(swQueueId != null ? swQueueId : UserInfo.getUserId())),
    new Case(Subject='Cambio RAM servidor resuelto', AccountId=accounts[3].Id,
             ContactId=contacts[3].Id, Type='Hardware', Status='Closed',
             Priority='High', Description='Ampliación de RAM completada',
             OwnerId=(hwQueueId != null ? hwQueueId : UserInfo.getUserId()))
};
insert cases;
System.debug('Cases insertados: ' + cases.size());

// Cerrar los casos con ClosedDate para que Resolution_Time__c se calcule
// (Resolution_Time__c = IF(IsClosed, (ClosedDate - CreatedDate) * 24, NULL))
// Cuando Status = Closed en SF, IsClosed = true automáticamente y ClosedDate se setea.
// Los cerramos con fecha de cierre en días distintos para variedad:
List<Case> casesToClose = new List<Case>();
Integer[] closedIndices = new Integer[]{9, 10, 11, 12, 13};
Integer[] daysAgo = new Integer[]{3, 7, 14, 5, 10};
for (Integer i = 0; i < closedIndices.size(); i++) {
    // Nota: ClosedDate es de solo lectura en SF (lo setea el sistema al cerrar).
    // Simplemente actualizamos Status a Closed para que SF lo cierre correctamente.
    casesToClose.add(new Case(Id=cases[closedIndices[i]].Id, Status='Closed'));
}
update casesToClose;
System.debug('Cases cerrados correctamente.');

// =========================================================
// 9. LEADS (para probar el Flow de asignación)
// =========================================================
List<Lead> leads = new List<Lead>{
    new Lead(FirstName='Roberto', LastName='Sánchez', Company='Sánchez Tech SL',
             Email='roberto.sanchez@sanchez-tech.es', Phone='913456789',
             LeadSource='Web', Status='Open - Not Contacted',
             ProductInterest__c='Hardware'),
    new Lead(FirstName='Elena', LastName='Vázquez', Company='Vázquez Digital SA',
             Email='elena.vazquez@vazquez-digital.es', Phone='934567890',
             LeadSource='Phone Inquiry', Status='Open - Not Contacted',
             ProductInterest__c='Software'),
    new Lead(FirstName='Miguel', LastName='Torres', Company='Torres Consulting',
             Email='miguel.torres@torres-consulting.es', Phone='964567890',
             LeadSource='Partner Referral', Status='Working',
             ProductInterest__c='Hardware'),
    new Lead(FirstName='Sofía', LastName='Moreno', Company='Moreno & Asociados',
             Email='sofia.moreno@moreno-asociados.es', Phone='954567890',
             LeadSource='Web', Status='Open - Not Contacted',
             ProductInterest__c='Software')
};
insert leads;
System.debug('Leads insertados: ' + leads.size());

// =========================================================
// RESUMEN FINAL
// =========================================================
System.debug('=== DATOS DE MUESTRA INSERTADOS CORRECTAMENTE ===');
System.debug('Accounts: ' + accounts.size());
System.debug('Contacts: ' + contacts.size());
System.debug('Opportunities: ' + opps.size() + ' (8 pipeline, 3 ganadas mes, 1 perdida, 3 con descuento pendiente)');
System.debug('Products: ' + products.size());
System.debug('PricebookEntries: ' + pbeList.size());
System.debug('Inventory: ' + inventories.size() + ' (3 normales, 3 bajo reorder point)');
System.debug('Orders: ' + orders.size());
System.debug('OrderItems: ' + orderItems.size());
System.debug('Shipment Trackings: ' + shipments.size());
System.debug('Cases: ' + cases.size() + ' (9 abiertos, 5 cerrados)');
System.debug('Leads: ' + leads.size());
