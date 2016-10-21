# InstallSolidCP

-Requirements-
* PowerShell Version 5
* Windows O\S
* PowerShell IIS Module

## Resources

* **InstallSolidCP** Allows for easy installing and uninstalling of the SolidCP components.

### InstallSolidCP

* **component**:           Component to be installed the options are 'Server', 'Enterprise Server', 'Portal'.
* **ensure**:              Should the component be installed or not.
* **portalPassword**:      The serveradmin password.
* **serverPassword**:      The password used to connect to the servers from the enterprise server.
* **enterpriseServerURL**: The enterprise server URL that the portal should connect to.

## Versions

### 1.0.0.0
####Limitations
* Doesn't support Domain User install.
* Doesn't remove DB or DB User when Enterprise Server is uninstalled.
* Doesn't remove component information from SolidCP.Installer.exe.xml when component uninstalled.
* Doesn't support all the possible switches

* Initial release with the following resources:
    * InstallSolidCP