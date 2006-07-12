/*integriert shellsort Algorithmus*/
/*shellsort aufsteigend sortierend aus Kernighan Ritchie (S.61)*/


#ifndef __SHELLSORT_H__
#define __SHELLSORT_H__

void shellsort(uint16_t basis[] , uint16_t size)
{
	int gap, i, j, temp;
	
	for (gap = size/2; gap > 0; gap /= 2)
		for (i = gap; i < size; i++)
			for (j = i-gap; j >= 0 && basis[j] > basis[j+gap]; j-=gap) {
				temp = basis[j];
				basis[j] = basis[j+gap];
				basis[j+gap] = temp;
			}
}
#endif /* __SHELLSORT_H__ */
