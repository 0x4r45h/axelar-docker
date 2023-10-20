#!/bin/bash

CURRENT_BINARY="axelard"
set -e

_get_wallet_balance() {
  WALLET_ADDRESS=$($CURRENT_BINARY keys show -a $ACCOUNT_NAME)
  $CURRENT_BINARY query \
      bank balances \
      $WALLET_ADDRESS \
      --denom uaxl
}
_validator_connect() {
$CURRENT_BINARY tx staking create-validator \
    --amount="10000uaxl" \
    --pubkey=$($CURRENT_BINARY tendermint show-validator) \
    --moniker=$MONIKER_NAME \
    --chain-id=$CHAIN_ID \
    --commission-rate="0.10" \
    --commission-max-rate="0.20" \
    --commission-max-change-rate="0.01" \
    --min-self-delegation="10000" \
    --gas="auto" \
    --gas-adjustment="1.5" \
    --gas-prices="0.05uaxl" \
    --from=$ACCOUNT_NAME
}

_validator_unjail() {
$CURRENT_BINARY tx slashing unjail \
    --chain-id=$CHAIN_ID \
    --gas="auto" \
    --gas-adjustment="1.5" \
    --gas-prices="0.05uaxl" \
    --from=$ACCOUNT_NAME
}
_vote() {
$CURRENT_BINARY tx gov vote $2 $3\
    --chain-id=$CHAIN_ID \
    --gas="auto" \
    --gas-adjustment="1.5" \
    --gas-prices="0.05uaxl" \
    --from=$ACCOUNT_NAME
}

_delegate_to_validator() {
  # first argument is valoper address of validator and second is the amount e.g 1000000u
$CURRENT_BINARY-appd tx staking delegate \
    $2 $3 \
    --chain-id=$CHAIN_ID \
    --gas="auto" \
    --gas-adjustment="1.5" \
    --gas-prices="0.05uaxl" \
    --from=$ACCOUNT_NAME
}
_getNodeValoperAddress() {
  $CURRENT_BINARY keys show $ACCOUNT_NAME --bech val -a
}
_getValidatorStakingState() {
  valoper=$(_getNodeValoperAddress)
  $CURRENT_BINARY query staking validator $valoper --chain-id $CHAIN_ID
}

if [ "$1" = 'wallet:balance' ]; then
  _get_wallet_balance
elif [ "$1" = 'node:backup' ]; then
    if [ -z "$2" ]; then
      echo "Usage: $0 node:backup VOLUME_NAME. VOLUME_NAME is required"
      exit 1
    fi

    VOLUME_NAME="$2"

    mkdir -p ./backup_validator_keys
    docker run --rm \
      -v "$VOLUME_NAME:/src" \
      -v "$(pwd)/backup_validator_keys:/dst" \
      busybox sh -c "cp /src/config/node_key.json /src/config/priv_validator_key.json /dst/"

elif [ "$1" = 'node:restore' ]; then
      if [ -z "$2" ]; then
        echo "Usage: $0 node:restore VOLUME_NAME. VOLUME_NAME is required"
        exit 1
      fi

      VOLUME_NAME="$2"
    docker run --rm \
    -v $VOLUME_NAME:/dst \
    -v $(pwd)/backup_validator_keys:/src \
    busybox sh -c "cp /src/node_key.json /src/priv_validator_key.json /dst/config/"
elif [ "$1" = 'node:valoper' ]; then
  _getNodeValoperAddress
elif [ "$1" = 'validator:query' ]; then
  _getValidatorStakingState
elif [ "$1" = 'validator:connect' ]; then
  _validator_connect
elif [ "$1" = 'validator:unjail' ]; then
  _validator_unjail
elif [ "$1" = 'validator:delegate' ]; then
  _delegate_to_validator "$@"
elif [ "$1" = 'validator:vote' ]; then
  _vote "$@"
elif [ "$1" = 'validator:sync-info' ]; then
  $CURRENT_BINARY status | jq .SyncInfo
else
  echo "bad command"
fi
