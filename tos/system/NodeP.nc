/* 
@author Md.Jamal <mjmohiuddin@cdac.in>
@version $Revision: 1.0

*/
//#include "printf.h"
module NodeP 
{

	provides interface Node;

}


implementation
{
	bool Router=FALSE;
 	bool LBR=FALSE;
 	bool HOST=FALSE;
	command void Node.setHost()
	{
		//printf("\n Node is set as Host");
		HOST=TRUE;
	}

	command bool Node.getHostState()
	{
		return HOST;

	}

	command void Node.unsetHost()
	{
		//printf("\n Not a HOST now");
		HOST=FALSE;
	}
	command void Node.setRouter()
	{
		//printf("\n Node is set as Router");
		Router=TRUE;
	}

	command bool Node.getRouterState()
	{

		return Router;
	}

	command void Node.setLBR()
	{
		//printf("\n Node is set as LBR");		
		LBR=TRUE;
	}
	
	command bool Node.getLBRState()
	{
		return LBR;
	}
	
}
