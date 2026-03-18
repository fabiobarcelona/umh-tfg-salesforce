import { LightningElement, api, wire } from 'lwc';
import { refreshApex } from '@salesforce/apex';
import getTrackingInfo from '@salesforce/apex/OrderTrackingController.getTrackingInfo';
import refreshTrackingInfo from '@salesforce/apex/OrderTrackingController.refreshTrackingInfo';

export default class OrderTrackingDetail extends LightningElement {
    @api recordId;
    trackingData;
    error;
    isLoading = false;
    wiredTrackingResult;

    @wire(getTrackingInfo, { orderId: '$recordId' })
    wiredTracking(result) {
        this.wiredTrackingResult = result;
        const { error, data } = result;
        if (data) {
            this.trackingData = data;
            this.error = undefined;
            this.tryRefresh(data);
        } else if (error) {
            this.error = error;
            this.trackingData = undefined;
        }
    }

    tryRefresh(tracking) {
        const needsRefresh = !tracking.Last_API_Update__c ||
            new Date(tracking.Last_API_Update__c) < new Date(Date.now() - 3600000);

        if (needsRefresh) {
            this.isLoading = true;
            refreshTrackingInfo({ orderId: this.recordId })
                .then(() => refreshApex(this.wiredTrackingResult))
                .catch(err => {
                    console.error('Error refreshing tracking:', err);
                })
                .finally(() => {
                    this.isLoading = false;
                });
        }
    }

    get hasTracking() {
        return this.trackingData != null;
    }

    get isDelivered() {
        return this.trackingData && this.trackingData.Status__c === 'Entregado';
    }
}
