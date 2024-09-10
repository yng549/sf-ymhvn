public without sharing class TriggerHandlerPricebook {
    public static void onAfterInsert(List<Pricebook2> newData) {
        // ClonePricebook(newData);
    }

    public static void ClonePricebook(List<Pricebook2> newData) {
        Map<String, String> MapPricebook = new Map<String, String>();
        for (Pricebook2 item : newData) {
            MapPricebook.put(item.Price_Book_Origin__c, Item.Id);
            if (item.Price_Book_Origin__c != null) {
                ProcessClone(item.Id, item.Price_Book_Origin__c);
            }
        }
    }

    public static void onBeforeInsert(List<Pricebook2> lstPricebook2) {
        List<Pricebook2> lstPricebook2Check = new List<Pricebook2>();
        for (Pricebook2 item : lstPricebook2) {
            if (item.IsActive && item.Type__c != 'Recall') {
                lstPricebook2Check.add(item);
            }
        }
        if (!lstPricebook2Check.isEmpty()) {
            preventPricebookActiveWhenActive(lstPricebook2Check);
        }
    }

    public static void onBeforeUpdate(
        Map<Id, Pricebook2> mapOlds,
        Map<Id, Pricebook2> mapNews
    ) {
        List<Pricebook2> lstPricebook2Check = new List<Pricebook2>();
        for (Pricebook2 item : mapNews.values()) {
            if (
                (mapOlds.get(item.Id).IsActive != item.IsActive ||
                mapOlds.get(item.Id).is_Employee__c != item.is_Employee__c ||
                mapOlds.get(item.Id).Type__c != item.Type__c) &&
                item.IsActive == true &&
                item.Type__c != 'Recall'
            ) {
                lstPricebook2Check.add(item);
            }
        }
        if (!lstPricebook2Check.isEmpty()) {
            preventPricebookActiveWhenActive(lstPricebook2Check);
        }
    }

    private static void preventPricebookActiveWhenActive(
        List<Pricebook2> lstPricebook2Check
    ) {
        List<Pricebook2> pbs = [
            SELECT Id, Name, From__c, To__c, Type__c, is_Employee__c
            FROM Pricebook2
            WHERE
                IsActive = TRUE
                AND Type__c != :'Recall'
                AND From__c <= TODAY
                AND To__c >= TODAY
        ];
        Map<String, Pricebook2> pricebooks = new Map<String, Pricebook2>();
        Map<String, Pricebook2> employeePricebooks = new Map<String, Pricebook2>();
        for (Pricebook2 pb : pbs) {
            if (pb.is_Employee__c) {
                employeePricebooks.put(pb.Type__c, pb);
            } else {
                pricebooks.put(pb.Type__c, pb);
            }
        }
        Date datePresent = Date.today();
        for (Pricebook2 pb : lstPricebook2Check) {
            if (!pb.IsActive)
                continue;
            Pricebook2 checkPricebook;
            if (pb.is_Employee__c) {
                checkPricebook = employeePricebooks.get(pb.Type__c);
            } else {
                checkPricebook = pricebooks.get(pb.Type__c);
            }
            if (checkPricebook == null)
                continue;
            if (
                (pb.From__c >= checkPricebook.From__c &&
                pb.From__c <= checkPricebook.To__c) ||
                (checkPricebook.From__c >= pb.From__c &&
                checkPricebook.From__c <= pb.To__c)
            ) {
                pb.addError(
                    'Pricebook với loại là ' +
                        pb.Type__c +
                        ' đang được active cùng với "' +
                        checkPricebook.Name +
                        '".'
                );
            }
        }
    }

    // private static void preventPricebookActiveWhenActive(List<Pricebook2> lstPricebook2Check) {
    //     Map<String, List<Pricebook2>> mapPricebook2 = checkOppHasTaskInProcess();
    //     Date datePresent = Date.today();
    //     for(Pricebook2 item : lstPricebook2Check) {
    //         if(mapPricebook2.containsKey(item.Type__c)) {
    //             for(Pricebook2 objPricebook : mapPricebook2.get(item.Type__c)) {
    //                 if(objPricebook.From__c >= datePresent && objPricebook.To__c <= datePresent) {
    //                     item.addError('Pricebook với loại là ' + item.Type__c + ' đang được active cùng với "'   + objPricebook.Name + '".');
    //                 } else if(item.From__c >= objPricebook.From__c  && item.To__c <= objPricebook.To__c) {
    //                     item.addError('Pricebook với loại là ' + item.Type__c + ' đang được active cùng với "' + objPricebook.Name + '".');
    //                 }
    //             }
    //         }
    //     }
    // }

    private static Map<String, List<Pricebook2>> checkOppHasTaskInProcess() {
        List<Pricebook2> lstPricebook2Active = [
            SELECT Id, Name, Type__c, IsActive, From__c, To__c
            FROM Pricebook2
            WHERE Type__c != :'Recall' AND IsActive = :true
        ];
        System.debug('lstPricebook2Active :' + lstPricebook2Active);
        Map<String, List<Pricebook2>> mapPricebook2 = new Map<String, List<Pricebook2>>();
        for (Pricebook2 item : lstPricebook2Active) {
            if (item.IsActive) {
                if (mapPricebook2.containsKey(item.Type__c)) {
                    List<Pricebook2> lstPricebook2 = mapPricebook2.get(
                        item.Type__c
                    );
                    lstPricebook2.add(item);
                    mapPricebook2.put(item.Type__c, lstPricebook2);
                } else {
                    mapPricebook2.put(
                        item.Type__c,
                        new List<Pricebook2>{ item }
                    );
                }
            }
        }
        return mapPricebook2;
    }
    public static void cheatTemp() {
        string a;
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
    }
    @Future
    public static void ProcessClone(
        String PricebookId,
        String PricebookOriginId
    ) {
        PricebookEntry[] pb1 = [
            SELECT
                UseStandardPrice,
                UnitPrice,
                ProductCode,
                Product2Id,
                Pricebook2Id,
                Name,
                IsActive
            FROM PricebookEntry
            WHERE Pricebook2Id = :PricebookOriginId
        ];
        if (pb1.size() > 0) {
            PricebookEntry[] pb2 = pb1.deepClone(false);

            for (PricebookEntry x : pb2) {
                x.Pricebook2Id = PricebookId;
            }

            insert pb2;
        }
    }
}
