import { LightningElement, api, track } from 'lwc';
import searchProducts from '@salesforce/apex/ProductSearchController.searchProducts';
import addProductsToOpportunity from '@salesforce/apex/ProductSearchController.addProductsToOpportunity';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

export default class ProductSearchAndAdd extends LightningElement {
    @api recordId; // ID de la Opportunity
    searchKey = '';
    products = [];
    selectedProducts = [];
    isLoading = false;

    get hasProducts() {
        return this.products && this.products.length > 0;
    }

    get hasSelectedProducts() {
        return this.selectedProducts && this.selectedProducts.length > 0;
    }

    handleSearchKeyChange(event) {
        this.searchKey = event.target.value;
        if (this.searchKey.length >= 3) {
            this.performSearch();
        } else {
            this.products = [];
        }
    }

    performSearch() {
        this.isLoading = true;
        searchProducts({ searchTerm: this.searchKey })
            .then(result => {
                this.products = result.map(prod => ({
                    ...prod,
                    quantity: 1,
                    discount: 0
                }));
                this.isLoading = false;
            })
            .catch(error => {
                this.showToast('Error', error.body.message, 'error');
                this.isLoading = false;
            });
    }

    handleSelectProduct(event) {
        const productId = event.currentTarget.dataset.id;
        const product = this.products.find(p => p.Id === productId);

        if (!this.selectedProducts.some(p => p.Id === productId)) {
            this.selectedProducts = [...this.selectedProducts, { ...product }];
        }
    }

    handleQuantityChange(event) {
        const productId = event.target.dataset.id;
        const quantity = parseInt(event.target.value, 10);
        this.selectedProducts = this.selectedProducts.map(p =>
            p.Id === productId ? { ...p, quantity } : p
        );
    }

    handleDiscountChange(event) {
        const productId = event.target.dataset.id;
        const discount = parseFloat(event.target.value);
        this.selectedProducts = this.selectedProducts.map(p =>
            p.Id === productId ? { ...p, discount } : p
        );
    }

    handleRemoveProduct(event) {
        const productId = event.currentTarget.dataset.id;
        this.selectedProducts = this.selectedProducts.filter(p => p.Id !== productId);
    }

    handleAddToOpportunity() {
        if (!this.hasSelectedProducts) return;

        this.isLoading = true;
        const productsToAdd = this.selectedProducts.map(p => ({
            productId: p.Id,
            quantity: p.quantity,
            discount: p.discount
        }));

        addProductsToOpportunity({
            opportunityId: this.recordId,
            products: productsToAdd
        })
            .then(() => {
                this.showToast('Éxito', 'Productos añadidos a la oportunidad', 'success');
                this.selectedProducts = [];
                this.products = [];
                this.searchKey = '';
                this.isLoading = false;
                this.dispatchEvent(new CustomEvent('productsadded'));
            })
            .catch(error => {
                this.showToast('Error', error.body.message, 'error');
                this.isLoading = false;
            });
    }

    showToast(title, message, variant) {
        const event = new ShowToastEvent({ title, message, variant });
        this.dispatchEvent(event);
    }
}