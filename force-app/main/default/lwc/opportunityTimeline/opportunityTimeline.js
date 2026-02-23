import { LightningElement, api, wire } from 'lwc';
import getOpportunityHistory from '@salesforce/apex/OpportunityTimelineController.getOpportunityHistory';

export default class OpportunityTimeline extends LightningElement {
    @api recordId; // ID de la Opportunity
    timelineData = [];
    error;

    @wire(getOpportunityHistory, { opportunityId: '$recordId' })
    wiredHistory({ error, data }) {
        if (data) {
            this.timelineData = data.map(item => ({
                id: item.Id,
                date: this.formatDate(item.CreatedDate),
                stage: item.StageName,
                icon: this.getStageIcon(item.StageName),
                cssClass: this.getStageClass(item.StageName)
            }));
            this.error = undefined;
        } else if (error) {
            this.error = error;
            this.timelineData = [];
        }
    }

    get hasData() {
        return this.timelineData && this.timelineData.length > 0;
    }

    formatDate(dateString) {
        const date = new Date(dateString);
        return date.toLocaleDateString('es-ES', {
            year: 'numeric',
            month: 'long',
            day: 'numeric'
        });
    }

    getStageIcon(stage) {
        const iconMap = {
            'Prospección': 'custom:custom63',
            'Cualificación': 'custom:custom19',
            'Análisis de Necesidades': 'custom:custom87',
            'Propuesta/Presupuesto': 'custom:custom14',
            'Negociación/Revisión': 'custom:custom41',
            'Closed Won': 'custom:custom58',
            'Cerrada Perdida': 'custom:custom90'
        };
        return iconMap[stage] || 'custom:custom1';
    }

    getStageClass(stage) {
        return stage === 'Closed Won' ? 'slds-timeline__item_success' :
            stage === 'Cerrada Perdida' ? 'slds-timeline__item_error' :
                'slds-timeline__item_call';
    }
}