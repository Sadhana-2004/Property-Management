@isTest
public class AssignVendorTest {
    @testSetup
    static void setupData() {
        // Create vendors
        List<Vendor__c> vendors = new List<Vendor__c>();
        for (Integer i = 0; i < 3; i++) {
            vendors.add(new Vendor__c(Name = 'Vendor ' + i));
        }
        insert vendors;

        // Create a property
        Property__c prop = new Property__c(
            Address__c = 'Addr',
            City__c = 'City',
            State__c = 'State',
            Postal_Code__c = '12345',
            Country__c = 'India',
            Type__c = 'Residential',
            Status__c = 'Available',
            Rent__c = 10000,
            Description__c = 'Test'
        );
        insert prop;
    }

    @isTest
    static void testBulkInsert() {
        Property__c prop = [SELECT Id FROM Property__c LIMIT 1];
        List<Maintenance_Request__c> requests = new List<Maintenance_Request__c>();
        for (Integer i = 0; i < 200; i++) {
            requests.add(new Maintenance_Request__c(
                Property__c = prop.Id,
                Status__c = 'Open',
                Description__c = 'Bulk ' + i
            ));
        }
        insert requests;

        List<Maintenance_Request__c> inserted =
            [SELECT Vendor__c FROM Maintenance_Request__c WHERE Id IN :requests];
        for (Maintenance_Request__c r : inserted) {
            System.assertNotEquals(null, r.Vendor__c, 'Vendor should be assigned');
        }

        // Distribution check
        Set<Id> distinctVendors = new Set<Id>();
        for (Maintenance_Request__c r : inserted) {
            distinctVendors.add(r.Vendor__c);
        }
        System.assert(distinctVendors.size() > 1,
            'Requests should be distributed across multiple vendors');
    }
}
