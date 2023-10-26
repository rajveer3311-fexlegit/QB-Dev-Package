/**
*  Purpose         : This component is calling from QB Invoice record page to create QB Invoice record online
*  Created Date    : 12/10/2023
*  Created By      : Rajveer Singh Rawat
*  Revision Logs   : V_1.0 - Created
**/

import { LightningElement, api, wire } from 'lwc';
import getQBInvoice from '@salesforce/apex/QuickbookSFHelper.getQuickbookInvoiceById';
import createQBInvoice from '@salesforce/apex/QuickbookSFHelper.createQuickBookInvoiceFromLWC';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

export default class CreateInvoice extends LightningElement {
    @api recordId;
    qbInvoiceId;
    qbInvoices = [];
    isLoading = false;

    @api invoke(){
        this.handleGetQBInvoices();
    }

    //Get QB Invoice record exist on SF org related to this recordID
    handleGetQBInvoices() {
        this.isLoading = true;
        getQBInvoice({ recordId : this.recordId})
            .then(message => {
                if(message.ERROR){
                   this.dispatchEvent(new ShowToastEvent({
                        title: 'Error ',
                        message: 'This QB Invoice record already exist on QB online.',
                        variant: 'error'
                    }));
                    this.isLoading = false;
                    return;
                }
                if(message.Quickbook){
                    this.qbInvoices = JSON.parse(message.Quickbook);
                    this.createQBInvoicesRecord();
                }
            }).catch(message => {
                this.isLoading = false;
                console.log('ERROR ###'+message);
            }).finally(() => {
                console.log("Finally Called!");
            });
      }

    //Create QB Invoice record
      createQBInvoicesRecord() {
        createQBInvoice({ recordId : this.recordId})
            .then(message => {
                console.log('Message');
            }).catch(message => {
                console.log(message);
            }).finally(() => {
                this.isLoading = false;
                window.location.reload();
                console.log("Create Invoices Finally Called!");
            });
      }
}