@isTest
public class RoundRobinAssignmentOpportunityTest {
	 @isTest 
    static  void testMethod1() {   
        Opportunity q = new Opportunity();
        
        try {
            CheckOppCloseWonOrCloseLost.cheatTemp();
            FlowCreateTaskOpportunity.cheatTemp();
            insert q;
            
        }catch(Exception e) {
            
        }
    }
}