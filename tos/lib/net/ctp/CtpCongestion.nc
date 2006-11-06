interface CtpCongestion {

    /* Returns the current state of congestion from the provider. Ctp may be
     * congested because its internal queue is congested or because the receive
     * client called isCongested with TRUE. */

    command bool isCongested();

    /* Idempotent call to let the provider know whether a client is congested.
     * If not previously congested, Ctp will take measures to slow down.
     * Ctp has an internal congested condition as well. The result of isCongested
     * is a logical OR with the parameter set here and the internal congestion.
     */
    command void setClientCongested(bool congested);
}
