#include <windows.h>
#include <iostream>
#include <string>
#include <algorithm>
using namespace std;

int help()
{
    cout << "usage: giveio-install [option]" << endl;
    cout << "    [option] is one of the following:" << endl;
    cout << "        --install    Installs GiveIO driver" << endl;
    cout << "        --uninstall  Uninstalls GiveIO driver" << endl;
    cout << "        --help       Prints this help message" << endl;
    return 1;
}

int error(const char* msg)
{
    cout << "giveio-install: " << msg << endl;
    return 0;
}

class auto_sc_handle {
public:
    auto_sc_handle(SC_HANDLE h_arg) : h(h_arg) { }
    ~auto_sc_handle() { CloseServiceHandle(h); }

    operator SC_HANDLE() { return h; }
private:
    SC_HANDLE h;
};

bool is_installed(SC_HANDLE scmh)
{
    bool result = false;
    size_t ess_size = sizeof(ENUM_SERVICE_STATUS) + 256 + 256;
    ENUM_SERVICE_STATUS* essp =
	reinterpret_cast<ENUM_SERVICE_STATUS*>(new char[ess_size]);
    DWORD bytes_needed = 0;
    DWORD services_returned = 0;
    DWORD resume_handle = 0;
    do {
	BOOL success =
	    EnumServicesStatus(scmh,
			       SERVICE_DRIVER/* | SERVICE_WIN32*/,
			       SERVICE_STATE_ALL,
			       essp,
			       ess_size,
			       &bytes_needed,
			       &services_returned,
			       &resume_handle);
	if (success == FALSE && GetLastError() != ERROR_MORE_DATA)
	    break;
	
	for (DWORD i = 0; i < services_returned; i++) {
	    // cout << essp[i].lpServiceName << endl;
	    if (strcasecmp(essp[i].lpServiceName, "GiveIO") == 0
		|| strcasecmp(essp[i].lpDisplayName, "GiveIO") == 0) {
		result = true;
		break;
	    }
		
	}
    } while (bytes_needed != 0 && ! result);
    delete[] essp;
    return result;
}

int install()
{
    // Taking out the input from stdin -- eases installation and if
    // the user chooses N, TOS won't work right. 
    // -lkw 1/25/2002
    //cout << "giveio-install:" << endl;
    //cout << "You are about to install the GiveIO driver" << endl;
    //cout << "on your computer!  This driver can give applications" << endl;
    //cout << "direct access to I/O, circumventing" << endl;
    //cout << "Windows NT/Windows 2000 prohibitions." << endl << endl;
    //cout << "Do you want to continue?  (Y/N) ";
    char c;
    //cin >> c;
    //cout << endl;
    //if (c != 'y' && c != 'Y')
	//return error("Installation aborted");

    auto_sc_handle scmh = OpenSCManager(0, 0, GENERIC_WRITE | GENERIC_READ);
    if (! scmh)
	return error("Could not connect to the Service Control Manager");

    if (is_installed(scmh))
	return error("Driver already installed");

    bool copy_failed = false;
    string WINDIR = getenv("WINDIR");
    if (WINDIR.empty()) {
	copy_failed = true;
	cout << "giveio-install: warning: "
	     << "WINDIR environment variable is not defined." << endl;
    } else {
	replace(WINDIR.begin(), WINDIR.end(), '\\', '/');
	const string cp =
	    "cp giveio.sys " + WINDIR + "/system32/drivers/giveio.sys";
	cout << cp << endl;
	if (system(cp.c_str()) != 0) {
	    copy_failed = true;
	    cout << "giveio-install: warning: "
		 << "Copy failed." << endl;
	}
    }
    if (copy_failed)
	cout << "giveio-install: warning: "
	     << "Please copy giveio.sys to the "
	     << "$WINDIR/system32/drivers directory." << endl;

    auto_sc_handle csh =
	CreateService(scmh,
		      "GiveIO",
		      "GiveIO Port Access",
		      SERVICE_ALL_ACCESS,
		      SERVICE_KERNEL_DRIVER,
		      SERVICE_AUTO_START,
		      SERVICE_ERROR_NORMAL,
		      "system32\\drivers\\giveio.sys",
		      0,
		      0,
		      0,
		      0,
		      0);
    if (csh == 0)
      return error("Could not create service");
    BOOL result = StartService(csh,0,NULL);
    if (!result)
      return error("Could not start service");
    return 0;
}

int uninstall()
{
  SERVICE_STATUS status;
    auto_sc_handle scmh = OpenSCManager(0, 0, GENERIC_WRITE | GENERIC_READ);
    if (! scmh)
	return error("Could not connect to the Service Control Manager");

    if (! is_installed(scmh))
	return error("Driver has not been installed");
    auto_sc_handle csh =
	OpenService(scmh,
		    "GiveIO",
		    SERVICE_ALL_ACCESS);
    if (!csh)
	return error("Could not access GiveIO driver");
    BOOL result = ControlService(csh,
				 SERVICE_CONTROL_STOP,
				 &status);
    if (!result) {
      cout << "giveio-install: warning:"
	   << "The GiveIO service could not be stopped. "
	   << "Uninstall will complete when the system restarts." << endl;
    }
    DeleteService(csh);
    return 0;
}

int main(int argc, char* argv[])
{
    enum actions {
	a_install,
	a_uninstall,
	a_help
    } action = a_install;

    for (int i = 1; i < argc; i++) {
	if (strcmp(argv[i], "--install") == 0)
	    action = a_install;
	else if (strcmp(argv[i], "--uninstall") == 0)
	    action = a_uninstall;
	else if (strcmp(argv[i], "--help") == 0)
	    action = a_help;
	else
	    action = a_help;
    }
    switch (action) {
    case a_help:
	return help();
    case a_install:
	return install();
    case a_uninstall:
	return uninstall();
    }
    return 0;
}
