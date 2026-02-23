import { LightningElement, api, wire, track } from 'lwc';
import getTrackingInfo from '@salesforce/apex/OrderTrackingController.getTrackingInfo';

export default class OrderTrackingDetail extends LightningElement {
    @api recordId; // ID del Order
    @track trackingData;
    @track error;
    isLoading = false;

    @wire(getTrackingInfo, { orderId: '$recordId' })
    wiredTracking({ error, data }) {
        if (data) {
            this.trackingData = data;
            this.error = undefined;
        } else if (error) {
            this.error = error;
            this.trackingData = undefined;
        }
    }

    get hasTracking() {
        return this.trackingData != null;
    }

    get isDelivered() {
        return this.trackingData && this.trackingData.Status__c === 'Entregado';
    }
}