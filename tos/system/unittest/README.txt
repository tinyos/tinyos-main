Crude infrastructure for TinyOS unit tests.

In the implementation section of your application configuration, add this
line:

#include <unittest/config_impl.h>

Where the specification section of your application module changes to the
implementation section, use this pattern:

#include <unittest/module_spec.h>
} implementation {
#include <unittest/module_impl.h>

Within your test module, use these macros:

ASSERT_EQUAL(v1, v2);
ASSERT_EQUAL_32(long1, long2);
ASSERT_EQUAL_PTR(p1, p2);
ASSERT_TRUE(condition);

Put the following line after all tests:

ALL_TESTS_PASSED()

Then make platform install, cat /dev/ttyUSB0, and watch as everything is
verified.  If something goes wrong, the red LED will be lit and failure will
be repeatedly printed to the screen, including the parameters and the line
number of the failure.  If everything goes right, the green LED will be lit
and "All tests passed" will be printed to the screen.

You can run all unit tests that are found within a directory (default:
${TOSROOT/apps}) by using the ${TOSDIR}/system/unittests/runtests script.

When creating a new unit test, copy the basic configuration (Makefile,
application configuration, application module) from
${TOSDIR}/system/unittest/Stub.
