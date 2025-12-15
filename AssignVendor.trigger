trigger AssignVendor on Maintenance_Request__c (before insert) {
    // Query all vendors once
    List<Vendor__c> allVendors = [SELECT Id FROM Vendor__c];
    if (allVendors.isEmpty()) {
        return; // No vendors to assign
    }

    // Initialize workload map (default 0)
    Map<Id, Integer> vendorWorkload = new Map<Id, Integer>();
    for (Vendor__c v : allVendors) {
        vendorWorkload.put(v.Id, 0);
    }

    // Query current open workloads once
    for (AggregateResult ar : [
        SELECT Vendor__c, COUNT(Id) cnt
        FROM Maintenance_Request__c
        WHERE Status__c = 'Open'
        GROUP BY Vendor__c
    ]) {
        Id vId = (Id)ar.get('Vendor__c');
        Integer cnt = (Integer)ar.get('cnt');
        if (vendorWorkload.containsKey(vId)) {
            vendorWorkload.put(vId, cnt);
        }
    }

    // Sort vendors by workload (ascending)
    List<Id> sortedVendors = new List<Id>();
    Map<Id, Integer> remaining = new Map<Id, Integer>(vendorWorkload);
    while (!remaining.isEmpty()) {
        Id minVendor;
        Integer minCount = 9999999; // use a large literal instead of MAX_VALUE
        for (Id vId : remaining.keySet()) {
            Integer c = remaining.get(vId);
            if (c < minCount) {
                minCount = c;
                minVendor = vId;
            }
        }
        sortedVendors.add(minVendor);
        remaining.remove(minVendor);
    }

    // Round‑robin assignment without modulo operator
    Integer idx = 0;
    Integer size = sortedVendors.size();
    for (Maintenance_Request__c req : Trigger.new) {
        if (idx == size) {
            idx = 0; // wrap around
        }
        req.Vendor__c = sortedVendors[idx];
        idx = idx + 1;
    }
}
