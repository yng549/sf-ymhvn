public class SurveyCalculateHelper {
	public static Decimal calculatePoint(List<Order> listOrder,Decimal KPITarget,Monthly_KPI_Employee__c employee,List<Monthly_KPI_Employee_Detail__c> listMKPIDetail,String rule)
    {        
        Decimal countSurvey = 0;
        
        Decimal CSI = 0;
        Decimal PSI = 0;
        Decimal NPS = 0;
        Decimal TSI = 0;    
        
        Decimal allCSISelection = 0;
        Decimal allPSISelection = 0;
        Decimal allNPSSelection = 0;
        Decimal positiveCSISelection = 0;   
        Decimal positivePSISelection = 0;     
        Decimal positiveNPSSelection = 0;
        Decimal negativeNPSSelection = 0;
        
        
        for(Order o : listOrder)
        {  
            //system.debug('Before if : '+ o.Id + ', Is Survery : '+o.Is_Surveyed__c+ ', Status : '+o.Status);
            if(o.Is_Surveyed__c == true && o.Status == 'Completed')
            {
                //system.debug(o.Id);

                countSurvey++;
                
                allCSISelection += o.CSI__c;
                allPSISelection += o.PSI__c;
                allNPSSelection += o.NPS__c;
                
                positiveCSISelection += o.CSI_Positive__c;
                positivePSISelection += o.PSI_Positive__c;
                positiveNPSSelection += o.NPS_Positive__c;
                negativeNPSSelection += o.NPS_Nagative__c;
                
                listMKPIDetail.add(KPIHelper.createEmployeeRuleDetail(o.Id, rule, 0,employee.Id, 'Order', 'Order Survey', null));
                
                //system.debug('Order Surveyed : '+o.Id);
            }
        }
        
        //system.debug('P PSI :'+ positivePSISelection);
        //system.debug('All PSI '+ allPSISelection);
        
        CSI = allCSISelection != 0 ? positiveCSISelection / allCSISelection * 100 : 0;
        PSI = allPSISelection != 0 ? positivePSISelection / allPSISelection * 100 : 0;
        NPS = allNPSSelection != 0 ? (positiveNPSSelection / allNPSSelection - negativeNPSSelection / allNPSSelection ) * 100 : 0;
        
        employee.CSI__c = CSI;
        employee.PSI__c = PSI;
        employee.NPS__c = NPS;
        
        //system.debug('CSI :'+ CSI);
        //system.debug('PSI :'+ PSI);
        //system.debug('NPS :'+ NPS);
        
        if(CSI >= 80)
        {
            TSI += 40;
        }
        else if(CSI >= 70)
        {
            TSI += 35;
        }
        else if(CSI >= 60)
        {
            TSI += 30;
        }
        else
        {
            TSI += 25;
        }
        
        //system.debug('TSI 1 : '+TSI); // 25
        
        if(PSI >= 90)
        {
            TSI += 40;
        }
        else if(PSI >= 80)
        {
            TSI += 35;
        }
        else if(PSI >= 70)
        {
            TSI += 30;
        }
        else
        {
            TSI += 25;
        }
        
        //system.debug('TSI 2 : '+TSI); // 55
        
        if(NPS >= 50)
        {
            TSI += 20;
        }
        else
        {
            TSI += 15;
        }   
        
        //system.debug('TSI 3 : '+TSI); // 70
        
        if(countSurvey == 0)
        {
            TSI = KPITarget;
        }
        
        employee.TSI__c = TSI;
        
        return TSI;
    }
}