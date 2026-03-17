public class OpportunityTriggerHandler {

    public static void beforeUpdate(List<Opportunity> newOpps, Map<Id, Opportunity> oldOppMap) {
        // Recopilar IDs de oportunidades que pasan a Closed Won
        List<Opportunity> oppsClosingAsWon = new List<Opportunity>();
        Set<Id> oppIds = new Set<Id>();

        for (Opportunity opp : newOpps) {
            Opportunity oldOpp = oldOppMap.get(opp.Id);
            if (opp.StageName == 'Closed Won' && oldOpp.StageName != 'Closed Won') {
                oppsClosingAsWon.add(opp);
                oppIds.add(opp.Id);
            }
        }

        if (oppsClosingAsWon.isEmpty()) {
            return;
        }

        // query para obtener todos los Quotes sincronizados
        validateQuotesBeforeClosing(oppsClosingAsWon, oppIds);
    }

    /**
     * Valida que exista un Quote sincronizado y aceptado para cada oportunidad que se cierra como ganada.
     * Se usa SOQL dinámico para que la clase compile aunque Quotes no esté habilitado en la org.
     */
    private static void validateQuotesBeforeClosing(List<Opportunity> oppsClosingAsWon, Set<Id> oppIds) {
        try {
            // Query única: obtener todos los Quotes sincronizados de todas las oportunidades
            Map<Id, SObject> syncedQuoteByOppId = new Map<Id, SObject>();

            List<SObject> syncedQuotes = Database.query(
                'SELECT Id, Status, OpportunityId FROM Quote ' +
                'WHERE OpportunityId IN :oppIds AND IsSyncing = true'
            );

            for (SObject q : syncedQuotes) {
                Id oppId = (Id) q.get('OpportunityId');
                // Si hay varios Quotes sincronizados por Opp, guardamos el último encontrado
                syncedQuoteByOppId.put(oppId, q);
            }

            // Iterar sobre las oportunidades y validar usando el Map
            for (Opportunity opp : oppsClosingAsWon) {
                if (!syncedQuoteByOppId.containsKey(opp.Id)) {
                    opp.addError('No se puede cerrar la oportunidad como ganada sin un presupuesto sincronizado.');
                    continue;
                }

                String status = (String) syncedQuoteByOppId.get(opp.Id).get('Status');
                if (status != 'Accepted') {
                    opp.addError('El presupuesto debe estar en estado "Aceptado" antes de cerrar la oportunidad.');
                }
            }
        } catch (QueryException e) {
            // Si Quotes no está habilitado en la org, la validación se omite
            System.debug('Quote validation skipped (Quotes feature may not be enabled): ' + e.getMessage());
        }
    }
}