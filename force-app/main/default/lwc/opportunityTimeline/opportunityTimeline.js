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
            'Prospecting': 'utility:user',
            'Qualification': 'utility:filter',
            'Needs Analysis': 'utility:search',
            'Proposal/Price Quote': 'utility:file',
            'Negotiation/Review': 'utility:chat',
            'Closed Won': 'utility:check',
            'Closed Lost': 'utility:close'
        };
        return iconMap[stage] || 'utility:opportunity';
    }

    getStageClass(stage) {
        if (stage === 'Closed Won') return 'timeline-item timeline-item_won';
        if (stage === 'Closed Lost') return 'timeline-item timeline-item_lost';
        return 'timeline-item';
    }
}