/* 
@author Md.Jamal <mjmohiuddin@cdac.in>
@version $Revision: 1.0

*/

configuration NodeC
{

	provides interface Node;
}

implementation {

	components NodeP;
	Node=NodeP;
}
