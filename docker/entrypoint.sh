#!/bin/bash
GENESIS_BINARY="axelard"

update_snapshot() {
  cp $HOME/.axelar/data/priv_validator_state.json $HOME/.axelar/priv_validator_state.json.backup
  rm -rf $HOME/.axelar/data

  curl -L $SNAPSHOT_ENDPOINT | tar -Ilz4 -xf - -C $HOME/.axelar
  mv $HOME/.axelar/priv_validator_state.json.backup $HOME/.axelar/data/priv_validator_state.json

}

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



  # Run init command
    $GENESIS_BINARY init $MONIKER_NAME --chain-id $CHAIN_ID >/dev/null 2>&1
  # Replace genesis.json with backed up file
    if [ "$CHAIN_ID" = "axelar-dojo-1" ]; then
    cp -f /tmp/mainnet/genesis.json /root/.axelar/config/genesis.json
    cp -f /tmp/mainnet/addrbook.json /root/.axelar/config/addrbook.json
    else
    cp -f /tmp/testnet/genesis.json /root/.axelar/config/genesis.json
    fi
  # Set minimum gas price
  sed -i -e "s|^minimum-gas-prices *=.*|minimum-gas-prices = \"0.007uaxl\"|" $HOME/.axelar/config/app.toml

  # Set pruning
  sed -i \
    -e 's|^pruning *=.*|pruning = "custom"|' \
    -e 's|^pruning-keep-recent *=.*|pruning-keep-recent = "55000"|' \
    -e 's|^pruning-keep-every *=.*|pruning-keep-every = "500"|' \
    -e 's|^pruning-interval *=.*|pruning-interval = "17"|' \
    $HOME/.axelar/config/app.toml

# Set custom ports
sed -i -e "s%^laddr = \"tcp://127.0.0.1:26657\"%laddr = \"tcp://0.0.0.0:26657\"%; s%^pprof_laddr = \"localhost:6060\"%pprof_laddr = \"0.0.0.0:6060\"%;" $HOME/.axelar/config/config.toml
# set flags
sed -i '/\[api\]/,/^ *enable =/ s/enable = false/enable = true/' $HOME/.axelar/config/app.toml
sed -i '/\[grpc\]/,/^ *enable =/ s/enable = false/enable = true/' $HOME/.axelar/config/app.toml
sed -i '/\[grpc-web\]/,/^ *enable =/ s/enable = false/enable = true/' $HOME/.axelar/config/app.toml
sed -i '/\[rosetta\]/,/^ *enable =/ s/enable = true/enable = false/' $HOME/.axelar/config/app.toml

  # Print validator pubkey

  echo "Validator pubkey is : "
  $GENESIS_BINARY tendermint show-validator
}

main() {
  case "$1" in
  "init")
    init_function
    ;;
  "update-snapshot")
    update_snapshot
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
