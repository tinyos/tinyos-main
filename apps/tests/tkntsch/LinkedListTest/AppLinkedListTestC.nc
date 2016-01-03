configuration AppLinkedListTestC
{
} implementation {

	components MainC;
	components LinkedListTestC;
	components PrintfC;
	components SerialStartC;
	components new LinkedListC(message_t*, 10) as List;

	LinkedListTestC -> MainC.Boot;
	LinkedListTestC.Queue -> List;
	LinkedListTestC.LinkedList -> List;
	List.Compare -> LinkedListTestC;
}
