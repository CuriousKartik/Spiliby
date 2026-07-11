// WifiDirectService — placeholder for Wi-Fi Direct transport, useful for
// larger payloads (e.g. syncing a whole trip's worth of expenses/photos)
// where Bluetooth is too slow.
// TODO(sync): implement via native Android APIs after Bubblewrap
// conversion; no browser-only equivalent exists today.
export const WifiDirectService = {
  isSupported: () => false,
  createGroup: async () => { throw new Error('WifiDirectService.createGroup: not implemented yet'); },
  joinGroup: async (_groupInfo) => { throw new Error('WifiDirectService.joinGroup: not implemented yet'); },
};
