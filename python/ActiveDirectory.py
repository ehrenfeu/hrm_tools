'''
ActiveDirectory

Manages active directory connections through the adLDAP library
@author: Aaron Ponti
'''
import ldap

class ActiveDirectory(object):
    '''
    Class to manage user authentication and information querying against
    ActiveDirectory.
    '''
    
    # The account suffix for your domain
    ACCOUNT_SUFFIX = ''
    
    # The base dn for your domain
    BASE_DN = ''
    
    # Domain controller
    DOMAIN_CONTROLLER = ''
    
    # Account with higher privileges for searching (username and password). 
    # Only read-only actions are performed.
    ADMIN_USERNAME = ''
    ADMIN_PASSWORD = ''
    
    # Use SSL (LDAPS)
    USE_SSL = False

    # Use TSL
    USE_TLS = False

    # LDAP connection port
    PORT = -1
    
    # LDAP connection object
    LDAP_CONNECTION = None
    

    def __init__(self, account_suffix, base_dn, domain_controller,
                 admin_username, admin_password, use_ssl=False, use_tls=False):
        '''
        Constructor.

Arguments:

account_suffix:      the account suffix for your domain
base_dn:             the base dn for your domain
domain_controller:   domain controller server
admin_username:      name of the (proxy) user with higher privileges for 
                     searching (exclusively read-only operations are 
                     performed)
admin_username:      password of the (proxy) user with higher privileges
                     for searching (exclusively read-only operations are 
                     performed)
use_ssl:             (default = False) use SSL (LDAPS) for connection
                     (port 636 instead of 389)
use_tls:             start TLS on connection
        '''
        
        # Set properties
        self.ACCOUNT_SUFFIX = account_suffix
        self.BASE_DN = base_dn
        self.DOMAIN_CONTROLLER = domain_controller
        self.ADMIN_USERNAME = admin_username
        self.ADMIN_PASSWORD = admin_password
        self.USE_SSL = use_ssl
        self.USE_TLS = use_tls

        # Set port
        if self.USE_SSL is True:
            self.PORT = 636
        else:
            self.PORT = 389
        
        # Set up connection
        self._connect()

    def __del__(self):
        '''
        Destructor.
        '''
        
        # Close connection if it exists
        self.close()


    def authenticate(self, username, password):
        '''
        Authenticate specified, non-admin user.
        '''
        
        # Check whether the user can bind
        success = self._bind(username, password)
        
        # Now rebind with the admin user
        self._bind(self.ADMIN_USERNAME, self.ADMIN_PASSWORD)
        
        # Return the status of the authentication of the normal user
        return success
       
        
    def close(self):
        '''
        Close LDAP connection
        '''
        if self.LDAP_CONNECTION is not None:
            self.LDAP_CONNECTION.unbind_s()

            
    def emailAddress(self, username):
        '''
        Query and return the email address associated to specified username.
        '''
        
        # Prepare filter
        Filter = "(&(objectClass=user)(sAMAccountName=" + username + "))"
        
        # Attribute
        Attrs = ["mail"]
        
        # Get the email address
        values = self._search(Filter, Attrs)
        if values is not None:
            Name, Attrs = values[0]
            if hasattr(Attrs, 'has_key') and Attrs.has_key('mail'):
                return Attrs['mail'][0]
            else:
                return ""
        return ""


    def group(self, username):
        '''
        Query and returns the group(s) to which a user belongs.
        '''
        
        # @todo Implement

        
    def _bind(self, username, password):
        '''
        Binds to the domain controller with specified user
        '''
        
        # Sanity check on the input parameters
        if (username is None or username is '') or \
        (password is None or password is ''):
            return False
        
        # Try to bind with the passed credentials
        try:
            self.LDAP_CONNECTION.simple_bind_s(username + self.ACCOUNT_SUFFIX,
                                               password)
            return True
        except:
            return False

            
    def _connect(self):
        '''
        Connect to domain (private)
        
        Return True if connecting and binding the admin user was successful,
        False otherwise.
        '''

        # Build the full URL
        if self.USE_SSL is True:
            protocol = "ldaps://"
        else:
            protocol = "ldap://"
                    
        url = protocol + self.DOMAIN_CONTROLLER + ":" + str(self.PORT)
        
        print("Connecting to " + url + "\n")

        # Connect
        try:
            self.LDAP_CONNECTION = ldap.initialize(url)
        except ldap.LDAPError, e:
            print e
            return False    
        
        # Set some options necessary to talk to Active Directory
        self.protocol_version = 3
        self.LDAP_CONNECTION.set_option(ldap.OPT_REFERRALS, 0)

        # Start TLS if needed
        if self.USE_TLS is True:
            try:
                self.LDAP_CONNECTION.set_option(ldap.OPT_X_TLS,
                                                ldap.OPT_X_TLS_DEMAND)
                self.LDAP_CONNECTION.start_tls_s()
            except ldap.LDAPError, e:
                print e
                return False

        # Bind as the admin user
        if self.ADMIN_USERNAME is not None and self.ADMIN_USERNAME is not '':
            try:
                self.LDAP_CONNECTION.simple_bind_s(self.ADMIN_USERNAME +
                                               self.ACCOUNT_SUFFIX,
                                               self.ADMIN_PASSWORD)
                return True
            
            except ldap.LDAPError, e:
                print e
                return False
          

    def _search(self, Filter, Attrs, scope=ldap.SCOPE_SUBTREE):
        '''
        Serch LDAP (private method)
        '''
        
        if self.LDAP_CONNECTION is None:
            return None

        # Search
        response = self.LDAP_CONNECTION.search(self.BASE_DN, scope,
                                               Filter, Attrs)

        # Get the values 
        Type, values = self.LDAP_CONNECTION.result(response, 60)
        
        # Return them
        return values
