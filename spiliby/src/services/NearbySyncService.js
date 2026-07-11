// NearbySyncService — placeholder for a higher-level "nearby devices" sync
// experience that picks the best available transport (Bluetooth, Wi-Fi
// Direct, or local network) automatically.
// TODO(sync): orchestrate BluetoothService / WifiDirectService under one
// simple "sync with people nearby" call, with conflict resolution for
// expenses edited on two devices at once.
export const NearbySyncService = {
  discoverPeers: async () => { throw new Error('NearbySyncService.discoverPeers: not implemented yet'); },
  syncGroupWithPeer: async (_groupId, _peerId) => { throw new Error('NearbySyncService.syncGroupWithPeer: not implemented yet'); },
};
