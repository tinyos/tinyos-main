// $Id: motelist-win32.cpp,v 1.3 2006-11-07 19:30:42 scipio Exp $

/* "Copyright (c) 2000-2003 The Regents of the University of California.  
 * All rights reserved.
 *
 * Permission to use, copy, modify, and distribute this software and its
 * documentation for any purpose, without fee, and without written agreement
 * is hereby granted, provided that the above copyright notice, the following
 * two paragraphs and the author appear in all copies of this software.
 * 
 * IN NO EVENT SHALL THE UNIVERSITY OF CALIFORNIA BE LIABLE TO ANY PARTY FOR
 * DIRECT, INDIRECT, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL DAMAGES ARISING OUT
 * OF THE USE OF THIS SOFTWARE AND ITS DOCUMENTATION, EVEN IF THE UNIVERSITY
 * OF CALIFORNIA HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 * 
 * THE UNIVERSITY OF CALIFORNIA SPECIFICALLY DISCLAIMS ANY WARRANTIES,
 * INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY
 * AND FITNESS FOR A PARTICULAR PURPOSE.  THE SOFTWARE PROVIDED HEREUNDER IS
 * ON AN "AS IS" BASIS, AND THE UNIVERSITY OF CALIFORNIA HAS NO OBLIGATION TO
 * PROVIDE MAINTENANCE, SUPPORT, UPDATES, ENHANCEMENTS, OR MODIFICATIONS."
 */

// @author Cory Sharp <cssharp@eecs.berkeley.edu>

#include <iostream>
#include <string>
#include <vector>
#include <stdexcept>
#include <list>

#include <windows.h>

namespace TelosList
{
using std::cout;
using std::endl;

typedef std::string String;
typedef const String& StringRef;
typedef std::vector<String> VecString;

struct RegValue
{
  typedef long long int_type;
  String name;
  String data;
  int_type data_int;
  int data_type;

  RegValue()
    : data_int(0), data_type(0)
  {
  }

  RegValue( StringRef _name, StringRef _data, int _type )
    : name(_name), data(_data), data_int(atoi(data.c_str())), data_type(_type)
  {
  }

  RegValue( StringRef _name, int_type _data, int _type )
    : name(_name), data(), data_int(_data), data_type(_type)
  {
    char buf[16];
    int nbuf = sprintf( buf, "%lld", data_int );
    data = String( buf, buf+nbuf );
  }

  RegValue( StringRef _name, const char* _data, DWORD _dlen, int _type )
    : name(_name), data_type(_type)
  {
    char buf[256];
    int nbuf = 0;

    switch( data_type )
    {
      case REG_BINARY:
      case REG_EXPAND_SZ:
      case REG_MULTI_SZ:
      case REG_SZ:
	data = String( _data, _dlen );
	data_int = atoi( _data );
	break;

      case REG_NONE:
	break;

      case REG_DWORD:
	data_int = *(DWORD*)_data;
	nbuf = sprintf( buf, "%d", *(DWORD*)_data );
	data = String( buf, buf+nbuf );
	break;

      case REG_QWORD:
	data_int = *(long long*)_data;
	nbuf = sprintf( buf, "%lld", *(long long*)_data );
	data = String( buf, buf+nbuf );
	break;

      default:
	throw std::runtime_error( "unsupported data type in " + name );
    }
  }
};


class RegKey;
typedef std::vector<RegKey> VecRegKey;
typedef std::vector<RegValue> VecRegValue;


class RegKey
{
  HKEY m_hkey;
  String m_name;

  void openKey( HKEY hkey, StringRef subkey )
  {
    LONG result = RegOpenKeyEx( hkey, subkey.c_str(), 0, (KEY_READ&~KEY_NOTIFY), &m_hkey );
    if( result != ERROR_SUCCESS )
      throw std::runtime_error( "could not open key " + m_name );
  }

  void prefixName( HKEY root )
  {
    if( root == HKEY_LOCAL_MACHINE )
      m_name = "HKLM\\" + m_name;
  }

public:

  ~RegKey()
  {
    RegCloseKey(m_hkey);
    m_hkey = (HKEY)INVALID_HANDLE_VALUE;
  }

  RegKey( HKEY hkey, StringRef subkey )
    : m_hkey((HKEY)INVALID_HANDLE_VALUE), m_name(subkey)
  {
    prefixName( hkey );
    openKey( hkey, subkey );
  }

  RegKey( const RegKey& key, StringRef subkey )
    : m_hkey((HKEY)INVALID_HANDLE_VALUE), m_name(key.m_name+"\\"+subkey)
  {
    openKey( key.m_hkey, subkey );
  }

  RegKey getSubkey( StringRef subkey ) const
  {
    return RegKey( m_hkey, subkey );
  }

  RegKey operator[]( StringRef subkey ) const
  {
    return getSubkey( subkey );
  }

  RegValue operator()( StringRef value ) const
  {
    return getValue( value );
  }

  RegValue getValue( StringRef value ) const;

  VecString getSubkeyNames() const;
  VecRegValue getValues() const;
};


VecString RegKey::getSubkeyNames() const
{
  VecString v;
  DWORD i = 0;

  while(true)
  {
    DWORD len = 4096;
    char name[len];
    LONG result = RegEnumKeyEx( m_hkey, i++, name, &len, NULL, NULL, NULL, NULL );

    if( result == ERROR_NO_MORE_ITEMS )
      break;

    if( result != ERROR_SUCCESS )
      throw std::runtime_error( "error iterating keys in " + m_name );

    v.push_back( String(name, name+len) );
  }

  return v;
}


RegValue RegKey::getValue( StringRef value ) const
{
  DWORD dtype = 0;
  DWORD dlen = 4096;
  char data[dlen];
  LONG result = RegQueryValueEx( m_hkey, value.c_str(), NULL, &dtype, (BYTE*)data, &dlen );

  if( result != ERROR_SUCCESS )
    throw std::runtime_error( "error iterating values in " + m_name );

  return RegValue( value, data, dlen, dtype );
}


VecRegValue RegKey::getValues() const
{
  VecRegValue v;
  DWORD i = 0;

  while(true)
  {
    DWORD nlen = 4096;
    DWORD dlen = 4096;
    char name[nlen];
    char data[dlen];
    DWORD dtype = 0;
    LONG result = RegEnumValue( m_hkey, i++, name, &nlen, NULL, &dtype, (BYTE*)data, &dlen );
    dtype = REG_NONE;
    dlen = 0;

    if( result == ERROR_NO_MORE_ITEMS )
      break;

    if( result != ERROR_SUCCESS )
      throw std::runtime_error( "error iterating values in " + m_name );

    v.push_back( RegValue( String(name,name+nlen), data, dlen, dtype ) );
  }

  return v;
}


struct Device
{
  String id;
  String comm;
  String info;
  int sortnum;
  int refcount;

  Device(): sortnum(0), refcount(0) { }

  bool operator<( const Device& a ) const
  {
    if( sortnum < a.sortnum )
      return true;
    
    if( sortnum == a.sortnum )
      return (id < a.id);

    return false;
  }
};

typedef std::list<Device> ListDevice;

String join( StringRef sep, const VecString& vs )
{
  String j;
  VecString::const_iterator i = vs.begin();
  if( i != vs.end() ) j = *i++;
  while( i != vs.end() ) j += sep + *i++;
  return j;
}

String join( StringRef sep, const VecRegValue& vrv )
{
  String j;
  VecRegValue::const_iterator i = vrv.begin();
  if( i != vrv.end() ) { j = i->name+"="+i->data; i++; }
  while( i != vrv.end() ) { j = i->name+"="+i->data; i++; }
  return j;
}

VecString split( const char* chars, StringRef str )
{
  VecString vs;

  String::size_type n0 = 0;
  String::size_type n1 = str.find_first_of( chars, 0 );
  vs.push_back( str.substr( n0, n1 ) );

  while( n1 != String::npos )
  {
    n0 = n1+1;
    n1 = str.find_first_of( chars, n0 );
    if( n1 != String::npos ) vs.push_back( str.substr( n0, n1-n0 ) );
    else vs.push_back( str.substr( n0 ) );
  }

  return vs;
}

int getRefCount( const RegKey& dclass, const RegKey& key )
{
  int refcnt = 0;

  try
  {
    String symstr = key["Device Parameters"]("SymbolicName").data;
    VecString sym = split( "\\#", symstr );

    if( sym.size() >= 4 )
    {
      sym.erase( sym.begin(), sym.begin()+sym.size()-4 );
      String devstr = sym[3] +"\\##?#" + join("#",sym) + "\\Control";
      RegKey ctrl = dclass[devstr];
      refcnt = strtol( ctrl("ReferenceCount").data.c_str(), NULL, 0 );
    }
  }
  catch( std::runtime_error e ) { }

  return refcnt;
}

ListDevice getDevices()
{
  ListDevice devs;

  String ccs = "SYSTEM\\CurrentControlSet\\";
  RegKey dclass( HKEY_LOCAL_MACHINE, ccs+"Control\\DeviceClasses" );
  RegKey ftdibus( HKEY_LOCAL_MACHINE, ccs+"Enum\\FTDIBUS" );
  RegKey usb6001( HKEY_LOCAL_MACHINE, ccs+"Enum\\USB\\Vid_0403&Pid_6001" );

  VecString fdev = ftdibus.getSubkeyNames();
  for( VecString::const_iterator i=fdev.begin(); i!=fdev.end(); i++ )
  {
    if( i->substr(0,18) == String("VID_0403+PID_6001+") )
    {
      Device d;
      d.id = i->substr(18,8);

      try
      {
	RegKey devkey = ftdibus[*i];
	VecString devsub = devkey.getSubkeyNames();
	d.comm = devkey[devsub[0]+"\\Device Parameters"]("PortName").data;
      }
      catch( std::runtime_error e )
      {
	d.comm = "no_comm";
      }

      try { d.info = usb6001[d.id]("LocationInformation").data; }
      catch( std::runtime_error e ) { }

      try { d.refcount = getRefCount( dclass, usb6001[d.id] ); }
      catch( std::runtime_error e ) { }

      String::size_type ncomm = d.comm.find_first_of("0123456789");
      if( ncomm != String::npos )
	d.sortnum = atoi( d.comm.substr(ncomm).c_str() );

      devs.push_back(d);
    }
  }

  return devs;
}


void prettyPrintDevices( const ListDevice& devs )
{
  const char* fmt = "%-10s %-10s %s\n";
  printf( fmt, "Reference", "CommPort", "Description" );
  printf( "---------- ---------- ----------------------------------------\n" );

  for( ListDevice::const_iterator i=devs.begin(); i!=devs.end(); i++ )
  {
    String comm = i->comm;
    if( i->refcount == 0 )
    {
      char buf[256];
      int n = snprintf( buf, 255, " (%s)", i->comm.c_str() );
      comm = String( buf, buf+n );
    }
    printf( fmt, i->id.c_str(), comm.c_str(), i->info.c_str() );
  }
}

void printDevices( const ListDevice& devs )
{
  for( ListDevice::const_iterator i=devs.begin(); i!=devs.end(); i++ )
  {
    cout << i->id << "," << i->comm << ","
	 << i->refcount << "," << i->info << endl;
  }
}

ListDevice getActiveDevices( const ListDevice& devs )
{
  ListDevice active;
  for( ListDevice::const_iterator i=devs.begin(); i!=devs.end(); i++ )
  {
    if( i->refcount > 0 )
      active.push_back( *i );
  }
  return active;
}

void usage()
{
  cout << "usage: motelist [-l] [-c]\n"
       << "\n"
       << "  $Revision: 1.3 $ $Date: 2006-11-07 19:30:42 $\n"
       << "\n"
       << "options:\n"
       << "  -h  display this help\n"
       << "  -l  long format, also display disconnected devices\n"
       << "  -c  compact format, not pretty but easier for parsing\n"
       << std::endl;
}

int main( VecString args )
{
  bool showall = false;
  bool compact = false;
  //bool recovery = false;

  for( VecString::size_type n=1; n!=args.size(); n++ )
  {
    StringRef opt = args[n];
    if( opt == "-h" ) { usage(); return 0; }
    else if( opt == "-l" ) { showall = true; }
    else if( opt == "-c" ) { compact = true; }
    else if( opt == "-c" ) { compact = true; }
    else { usage(); throw std::runtime_error("unknown command line option "+opt); }
  }

  ListDevice devs = getDevices();

  if( showall == false )
    devs = getActiveDevices( devs );

  devs.sort();

  if( devs.empty() )
    { cout << "No devices found." << endl; return 2; }
  else if( compact )
    printDevices( devs );
  else
    prettyPrintDevices( devs );

  return 0;
}

}//namespace TelosList


int main( int argc, char* argv[] )
{
  try
  {
    return TelosList::main( TelosList::VecString(argv,argv+argc) );
  }
  catch( std::runtime_error e )
  {
    std::cerr << "error, " << e.what() << std::endl;
  }
  return 1;
}

