#!/bin/bash
#
# Script che avvia un proxy di tipo socks tramite ssh. Riavvia il proxy se si
# blocca e permette di fermarlo una volta finito di usarlo.
#
# Autore: Paolo Scaramuzza
#

#######################################
# Variabili globali di configurazione #
#######################################
CONTROL_SOCKET="proxyctl_socket"
SSH_KEY="./tunnel_rsa"
PROXY_PORT="9999"
PROXY_TARGET=""

# Returns 0 if the proxy is running 255 otherwise
function proxy_running {
	ssh -S $CONTROL_SOCKET -O check $PROXY_TARGET >/dev/null 2>&1
	return $?
}
# Wait for the user to press q
function waitq {
	read -n 1
	if [ $REPLY == "q" -o $REPLY == "Q" ]; then
		echo ""
		exit 0
	fi
}
# Shutdown the proxy on exit
function stop_proxy {
	echo "Disattivo il proxy..."
	ssh -S $CONTROL_SOCKET -O exit $PROXY_TARGET >/dev/null 2>&1
}

########
# main #
########
trap stop_proxy EXIT

while :
do
	if proxy_running; then
		echo "Il proxy è attivo sulla porta $PROXY_PORT. Premi q per uscire."
		waitq
	else
		echo "Avvio del proxy in corso..."
		ssh -M -S $CONTROL_SOCKET -i $SSH_KEY -CNn -D $PROXY_PORT $PROXY_TARGET
	fi
done
