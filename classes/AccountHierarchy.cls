/*
 *   @Author: Simon McVeigh - Acumen Solutions
 *   Purpose: This class is the primary programatic interface to managing and querying Account Hierarchy.
 *
 */
 
public class AccountHierarchy {

  /*
   *  Wrapper class representing a single Account Hierarchy Node
  */
  public class AccountHierarchyNode {
  
    public Integer hierarchyLevel { get; private set; }
    public Boolean isLeafNode { get; private set; }
    public String recordType { get; private set; }
    public String accountOwner { get; private set; }
    public Account account { get; private set; }
    public List<String> reportLink {get;private set;}
    
    public Set<Product2> productGroups { get; private set; }
    public String productGroupsCSV { get; private set; }
    public Integer productGroupsCount { 
      get { 
        return (productGroups != null) ? productGroups.size() : 0; 
      }
    }
    
    public List<AccountTeamMember> accountTeamMembers { get; private set; }
    public String accountTeamMembersCSV { get; private set; }
    public Integer accountTeamMembersCount { 
      get { 
        return (accountTeamMembers != null) ? accountTeamMembers.size() : 0; 
      }
    }
    public String reportLink1{get;set;}
    public String reportLink2{get;set;}
    
    // child ID list for report list
    // columns for advanced view as fields (Product Groups, Owner List, Payment Terms, etc)
    
  }

  // TODO: hard coded record type names could be moved to custom setting, or queried on 'Tyco_CE' prefix if needs be (do we want to give them this flexibility?)
  private final Set<String> RECORD_TYPE_NAMES = new Set<String>{'Tyco_International_Account','Tyco_Global_Account','National_Account','Regional_Account','Site_Account'};
  
  public Account fromAccount { get; set; }
  public Boolean fromAccountIsLeafNode { get; private set; }
  public Boolean includeLeafNodes { get; set; }
  public Boolean includeAdvanced { get; set; }
  
  // populated as part of getter for productsByAccountId
  // TODO: abstract to independently built set, sorted alphanumerically
  public Set<Product2> allProductGroups = new Set<Product2>();
  
  private List<Account> accounts {
    get {
      if (accounts == null) {
        accounts = getAccountsByUltimateParentId(fromAccount.Ultimate_Parent_Id__c);
        System.debug('Created accounts list: ' + accounts);
      }
      return accounts;
    }
    set;
  }
  
  private Set<Id> accountIds {
    get {
      if (accountIds == null) {
        accountIds = new Set<Id>();
        for (Account a : accounts) {
          accountIds.add(a.Id);
        }
        System.debug('Created accountIds set: ' + accountIds);
      }
      return accountIds;
    }
    set;
  }
  
  // TODO: extract to AccountUtility class
  private Map<String,RecordType> recordTypesByName {
    get {
      if (recordTypesByName == null) {
        recordTypesByName = new Map<String,RecordType>();
        for (RecordType rt : recordTypes) {
          recordTypesByName.put(rt.DeveloperName, rt);
        }
        System.debug('Created recordTypesByName: ' + recordTypesByName);
      }
      return recordTypesByName;
    }
    set;
  }
  
  private List<RecordType> recordTypes { 
    get {
      if (recordTypes == null) {
        recordTypes = getRecordTypes();
      }
      return recordTypes;
    }
    set;
  }
  
  private Set<Id> recordTypeIds {
    get {
      if (recordTypeIds == null) {
        recordTypeIds = (Set<Id>) Utilities.sObjectListToIdSet( (List<sObject>) recordTypesByName.values() );
      }
      return recordTypeIds;
    }
    private set;
  }
  
  /*
   *  Retrieves a distinct list of Product2Ids from first 40,000 line items used in close/won opptys for each account in this hierarchy
   *  where the close date of the opportunity falls within the last two years.
   *
   *  It is used to establish INDICATIVE Product Group usage by account. It is NOT designed for accurate product usage reporting
   *  as it cannot operate on the entire Opportunity Line Item data set for all accounts in very large hierarchies, or with a long history
   */
  private Map<Id,Set<Product2>> productsByAccountId {
    get {
      if (productsByAccountId == null) {
        
        Set<Product2> productSet = new Set<Product2>();
        productsByAccountId = new Map<Id, Set<Product2>>();
        
        for (OpportunityLineItem li : [SELECT Opportunity.AccountId, PricebookEntry.Product2.Id, PricebookEntry.Product2.Name
                        FROM OpportunityLineItem
                        WHERE Opportunity.IsClosed = true
                          AND Opportunity.IsWon = true
                          AND Opportunity.AccountId IN :accountIds
                        ORDER BY Opportunity.AccountId
                        LIMIT 40000])
        {
          // is there an existing set for this account? If so, retrieve it otherwise create a new set
          productSet = (!productsByAccountId.containsKey(li.Opportunity.AccountId)) ? new Set<Product2>() : productsByAccountId.get(li.Opportunity.AccountId);
          // add latest product2 record
          productSet.add(li.PricebookEntry.Product2);
          // add to all product groups set
          allProductGroups.add(li.PricebookEntry.Product2);
          // add/replace product set for this account
          productsByAccountId.put(li.Opportunity.AccountId, productSet);
          
          System.debug('added product set ' + productSet + ' to account ' + li.Opportunity.AccountId);
        }
      }
      return productsByAccountId;
    }
    set;
  }
  
  public AccountHierarchy(Account fromAccount, Boolean includeAdvanced, Boolean includeLeafNodes) {
    this.fromAccount = getAccount(fromAccount.Id);
    this.includeAdvanced = includeAdvanced;
    this.includeLeafNodes = includeLeafNodes;
  }
  
  public List<AccountHierarchyNode> getHierarchy() {
    AccountHierarchyNode node;
    List<AccountHierarchyNode> nodeList = new List<AccountHierarchyNode>();
    
    //Report Link values;
    String oppReportId;
    String sHistoryId;
    CustomerHierarchyReports__c chReport1 = CustomerHierarchyReports__c.getInstance('One');
    CustomerHierarchyReports__c chReport2 = CustomerHierarchyReports__c.getInstance('Two');
    if(chReport1 != null)
      {oppReportId = chReport1.Report_Id__c;}
      if(chReport2 != null)
      {sHistoryId = chReport2.Report_Id__c;}
      
      TCE_Account_Report_Fields__c gFields = TCE_Account_Report_Fields__c.getInstance('Ultimate Parent Id');
      TCE_Account_Report_Fields__c iFields = TCE_Account_Report_Fields__c.getInstance('Hierarchy International Account');
      TCE_Account_Report_Fields__c nFields = TCE_Account_Report_Fields__c.getInstance('Hierarchy National Account');
      TCE_Account_Report_Fields__c rFields = TCE_Account_Report_Fields__c.getInstance('Hierarchy Regional Account');
      TCE_Account_Report_Fields__c shGFields = TCE_Account_Report_Fields__c.getInstance('SH Ultimate Parent Id');
      TCE_Account_Report_Fields__c shIFields = TCE_Account_Report_Fields__c.getInstance('SH Hierarchy International Account');
      TCE_Account_Report_Fields__c shNFields = TCE_Account_Report_Fields__c.getInstance('SH Hierarchy National Account');
      TCE_Account_Report_Fields__c shRFields = TCE_Account_Report_Fields__c.getInstance('SH Hierarchy Regional Account');
      TCE_Account_Report_Fields__c shSFields = TCE_Account_Report_Fields__c.getInstance('SH Account Id');
      
      String gFieldId = gFields.Field_Id__c;
      
      System.debug('iField'+iFields);
     
      String iFieldId = iFields.Field_Id__c;
      
      String nFieldId = nFields.Field_Id__c;
      String rFieldId = rFields.Field_Id__c;
      String sFieldId = 'ACCOUNT_ID';
      
      String shgFieldId = shGFields.Field_Id__c;
      String shiFieldId = shIFields.Field_Id__c;
      String shnFieldId = shNFields.Field_Id__c;
      String shrFieldId = shRFields.Field_Id__c;
      String shsFieldId = shSFields.Field_Id__c;
        
    for (Account a : accounts) {
      node = new AccountHierarchyNode();
      node.Account = a;
      node.hierarchyLevel = getHierarchyLevel(node.Account);
      node.isLeafNode = (node.hierarchyLevel == 5);
      
      //Create Report Links
      String pv0 = '';
      String pv1 = '';
      String pv2 = '';

      if(a.RecordType.Name == 'Tyco Global Account'){
        node.reportLink1 = '/' + oppReportId + '?pc0=' + gFieldId + '&pn0=eq&pv0=' + String.ValueOf(a.Ultimate_Parent_Id__c).Left(15);
        node.reportLink2 = '/' + sHistoryId + '?pc0=' + shgFieldId + '&pn0=eq&pv0=' + String.ValueOf(a.Ultimate_Parent_Id__c).Left(15);
      }
      else if(a.RecordType.Name == 'International Account'){
        node.reportLink1 = '/' + oppReportId + '?pc0=' + iFieldId + '&pn0=eq&pv0=' + String.ValueOf(a.Hierarchy_International_Account__c).Left(15);
        node.reportLink2 = '/' + sHistoryId + '?pc0=' + shiFieldId + '&pn0=eq&pv0=' + String.ValueOf(a.Hierarchy_International_Account__c).Left(15);
      }
      else if(a.RecordType.Name == 'National Account'){
        node.reportLink1 = '/' + oppReportId + '?pc0=' + nFieldId + '&pn0=eq&pv0=' + String.ValueOf(a.Hierarchy_National_Account__c).Left(15);
        node.reportLink2 = '/' + sHistoryId + '?pc0=' + shnFieldId + '&pn0=eq&pv0=' + String.ValueOf(a.Hierarchy_National_Account__c).Left(15);
      }else if(a.RecordType.Name == 'Regional Account'){
        node.reportLink1 = '/' + oppReportId + '?pc0=' + rFieldId + '&pn0=eq&pv0=' + String.ValueOf(a.Hierarchy_Regional_Account__c).Left(15);
        node.reportLink2 = '/' + sHistoryId + '?pc0=' + shrFieldId + '&pn0=eq&pv0=' + String.ValueOf(a.Hierarchy_Regional_Account__c).Left(15);
      }else if(a.RecordType.Name == 'Site Account'){
        node.reportLink1 = '/' + oppReportId + '?pc0=' + sFieldId + '&pn0=eq&pv0=' + String.ValueOf(a.Id).Left(15);
        node.reportLink2 = '/' + sHistoryId + '?pc0=' + shsFieldId + '&pn0=eq&pv0=' + String.ValueOf(a.Id).Left(15);
      }
      
      // add advanced information
      if (includeAdvanced) {
        System.debug('Adding advanced information for account ' + a.Id);
        if (productsByAccountId.containsKey(node.Account.Id)) {
          node.productGroups = productsByAccountId.get(node.Account.Id);
          node.productGroupsCSV = getProductGroupsAsDelimitedList(node.productGroups);
        }
        else {
          node.productGroupsCSV = '-';
        }
        if (a.AccountTeamMembers.size() > 0) {
          node.accountTeamMembers = a.AccountTeamMembers;
          node.accountTeamMembersCSV = accountTeamUsersAsCSV(a.AccountTeamMembers);
          System.debug('Added Account Team: ' + node.accountTeamMembers);
        }
      }
      
      if (includeLeafNodes || (!includeLeafNodes && !node.isLeafNode)) nodeList.add(node);
    }
    System.debug('retrieved hierarchy containing ' + nodeList.size() + ' node(s). ' + nodeList);

      
    return sortByLevel(nodeList);
  }
  
  private Integer getHierarchyLevel(Account account) {
    
    if (account.RecordTypeId == recordTypesByName.get('Site_Account').Id) return 5;
    if (account.RecordTypeId == recordTypesByName.get('Regional_Account').Id) return 4;
    if (account.RecordTypeId == recordTypesByName.get('National_Account').Id) return 3;
    if (account.RecordTypeId == recordTypesByName.get('Tyco_International_Account').Id) return 2;
    
    // TODO: adapt hierarchy level for scenarios where no global account exists
      
    else return 1;
  }
  
  private List<Account> getAccountsByUltimateParentId(Id ultimateParentId) {
    System.debug('ultimate parent ID: ' + ultimateParentId);
    List<Account> returnList = new List<Account>();
    
    for(Account a : [Select Id, Name, Owner.Name, OwnerId, RecordTypeId, RecordType.Name, Ultimate_Parent_Id__c,Hierarchy_Regional_Account__c, Hierarchy_National_Account__c,Hierarchy_International_Account__c,
            BillingCity, BillingCountry, Payment_Terms_Agreed__c, Payment_Terms_Description__c, 
              (Select AccountId, UserId, User.Name, TeamMemberRole From AccountTeamMembers)
        From Account
        Where isPersonAccount = false
          and RecordTypeId IN :recordTypeIds
          // this is the only instance that uses Ultimate Parent ID
          // for other queries, use 'AccountID IN :accountIds', which is populated from this query
          and Ultimate_Parent_Id__c = :String.valueOf(ultimateParentId).substring(0,15)
        Order By BillingCountry DESC ])
        
    {
      //Adding this to make sure the case sensitive Id comparison is implemented.
      if(a.Ultimate_Parent_Id__c == ultimateParentId){
        returnList.Add(a);
      }
    }
    
    return returnList;
  }
  
  private Account getAccount(Id accountId) {
    return [Select Id, Name, Ultimate_Parent_Id__c, RecordType.Name From Account Where Id = :accountId];
  }
  
  private List<RecordType> getRecordTypes() {
    return [Select Id, Name, DeveloperName 
        From RecordType
        Where sObjectType = 'Account'
          and DeveloperName IN :RECORD_TYPE_NAMES];  
  }
  
  private String sObjectListAsDelimitedList(List<sObject> objects, String key, String delimiter) {
    // TODO: extract to utility class
    String str = '';
      delimiter = (delimiter == null) ? ', ' : delimiter;
      key = (key == null) ? 'Name' : key;
      
      for (sObject obj : objects) {
        try {
          str += obj.get(key) + delimiter;
        }
        catch(System.NullPointerException ex) {
          System.debug('no key "' + key + '" found on obj ' + obj);
        }
      }
      return str.substring(0,str.length() - (delimiter.length()));
  }
  
  /*
   * Type-specific implementation of sObjectListAsDelimitedList, as User.Name cannot be retrieved dynamically
   * Should look for a way to genericise when more time available
   */
  private String accountTeamUsersAsCSV(List<AccountTeamMember> objects) {
    
    // TODO: extract to utility class
    String str = '';
      String delimiter = ', ';
      
      for (AccountTeamMember obj : objects) {
        str += obj.User.Name + ' (' + obj.TeamMemberRole + ')' + delimiter;
      }
      
      return str.substring(0,str.length() - (delimiter.length()));
  }
  
  /*
   * Type-specific implementation of sObjectListAsDelimitedList, as Product2 cannot be cast to sObject
   * Should look for a way to genericise when more time available
   */
  private String getProductGroupsAsDelimitedList(Set<Product2> objSet) {
    
    // TODO: extract to utility class
    String str = '';
      String delimiter = ', ';
      String key = 'Name';
      
      for (Product2 obj : objSet) {
        try {
          str += obj.get(key) + delimiter;
        }
        catch(System.NullPointerException ex) {
          System.debug('no key "' + key + '" found on obj ' + obj);
        }
      }
      return str.substring(0,str.length() - (delimiter.length()));
  }
  
  /*
   * Accounts have a Hierarchy level associated with them. Sort according to that level.
     This function generates a custom key for each node in listToSort. This key is tied to a node in a map.
     The map then gets sorted according to hierachy level.
  */
  private List<AccountHierarchyNode> sortByLevel(List<AccountHierarchyNode> listToSort) {
    Integer maxLevel = 1;
    String key;
    List<AccountHierarchyNode> returnList = new List<AccountHierarchyNode>();
    Map<String, AccountHierarchyNode> nodesByCompositeKey = new Map<String, AccountHierarchyNode>();
    List<String> compositeKeyList = new List<String>();

    // Get a list of all the levels combined with record Id as a keyed set.
    // Each pass through the loop generates a unique sort key for each AccountHierarchyNode.
    for (AccountHierarchyNode node : listToSort) {
   
      
      key = node.account.Ultimate_parent_Id__c;
      
      
      if(node.account.Hierarchy_International_Account__c != '' && node.account.Hierarchy_International_Account__c != node.account.Id)
        key = key + '-' + node.account.Hierarchy_International_Account__c + '-1';
      else
        key = key + '-' + node.account.Hierarchy_International_Account__c + '-0';
      
          

      if(node.account.Hierarchy_National_Account__c != '' && node.account.Hierarchy_National_Account__c != node.account.Id)
        key = key + '-' + node.account.Hierarchy_National_Account__c + '-1';
      else
        key = key + '-' + node.account.Hierarchy_National_Account__c + '-0';
      
      if(node.account.Hierarchy_Regional_Account__c != '' && node.account.Hierarchy_Regional_Account__c != node.account.Id)
        key = key + '-' + node.account.Hierarchy_Regional_Account__c + '-1';
      else
        key = key + '-' + node.account.Hierarchy_Regional_Account__c + '-0';
        
      
      
      key = key + '-' + node.hierarchyLevel;
    
      
      // Ensure top level always comes first.
      if (node.hierarchyLevel == maxLevel)
        key = maxLevel + '-' + key;
      else
        key = '2-' + key;

      // Nodes at the same hierarchy level are the same until this point. 
      // Appends the nodes' id to the end of the key to make it unique.
      // Otherwise, the same key could be mapped onto multiple nodes.
      key = key + '-' + node.account.id;
        
      nodesByCompositeKey.put(key, node);
      system.debug('nodesByCompositeKey--->'+nodesByCompositeKey);
      compositeKeyList.add(key);
     
    }

    // Sort primitive type list that contains composite keys.
    compositeKeyList.sort();
    System.debug('Key sort:'+ compositeKeyList); 
    // Loop through the set and append records by sorted Id.
    for (String cKey : compositeKeyList) {
      returnList.add(nodesByCompositeKey.get(cKey));
    }

    return returnList; 
  }
}