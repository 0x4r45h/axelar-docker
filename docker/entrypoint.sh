#!/bin/bash
#GENESIS_BINARY="/root/.axelar/cosmovisor/genesis/bin/lavad --home /root/.axelar"
GENESIS_BINARY="axelard"

init_function() {
  if [ -z "$ACCOUNT_NAME" ]; then
    echo "Error: ACCOUNT_NAME environment variable is not set or empty."
    exit 1
  fi
  output=$($GENESIS_BINARY keys list)
  if echo "$output" | grep -q "$ACCOUNT_NAME"; then
    echo "Account '$ACCOUNT_NAME' already exists."
    $GENESIS_BINARY keys show "$ACCOUNT_NAME"
  else
    echo "Account '$ACCOUNT_NAME' not found."
    echo "Would you like to recover a previous account using mnemonic keys? (Y/N)"
    while true; do
      read -p "Enter choice: " choice
      case "$choice" in
      [Yy])
        $GENESIS_BINARY keys add "$ACCOUNT_NAME" --recover
        break
        ;;
      [Nn])
        $GENESIS_BINARY keys add "$ACCOUNT_NAME"
        break
        ;;
      *)
        echo "Invalid choice. Please enter Y or N."
        ;;
      esac
    done
  fi

  # Backup genesis.json
  mv /root/.axelar/config/genesis.json /root/.axelar/config/genesis.json.bak && \
  mv /root/.axelar/config/addrbook.json /root/.axelar/config/addrbook.json.bak
  # Run lavad init command
#  $GENESIS_BINARY init $MONIKER_NAME --chain-id $CHAIN_ID >/dev/null 2>&1
  $GENESIS_BINARY init $MONIKER_NAME --chain-id $CHAIN_ID
  # Replace genesis.json with backed up file
  mv /root/.axelar/config/genesis.json.bak /root/.axelar/config/genesis.json && \
  mv /root/.axelar/config/addrbook.json.bak /root/.axelar/config/addrbook.json
  # set chain id for testnet-2
  #  $GENESIS_BINARY config chain-id lava-testnet-2
  # Set minimum gas price
  sed -i -e "s|^minimum-gas-prices *=.*|minimum-gas-prices = \"0.007uaxl\"|" /root/.axelar/config/app.toml

  # Set pruning
  sed -i \
    -e 's|^pruning *=.*|pruning = "custom"|' \
    -e 's|^pruning-keep-recent *=.*|pruning-keep-recent = "100"|' \
    -e 's|^pruning-keep-every *=.*|pruning-keep-every = "0"|' \
    -e 's|^pruning-interval *=.*|pruning-interval = "19"|' \
    /root/.axelar/config/app.toml
  # Print validator pubkey

  echo "Validator pubkey is : "
  $GENESIS_BINARY tendermint show-validator
}

main() {
  case "$1" in
  "init")
    init_function
    ;;
  "start-node")
    cosmovisor start --p2p.seeds $SEED_NODE
    ;;
  *)
    exec "$@"
    ;;
  esac
}

main "$@"
