import { LightningElement, track, api, wire } from 'lwc';
import { refreshApex } from '@salesforce/apex';
import findCase from '@salesforce/apex/CustomLookupController.findCase';
import saveProyect from '@salesforce/apex/CustomLookupController.saveProyect';
import { getRecord, getFieldValue } from "lightning/uiRecordApi";
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { reduceErrors } from 'c/fs_ldsUtils';
import { RefreshEvent } from 'lightning/refresh';

import CLIENT from "@salesforce/schema/Case.AccountId";
import SEARCH_PROJECT from "@salesforce/schema/Case.FS_Buscar_Proyecto__r.Name";
import SEARCH_PROJECT2 from "@salesforce/schema/Case.FS_Buscar_Proyecto2__r.Name";
import SEARCH_PROJECT3 from "@salesforce/schema/Case.FS_Buscar_Proyecto3__r.Name";
import SEARCH_PROJECT4 from "@salesforce/schema/Case.FS_Buscar_Proyecto4__r.Name";
import TARIFA from "@salesforce/schema/Case.FS_Tarifa_Dias_Hombre__c";
import TARIFA2 from "@salesforce/schema/Case.FS_Tarifa_Dias_Hombre2__c";
import TARIFA3 from "@salesforce/schema/Case.FS_Tarifa_Dias_Hombre3__c";
import TARIFA4 from "@salesforce/schema/Case.FS_Tarifa_Dias_Hombre4__c";
import SALDO from "@salesforce/schema/Case.FS_Saldo_de_dias__c";
import SALDO2 from "@salesforce/schema/Case.FS_Saldo_de_dias2__c";
import SALDO3 from "@salesforce/schema/Case.FS_Saldo_de_dias3__c";
import SALDO4 from "@salesforce/schema/Case.FS_Saldo_de_dias4__c";
import STATUS from "@salesforce/schema/Case.Status";
import ID_PROJECT from "@salesforce/schema/Case.FS_Buscar_Proyecto__c";
import ID_PROJECT2 from "@salesforce/schema/Case.FS_Buscar_Proyecto2__c";
import ID_PROJECT3 from "@salesforce/schema/Case.FS_Buscar_Proyecto3__c";
import ID_PROJECT4 from "@salesforce/schema/Case.FS_Buscar_Proyecto4__c";

const FIELDS = [CLIENT, SEARCH_PROJECT, SEARCH_PROJECT2, SEARCH_PROJECT3, SEARCH_PROJECT4, TARIFA, TARIFA2, TARIFA3, TARIFA4, SALDO, SALDO2, SALDO3, SALDO4, STATUS, ID_PROJECT, ID_PROJECT2, ID_PROJECT3, ID_PROJECT4];

export default class Fs_customLookup extends LightningElement {
    @api recordId;
    @track error;
    @track projectId;
    @track AccountId;
    @track clientVal;
    @track caseType;
    filter = {};
    caseList = [];
    isLoading = false;
    isLoading2 = false;

    connectedCallback() {
        this.callApexMethod();
    }

    callApexMethod() {
        this.isLoading2 = true;
        findCase({ recordId: this.recordId })
            .then(result => {
                this.caseList = result;             
                this.clientVal = this.caseList[0].AccountId;
                this.caseType = this.caseList[0].RecordType.Name;

                this.filter = {
                    criteria: [
                        {
                            fieldPath: 'FS_Cliente__c',
                            operator: 'eq',
                            value: this.clientVal
                        },
                        {
                            fieldPath: 'FS_Tipo_de_Caso__c',
                            operator: 'eq',
                            value: this.caseType
                        },
                        {
                            fieldPath: 'FS_Saldo_de_dias__c',
                            operator: 'ne',
                            value: 0
                        },
                        {
                            fieldPath: 'FS_Fecha_Fin_Proyecto__c',
                            operator: 'gt',
                            value: { literal: 'TODAY' }
                        }
                    ],
                    filterLogic: '1 AND 2 AND 3 AND 4',
                }
                this.isLoading2 = false;
            })
            .catch(error => {
                console.error('Error calling Apex method: ', error);
                this.isLoading2 = false;
            });
    }
    

    @wire(getRecord, { recordId: "$recordId", fields: FIELDS })
    case;

    get clientVal() {
        return getFieldValue(this.case.data, CLIENT);
    }

    get statusVal() {
        return getFieldValue(this.case.data, STATUS);
    }

    get proyecto() {
        let projectName = '';
        if(this.statusVal == 'Nuevo' || this.statusVal == 'En Análisis') {
            this.projectName = getFieldValue(this.case.data, SEARCH_PROJECT);
        } else if(this.statusVal == 'Estimación Macro') {
            this.projectName = getFieldValue(this.case.data, SEARCH_PROJECT2);
        } else if(this.statusVal == 'Documento de Especificación Funcional') {
            this.projectName = getFieldValue(this.case.data, SEARCH_PROJECT3)
        } else if(this.statusVal == 'En Propuesta Económica') {
            this.projectName = getFieldValue(this.case.data, SEARCH_PROJECT4)
        }
        return this.projectName;
    }

    get tarifa() {
        let tarifaVal = '';
        if(this.statusVal == 'Nuevo' || this.statusVal == 'En Análisis') {
            this.tarifaVal = getFieldValue(this.case.data, TARIFA);
        } else if(this.statusVal == 'Estimación Macro') {
            this.tarifaVal = getFieldValue(this.case.data, TARIFA2);
        } else if(this.statusVal == 'Documento de Especificación Funcional') {
            this.tarifaVal = getFieldValue(this.case.data, TARIFA3)
        } else if(this.statusVal == 'En Propuesta Económica') {
            this.tarifaVal = getFieldValue(this.case.data, TARIFA4)
        }
        return this.tarifaVal;
    }

    get saldo() {
        let saldoVal = '';
        if(this.statusVal == 'Nuevo' || this.statusVal == 'En Análisis') {
            this.saldoVal = getFieldValue(this.case.data, SALDO);
        } else if(this.statusVal == 'Estimación Macro') {
            this.saldoVal = getFieldValue(this.case.data, SALDO2);
        } else if(this.statusVal == 'Documento de Especificación Funcional') {
            this.saldoVal = getFieldValue(this.case.data, SALDO3)
        } else if(this.statusVal == 'En Propuesta Económica') {
            this.saldoVal = getFieldValue(this.case.data, SALDO4)
        }
        return this.saldoVal;
    }

    get idProject() {
        let projectVal = '';
        if(this.statusVal == 'Nuevo' || this.statusVal == 'En Análisis') {
            this.projectVal = getFieldValue(this.case.data, ID_PROJECT);
        } else if(this.statusVal == 'Estimación Macro') {
            this.projectVal = getFieldValue(this.case.data, ID_PROJECT2);
        } else if(this.statusVal == 'Documento de Especificación Funcional') {
            this.projectVal = getFieldValue(this.case.data, ID_PROJECT3)
        } else if(this.statusVal == 'En Propuesta Económica') {
            this.projectVal = getFieldValue(this.case.data, ID_PROJECT4)
        }
        return this.projectVal;
    }

    handleChange(event) {
        console.log(event.detail);
        this.projectId = event.detail.recordId;
        console.log("projectId -", this.projectId);
    }

    //to assign Project in Case
    saveProyect() {
        this.isLoading = true;
        this.projectId = this.projectId == null ? this.idProject : this.projectId;

        saveProyect({caseId: this.recordId, projectId: this.projectId})
        .then(result => {
            this.isLoading = false;
            this.fireToastMessage('Éxito', 'Proyecto asignado al caso', 'success');
            this.dispatchEvent(new RefreshEvent());
        })
        .catch(error => {
            this.isLoading = false;
            this.error = error;
            this.displayMessageError(error);
        });
    }

    isJSON(str) {
        try {
            return (JSON.parse(str) && !!str);
        } catch (e) {
            return false;
        }
    }

    displayMessageError(error){
        let errorResolved = reduceErrors(error);
        
        if(this.isJSON(errorResolved[0])){
            let jsonError = JSON.parse(errorResolved[0]);
            if(typeof jsonError.error.message.value !== "undefined"){
                this.fireToastMessage('Error al asignar el Proyecto', jsonError.error.message.value, 'error');
            } else {
                this.fireToastMessage('Error al asignar el Proyecto', jsonError, 'error');
            }
        } else {
            this.fireToastMessage('Error al asignar el Proyecto', errorResolved[0], 'error');
        }
    }

    fireToastMessage(title,message,variant){
        const evt = new ShowToastEvent({
            title,
            message,
            variant
        });
        this.dispatchEvent(evt);

        return refreshApex(this.wiredAccountResults);
    }

}