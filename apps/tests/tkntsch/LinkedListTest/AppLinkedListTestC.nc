configuration AppLinkedListTestC
{
} implementation {

	components MainC;
	components LinkedListTestC;
	components PrintfC;
	components SerialStartC;
	components new LinkedListC(10) as List;

	LinkedListTestC -> MainC.Boot;
	LinkedListTestC.Queue -> List;
	LinkedListTestC.LinkedList -> List;
}
