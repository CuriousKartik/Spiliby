// BluetoothService — placeholder for future peer-to-peer sync over Bluetooth.
// TODO(sync): use the Web Bluetooth API (or a native bridge post-APK
// conversion) to discover nearby classmates' devices and exchange group /
// expense payloads directly, no internet required.
export const BluetoothService = {
  isSupported: () => 'bluetooth' in navigator,
  scan: async () => { throw new Error('BluetoothService.scan: not implemented yet'); },
  connect: async (_deviceId) => { throw new Error('BluetoothService.connect: not implemented yet'); },
  sendPayload: async (_deviceId, _payload) => { throw new Error('BluetoothService.sendPayload: not implemented yet'); },
};
