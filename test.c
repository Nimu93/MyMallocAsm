#include <stdio.h>

void* mymalloc(size_t size); // Replace the default mymalloc
void* myfree(void* ptr); // Replace the default myfree

int main() {
    // Test 1: Allocation simple
    printf("Test 1: Allocation simple\n");

    int *ptr = (int*) mymalloc(sizeof(int)); // Allocation d'un entier
    if (ptr == NULL) {
        printf("Échec de l'allocation de mémoire.\n");
        return 1;
    }

    *ptr = 42;  // Assigner une valeur
    printf("Valeur de ptr: %d\n", *ptr);

    myfree(ptr);  // Libérer la mémoire
    printf("Mémoire libérée.\n");

    // Test 2: Allocation de plusieurs blocs
    printf("\nTest 2: Allocation de plusieurs blocs\n");

    int *ptr1 = (int*) mymalloc(sizeof(int));  // Allocation du premier bloc
    char *ptr2 = (char*) mymalloc(50 * sizeof(char));  // Allocation du second bloc
    float *ptr3 = (float*) mymalloc(10 * sizeof(float));  // Allocation du troisième bloc

    if (ptr1 == NULL || ptr2 == NULL || ptr3 == NULL) {
        printf("Échec de l'allocation de mémoire.\n");
        return 1;
    }

    *ptr1 = 10;
    *ptr2 = 'A';
    ptr3[0] = 3.14;

    printf("Valeur de ptr1: %d\n", *ptr1);
    printf("Valeur de ptr2: %c\n", *ptr2);
    printf("Valeur de ptr3[0]: %f\n", ptr3[0]);

    myfree(ptr1);  // Libérer le premier bloc
    myfree(ptr2);  // Libérer le second bloc
    myfree(ptr3);  // Libérer le troisième bloc

    printf("Mémoire libérée pour tous les blocs.\n");

    // Test 3: Tentative de libération d'un pointeur NULL
    printf("\nTest 3: Tentative de libération d'un pointeur NULL\n");

    int *null_ptr = NULL;

    // Libération d'un pointeur NULL ne doit rien faire
    myfree(null_ptr);  // Aucune action ne devrait être effectuée, et il ne doit y avoir de crash

    printf("La tentative de libération d'un pointeur NULL n'a pas causé de crash.\n");


    // Test 5: Allocation et libération dans une boucle
    printf("\nTest 5: Allocation et libération dans une boucle\n");

    for (int i = 0; i < 10; i++) {
        int *loop_ptr = (int*) mymalloc(sizeof(int));
        if (loop_ptr == NULL) {
            printf("Échec de l'allocation de mémoire.\n");
            return 1;
        }

        *loop_ptr = i;  // Assigner une valeur
        printf("Valeur de loop_ptr[%d]: %d\n", i, *loop_ptr);

        myfree(loop_ptr);  // Libérer la mémoire
    }

    printf("Tous les blocs de mémoire ont été alloués et libérés avec succès.\n");

    // Test 6: Libération de mémoire après double myfree
    printf("\nTest 6: Libération de mémoire après double myfree\n");

    int *double_free_ptr = (int*) mymalloc(sizeof(int));  // Allocation d'un bloc de mémoire
    if (double_free_ptr == NULL) {
        printf("Échec de l'allocation de mémoire.\n");
        return 1;
    }

    *double_free_ptr = 10;
    printf("Valeur de double_free_ptr: %d\n", *double_free_ptr);

    myfree(double_free_ptr);  // Libération de la mémoire
    printf("Mémoire libérée.\n");

    myfree(double_free_ptr);  // Double myfree (ne devrait pas causer de problème si géré correctement)
    printf("Double myfree effectué sans erreur (si implémentation correcte).\n");

    // Test 7: Allocation de mémoire et vérification de l'initialisation (en utilisant calloc)
   /* printf("\nTest 7: Allocation avec calloc (initialisation à zéro)\n");

    int *calloc_ptr = (int*) calloc(10, sizeof(int));  // Allouer 10 entiers (initialisés à zéro)
    if (calloc_ptr == NULL) {
        printf("Échec de l'allocation de mémoire.\n");
        return 1;
    }

    for (int i = 0; i < 10; i++) {
        printf("calloc_ptr[%d] = %d\n", i, calloc_ptr[i]);  // Tous devraient être 0
    }

    myfree(calloc_ptr);  // Libérer la mémoire
    printf("Mémoire libérée.\n");*/

    return 0;
}
