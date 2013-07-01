#include <stdio.h>

#include <CUnit/CUnit.h>
#include <CUnit/Basic.h>

/* #include <coap.h> */

#include "test_uri.h"
#include "test_options.h"
#include "test_pdu.h"


int
main(int argc, char **argv) {
  CU_ErrorCode result;
  CU_BasicRunMode run_mode = CU_BRM_VERBOSE;

  if (CU_initialize_registry() != CUE_SUCCESS) {
    fprintf(stderr, "E: test framework initialization failed\n");
    return -2;
  }

  t_init_uri_tests();
  t_init_option_tests();
  t_init_pdu_tests();

  CU_basic_set_mode(run_mode);
  result = CU_basic_run_tests();

  CU_cleanup_registry();

  printf("\n\nknown bugs:\n");
  printf("\t- Test: t_parse_uri5 ... FAILED\n"
	 "\t    1. test_uri.c:109  - CU_FAIL(\"invalid port not detected\")\n");
  printf("\t- Test: t_parse_uri12 ... FAILED\n"
    	 "\t    1. test_uri.c:301  - result == 4\n"
    	 "\t    2. test_uri.c:302  - buflen == sizeof(uricheckbuf)\n"
    	 "\t    3. test_uri.c:303  - CU_ASSERT_NSTRING_EQUAL(buf,uricheckbuf,buflen)\n"
         "\t    4. test_uri.c:309  - buflen == sizeof(querycheckbuf)\n"
         "\t    5. test_uri.c:310  - CU_ASSERT_NSTRING_EQUAL(buf,querycheckbuf,buflen)\n");

  return result;
}
