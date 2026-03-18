import { LightningElement, wire } from 'lwc';
import getCustomerOrders from '@salesforce/apex/OrderTrackingController.getCustomerOrders';

const STATUS_CLASSES = {
    Activated: 'slds-badge slds-theme_success',
    Draft: 'slds-badge',
    Cancelled: 'slds-badge slds-theme_error'
};

export default class OrderTrackingList extends LightningElement {
    orders;
    error;
    selectedOrderId;

    @wire(getCustomerOrders)
    wiredOrders({ error, data }) {
        if (data) {
            this.orders = data.map(order => ({
                ...order,
                formattedDate: this.formatDate(order.EffectiveDate),
                formattedAmount: this.formatCurrency(order.TotalAmount),
                statusClass: STATUS_CLASSES[order.Status] || 'slds-badge',
                trackingStatus: this.getTrackingStatus(order)
            }));
            this.error = undefined;
        } else if (error) {
            this.error = error;
            console.error('Error fetching orders:', error);
            this.orders = undefined;
        }
    }

    get hasOrders() {
        return this.orders && this.orders.length > 0;
    }

    get noOrders() {
        return !this.error && this.orders && this.orders.length === 0;
    }

    get showDetail() {
        return this.selectedOrderId != null;
    }

    get showList() {
        return !this.showDetail;
    }

    formatDate(dateStr) {
        if (!dateStr) return '';
        const d = new Date(dateStr);
        return d.toLocaleDateString('es-ES', { year: 'numeric', month: 'long', day: 'numeric' });
    }

    formatCurrency(amount) {
        if (amount == null) return '—';
        return new Intl.NumberFormat('es-ES', { style: 'currency', currency: 'EUR' }).format(amount);
    }

    getTrackingStatus(order) {
        if (order.Shipment_Trackings__r && order.Shipment_Trackings__r.length > 0) {
            return order.Shipment_Trackings__r[0].Status__c;
        }
        return null;
    }

    handleOrderClick(event) {
        this.selectedOrderId = event.currentTarget.dataset.id;
    }

    handleBack() {
        this.selectedOrderId = null;
    }
}