/*
@author Md.Jamal <mjmohiuddin@cdac.in>
@version $Revision: 1.0

*/

interface Node {


	/* It is used to set the node acts as Host*/

	command void setHost();


	/*It is used to check whether the node is host or not
	  Returns FALSE if it is not a host
	  Returns TRUE if it is a host*/

	command bool getHostState();


	/* It is used to unset the Node from Host */
	command void unsetHost();

	/* It is used to set the node to act as Router*/
	command void setRouter();

	/* It is used to check whether the node is router or not
		Returns FALSE when it is not a Router
		Returns TRUE when it is Router */
	command bool getRouterState();

	/* It is used to set the node to act as 6LoWPAN Border Router*/
	command void setLBR();


	/* It is used to check whether the node is EdgeRouter or Not
		Returns FALSE when it is not a EdgeRouter
		Returns TRUE when it is a EdgeRouter*/

	command bool getLBRState();

}
