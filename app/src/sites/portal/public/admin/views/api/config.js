define([], function () {
  var _providers = ["INFURA", "GETBLOCK", "QUICKNODE", "CUSTOM"];
  var _blockchains = [
    {
      id: "eth",
      value: "Ethereum",
      api_interface: [
        { id: "jsonrpc", value: "JSON-RPC" },
        { id: "ws", value: "WS" },
      ],
      network: [
        { id: "mainnet", value: "Mainnet" },
        { id: "testnet", value: "Testnet" },
      ],
    },
    {
      id: "btc",
      value: "Bitcoin",
      api_interface: [
        { id: "jsonrpc", value: "JSON-RPC" },
        { id: "rest", value: "Rest" },
      ],
      network: [
        { id: "mainnet", value: "Mainnet" },
        { id: "testnet", value: "Testnet" },
      ],
    },
    {
      id: "bsc",
      value: "Binance Smart Chain",
      api_interface: [
        { id: "jsonrpc", value: "JSON-RPC" },
        { id: "ws", value: "WS" },
      ],
      network: [
        { id: "mainnet", value: "Mainnet" },
        { id: "testnet", value: "Testnet" },
      ],
    },
    {
      id: "sol",
      value: "Solana",
      api_interface: [
        { id: "jsonrpc", value: "JSON-RPC" },
        { id: "ws", value: "WS" },
      ],
      network: [
        { id: "mainnet", value: "Mainnet" },
        { id: "testnet", value: "Testnet" },
        { id: "devnet", value: "Devnet" },
      ],
    },
    {
      id: "bch",
      value: "Bitcoin Cash",
      api_interface: [
        { id: "jsonrpc", value: "JSON-RPC" },
        { id: "ws", value: "WS" },
      ],
      network: [{ id: "mainnet", value: "Mainnet" }],
    },
    {
      id: "xrp",
      value: "XRP",
      api_interface: [{ id: "jsonrpc", value: "JSON-RPC" }],
      network: [{ id: "mainnet", value: "Mainnet" }],
    },
    {
      id: "dot",
      value: "Palkadot",
      api_interface: [{ id: "jsonrpc", value: "JSON-RPC" }],
      network: [
        { id: "mainnet", value: "Mainnet" },
        { id: "testnet", value: "Testnet" },
      ],
    },
    {
      id: "zen",
      value: "Horizen",
      api_interface: [{ id: "jsonrpc", value: "JSON-RPC" }],
      network: [{ id: "mainnet", value: "Mainnet" }],
    },
    { id: "bsv", value: "Bitcoin-SV" },
    { id: "eos", value: "EOS" },
    { id: "ltc", value: "Litecoin" },
    { id: "stake", value: "xDai" },
    { id: "ada", value: "Cardano" },
    { id: "xmr", value: "Monero" },
    { id: "matic", value: "Polygon" },
    { id: "ksm", value: "Kusama" },
    { id: "nem", value: "NEM" },
    { id: "neo", value: "NEO" },
    { id: "trx", value: "Tron" },
    { id: "xlm", value: "Stellar" },
    { id: "xtz", value: "Tezos" },
    { id: "atom", value: "Cosmos" },
    { id: "iota", value: "Miota" },
    { id: "dash", value: "DASH" },
    { id: "zcash", value: "ZEC" },
    { id: "theta", value: "THETA" },
    { id: "etc", value: "Ethereum Classic" },
    { id: "doge", value: "Dogecoin" },
    { id: "waves", value: "Waves" },
    { id: "dgb", value: "DigiByte" },
    { id: "icx", value: "ICON" },
    { id: "zil", value: "Zilliqa" },
    { id: "band", value: "Band Protocol" },
    { id: "dcr", value: "Decred" },
    { id: "btg", value: "Bitcoin Gold" },
    { id: "lsk", value: "Lisk" },
    { id: "xvg", value: "Verge" },
    { id: "steem", value: "Steem" },
    { id: "waxp", value: "Wax" },
    { id: "hive", value: "Hive" },
    { id: "rdd", value: "Reddcoin" },
    { id: "ccxx", value: "Counos X" },
    { id: "bcn", value: "Bytecoin" },
    { id: "grs", value: "Groestlcoin" },
    { id: "fct", value: "Factom" },
    { id: "rsk", value: "Rsk" },
    { id: "fuse", value: "Fuse.io" },
  ];
  return {
    blockchains: _blockchains,
    providers: _providers,
  };
});
