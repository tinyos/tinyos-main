#include<Dhv.h>
interface DhvNeighbour{
	command uint8_t getNeighbourCount();
	command void addNeighbour(uint8_t nodeId);
}
