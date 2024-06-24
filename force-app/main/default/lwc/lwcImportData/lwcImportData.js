import { LightningElement, track, api } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { CloseActionScreenEvent } from "lightning/actions";
// import csvFileRead from '@salesforce/apex/LwcImportDataController.csvFileRead';
// import readFileFromRecord from '@salesforce/apex/LwcImportDataController.readFileFromRecord';
import readData from '@salesforce/apex/LwcImportDataController.readData';
import { loadScript } from 'lightning/platformResourceLoader';
import excelFileReader from '@salesforce/resourceUrl/sheetmin';

let XLS = {};

export default class LwcImportData extends LightningElement {
    @api recordId;
    @api objectApiName;
    @track error;
    @track loading=false;
    /*Accepted formats for the excel file*/

    @track acceptedFormats = ['.xls', '.xlsx'];
    strUploadFileName; //Store the name of the selected file.
    objExcelToJSON; //Javascript object to store the content of the file

    connectedCallback() {
        Promise.all([loadScript(this, excelFileReader)])
        .then(() => {
            XLS = XLSX;
            // this.readFromFile()
        })
        .catch((error) => {
            console.log('An error occurred while processing the file');
            console.log(JSON.stringify(error));
        });
    }

    // async readFromFile() {
    //     let returnVal = await readFileFromRecord({recordId:this.recordId})
    //     let wb = XLS.read(returnVal, {type:'base64', WTF:false});
    //     console.log(this.to_json(wb));
    // }


    handleCancel() {
        this.dispatchEvent(new CloseActionScreenEvent());
    }
    to_json(workbook) {
        var result = {};
		workbook.SheetNames.forEach(function(sheetName) {
			var roa = XLS.utils.sheet_to_json(workbook.Sheets[sheetName], {header:1});
			if(roa.length) result[sheetName] = roa;
		});
		return JSON.stringify(result, 2, 2);
    }

    handleUploadFinished(event){
        this.loading = true;
        const uploadedFiles = event.detail.files;
        if(uploadedFiles.length > 0) {   
            this.ExcelToJSON(uploadedFiles[0])
        }
    }
    ExcelToJSON(file){
        var reader = new FileReader();
        reader.onload = event => {
            var data=event.target.result;
            var workbook=XLS.read(data, {
                type: 'binary',
                cellDates: true
            });
            var XL_row_object = XLS.utils.sheet_to_row_object_array(workbook.Sheets["ImportTemplate"]);
            if(XL_row_object.length  === 0 ){
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Error!!',
                        message: 'Please input data in the template and change sheet name to \'ImportTemplate\'',
                        variant: 'Error',
                    }),
                );
                this.loading = false;
                return;
            }
            console.log('test');
          
            XL_row_object = XL_row_object.map(x => {
                if(x.RetailPriceRevisionDate__c){
                    x.RetailPriceRevisionDate__c = Date.parse(x.RetailPriceRevisionDate__c) + (7*3700000);
                }
                return x;
            });

            XL_row_object = XL_row_object.map(x => {
                if(x.WholesalePriceRevisionDate__c){
                    x.WholesalePriceRevisionDate__c = Date.parse(x.WholesalePriceRevisionDate__c) +(7*3700000);
                }
                return x;
            });
              console.log('test2');
            let jsondata = JSON.stringify(XL_row_object);
      
            console.log(jsondata);
        
          
            readData({ jsonData: jsondata,
                        recordId: this.recordId,
                        objectApiName: this.objectApiName
            })
            .then(res => {
                if(res.success){
                    this.loading = false;
                    this.dispatchEvent(
                        new ShowToastEvent({
                            title: 'Success!!',
                            message: 'Upload data success',
                            variant: 'Success',
                        }),
                    );
                }else{
                    this.loading = false;
                    this.dispatchEvent(
                        new ShowToastEvent({
                            title: 'Error!!',
                            message: res.error,
                            variant: 'error',
                        }),
                    );
                }
               
            })
            .catch(error => {
                this.loading = false;
                this.error = error;
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Error!!',
                        message: JSON.stringify(error),
                        variant: 'error',
                    }),
                );
                console.log(JSON.stringify(error));
            });
         
        };
        reader.onerror = function(ex) {
            this.loading = false;
            this.error=ex;
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Error while reding the file',
                    message: ex.message,
                    variant: 'error',
                }),
            );
        };
        reader.readAsBinaryString(file);
 
    }
  
}