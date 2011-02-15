#include <stdio.h>

module TestP {
  uses interface Boot;
#include <unittest/module_spec.h>
} implementation {
#include <unittest/module_impl.h>
  event void Boot.booted () {
    ALL_TESTS_PASSED();
  }
}
