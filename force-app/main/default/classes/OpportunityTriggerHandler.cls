public class OpportunityTriggerHandler {

    public static void beforeUpdate(List<Opportunity> newOpps, Map<Id, Opportunity> oldOppMap) {
        for (Opportunity opp : newOpps) {
            Opportunity oldOpp = oldOppMap.get(opp.Id);

            // Si la oportunidad está pasando a Closed Won
            if (opp.StageName == 'Closed Won' && oldOpp.StageName != 'Closed Won') {
                validateQuoteBeforeClosing(opp);
            }
        }
    }

    /**
     * Valida que exista un Quote sincronizado y aceptado antes de cerrar como ganada.
     * NOTA: Requiere que la funcionalidad Quotes esté habilitada en la org
     * (Setup > Quote Settings > Enable Quotes).
     * Se usa SOQL dinámico para que la clase compile aunque Quotes no esté habilitado.
     */
    private static void validateQuoteBeforeClosing(Opportunity opp) {
        try {
            List<SObject> syncedQuotes = Database.query(
                'SELECT Id, Status FROM Quote WHERE OpportunityId = \'' + opp.Id + '\' AND IsSyncing = true LIMIT 1'
            );

            if (syncedQuotes.isEmpty()) {
                opp.addError('No se puede cerrar la oportunidad como ganada sin un presupuesto sincronizado.');
                return;
            }

            String status = (String) syncedQuotes[0].get('Status');
            if (status != 'Accepted') {
                opp.addError('El presupuesto debe estar en estado "Aceptado" antes de cerrar la oportunidad.');
            }
        } catch (QueryException e) {
            // Si Quotes no está habilitado en la org, la validación se omite
            System.debug('Quote validation skipped (Quotes feature may not be enabled): ' + e.getMessage());
        }
    }
}