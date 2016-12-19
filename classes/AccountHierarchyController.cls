/*
 *   @Author: Simon McVeigh - Acumen Solutions
 *   Purpose: This class is responsible for building/controlling Account Hierarchy page.
 *
 */
public class AccountHierarchyController {

    // component attributes
    public Account fromAccount { get; set; }
    public Boolean displayLeafNodes { get; set; }
    public Boolean displayAdvancedView { get; set; }
    
        
    public List<Product2> allProductGroups {
        get {
            if (allProductGroups == null && accountHierarchy.allProductGroups.size() > 0) {
            	allProductGroups = new List<Product2>();
            	allProductGroups.addAll(accountHierarchy.allProductGroups);
            	allProductGroups.sort();
            }
            return allProductGroups;
        }
        private set;
    }
    
    public Boolean fromAccountIsLeafNode {
        get {
            if (fromAccountIsLeafNode == null) {
                fromAccountIsLeafNode = accountHierarchy.fromAccountIsLeafNode;
            }
            return fromAccountIsLeafNode;
        }
        private set;
    }
    
    public AccountHierarchy accountHierarchy {
        get {
            if (accountHierarchy == null) {
                try {
                    if (fromAccount != null) accountHierarchy = new AccountHierarchy(fromAccount, displayAdvancedView, displayLeafNodes);
                    if (accountHierarchy != null) accountHierarchy.includeLeafNodes = displayLeafNodes;
                }
                catch (Exception ex) {
                    Utilities.addExceptionAndMessage(System.Label.Account_Hierarchy_General_Error, ex);
                }
            }
            return accountHierarchy;
        }
        private set;
    }
    
    public List<AccountHierarchy.AccountHierarchyNode> accountHierarchyNodeList {
        get {
            if (accountHierarchyNodeList == null) {
                try {
                    accountHierarchyNodeList = accountHierarchy.getHierarchy();
                }
                catch (Exception ex) {
                    Utilities.addExceptionAndMessage(System.Label.Account_Hierarchy_General_Error, ex);
                }
            }
            return accountHierarchyNodeList;
        }
        private set;
    }
    
    // Constructor
    public AccountHierarchyController() {
        displayLeafNodes = true;
        displayAdvancedView = true;
    }
    
    public PageReference reloadHierarchy() {
        accountHierarchy.includeLeafNodes = displayLeafNodes;
        accountHierarchyNodeList = accountHierarchy.getHierarchy();
        return null;
    }
}