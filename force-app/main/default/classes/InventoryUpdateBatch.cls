/**
 * Batch Apex para actualización masiva del inventario.
 * Recalcula el Available_Stock__c y Reserved_Stock__c de todos los productos
 * basándose en los OrderItems de pedidos activos.
 */
public class InventoryUpdateBatch implements Database.Batchable<SObject>, Database.Stateful {

    private Integer recordsProcessed = 0;

    public Database.QueryLocator start(Database.BatchableContext bc) {
        return Database.getQueryLocator([
            SELECT Id, Product__c, Available_Stock__c, Reserved_Stock__c, Reorder_Point__c
            FROM Inventory__c
            ORDER BY Product__c
        ]);
    }

    public void execute(Database.BatchableContext bc, List<Inventory__c> inventories) {
        Set<Id> productIds = new Set<Id>();
        for (Inventory__c inv : inventories) {
            productIds.add(inv.Product__c);
        }

        // Calcular stock reservado desde OrderItems de pedidos no completados
        Map<Id, Decimal> reservedByProduct = new Map<Id, Decimal>();
        for (AggregateResult ar : [
            SELECT Product2Id productId, SUM(Quantity) totalQty
            FROM OrderItem
            WHERE Order.Status NOT IN ('Completed', 'Cancelled')
            AND Product2Id IN :productIds
            GROUP BY Product2Id
        ]) {
            reservedByProduct.put((Id) ar.get('productId'), (Decimal) ar.get('totalQty'));
        }

        List<Inventory__c> toUpdate = new List<Inventory__c>();
        List<Task> alertTasks = new List<Task>();

        for (Inventory__c inv : inventories) {
            Decimal reserved = reservedByProduct.containsKey(inv.Product__c)
                ? reservedByProduct.get(inv.Product__c)
                : 0;

            inv.Reserved_Stock__c = reserved;

            // Alerta de reposición
            if (inv.Available_Stock__c != null && inv.Reorder_Point__c != null
                    && inv.Available_Stock__c < inv.Reorder_Point__c) {
                alertTasks.add(new Task(
                    Subject = 'Alerta de stock bajo: reposición necesaria',
                    Description = 'El producto ID ' + inv.Product__c + ' está por debajo del punto de reposición.',
                    Status = 'Open',
                    Priority = 'High',
                    WhatId = inv.Id
                ));
            }

            toUpdate.add(inv);
            recordsProcessed++;
        }

        update toUpdate;
        if (!alertTasks.isEmpty()) {
            insert alertTasks;
        }
    }

    public void finish(Database.BatchableContext bc) {
        System.debug('InventoryUpdateBatch completado. Registros procesados: ' + recordsProcessed);
    }
}