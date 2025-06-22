#include <stdio.h>
#include <stdlib.h>

/* This program reads two vectors from the command line and
   multiplies them. The syntax for the command line is:
   program_name operation dimension vector_content
   so an example would be: vector m 1 2 4
   in this case the vectors are of dimension 1 and the content
   is x=(2) and y=(4)
   another example: vector m 2 3 5 4 6
   here both vectors are two-dimensional x=(3,5) y=4,6)                         
*/

/* define a vector as being a struct with data and a dimension,
   use an array of flexible length */
typedef struct {
  int dimension; /* the vectors dimension */
  int *data; /* the vectors data */
} vector;

/* define global constant */
const int minArgC=3;

/* reads in a vector from the command line, parameters are:
   the vector to read data into, the vectors dimension (i.e. how
   many numbers to read) and the commandline arguments starting
   with the first number that is content for the vector */
void readVector(vector *vector, int dimension, char *argv[])
{
  int i;

  vector->dimension=dimension;
  vector->data=(int *)malloc(dimension*sizeof(int));
 
  for (i=0;i<dimension;i++)
    vector->data[i]=atoi(argv[i]);
  return;
}

/* multiply two vectors to a scalar */
int mult (vector x, vector y)
{
  int i;
  int result=0;

  for (i=0;i<x.dimension;i++)
    result=result+x.data[i]*y.data[i];

  return result;
}

/*
  main function: read in the data, call the operations, print out result
*/
int main(int argc, char *argv[])
{
  vector vector1, vector2; /* input */
  int dimension; /* dimension of the vectors */
  int scalar; /* computed result */

  /* this program comes with at least three arguments: 
     argv[0] is the program name, 
     argv[1] specifies the operation ('m'ultiply)  
     argv[2] is the vectors' dimension 
     followed by the integers in the vectors */

  /* read in dimension of vectors, suppress negative dimensions */
  if (atoi(argv[2])>=0)
    dimension=atoi(argv[2]);
  else 
    dimension=0;

  readVector(&vector1, dimension, &argv[minArgC]);
  readVector(&vector2, dimension, &argv[minArgC+dimension]);

  /* perform chosen operation, only one case is implemented to
     keep the code short */ 
  switch (*argv[1])
  {
    case 'm': scalar=mult(vector1, vector2);
              /* print result */
              printf("MULT %d",scalar);
              break;
    default:  printf("error in input stream\n");
              exit(1);
              break;
  }

  return 0;
}

