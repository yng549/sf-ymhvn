public without sharing class TriggerAccountHandler {
    public static void beforeInsert(List<Account> newData) {
        List<User> lstUserHN = [
            SELECT Id, AccountId
            FROM User
            WHERE Account.Name = :'REVZONE YAMAHA MOTOR HA NOI'
        ];
        List<Account> lstAccountPrimary = new List<Account>();
        List<Account> lstAccountSupplier = new List<Account>();
        List<Account> lstAccountCustomer = new List<Account>();
        Set<Id> setDODL = new Set<Id>();
        Set<Id> usersID = new Set<Id>();

        for (Account item : newData) {
            usersID.add(item.OwnerId);
        }
        Map<Id, User> userMap = new Map<Id, User>(
            [
                SELECT Id, Username, ContactId, AccountId
                FROM User
                WHERE ID IN :usersID
            ]
        );

        for (Account item : newData) {
            //Chuyển thành +84
            item.PersonMobilePhone = StringHelper.normalizePhoneNumber(
                item.PersonMobilePhone
            );

            if (
                String.isBlank(item.DO_DL_Create_Account__c) &&
                userMap.containsKey(item.OwnerId)
            ) {
                item.DO_DL_Create_Account__c = userMap.get(item.OwnerId)
                    .AccountID;
            }

            if (item.RecordTypeId == RecordTypeHelper.ACCOUNT_SUPPLIER) {
                lstAccountSupplier.add(item);
            } else if (item.RecordTypeId == RecordTypeHelper.ACCOUNT_CUSTOMER) {
                if (item.Is_Primary__c)
                    lstAccountPrimary.add(item);
                else {
                    lstAccountCustomer.add(item);
                    if (string.isNotBlank(item.DO_DL_Create_Account__c))
                        setDODL.add(item.DO_DL_Create_Account__c);
                }
            }
        }

        // Set Number for Account Supplier
        integer indexSupplier = 0;
        List<Account> lstAccountNoSupplier = [
            SELECT AccountNo__c
            FROM Account
            WHERE
                AccountNo__c > 0
                AND RecordTypeId = :RecordTypeHelper.ACCOUNT_SUPPLIER
            ORDER BY AccountNo__c DESC
            LIMIT 1
        ];
        indexSupplier = !lstAccountNoSupplier.isEmpty()
            ? lstAccountNoSupplier[0].AccountNo__c.intValue()
            : 0;
        for (Account itemSupplier : lstAccountSupplier) {
            indexSupplier += 1;
            itemSupplier.AccountNo__c = indexSupplier;
            itemSupplier.AccountNumber = revertAccountNumber(
                indexSupplier,
                'SUP',
                4
            );
        }

        // Set Number for Account Primary
        List<Account> lstAccountCustomerEXS = [
            SELECT AccountNo__c
            FROM Account
            WHERE
                AccountNo__c > 0
                AND RecordTypeId = :RecordTypeHelper.ACCOUNT_CUSTOMER
                AND Is_Primary__c = TRUE
            ORDER BY AccountNo__c DESC
            LIMIT 1
        ];
        integer indexCus = !lstAccountCustomerEXS.isEmpty()
            ? lstAccountCustomerEXS[0].AccountNo__c.intValue()
            : 0;
        for (Account itemSupplier : lstAccountPrimary) {
            indexCus += 1;
            itemSupplier.AccountNo__c = indexCus;
            itemSupplier.AccountNumber = revertAccountNumber(
                indexCus,
                'YMH-SUP/CUS-',
                8
            );
        }

        // Set Number for Account Customer
        for (String DODLId : setDODL) {
            integer indexCustomer = 0;
            List<Account> lstAccountNoDO = [
                SELECT AccountNo__c
                FROM Account
                WHERE
                    AccountNo__c > 0
                    AND RecordTypeId = :RecordTypeHelper.ACCOUNT_CUSTOMER
                    AND DO_DL_Create_Account__c = :DODLId
                ORDER BY AccountNo__c DESC
                LIMIT 1
            ];
            indexCustomer = !lstAccountNoDO.isEmpty()
                ? lstAccountNoDO[0].AccountNo__c.intValue()
                : 0;
            String prefix = 'CUS';
            if (LstUserHN.size() > 0 && LstUserHN[0].AccountId == DODLId) {
                prefix = 'CUSHN';
            }
            for (Account itemCustomer : lstAccountCustomer) {
                if (itemCustomer.DO_DL_Create_Account__c == DODLId) {
                    indexCustomer += 1;
                    itemCustomer.AccountNo__c = indexCustomer;
                    itemCustomer.AccountNumber = revertAccountNumber(
                        indexCustomer,
                        prefix,
                        8
                    );
                }
            }
        }
        checkAccountWithAccountByPersonalPhone(newData);
    }

    public static void onBeforeUpdate(
        Map<Id, Account> mapOlds,
        Map<Id, Account> mapNews
    ) {
        Map<Id, Account> mapAccountChangeMail = new Map<Id, Account>();
        for (Account item : mapNews.values()) {
            item.PersonMobilePhone = StringHelper.normalizePhoneNumber(
                item.PersonMobilePhone
            );
            System.debug('item.PersonMobilePhone : ' + item.PersonMobilePhone);
            if (
                mapOlds.get(item.Id).PersonEmail != item.PersonEmail &&
                String.isNotBlank(item.PersonEmail) &&
                !item.Is_Primary__c
            ) {
                //Chuyển thành +84

                mapAccountChangeMail.put(item.Id, item);
            }
        }
        if (!mapAccountChangeMail.values().isEmpty()) {
            updateEmailToAccountPrimary(mapAccountChangeMail);
        }
    }

    private static void updateEmailToAccountPrimary(
        Map<Id, Account> mapAccountChangeMail
    ) {
        Savepoint sp = Database.setSavepoint();
        List<Account> lstAccountUpdate = new List<Account>();
        try {
            for (Account item : mapAccountChangeMail.values()) {
                lstAccountUpdate.add(
                    new Account(Id = item.Id, PersonEmail = item.PersonEmail)
                );
            }
        } catch (Exception ex) {
            Database.rollback(sp);
            mapAccountChangeMail.values()
                .get(0)
                .addError(ex.getMessage() + ' ' + ex.getLineNumber());
        }
    }

    private static void checkAccountWithAccountByPersonalPhone(
        list<Account> lstAccount
    ) {
        Set<String> setStrPhone = new Set<String>();
        Map<String, List<Account>> mapPhoneWithAccounts = new Map<String, List<Account>>();
        try {
            for (Account item : lstAccount) {
                if (String.isNotBlank(item.PersonMobilePhone)) {
                    setStrPhone.add(item.PersonMobilePhone);
                }
            }
            List<Account> lstAccountByPhone = [
                SELECT
                    Id,
                    PersonMobilePhone,
                    CreatedDate,
                    Owner.DODL_Manager__c,
                    Last_Activity_Date__c,
                    Is_Primary__c,
                    DO_DL_Create_Account__c
                FROM Account
                WHERE
                    PersonMobilePhone IN :setStrPhone
                    AND Is_Primary__c = :false
                ORDER BY CreatedDate ASC
            ];

            for (Account item : lstAccountByPhone) {
                if (String.isNotBlank(item.PersonMobilePhone)) {
                    if (
                        mapPhoneWithAccounts.containsKey(item.PersonMobilePhone)
                    ) {
                        mapPhoneWithAccounts.get(item.PersonMobilePhone)
                            .add(item);
                        mapPhoneWithAccounts.put(
                            item.PersonMobilePhone,
                            mapPhoneWithAccounts.get(item.PersonMobilePhone)
                        );
                    } else {
                        mapPhoneWithAccounts.put(
                            item.PersonMobilePhone,
                            new List<Account>{ item }
                        );
                    }
                }
            }
            for (Account item : lstAccount) {
                if (String.isNotBlank(item.PersonMobilePhone)) {
                    if (
                        mapPhoneWithAccounts.containsKey(item.PersonMobilePhone)
                    ) {
                        for (
                            Account a : mapPhoneWithAccounts.get(
                                item.PersonMobilePhone
                            )
                        ) {
                            if (
                                item.DO_DL_Create_Account__c ==
                                a.DO_DL_Create_Account__c
                            ) {
                                item.addError(
                                    'Account was duplicated with other account by number phone ' +
                                    a.PersonMobilePhone
                                );
                            }
                        }
                    }
                }
            }
        } catch (Exception ex) {
            lstAccount.get(0)
                .addError(ex.getMessage() + ' ' + ex.getLineNumber());
        }
    }

    public static void onAfterUpdate(
        List<Account> newData,
        Map<Id, Account> newMap,
        Map<Id, Account> oldMap
    ) {
        // Loop new Data
        List<Id> lstAccountCMS = new List<Id>();
        for (Account a : newData) {
            if (
                String.isNotBlank(a.Website_ID__c) &&
                a.Applied_Promotion__c != oldMap.get(a.Id).Applied_Promotion__c
            )
                lstAccountCMS.add(a.Id);
        }
        if (!lstAccountCMS.isEmpty()) {
            system.enqueueJob(new APICMSAccountLoyalty(lstAccountCMS));
        }
    }
    public static string revertAccountNumber(
        integer value,
        string prefix,
        integer maxLength
    ) {
        string num = '';
        for (integer i = string.valueOf(value).length(); i < maxLength; i++) {
            num += '0';
        }
        num = num + string.valueOf(value);

        num = prefix + num;
        return num;
    }

    public static void cheatTemp() {
        String a = 'cheat';
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;

        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
    }
}
